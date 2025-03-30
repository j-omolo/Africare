import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({super.key});

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _dateFormat = DateFormat('MMM d, y');
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Tracking'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Vitals'),
              Tab(text: 'Medications'),
              Tab(text: 'Exercise'),
              Tab(text: 'Sleep'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVitalsTab(),
            _buildMedicationsTab(),
            _buildExerciseTab(),
            _buildSleepTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDataDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildVitalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('vitals')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final vitals = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildVitalsChart(vitals),
              const SizedBox(height: 24),
              _buildVitalsList(vitals),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalsChart(List<QueryDocumentSnapshot> vitals) {
    if (vitals.isEmpty) return const SizedBox();

    final bloodPressureData = vitals.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FlSpot(
        vitals.indexOf(doc).toDouble(),
        data['systolic'].toDouble(),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= vitals.length) return const Text('');
                  final data = vitals[value.toInt()].data() as Map<String, dynamic>;
                  return Text(
                    DateFormat('MM/dd').format((data['timestamp'] as Timestamp).toDate()),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: bloodPressureData,
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsList(List<QueryDocumentSnapshot> vitals) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vitals.length,
      itemBuilder: (context, index) {
        final vital = vitals[index].data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(
              '${vital['systolic']}/${vital['diastolic']} mmHg',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Heart Rate: ${vital['heartRate']} bpm\n'
              'Temperature: ${vital['temperature']}°C\n'
              'Recorded: ${_dateFormat.format((vital['timestamp'] as Timestamp).toDate())}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('medications')
          .orderBy('nextDose')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final medications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index].data() as Map<String, dynamic>;
            final nextDose = (medication['nextDose'] as Timestamp).toDate();
            final isOverdue = nextDose.isBefore(DateTime.now());

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(
                  Icons.medication,
                  color: isOverdue ? Colors.red : Colors.green,
                ),
                title: Text(
                  medication['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Dosage: ${medication['dosage']}\n'
                  'Next dose: ${_dateFormat.format(nextDose)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _markMedicationTaken(medications[index].id),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('exercise')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final exercises = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(
                  _getExerciseIcon(exercise['type']),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  exercise['type'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Duration: ${exercise['duration']} minutes\n'
                  'Calories: ${exercise['calories']} kcal\n'
                  'Date: ${_dateFormat.format((exercise['date'] as Timestamp).toDate())}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSleepTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('sleep')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sleepRecords = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sleepRecords.length,
          itemBuilder: (context, index) {
            final sleep = sleepRecords[index].data() as Map<String, dynamic>;
            final duration = sleep['duration'] as int;
            final hours = duration ~/ 60;
            final minutes = duration % 60;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(
                  Icons.bedtime,
                  color: Colors.indigo,
                ),
                title: Text(
                  '${hours}h ${minutes}m',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Quality: ${sleep['quality']}/5\n'
                  'Date: ${_dateFormat.format((sleep['date'] as Timestamp).toDate())}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  IconData _getExerciseIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  Future<void> _showAddDataDialog() async {
    final tabController = DefaultTabController.of(context);
    final currentTab = tabController.index;
    
    switch (currentTab) {
      case 0:
        await _showAddVitalsDialog();
        break;
      case 1:
        await _showAddMedicationDialog();
        break;
      case 2:
        await _showAddExerciseDialog();
        break;
      case 3:
        await _showAddSleepDialog();
        break;
    }
  }

  Future<void> _showAddVitalsDialog() async {
    final formKey = GlobalKey<FormState>();
    final vitals = <String, dynamic>{};

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vitals'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Systolic (mmHg)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final number = int.tryParse(value);
                    if (number == null || number < 0) return 'Invalid value';
                    return null;
                  },
                  onSaved: (value) => vitals['systolic'] = int.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Diastolic (mmHg)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final number = int.tryParse(value);
                    if (number == null || number < 0) return 'Invalid value';
                    return null;
                  },
                  onSaved: (value) => vitals['diastolic'] = int.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final number = int.tryParse(value);
                    if (number == null || number < 0) return 'Invalid value';
                    return null;
                  },
                  onSaved: (value) => vitals['heartRate'] = int.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final number = double.tryParse(value);
                    if (number == null || number < 0) return 'Invalid value';
                    return null;
                  },
                  onSaved: (value) => vitals['temperature'] = double.parse(value!),
                ),
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
                vitals['timestamp'] = FieldValue.serverTimestamp();
                _saveVitals(vitals);
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVitals(Map<String, dynamic> vitals) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('vitals')
          .add(vitals);

      Get.snackbar(
        'Success',
        'Vitals recorded successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to record vitals: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _markMedicationTaken(String medicationId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('medications')
          .doc(medicationId)
          .get();

      final data = doc.data()!;
      final frequency = data['frequency'] as int; // hours
      final nextDose = DateTime.now().add(Duration(hours: frequency));

      await doc.reference.update({'nextDose': Timestamp.fromDate(nextDose)});

      Get.snackbar(
        'Success',
        'Medication marked as taken',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update medication: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
