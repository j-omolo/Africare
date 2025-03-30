import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/analytics_service.dart';

class InsuranceService extends GetxService {
  static InsuranceService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService.to;

  // Get user's insurance information
  Future<Map<String, dynamic>> getUserInsurance() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('insurance')
          .doc('current')
          .get();

      if (!doc.exists) return {};

      return doc.data() ?? {};
    } catch (e) {
      print('Error getting user insurance: $e');
      return {};
    }
  }

  // Add or update insurance information
  Future<bool> updateInsurance(Map<String, dynamic> insuranceInfo) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('insurance')
          .doc('current')
          .set(insuranceInfo, SetOption(merge: true));

      return true;
    } catch (e) {
      print('Error updating insurance: $e');
      return false;
    }
  }

  // Submit an insurance claim
  Future<Map<String, dynamic>> submitClaim({
    required String appointmentId,
    required double amount,
    required String serviceType,
    required List<String> documentUrls,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final insurance = await getUserInsurance();
      if (insurance.isEmpty) throw Exception('No insurance information found');

      // Create claim document
      final claim = {
        'userId': userId,
        'appointmentId': appointmentId,
        'insuranceProvider': insurance['provider'],
        'policyNumber': insurance['policyNumber'],
        'amount': amount,
        'serviceType': serviceType,
        'documentUrls': documentUrls,
        'status': 'pending',
        'submissionDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add to Firestore
      final claimRef = await _firestore
          .collection('insurance_claims')
          .add(claim);

      // Track the claim
      await _analytics.trackInsuranceClaim(
        insuranceProvider: insurance['provider'],
        claimType: serviceType,
        amount: amount,
        status: 'pending',
      );

      return {
        'claimId': claimRef.id,
        'status': 'pending',
        'message': 'Claim submitted successfully',
      };
    } catch (e) {
      print('Error submitting claim: $e');
      return {
        'error': 'Failed to submit claim: $e',
      };
    }
  }

  // Get claim status
  Future<Map<String, dynamic>> getClaimStatus(String claimId) async {
    try {
      final doc = await _firestore
          .collection('insurance_claims')
          .doc(claimId)
          .get();

      if (!doc.exists) {
        return {'error': 'Claim not found'};
      }

      return doc.data() ?? {};
    } catch (e) {
      print('Error getting claim status: $e');
      return {'error': 'Failed to get claim status'};
    }
  }

  // Get user's claims history
  Future<List<Map<String, dynamic>>> getClaimsHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('insurance_claims')
          .where('userId', isEqualTo: userId)
          .orderBy('submissionDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'claimId': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting claims history: $e');
      return [];
    }
  }

  // Generate claim PDF
  Future<String?> generateClaimPDF(String claimId) async {
    try {
      final claim = await getClaimStatus(claimId);
      if (claim.containsKey('error')) return null;

      final insurance = await getUserInsurance();
      final user = _auth.currentUser;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Insurance Claim Form',
                      style: pw.TextStyle(fontSize: 24)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Claim ID: $claimId'),
                pw.SizedBox(height: 10),
                pw.Text('Date: ${DateTime.now().toLocal()}'),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, child: pw.Text('Patient Information')),
                pw.Text('Name: ${user?.displayName}'),
                pw.Text('Email: ${user?.email}'),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, child: pw.Text('Insurance Information')),
                pw.Text('Provider: ${insurance['provider']}'),
                pw.Text('Policy Number: ${insurance['policyNumber']}'),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, child: pw.Text('Claim Details')),
                pw.Text('Service Type: ${claim['serviceType']}'),
                pw.Text('Amount: \$${claim['amount']}'),
                pw.Text('Status: ${claim['status']}'),
                pw.Text('Submission Date: ${claim['submissionDate']}'),
              ],
            );
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/claim_$claimId.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('Error generating claim PDF: $e');
      return null;
    }
  }

  // Check coverage for a service
  Future<Map<String, dynamic>> checkCoverage({
    required String serviceType,
    required double amount,
  }) async {
    try {
      final insurance = await getUserInsurance();
      if (insurance.isEmpty) {
        return {
          'covered': false,
          'message': 'No insurance information found',
        };
      }

      // Get coverage details
      final coverageDoc = await _firestore
          .collection('insurance_providers')
          .doc(insurance['provider'])
          .collection('coverage')
          .doc(serviceType)
          .get();

      if (!coverageDoc.exists) {
        return {
          'covered': false,
          'message': 'Service type not covered',
        };
      }

      final coverage = coverageDoc.data()!;
      final coveragePercentage = coverage['percentage'] as num;
      final maxAmount = coverage['maxAmount'] as num;

      final coveredAmount = (amount * coveragePercentage / 100)
          .clamp(0, maxAmount)
          .toDouble();

      return {
        'covered': true,
        'coveragePercentage': coveragePercentage,
        'coveredAmount': coveredAmount,
        'outOfPocket': amount - coveredAmount,
        'message': 'Service is covered',
      };
    } catch (e) {
      print('Error checking coverage: $e');
      return {
        'covered': false,
        'message': 'Error checking coverage',
      };
    }
  }

  // Verify insurance card
  Future<bool> verifyInsuranceCard(String imageUrl) async {
    try {
      // TODO: Implement OCR to verify insurance card
      // For now, return true
      return true;
    } catch (e) {
      print('Error verifying insurance card: $e');
      return false;
    }
  }
}
