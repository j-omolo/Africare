import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/insurance_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  final _insuranceService = InsuranceService.to;
  final _dateFormat = DateFormat('MMM d, y');
  Map<String, dynamic> _insuranceInfo = {};
  List<Map<String, dynamic>> _claims = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final insurance = await _insuranceService.getUserInsurance();
      final claims = await _insuranceService.getClaimsHistory();
      setState(() {
        _insuranceInfo = insurance;
        _claims = claims;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load insurance information',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddInsuranceDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsuranceCard(),
                    const SizedBox(height: 24),
                    _buildClaimsSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewClaimDialog,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('New Claim'),
      ),
    );
  }

  Widget _buildInsuranceCard() {
    if (_insuranceInfo.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No Insurance Added',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your insurance information to submit claims and check coverage.',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAddInsuranceDialog,
                child: const Text('Add Insurance'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _insuranceInfo['provider'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showAddInsuranceDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Policy Number', _insuranceInfo['policyNumber']),
            _buildInfoRow('Member ID', _insuranceInfo['memberId']),
            _buildInfoRow(
              'Valid Until',
              _dateFormat.format(
                (_insuranceInfo['validUntil'] as Timestamp).toDate(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _checkCoverage(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Check Coverage'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewCard(),
                    icon: const Icon(Icons.credit_card),
                    label: const Text('View Card'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsSection() {
    if (_claims.isEmpty) {
      return const Center(
        child: Text('No claims history'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Claims History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _claims.length,
          itemBuilder: (context, index) {
            final claim = _claims[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(
                  claim['serviceType'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Amount: \$${claim['amount']}\n'
                  'Status: ${claim['status']}\n'
                  'Date: ${_dateFormat.format((claim['submissionDate'] as Timestamp).toDate())}',
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('View Details'),
                      onTap: () => _viewClaimDetails(claim),
                    ),
                    PopupMenuItem(
                      child: const Text('Download PDF'),
                      onTap: () => _downloadClaimPDF(claim['claimId']),
                    ),
                    PopupMenuItem(
                      child: const Text('Share'),
                      onTap: () => _shareClaim(claim),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _viewClaimDetails(claim),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddInsuranceDialog() async {
    final formKey = GlobalKey<FormState>();
    final insuranceData = Map<String, dynamic>.from(_insuranceInfo);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_insuranceInfo.isEmpty
            ? 'Add Insurance'
            : 'Update Insurance'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Insurance Provider',
                  ),
                  initialValue: insuranceData['provider'],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter insurance provider';
                    }
                    return null;
                  },
                  onSaved: (value) => insuranceData['provider'] = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Policy Number',
                  ),
                  initialValue: insuranceData['policyNumber'],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter policy number';
                    }
                    return null;
                  },
                  onSaved: (value) => insuranceData['policyNumber'] = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Member ID',
                  ),
                  initialValue: insuranceData['memberId'],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter member ID';
                    }
                    return null;
                  },
                  onSaved: (value) => insuranceData['memberId'] = value,
                ),
                // Add more fields as needed
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final success = await _insuranceService.updateInsurance(
                  insuranceData,
                );
                if (success) {
                  Get.back();
                  _loadData();
                  Get.snackbar(
                    'Success',
                    'Insurance information updated',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to update insurance information',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewClaimDialog() async {
    final formKey = GlobalKey<FormState>();
    final claimData = <String, dynamic>{};

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Claim'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Service Type',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter service type';
                    }
                    return null;
                  },
                  onSaved: (value) => claimData['serviceType'] = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                  onSaved: (value) => claimData['amount'] = double.parse(value!),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      allowMultiple: true,
                    );

                    if (result != null) {
                      claimData['documentUrls'] = result.files
                          .map((file) => file.path!)
                          .toList();
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Documents'),
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final result = await _insuranceService.submitClaim(
                  appointmentId: 'manual_claim',
                  amount: claimData['amount'],
                  serviceType: claimData['serviceType'],
                  documentUrls: claimData['documentUrls'] ?? [],
                );

                if (!result.containsKey('error')) {
                  Get.back();
                  _loadData();
                  Get.snackbar(
                    'Success',
                    'Claim submitted successfully',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to submit claim: ${result['error']}',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkCoverage() async {
    final formKey = GlobalKey<FormState>();
    String serviceType = '';
    double amount = 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check Coverage'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service type';
                  }
                  return null;
                },
                onSaved: (value) => serviceType = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onSaved: (value) => amount = double.parse(value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final coverage = await _insuranceService.checkCoverage(
                  serviceType: serviceType,
                  amount: amount,
                );
                Get.back();
                _showCoverageResult(coverage);
              }
            },
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }

  void _showCoverageResult(Map<String, dynamic> coverage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coverage Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Covered: ${coverage['covered'] ? 'Yes' : 'No'}'),
            if (coverage['covered']) ...[
              Text('Coverage: ${coverage['coveragePercentage']}%'),
              Text('Covered Amount: \$${coverage['coveredAmount']}'),
              Text('Out of Pocket: \$${coverage['outOfPocket']}'),
            ],
            Text('Message: ${coverage['message']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewCard() async {
    // TODO: Implement insurance card view
    Get.snackbar(
      'Coming Soon',
      'Digital insurance card view will be available soon',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> _viewClaimDetails(Map<String, dynamic> claim) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${claim['serviceType']}'),
            Text('Amount: \$${claim['amount']}'),
            Text('Status: ${claim['status']}'),
            Text(
              'Submitted: ${_dateFormat.format((claim['submissionDate'] as Timestamp).toDate())}',
            ),
            if (claim['documentUrls'] != null) ...[
              const SizedBox(height: 16),
              const Text('Documents:'),
              ...List.from(claim['documentUrls']).map(
                (url) => TextButton.icon(
                  onPressed: () {
                    // TODO: Implement document view
                  },
                  icon: const Icon(Icons.description),
                  label: Text('View Document'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadClaimPDF(String claimId) async {
    try {
      final pdfPath = await _insuranceService.generateClaimPDF(claimId);
      if (pdfPath != null) {
        // Open PDF
        Get.toNamed('/pdf-viewer', arguments: {'path': pdfPath});
      } else {
        throw Exception('Failed to generate PDF');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download claim PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _shareClaim(Map<String, dynamic> claim) async {
    try {
      final pdfPath = await _insuranceService.generateClaimPDF(claim['claimId']);
      if (pdfPath != null) {
        await Share.shareFiles(
          [pdfPath],
          text: 'Insurance Claim Details',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share claim: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
