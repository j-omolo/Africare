import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';

class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find();
  
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track health metrics
  Future<void> trackHealthMetrics({
    required String metricType,
    required Map<String, dynamic> values,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('healthMetrics')
          .doc(metricType)
          .collection('readings')
          .add({
        ...values,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Log to Analytics
      await _analytics.logEvent(
        name: 'health_metric_recorded',
        parameters: {
          'metric_type': metricType,
          'values': values.toString(),
        },
      );
    } catch (e) {
      print('Error tracking health metrics: $e');
    }
  }

  // Get health trends
  Future<List<Map<String, dynamic>>> getHealthTrends({
    required String metricType,
    required int days,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('healthMetrics')
          .doc(metricType)
          .collection('readings')
          .where('timestamp', isGreaterThan: startDate)
          .orderBy('timestamp')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting health trends: $e');
      return [];
    }
  }

  // Track symptom check
  Future<void> trackSymptomCheck({
    required List<String> symptoms,
    required String urgencyLevel,
    required List<String> conditions,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'symptom_check',
        parameters: {
          'symptoms': symptoms.join(','),
          'urgency_level': urgencyLevel,
          'conditions': conditions.join(','),
        },
      );
    } catch (e) {
      print('Error tracking symptom check: $e');
    }
  }

  // Track appointment booking
  Future<void> trackAppointmentBooking({
    required String doctorId,
    required String doctorName,
    required String specialization,
    required DateTime appointmentTime,
    required bool isVideoConsultation,
    required double fee,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'appointment_booked',
        parameters: {
          'doctor_id': doctorId,
          'doctor_name': doctorName,
          'specialization': specialization,
          'appointment_time': appointmentTime.toIso8601String(),
          'is_video_consultation': isVideoConsultation,
          'fee': fee,
        },
      );
    } catch (e) {
      print('Error tracking appointment booking: $e');
    }
  }

  // Track medication adherence
  Future<void> trackMedicationAdherence({
    required String medicationName,
    required bool takenOnTime,
    required DateTime scheduledTime,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicationAdherence')
          .add({
        'medication_name': medicationName,
        'taken_on_time': takenOnTime,
        'scheduled_time': scheduledTime,
        'actual_time': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'medication_taken',
        parameters: {
          'medication_name': medicationName,
          'taken_on_time': takenOnTime,
          'scheduled_time': scheduledTime.toIso8601String(),
        },
      );
    } catch (e) {
      print('Error tracking medication adherence: $e');
    }
  }

  // Get medication adherence rate
  Future<double> getMedicationAdherenceRate({
    required int days,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0.0;

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicationAdherence')
          .where('scheduled_time', isGreaterThan: startDate)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final takenOnTime = snapshot.docs
          .where((doc) => doc.data()['taken_on_time'] as bool)
          .length;

      return takenOnTime / snapshot.docs.length;
    } catch (e) {
      print('Error getting medication adherence rate: $e');
      return 0.0;
    }
  }

  // Track insurance claim
  Future<void> trackInsuranceClaim({
    required String insuranceProvider,
    required String claimType,
    required double amount,
    required String status,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'insurance_claim',
        parameters: {
          'insurance_provider': insuranceProvider,
          'claim_type': claimType,
          'amount': amount,
          'status': status,
        },
      );
    } catch (e) {
      print('Error tracking insurance claim: $e');
    }
  }

  // Get health insights
  Future<Map<String, dynamic>> getHealthInsights() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      // Get various health metrics
      final vitalsData = await getHealthTrends(metricType: 'vitals', days: 30);
      final medicationAdherence = await getMedicationAdherenceRate(days: 30);
      
      // Calculate insights
      final insights = <String, dynamic>{
        'medication_adherence': medicationAdherence,
        'vital_trends': _analyzeVitalTrends(vitalsData),
        'recommendations': _generateRecommendations(
          vitalsData: vitalsData,
          medicationAdherence: medicationAdherence,
        ),
      };

      return insights;
    } catch (e) {
      print('Error getting health insights: $e');
      return {};
    }
  }

  Map<String, dynamic> _analyzeVitalTrends(List<Map<String, dynamic>> vitalsData) {
    if (vitalsData.isEmpty) return {};

    // Calculate average values
    final systolicReadings = vitalsData
        .map((data) => data['systolic'] as num)
        .toList();
    final diastolicReadings = vitalsData
        .map((data) => data['diastolic'] as num)
        .toList();
    final heartRateReadings = vitalsData
        .map((data) => data['heartRate'] as num)
        .toList();

    return {
      'systolic': {
        'average': _calculateAverage(systolicReadings),
        'trend': _calculateTrend(systolicReadings),
      },
      'diastolic': {
        'average': _calculateAverage(diastolicReadings),
        'trend': _calculateTrend(diastolicReadings),
      },
      'heart_rate': {
        'average': _calculateAverage(heartRateReadings),
        'trend': _calculateTrend(heartRateReadings),
      },
    };
  }

  double _calculateAverage(List<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _calculateTrend(List<num> values) {
    if (values.length < 2) return 'stable';
    
    final first = values.first;
    final last = values.last;
    final difference = last - first;
    
    if (difference > 0) return 'increasing';
    if (difference < 0) return 'decreasing';
    return 'stable';
  }

  List<String> _generateRecommendations({
    required List<Map<String, dynamic>> vitalsData,
    required double medicationAdherence,
  }) {
    final recommendations = <String>[];

    // Check medication adherence
    if (medicationAdherence < 0.8) {
      recommendations.add(
        'Your medication adherence is below 80%. Set reminders to take medications on time.',
      );
    }

    // Check vital signs
    if (vitalsData.isNotEmpty) {
      final latestVitals = vitalsData.last;
      final systolic = latestVitals['systolic'] as num;
      final diastolic = latestVitals['diastolic'] as num;

      if (systolic > 140 || diastolic > 90) {
        recommendations.add(
          'Your blood pressure readings are high. Consider scheduling a check-up.',
        );
      }
    }

    return recommendations;
  }
}
