import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vital_signs_provider.dart';
import '../models/vital_sign.dart';

class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<VitalSignsProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.medical_services,
                        label: 'Total Records',
                        value: provider.vitalSigns.length.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.warning,
                        label: 'Alerts',
                        value: provider.unreadAlertsCount.toString(),
                        color: provider.unreadAlertsCount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.dangerous,
                        label: 'Critical',
                        value: provider.criticalAlertsCount.toString(),
                        color: provider.criticalAlertsCount > 0 ? Colors.purple : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHealthStatus(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHealthStatus(VitalSignsProvider provider) {
    final recentVitals = provider.getRecentVitalSigns(limit: 5);
    final abnormalCount = recentVitals.where((v) => !v.isNormal || v.isAnomaly).length;
    
    String status;
    Color statusColor;
    IconData statusIcon;
    
    if (recentVitals.isEmpty) {
      status = 'No Data';
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
    } else if (abnormalCount == 0) {
      status = 'All Normal';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (abnormalCount <= 2) {
      status = 'Mostly Normal';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      status = 'Needs Attention';
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Health Status: $status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
