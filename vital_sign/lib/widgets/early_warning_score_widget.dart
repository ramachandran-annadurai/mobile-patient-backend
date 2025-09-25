import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vital_signs_provider.dart';

class EarlyWarningScoreWidget extends StatefulWidget {
  const EarlyWarningScoreWidget({Key? key}) : super(key: key);

  @override
  State<EarlyWarningScoreWidget> createState() => _EarlyWarningScoreWidgetState();
}

class _EarlyWarningScoreWidgetState extends State<EarlyWarningScoreWidget> {
  Map<String, dynamic>? _ewsData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEWSData();
  }

  Future<void> _loadEWSData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<VitalSignsProvider>(context, listen: false);
      final ewsData = await provider.getEarlyWarningScore();
      setState(() {
        _ewsData = ewsData;
      });
    } catch (e) {
      debugPrint('Error loading EWS data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Early Warning Score (EWS)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ewsData != null) ...[
              _buildScoreDisplay(),
              const SizedBox(height: 16),
              _buildRiskLevel(),
              const SizedBox(height: 16),
              _buildScoreBreakdown(),
            ] else if (!_isLoading) ...[
              const Text('No EWS data available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    final totalScore = _ewsData!['totalScore'] as int;
    final riskLevel = _ewsData!['riskLevel'] as String;

    Color scoreColor = _getScoreColor(totalScore);
    Color riskColor = _getRiskColor(riskLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withOpacity(0.1),
            scoreColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Score',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalScore.toString(),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  'out of 15',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              riskLevel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevel() {
    final riskLevel = _ewsData!['riskLevel'] as String;
    final totalScore = _ewsData!['totalScore'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRiskColor(riskLevel).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRiskColor(riskLevel).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRiskIcon(riskLevel),
                color: _getRiskColor(riskLevel),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Risk Assessment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getRiskColor(riskLevel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getRiskDescription(riskLevel, totalScore),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    final scores = _ewsData!['scores'] as Map<String, int>;

    if (scores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...scores.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getVitalSignDisplayName(entry.key),
                  style: const TextStyle(fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(entry.value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(entry.value),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score == 0) return Colors.green;
    if (score <= 2) return Colors.orange;
    if (score <= 4) return Colors.red;
    return Colors.purple;
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'low risk':
        return Colors.blue;
      case 'medium risk':
        return Colors.orange;
      case 'high risk':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'low risk':
        return Icons.info;
      case 'medium risk':
        return Icons.warning;
      case 'high risk':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getRiskDescription(String riskLevel, int totalScore) {
    switch (riskLevel.toLowerCase()) {
      case 'normal':
        return 'All vital signs are within normal ranges. Continue regular monitoring.';
      case 'low risk':
        return 'Some vital signs show minor deviations. Monitor closely and consider lifestyle adjustments.';
      case 'medium risk':
        return 'Multiple vital signs show abnormalities. Consider medical consultation and increased monitoring.';
      case 'high risk':
        return 'Critical vital sign abnormalities detected. Immediate medical attention recommended.';
      default:
        return 'Unable to assess risk level.';
    }
  }

  String _getVitalSignDisplayName(String type) {
    switch (type) {
      case 'heartRate':
        return 'Heart Rate';
      case 'bloodPressure':
        return 'Blood Pressure';
      case 'temperature':
        return 'Temperature';
      case 'spO2':
        return 'SpO₂';
      case 'respiratoryRate':
        return 'Respiratory Rate';
      default:
        return type;
    }
  }
}
