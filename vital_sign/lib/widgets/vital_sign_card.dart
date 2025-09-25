import 'package:flutter/material.dart';
import '../models/vital_sign.dart';

class VitalSignCard extends StatelessWidget {
  final VitalSign vitalSign;
  final VoidCallback? onTap;

  const VitalSignCard({
    Key? key,
    required this.vitalSign,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and type
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
                      vitalSign.type.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (vitalSign.isAnomaly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Value
              Text(
                vitalSign.formattedValue,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getValueColor(),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Unit
              Text(
                vitalSign.unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const Spacer(),
              
              // Status and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(vitalSign.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (vitalSign.type) {
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
    switch (vitalSign.type) {
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

  Color _getValueColor() {
    if (vitalSign.isAnomaly) {
      return Colors.red;
    } else if (!vitalSign.isNormal) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color _getStatusColor() {
    if (vitalSign.isAnomaly) {
      return Colors.red;
    } else if (!vitalSign.isNormal) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (vitalSign.isAnomaly) {
      return 'ANOMALY';
    } else if (!vitalSign.isNormal) {
      return 'ABNORMAL';
    } else {
      return 'NORMAL';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
