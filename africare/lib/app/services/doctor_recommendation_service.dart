import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:get/get.dart';
import '../models/doctor.dart';

class DoctorRecommendationService extends GetxService {
  static DoctorRecommendationService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseModelDownloader _modelDownloader = FirebaseModelDownloader.instance;
  Interpreter? _interpreter;

  Future<void> initialize() async {
    try {
      // Download the TFLite model
      final model = await _modelDownloader.getModel(
        'doctor_recommendation_model',
        FirebaseModelDownloadType.localModel,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
        ),
      );

      // Load the model
      _interpreter = await Interpreter.fromFile(model.file);
    } catch (e) {
      print('Error initializing recommendation model: $e');
    }
  }

  Future<List<Doctor>> getRecommendedDoctors({
    required List<String> symptoms,
    required List<String> specializations,
    required Map<String, dynamic> patientHistory,
  }) async {
    try {
      // Get all doctors
      final doctorsSnapshot = await _firestore.collection('doctors').get();
      final doctors = doctorsSnapshot.docs
          .map((doc) => Doctor.fromMap(doc.data()))
          .toList();

      // If ML model is not available, fall back to rule-based recommendations
      if (_interpreter == null) {
        return _getRuleBasedRecommendations(
          doctors: doctors,
          symptoms: symptoms,
          specializations: specializations,
        );
      }

      // Prepare input features for ML model
      final features = _prepareFeatures(
        symptoms: symptoms,
        specializations: specializations,
        patientHistory: patientHistory,
      );

      // Run inference
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputBuffer = List<double>.filled(outputShape[1], 0).reshape(outputShape);
      
      _interpreter!.run(features, outputBuffer);

      // Process results
      final scores = List<double>.from(outputBuffer[0]);
      final rankedDoctors = List<MapEntry<Doctor, double>>.generate(
        doctors.length,
        (i) => MapEntry(doctors[i], scores[i]),
      )..sort((a, b) => b.value.compareTo(a.value));

      return rankedDoctors.map((entry) => entry.key).toList();
    } catch (e) {
      print('Error getting recommended doctors: $e');
      return [];
    }
  }

  List<Doctor> _getRuleBasedRecommendations({
    required List<Doctor> doctors,
    required List<String> symptoms,
    required List<String> specializations,
  }) {
    // Score each doctor based on matching criteria
    final scoredDoctors = doctors.map((doctor) {
      var score = 0.0;

      // Check specialization match
      if (specializations.contains(doctor.specialization)) {
        score += 1.0;
      }

      // Check experience
      score += doctor.experience / 10; // Normalize by assuming max experience is 10 years

      // Check rating
      score += doctor.rating / 5; // Normalize by max rating of 5

      // Check availability
      if (doctor.isAvailableNow) {
        score += 0.5;
      }

      return MapEntry(doctor, score);
    }).toList();

    // Sort by score
    scoredDoctors.sort((a, b) => b.value.compareTo(a.value));

    return scoredDoctors.map((entry) => entry.key).toList();
  }

  List<List<double>> _prepareFeatures({
    required List<String> symptoms,
    required List<String> specializations,
    required Map<String, dynamic> patientHistory,
  }) {
    // Convert categorical features to numerical using one-hot encoding
    final features = <double>[];

    // Encode symptoms (assuming we have a predefined list of all possible symptoms)
    final allSymptoms = [
      'fever', 'cough', 'headache', 'fatigue', 'nausea',
      'dizziness', 'chest_pain', 'shortness_of_breath', 'body_aches',
      'sore_throat', 'runny_nose', 'stomach_pain', 'diarrhea',
      'vomiting', 'joint_pain', 'rash', 'loss_of_appetite',
      'back_pain', 'muscle_pain', 'chills',
    ];

    for (final symptom in allSymptoms) {
      features.add(symptoms.contains(symptom) ? 1.0 : 0.0);
    }

    // Encode specializations
    final allSpecializations = [
      'general_practitioner', 'cardiologist', 'dermatologist',
      'neurologist', 'pediatrician', 'psychiatrist', 'orthopedist',
      'gynecologist', 'urologist', 'ent_specialist', 'ophthalmologist',
    ];

    for (final specialization in allSpecializations) {
      features.add(specializations.contains(specialization) ? 1.0 : 0.0);
    }

    // Add patient history features
    features.addAll([
      patientHistory['age'] as double / 100, // Normalize age
      patientHistory['hasChronicCondition'] ? 1.0 : 0.0,
      patientHistory['previousVisits'] as double / 10, // Normalize visits
      patientHistory['preferredGender'] == 'male' ? 1.0 : 0.0,
      patientHistory['preferredGender'] == 'female' ? 1.0 : 0.0,
    ]);

    return [features];
  }

  Future<Map<String, dynamic>> analyzePatientHistory(String userId) async {
    try {
      final appointments = await _firestore
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .get();

      final vitals = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vitals')
          .get();

      final medications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .get();

      // Analyze appointment patterns
      final specializations = appointments.docs
          .map((doc) => doc.data()['doctorSpecialization'] as String)
          .toSet()
          .toList();

      final commonSymptoms = appointments.docs
          .expand((doc) => (doc.data()['symptoms'] as List).cast<String>())
          .fold<Map<String, int>>({}, (map, symptom) {
            map[symptom] = (map[symptom] ?? 0) + 1;
            return map;
          })
          .entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Analyze vital trends
      final vitalReadings = vitals.docs
          .map((doc) => doc.data())
          .toList()
        ..sort((a, b) => (a['timestamp'] as Timestamp)
            .compareTo(b['timestamp'] as Timestamp));

      // Analyze medication history
      final activeMedications = medications.docs
          .where((doc) {
            final endDate = doc.data()['endDate'] as Timestamp;
            return endDate.toDate().isAfter(DateTime.now());
          })
          .map((doc) => doc.data()['name'] as String)
          .toList();

      return {
        'frequentSpecializations': specializations,
        'commonSymptoms': commonSymptoms.take(5).map((e) => e.key).toList(),
        'vitalTrends': vitalReadings,
        'activeMedications': activeMedications,
        'totalVisits': appointments.docs.length,
      };
    } catch (e) {
      print('Error analyzing patient history: $e');
      return {};
    }
  }
}
