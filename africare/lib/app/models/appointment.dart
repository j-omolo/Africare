import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String type; // 'in-person', 'video'
  final double amount;
  final String doctorName;
  final String? symptoms;
  final String? notes;
  final bool isVideoConsultation;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    required this.type,
    required this.amount,
    required this.doctorName,
    required this.isVideoConsultation,
    this.symptoms,
    this.notes,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      doctorId: map['doctorId'] as String,
      patientId: map['patientId'] as String,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      status: map['status'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      doctorName: map['doctorName'] as String,
      isVideoConsultation: map['isVideoConsultation'] as bool? ?? false,
      symptoms: map['symptoms'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'type': type,
      'amount': amount,
      'doctorName': doctorName,
      'isVideoConsultation': isVideoConsultation,
      'symptoms': symptoms,
      'notes': notes,
    };
  }
}
