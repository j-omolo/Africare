import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Prescriptions'),
            Tab(text: 'Lab Results'),
            Tab(text: 'Medical History'),
            Tab(text: 'Allergies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrescriptionsTab(),
          _buildLabResultsTab(),
          _buildMedicalHistoryTab(),
          _buildAllergiesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('prescriptions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prescriptions = snapshot.data!.docs;

        if (prescriptions.isEmpty) {
          return _buildEmptyState('No prescriptions found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = prescriptions[index].data() as Map<String, dynamic>;
            return _buildPrescriptionCard(prescription);
          },
        );
      },
    );
  }

  Widget _buildLabResultsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('labResults')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs;

        if (results.isEmpty) {
          return _buildEmptyState('No lab results found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index].data() as Map<String, dynamic>;
            return _buildLabResultCard(result);
          },
        );
      },
    );
  }

  Widget _buildMedicalHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('medicalHistory')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data!.docs;

        if (history.isEmpty) {
          return _buildEmptyState('No medical history found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final record = history[index].data() as Map<String, dynamic>;
            return _buildMedicalHistoryCard(record);
          },
        );
      },
    );
  }

  Widget _buildAllergiesTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final allergies = (userData?['allergies'] as List<dynamic>?) ?? [];

        if (allergies.isEmpty) {
          return _buildEmptyState('No allergies recorded');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allergies.length,
          itemBuilder: (context, index) {
            final allergy = allergies[index] as Map<String, dynamic>;
            return _buildAllergyCard(allergy);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new record',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          prescription['medication'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Prescribed by Dr. ${prescription['doctor']} on ${_formatDate(prescription['date'].toDate())}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Dosage', prescription['dosage']),
                const SizedBox(height: 8),
                _buildInfoRow('Duration', prescription['duration']),
                const SizedBox(height: 8),
                _buildInfoRow('Instructions', prescription['instructions']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResultCard(Map<String, dynamic> result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          result['testName'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Test date: ${_formatDate(result['date'].toDate())}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Result', result['result']),
                const SizedBox(height: 8),
                _buildInfoRow('Reference Range', result['referenceRange']),
                const SizedBox(height: 8),
                _buildInfoRow('Lab', result['lab']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          record['condition'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Diagnosed: ${_formatDate(record['date'].toDate())}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Symptoms', record['symptoms']),
                const SizedBox(height: 8),
                _buildInfoRow('Treatment', record['treatment']),
                const SizedBox(height: 8),
                _buildInfoRow('Notes', record['notes']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyCard(Map<String, dynamic> allergy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text(
          allergy['allergen'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Severity: ${allergy['severity']}\nReaction: ${allergy['reaction']}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Future<void> _showAddRecordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String recordType = 'prescription';
    final Map<String, String> formData = {};

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical Record'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: recordType,
                  items: const [
                    DropdownMenuItem(
                      value: 'prescription',
                      child: Text('Prescription'),
                    ),
                    DropdownMenuItem(
                      value: 'labResult',
                      child: Text('Lab Result'),
                    ),
                    DropdownMenuItem(
                      value: 'medicalHistory',
                      child: Text('Medical History'),
                    ),
                    DropdownMenuItem(
                      value: 'allergy',
                      child: Text('Allergy'),
                    ),
                  ],
                  onChanged: (value) {
                    recordType = value!;
                  },
                ),
                const SizedBox(height: 16),
                // Add dynamic form fields based on record type
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                _saveRecord(recordType, formData);
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord(String type, Map<String, String> data) async {
    try {
      final collection = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection(type);

      await collection.add({
        ...data,
        'date': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Medical record added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add medical record: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }
}
