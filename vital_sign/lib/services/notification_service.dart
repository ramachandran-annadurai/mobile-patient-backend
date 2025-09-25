import 'package:flutter/foundation.dart';
import '../models/vital_sign.dart';
import '../config/app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AppConfig _config = AppConfig.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('Notification service initialized');
  }

  Future<void> showVitalSignAlert(VitalSignAlert alert) async {
    if (!_config.notificationEnabled) return;
    
    debugPrint('VITAL SIGN ALERT: ${alert.message}');
    debugPrint('Severity: ${alert.severity.displayName}');
    debugPrint('Type: ${alert.type.displayName}');
  }

  Future<void> showCriticalAlert(VitalSignAlert alert) async {
    if (!_config.notificationEnabled) return;
    
    debugPrint('🚨 CRITICAL ALERT: ${alert.message}');
    debugPrint('Action Required: ${alert.actionRequired ?? 'None'}');
  }

  Future<void> showEarlyWarningScoreAlert(Map<String, dynamic> ewsData) async {
    if (!_config.notificationEnabled) return;

    final totalScore = ewsData['totalScore'] as int;
    final riskLevel = ewsData['riskLevel'] as String;

    if (totalScore < _config.alertThresholdLow) return;

    debugPrint('EARLY WARNING SCORE ALERT: $riskLevel');
    debugPrint('Total Score: $totalScore');
    debugPrint('Message: ${_getEWSMessage(riskLevel)}');
  }

  Future<void> showTrendAlert(VitalSignType type, String trend, String recommendation) async {
    if (!_config.notificationEnabled) return;

    debugPrint('TREND ALERT: ${type.displayName} is $trend');
    debugPrint('Recommendation: $recommendation');
  }

  Future<void> showReminderNotification(String message) async {
    if (!_config.notificationEnabled) return;

    debugPrint('REMINDER: $message');
  }

  Future<void> scheduleReminder({
    required String message,
    required DateTime scheduledTime,
    int? id,
  }) async {
    if (!_config.notificationEnabled) return;

    debugPrint('SCHEDULED REMINDER: $message at ${scheduledTime.toIso8601String()}');
  }

  Future<void> cancelNotification(int id) async {
    debugPrint('Cancelled notification: $id');
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('Cancelled all notifications');
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    return [];
  }

  // Helper methods
  String _getEWSMessage(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high risk':
        return 'Immediate medical attention recommended.';
      case 'medium risk':
        return 'Consider medical consultation and increased monitoring.';
      case 'low risk':
        return 'Monitor closely and consider lifestyle adjustments.';
      default:
        return 'Continue regular monitoring.';
    }
  }
}