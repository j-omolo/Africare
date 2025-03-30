import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../services/analytics_service.dart';
import 'package:intl/intl.dart';

class HealthAnalyticsScreen extends StatefulWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  State<HealthAnalyticsScreen> createState() => _HealthAnalyticsScreenState();
}

class _HealthAnalyticsScreenState extends State<HealthAnalyticsScreen> {
  final _analyticsService = AnalyticsService.to;
  final _dateFormat = DateFormat('MMM d');
  
  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _vitalsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final insights = await _analyticsService.getHealthInsights();
      final vitals = await _analyticsService.getHealthTrends(
        metricType: 'vitals',
        days: 30,
      );

      setState(() {
        _insights = insights;
        _vitalsData = vitals;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load health analytics',
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
        title: const Text('Health Analytics'),
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
                    _buildHealthScore(),
                    const SizedBox(height: 24),
                    _buildVitalsCharts(),
                    const SizedBox(height: 24),
                    _buildMedicationAdherence(),
                    const SizedBox(height: 24),
                    _buildRecommendations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthScore() {
    final score = _calculateHealthScore();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[200],
                    color: _getScoreColor(score),
                    strokeWidth: 10,
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getScoreLabel(score),
                      style: TextStyle(
                        color: _getScoreColor(score),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCharts() {
    if (_vitalsData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No vitals data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vitals Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: _dateFormat,
                  intervalType: DateTimeIntervalType.days,
                  interval: 5,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Blood Pressure (mmHg)'),
                ),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                  LineSeries<Map<String, dynamic>, DateTime>(
                    name: 'Systolic',
                    dataSource: _vitalsData,
                    xValueMapper: (data, _) => (data['timestamp'] as DateTime),
                    yValueMapper: (data, _) => data['systolic'],
                    color: Colors.red,
                  ),
                  LineSeries<Map<String, dynamic>, DateTime>(
                    name: 'Diastolic',
                    dataSource: _vitalsData,
                    xValueMapper: (data, _) => (data['timestamp'] as DateTime),
                    yValueMapper: (data, _) => data['diastolic'],
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: _dateFormat,
                  intervalType: DateTimeIntervalType.days,
                  interval: 5,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Heart Rate (bpm)'),
                ),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                  LineSeries<Map<String, dynamic>, DateTime>(
                    name: 'Heart Rate',
                    dataSource: _vitalsData,
                    xValueMapper: (data, _) => (data['timestamp'] as DateTime),
                    yValueMapper: (data, _) => data['heartRate'],
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationAdherence() {
    final adherenceRate = _insights['medication_adherence'] as double? ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medication Adherence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: adherenceRate,
              backgroundColor: Colors.grey[200],
              color: _getAdherenceColor(adherenceRate),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${(adherenceRate * 100).toStringAsFixed(1)}% adherence rate',
              style: TextStyle(
                color: _getAdherenceColor(adherenceRate),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _insights['recommendations'] as List<String>? ?? [];
    
    if (recommendations.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  double _calculateHealthScore() {
    if (_insights.isEmpty) return 0.0;

    var score = 0.0;
    var count = 0;

    // Check vital signs
    final vitalTrends = _insights['vital_trends'] as Map<String, dynamic>? ?? {};
    if (vitalTrends.isNotEmpty) {
      final systolic = vitalTrends['systolic']['average'] as double? ?? 0;
      final diastolic = vitalTrends['diastolic']['average'] as double? ?? 0;
      final heartRate = vitalTrends['heart_rate']['average'] as double? ?? 0;

      // Score blood pressure (ideal: 120/80)
      if (systolic > 0) {
        score += (1 - (((systolic - 120).abs()) / 50).clamp(0, 1)) * 100;
        count++;
      }
      if (diastolic > 0) {
        score += (1 - (((diastolic - 80).abs()) / 30).clamp(0, 1)) * 100;
        count++;
      }

      // Score heart rate (ideal: 60-100)
      if (heartRate > 0) {
        score += (1 - (((heartRate - 80).abs()) / 40).clamp(0, 1)) * 100;
        count++;
      }
    }

    // Score medication adherence
    final adherence = _insights['medication_adherence'] as double? ?? 0;
    if (adherence > 0) {
      score += adherence * 100;
      count++;
    }

    return count > 0 ? score / count : 0;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 0.9) return Colors.green;
    if (rate >= 0.7) return Colors.orange;
    return Colors.red;
  }
}
