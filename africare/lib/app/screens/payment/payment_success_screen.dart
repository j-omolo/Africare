import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/appointment.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Appointment appointment;
  final String trackingId;

  const PaymentSuccessScreen({
    super.key,
    required this.appointment,
    required this.trackingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 96,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your appointment with Dr. ${appointment.doctorName} has been confirmed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.offAllNamed('/appointments'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Appointments'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.offAllNamed('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow('Date', appointment.dateTime),
          const SizedBox(height: 12),
          _buildInfoRow('Time', appointment.dateTime),
          const SizedBox(height: 12),
          _buildInfoRow('Doctor', 'Dr. ${appointment.doctorName}'),
          const SizedBox(height: 12),
          _buildInfoRow('Amount Paid', 'KES ${appointment.fee}'),
          const SizedBox(height: 12),
          _buildInfoRow('Transaction ID', trackingId),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue = value is DateTime
        ? label == 'Date'
            ? '${value.day}/${value.month}/${value.year}'
            : '${value.hour}:${value.minute.toString().padLeft(2, '0')}'
        : value.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Text(
          displayValue,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
