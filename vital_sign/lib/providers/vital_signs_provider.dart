import 'package:flutter/foundation.dart';
import '../models/vital_sign.dart';
import '../services/database_service.dart';
import '../services/ai_analysis_service.dart';

class VitalSignsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AIAnalysisService _aiService = AIAnalysisService();

  List<VitalSign> _vitalSigns = [];
  List<VitalSignAlert> _alerts = [];
  bool _isLoading = false;
  Map<VitalSignType, List<VitalSign>> _vitalSignsByType = {};
  Map<String, dynamic> _statistics = {};

  // Getters
  List<VitalSign> get vitalSigns => _vitalSigns;
  List<VitalSignAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  Map<VitalSignType, List<VitalSign>> get vitalSignsByType => _vitalSignsByType;
  Map<String, dynamic> get statistics => _statistics;

  // Unread alerts count
  int get unreadAlertsCount => _alerts.where((alert) => !alert.isRead).length;

  // Critical alerts count
  int get criticalAlertsCount => _alerts.where((alert) => alert.severity == AlertSeverity.critical).length;

  // Initialize provider
  Future<void> initialize() async {
    await _loadVitalSigns();
    await _loadAlerts();
    await _loadStatistics();
  }

  // Load vital signs
  Future<void> _loadVitalSigns() async {
    _setLoading(true);
    try {
      _vitalSigns = await _databaseService.getVitalSigns(
        limit: 100,
      );
      _organizeVitalSignsByType();
    } catch (e) {
      debugPrint('Error loading vital signs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load alerts
  Future<void> _loadAlerts() async {
    try {
      _alerts = await _databaseService.getAlerts(
        limit: 50,
      );
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  // Load statistics
  Future<void> _loadStatistics() async {
    try {
      _statistics = await _databaseService.getVitalSignStatistics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      // Set empty statistics if loading fails
      _statistics = {};
    }
  }

  // Organize vital signs by type
  void _organizeVitalSignsByType() {
    _vitalSignsByType.clear();
    for (final vitalSign in _vitalSigns) {
      if (!_vitalSignsByType.containsKey(vitalSign.type)) {
        _vitalSignsByType[vitalSign.type] = [];
      }
      _vitalSignsByType[vitalSign.type]!.add(vitalSign);
    }
  }

  // Add new vital sign
  Future<String?> addVitalSign(VitalSign vitalSign) async {
    print('🔄 VitalSignsProvider: Adding new vital sign');
    print('📊 Type: ${vitalSign.type.name}, Value: ${vitalSign.value}');
    
    _setLoading(true);
    try {
      // Analyze the vital sign for anomalies
      final analyzedVitalSign = await _aiService.analyzeVitalSign(vitalSign);
      print('🤖 AI Analysis completed');
      
      // Insert into database
      print('💾 Sending to database service...');
      final id = await _databaseService.createVitalSign(
        analyzedVitalSign,
      );
      print('✅ Database service returned ID: $id');
      
      // Update local state
      final newVitalSign = analyzedVitalSign.copyWith(id: id);
      _vitalSigns.insert(0, newVitalSign);
      _organizeVitalSignsByType();
      
      // Check for alerts
      await _checkForAlerts(newVitalSign);
      
      // Update statistics (don't fail if this fails)
      try {
        await _loadStatistics();
      } catch (e) {
        debugPrint('Warning: Failed to update statistics: $e');
      }
      
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Error adding vital sign: $e');
      // Show user-friendly error message
      if (e.toString().contains('Network Error')) {
        debugPrint('Network connection issue. Please check if backend is running.');
      } else if (e.toString().contains('Timeout')) {
        debugPrint('Request timed out. Please try again.');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update vital sign
  Future<bool> updateVitalSign(VitalSign vitalSign) async {
    _setLoading(true);
    try {
      await _databaseService.updateVitalSign(vitalSign);
      
      // Update local state
      final index = _vitalSigns.indexWhere((v) => v.id == vitalSign.id);
      if (index != -1) {
        _vitalSigns[index] = vitalSign;
        _organizeVitalSignsByType();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating vital sign: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete vital sign
  Future<bool> deleteVitalSign(String id) async {
    _setLoading(true);
    try {
      await _databaseService.deleteVitalSign(id);
      
      // Update local state
      _vitalSigns.removeWhere((v) => v.id == id);
      _organizeVitalSignsByType();
      
      // Update statistics
      await _loadStatistics();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting vital sign: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get vital signs by type
  List<VitalSign> getVitalSignsByType(VitalSignType type) {
    return _vitalSignsByType[type] ?? [];
  }

  // Get recent vital signs
  List<VitalSign> getRecentVitalSigns({int limit = 10}) {
    return _vitalSigns.take(limit).toList();
  }

  // Get vital signs in date range
  Future<List<VitalSign>> getVitalSignsInRange({
    required DateTime startDate,
    required DateTime endDate,
    VitalSignType? type,
  }) async {
    try {
      return await _databaseService.getVitalSigns(
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error getting vital signs in range: $e');
      return [];
    }
  }

  // Check for alerts
  Future<void> _checkForAlerts(VitalSign vitalSign) async {
    if (!vitalSign.isNormal || vitalSign.isAnomaly) {
      final severity = _determineAlertSeverity(vitalSign);
      final message = _generateAlertMessage(vitalSign);
      
      final alert = VitalSignAlert(
        id: '',
        type: vitalSign.type,
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
        actionRequired: severity == AlertSeverity.critical ? 'Immediate medical attention required' : null,
      );
      
      await _databaseService.createAlert(alert);
      _alerts.insert(0, alert);
      notifyListeners();
    }
  }

  // Determine alert severity
  AlertSeverity _determineAlertSeverity(VitalSign vitalSign) {
    switch (vitalSign.type) {
      case VitalSignType.heartRate:
        if (vitalSign.value < 40 || vitalSign.value > 150) return AlertSeverity.critical;
        if (vitalSign.value < 50 || vitalSign.value > 130) return AlertSeverity.high;
        if (vitalSign.value < 60 || vitalSign.value > 110) return AlertSeverity.medium;
        return AlertSeverity.low;
      
      case VitalSignType.bloodPressure:
        if (vitalSign.value > 180 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 110)) {
          return AlertSeverity.critical;
        }
        if (vitalSign.value > 160 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 100)) {
          return AlertSeverity.high;
        }
        if (vitalSign.value > 140 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 90)) {
          return AlertSeverity.medium;
        }
        return AlertSeverity.low;
      
      case VitalSignType.temperature:
        if (vitalSign.value < 35.0 || vitalSign.value > 39.0) return AlertSeverity.critical;
        if (vitalSign.value < 36.0 || vitalSign.value > 38.5) return AlertSeverity.high;
        if (vitalSign.value < 36.5 || vitalSign.value > 38.0) return AlertSeverity.medium;
        return AlertSeverity.low;
      
      case VitalSignType.spO2:
        if (vitalSign.value < 90) return AlertSeverity.critical;
        if (vitalSign.value < 95) return AlertSeverity.high;
        if (vitalSign.value < 97) return AlertSeverity.medium;
        return AlertSeverity.low;
      
      case VitalSignType.respiratoryRate:
        if (vitalSign.value < 8 || vitalSign.value > 30) return AlertSeverity.critical;
        if (vitalSign.value < 10 || vitalSign.value > 25) return AlertSeverity.high;
        if (vitalSign.value < 12 || vitalSign.value > 22) return AlertSeverity.medium;
        return AlertSeverity.low;
    }
  }

  // Generate alert message
  String _generateAlertMessage(VitalSign vitalSign) {
    final value = vitalSign.formattedValue;
    final unit = vitalSign.unit;
    final type = vitalSign.type.displayName;
    
    if (vitalSign.isAnomaly) {
      return 'Anomaly detected: $type is $value $unit (outside normal range)';
    } else {
      return 'Abnormal reading: $type is $value $unit';
    }
  }

  // Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _databaseService.markAlertAsRead(alertId);
      
      final index = _alerts.indexWhere((alert) => alert.id == alertId);
      if (index != -1) {
        _alerts[index] = VitalSignAlert(
          id: _alerts[index].id,
          type: _alerts[index].type,
          message: _alerts[index].message,
          severity: _alerts[index].severity,
          timestamp: _alerts[index].timestamp,
          isRead: true,
          actionRequired: _alerts[index].actionRequired,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking alert as read: $e');
    }
  }

  // Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _databaseService.deleteAlert(alertId);
      _alerts.removeWhere((alert) => alert.id == alertId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting alert: $e');
    }
  }

  // Get early warning score
  Future<Map<String, dynamic>> getEarlyWarningScore() async {
    try {
      final recentVitals = _vitalSigns.take(5).toList();
      return await _aiService.calculateEarlyWarningScore(recentVitals);
    } catch (e) {
      debugPrint('Error calculating early warning score: $e');
      return {
        'totalScore': 0,
        'riskLevel': 'Normal',
        'scores': {},
        'timestamp': DateTime.now(),
      };
    }
  }

  // Get trend analysis
  Future<Map<String, dynamic>> getTrendAnalysis(VitalSignType type) async {
    try {
      return await _aiService.analyzeTrends(type, days: 7);
    } catch (e) {
      debugPrint('Error analyzing trends: $e');
      return {
        'trend': 'Unknown',
        'slope': 0.0,
        'confidence': 0.0,
        'recommendation': 'Unable to analyze trends',
      };
    }
  }

  // Get prediction
  Future<Map<String, dynamic>> getPrediction(VitalSignType type) async {
    try {
      return await _aiService.predictNextValue(type);
    } catch (e) {
      debugPrint('Error getting prediction: $e');
      return {
        'predictedValue': null,
        'confidence': 0.0,
        'message': 'Unable to generate prediction',
      };
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadVitalSigns();
    await _loadAlerts();
    await _loadStatistics();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _vitalSigns.clear();
    _alerts.clear();
    _vitalSignsByType.clear();
    _statistics.clear();
    notifyListeners();
  }
}
