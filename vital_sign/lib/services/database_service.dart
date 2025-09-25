import '../models/vital_sign.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final AppConfig _config = AppConfig.instance;
  final ApiService _apiService = ApiService();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _apiService.initialize();
    _isInitialized = true;
  }

  // Vital Signs CRUD operations
  Future<String> createVitalSign(VitalSign vitalSign) async {
    return await _apiService.createVitalSign(vitalSign);
  }

  Future<List<VitalSign>> getVitalSigns({
    VitalSignType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    return await _apiService.getVitalSigns(
      type: type,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  Future<VitalSign?> getVitalSignById(String id) async {
    return await _apiService.getVitalSignById(id);
  }

  Future<void> updateVitalSign(VitalSign vitalSign) async {
    await _apiService.updateVitalSign(vitalSign);
  }

  Future<void> deleteVitalSign(String id) async {
    await _apiService.deleteVitalSign(id);
  }

  // Alerts CRUD operations
  Future<String> createAlert(VitalSignAlert alert) async {
    return await _apiService.createAlert(alert);
  }

  Future<List<VitalSignAlert>> getAlerts({
    bool? unreadOnly,
    AlertSeverity? minSeverity,
    int? limit,
  }) async {
    return await _apiService.getAlerts(
      unreadOnly: unreadOnly,
      minSeverity: minSeverity,
      limit: limit,
    );
  }

  Future<void> markAlertAsRead(String id) async {
    await _apiService.markAlertAsRead(id);
  }

  Future<void> deleteAlert(String id) async {
    await _apiService.deleteAlert(id);
  }

  // Statistics
  Future<Map<String, dynamic>> getVitalSignStatistics({
    VitalSignType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _apiService.getVitalSignStatistics(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // AI Analysis
  Future<Map<String, dynamic>> detectAnomalies({int days = 7}) async {
    return await _apiService.detectAnomalies(days: days);
  }

  Future<Map<String, dynamic>> analyzeTrends({int days = 7}) async {
    return await _apiService.analyzeTrends(days: days);
  }

  Future<Map<String, dynamic>> getEarlyWarningScore({int hours = 24}) async {
    return await _apiService.getEarlyWarningScore(hours: hours);
  }

  Future<Map<String, dynamic>> getHealthSummary() async {
    return await _apiService.getHealthSummary();
  }

  // Health check
  Future<bool> isHealthy() async {
    return await _apiService.isApiHealthy();
  }

  // Data export/import
  Future<Map<String, dynamic>> exportData() async {
    return await _apiService.exportData();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _apiService.importData(data);
  }
}