import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vital_signs_provider.dart';
import '../models/vital_sign.dart';

class TrendAnalysisWidget extends StatefulWidget {
  final VitalSignType type;

  const TrendAnalysisWidget({
    Key? key,
    required this.type,
  }) : super(key: key);

  @override
  State<TrendAnalysisWidget> createState() => _TrendAnalysisWidgetState();
}

class _TrendAnalysisWidgetState extends State<TrendAnalysisWidget> {
  Map<String, dynamic>? _trendData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<VitalSignsProvider>(context, listen: false);
      final trendData = await provider.getTrendAnalysis(widget.type);
      setState(() {
        _trendData = trendData;
      });
    } catch (e) {
      debugPrint('Error loading trend data: $e');
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
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.type.displayName} Trend Analysis',
                    style: const TextStyle(
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
            if (_trendData != null) ...[
              _buildTrendIndicator(),
              const SizedBox(height: 12),
              _buildTrendDetails(),
              const SizedBox(height: 12),
              _buildRecommendation(),
            ] else if (!_isLoading) ...[
              const Text('No trend data available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final trend = _trendData!['trend'] as String;
    final slope = _trendData!['slope'] as double;
    final confidence = _trendData!['confidence'] as double;

    Color trendColor;
    IconData trendIcon;
    String trendText;

    switch (trend.toLowerCase()) {
      case 'increasing':
        trendColor = Colors.red;
        trendIcon = Icons.trending_up;
        trendText = 'Increasing';
        break;
      case 'decreasing':
        trendColor = Colors.blue;
        trendIcon = Icons.trending_down;
        trendText = 'Decreasing';
        break;
      case 'stable':
        trendColor = Colors.green;
        trendIcon = Icons.trending_flat;
        trendText = 'Stable';
        break;
      default:
        trendColor = Colors.grey;
        trendIcon = Icons.help_outline;
        trendText = 'Unknown';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(trendIcon, color: trendColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend: $trendText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendDetails() {
    final slope = (_trendData?['slope'] as double?) ?? 0.0;
    final dataPoints = (_trendData?['dataPoints'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Details',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slope: ${slope.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Data Points: $dataPoints',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation() {
    final recommendation = _trendData!['recommendation'] as String;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case VitalSignType.heartRate:
        return Colors.red;
      case VitalSignType.bloodPressure:
        return Colors.blue;
      case VitalSignType.temperature:
        return Colors.orange;
      case VitalSignType.spO2:
        return Colors.green;
      case VitalSignType.respiratoryRate:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case VitalSignType.heartRate:
        return Icons.favorite;
      case VitalSignType.bloodPressure:
        return Icons.monitor_heart;
      case VitalSignType.temperature:
        return Icons.thermostat;
      case VitalSignType.spO2:
        return Icons.air;
      case VitalSignType.respiratoryRate:
        return Icons.airline_seat_flat;
    }
  }
}
