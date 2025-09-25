import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vital_signs_provider.dart';
import '../models/vital_sign.dart';
import '../widgets/vital_sign_chart.dart';
import '../widgets/trend_analysis_widget.dart';
import '../widgets/early_warning_score_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  VitalSignType _selectedType = VitalSignType.heartRate;
  int _selectedTimeRange = 7; // days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Charts', icon: Icon(Icons.show_chart)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Last 24 hours')),
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 3 months')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChartsTab(),
          _buildTrendsTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return Consumer<VitalSignsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vital Sign Type Selector
              _buildVitalSignTypeSelector(),
              
              const SizedBox(height: 16),
              
              // Chart
              VitalSignChart(
                type: _selectedType,
                timeRange: _selectedTimeRange,
                vitalSigns: provider.getVitalSignsByType(_selectedType),
              ),
              
              const SizedBox(height: 24),
              
              // Statistics
              _buildStatistics(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return Consumer<VitalSignsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Early Warning Score
              EarlyWarningScoreWidget(),
              
              const SizedBox(height: 16),
              
              // Trend Analysis for each vital sign type
              ...VitalSignType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TrendAnalysisWidget(type: type),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisTab() {
    return Consumer<VitalSignsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Statistics
              _buildOverallStatistics(provider),
              
              const SizedBox(height: 24),
              
              // Anomaly Analysis
              _buildAnomalyAnalysis(provider),
              
              const SizedBox(height: 24),
              
              // Recommendations
              _buildRecommendations(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalSignTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Vital Sign',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VitalSignType.values.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(VitalSignsProvider provider) {
    final vitalSigns = provider.getVitalSignsByType(_selectedType);
    if (vitalSigns.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = vitalSigns.map((v) => v.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final normalCount = vitalSigns.where((v) => v.isNormal).length;
    final abnormalCount = vitalSigns.length - normalCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedType.displayName} Statistics',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Average',
                    average.toStringAsFixed(1),
                    _selectedType.unit,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Min',
                    min.toStringAsFixed(1),
                    _selectedType.unit,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Max',
                    max.toStringAsFixed(1),
                    _selectedType.unit,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Normal',
                    normalCount.toString(),
                    'readings',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Abnormal',
                    abnormalCount.toString(),
                    'readings',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatistics(VitalSignsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Records',
                    provider.vitalSigns.length.toString(),
                    'entries',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Alerts',
                    provider.alerts.length.toString(),
                    'notifications',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Unread Alerts',
                    provider.unreadAlertsCount.toString(),
                    'pending',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Critical Alerts',
                    provider.criticalAlertsCount.toString(),
                    'urgent',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyAnalysis(VitalSignsProvider provider) {
    final anomalies = provider.vitalSigns.where((v) => v.isAnomaly).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anomaly Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (anomalies.isEmpty)
              const Text('No anomalies detected in recent data.')
            else
              Column(
                children: anomalies.take(5).map((anomaly) {
                  return ListTile(
                    leading: Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                    title: Text(anomaly.type.displayName),
                    subtitle: Text(
                      '${anomaly.formattedValue} ${anomaly.unit} • ${_formatDateTime(anomaly.timestamp)}',
                    ),
                    trailing: Text(
                      'Confidence: ${(anomaly.confidence ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(VitalSignsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecommendationItem(
              Icons.schedule,
              'Regular Monitoring',
              'Continue monitoring vital signs at regular intervals to track trends.',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildRecommendationItem(
              Icons.medical_services,
              'Medical Consultation',
              'Consider consulting with a healthcare provider for abnormal readings.',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildRecommendationItem(
              Icons.fitness_center,
              'Lifestyle Changes',
              'Maintain a healthy lifestyle with regular exercise and balanced diet.',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
