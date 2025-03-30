import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  final List<String> _selectedSymptoms = [];
  final List<String> _commonSymptoms = [
    'Fever',
    'Cough',
    'Headache',
    'Fatigue',
    'Nausea',
    'Dizziness',
    'Chest Pain',
    'Shortness of Breath',
    'Body Aches',
    'Sore Throat',
    'Runny Nose',
    'Stomach Pain',
    'Diarrhea',
    'Vomiting',
    'Joint Pain',
    'Rash',
    'Loss of Appetite',
    'Back Pain',
    'Muscle Pain',
    'Chills',
  ];

  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSymptomSelection(),
            const SizedBox(height: 24),
            if (_selectedSymptoms.isNotEmpty) _buildAnalyzeButton(),
            const SizedBox(height: 24),
            if (_analysis != null) _buildAnalysisResult(),
            const SizedBox(height: 24),
            _buildPreviousChecks(),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Symptoms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonSymptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return FilterChip(
              label: Text(symptom),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeSymptoms,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isAnalyzing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Analyze Symptoms',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final possibleConditions = _analysis!['possibleConditions'] as List<dynamic>;
    final urgencyLevel = _analysis!['urgencyLevel'] as String;
    final recommendations = _analysis!['recommendations'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Result',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getUrgencyIcon(urgencyLevel),
                      color: _getUrgencyColor(urgencyLevel),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Urgency Level: $urgencyLevel',
                      style: TextStyle(
                        color: _getUrgencyColor(urgencyLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Possible Conditions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...possibleConditions.map((condition) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8),
                          const SizedBox(width: 8),
                          Text(condition),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendations.map((recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(recommendation)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (urgencyLevel == 'High' || urgencyLevel == 'Medium')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to doctor booking
                Get.toNamed('/book-appointment');
              },
              icon: const Icon(Icons.medical_services),
              label: const Text('Book Doctor Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: urgencyLevel == 'High' ? Colors.red : Colors.orange,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviousChecks() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('symptomChecks')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final checks = snapshot.data!.docs;

        if (checks.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previous Checks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checks.length,
              itemBuilder: (context, index) {
                final check = checks[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(
                      _getUrgencyIcon(check['urgencyLevel']),
                      color: _getUrgencyColor(check['urgencyLevel']),
                    ),
                    title: Text(
                      (check['symptoms'] as List<dynamic>).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Urgency: ${check['urgencyLevel']}\n'
                      'Date: ${_formatDate(check['timestamp'].toDate())}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _analyzeSymptoms() async {
    if (_selectedSymptoms.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one symptom',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      // TODO: Replace with actual API call to a medical API
      // This is a mock response for demonstration
      await Future.delayed(const Duration(seconds: 2));
      final analysis = {
        'possibleConditions': [
          'Common Cold',
          'Seasonal Allergies',
          'Upper Respiratory Infection',
        ],
        'urgencyLevel': _selectedSymptoms.length > 5 ? 'High' : 'Medium',
        'recommendations': [
          'Rest and stay hydrated',
          'Monitor your symptoms',
          'Take over-the-counter medications as needed',
          'Seek medical attention if symptoms worsen',
        ],
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('symptomChecks')
          .add({
        'symptoms': _selectedSymptoms,
        'analysis': analysis,
        'urgencyLevel': analysis['urgencyLevel'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _analysis = analysis;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to analyze symptoms: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
}
