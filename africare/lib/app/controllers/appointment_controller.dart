import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../services/analytics_service.dart';
import '../services/payment_service.dart';

class AppointmentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService.to;
  final AnalyticsService _analytics = AnalyticsService.to;

  final appointments = <Appointment>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      isLoading.value = true;
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .get();

      appointments.value = snapshot.docs
          .map((doc) => Appointment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load appointments',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> bookAppointment({
    required Doctor doctor,
    required DateTime dateTime,
    required bool isVideoConsultation,
    required double amount,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        Get.snackbar(
          'Error',
          'Please sign in to book an appointment',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Create appointment
      final appointment = Appointment(
        id: '',
        doctorId: doctor.id,
        patientId: userId,
        dateTime: dateTime,
        isVideoConsultation: isVideoConsultation,
        status: 'pending',
        amount: amount,
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection('appointments')
          .add(appointment.toMap());

      // Track appointment booking
      await _analytics.trackAppointmentBooking(
        doctorId: doctor.id,
        isVideoConsultation: isVideoConsultation,
        amount: amount,
      );

      Get.snackbar(
        'Success',
        'Appointment booked successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to payment
      Get.toNamed('/payment', arguments: {
        'appointment': appointment.copyWith(id: docRef.id),
      });

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to book appointment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'cancelled'});

      // Track cancellation
      await _analytics.trackAppointmentCancellation(
        appointmentId: appointmentId,
      );

      Get.snackbar(
        'Success',
        'Appointment cancelled successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadAppointments();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel appointment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
