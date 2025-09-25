import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/vital_sign.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AppConfig _config = AppConfig.instance;
  late String _baseUrl;

  Future<void> initialize() async {
    _baseUrl = _config.apiBaseUrl;
  }

  // Vital Signs API
  Future<String> createVitalSign(VitalSign vitalSign, {String? patientId}) async {
    try {
      final requestBody = {
        'type': vitalSign.type.name,
        'value': vitalSign.value,
        'secondary_value': vitalSign.secondaryValue,
        'timestamp': vitalSign.timestamp.toIso8601String(),
        'notes': vitalSign.notes,
        'is_anomaly': vitalSign.isAnomaly,
        'confidence': vitalSign.confidence,
      };
      
      print('🚀 Sending vital sign to API: $_baseUrl/vital-signs');
      print('📤 Data: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/vital-signs'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('📥 API Response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Full response data: $data');
        
        // Handle different response formats
        String? id;
        if (data is Map<String, dynamic>) {
          id = data['_id']?.toString() ?? data['id']?.toString();
        } else if (data is String) {
          id = data;
        }
        
        if (id != null && id.isNotEmpty && id != 'null') {
          print('✅ Vital sign created successfully with ID: $id');
          return id;
        } else {
          print('❌ Invalid response: missing or null ID. Data: $data');
          throw Exception('Invalid response: missing or null ID');
        }
      } else {
        print('❌ Failed to create vital sign: ${response.body}');
        throw Exception('Failed to create vital sign: ${response.body}');
      }
    } catch (e) {
      print('❌ API Error details: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        throw Exception('Network Error: Cannot connect to backend API. Please check if the server is running at $_baseUrl');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout Error: Backend API took too long to respond');
      } else {
        throw Exception('API Error: $e');
      }
    }
  }

  Future<List<VitalSign>> getVitalSigns({
    VitalSignType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? patientId,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (type != null) queryParams['vital_type'] = type.name;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$_baseUrl/vital-signs').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Vital signs response data: $data');
        
        List<dynamic> vitalSignsJson;
        if (data is List) {
          vitalSignsJson = data;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          vitalSignsJson = data['data'] as List<dynamic>;
        } else {
          vitalSignsJson = [];
        }
        
        return vitalSignsJson.map((json) => VitalSign.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get vital signs: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<VitalSign?> getVitalSignById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vital-signs/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VitalSign.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get vital sign: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<void> updateVitalSign(VitalSign vitalSign) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/vital-signs/${vitalSign.id}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'value': vitalSign.value,
          'secondary_value': vitalSign.secondaryValue,
          'timestamp': vitalSign.timestamp.toIso8601String(),
          'notes': vitalSign.notes,
          'is_anomaly': vitalSign.isAnomaly,
          'confidence': vitalSign.confidence,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update vital sign: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<void> deleteVitalSign(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/vital-signs/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete vital sign: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // Alerts API
  Future<String> createAlert(VitalSignAlert alert, {String? patientId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/alerts'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'alert': alert.toJson(),
          'patientId': patientId ?? 'default_patient',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as String;
      } else {
        throw Exception('Failed to create alert: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<List<VitalSignAlert>> getAlerts({
    bool? unreadOnly,
    AlertSeverity? minSeverity,
    int? limit,
    String? patientId,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (unreadOnly == true) queryParams['unreadOnly'] = 'true';
      if (minSeverity != null) queryParams['minSeverity'] = minSeverity.name;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (patientId != null) queryParams['patientId'] = patientId;

      final uri = Uri.parse('$_baseUrl/alerts').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Alerts response data: $data');
        
        // Handle different response formats
        List<dynamic> alertsJson;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('alerts') && data['alerts'] is List) {
            alertsJson = data['alerts'];
          } else if (data.containsKey('data') && data['data'] is List) {
            alertsJson = data['data'];
          } else {
            alertsJson = [];
          }
        } else if (data is List) {
          alertsJson = data;
        } else {
          alertsJson = [];
        }
        
        return alertsJson.map((json) => VitalSignAlert.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get alerts: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<void> markAlertAsRead(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/alerts/$id/read'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark alert as read: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<void> deleteAlert(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/alerts/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete alert: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // Statistics API
  Future<Map<String, dynamic>> getVitalSignStatistics({
    VitalSignType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? patientId,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (type != null) queryParams['type'] = type.name;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (patientId != null) queryParams['patientId'] = patientId;

      final uri = Uri.parse('$_baseUrl/statistics').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Statistics response data: $data');
        
        // Handle both Map and List responses
        if (data is Map<String, dynamic>) {
          return data['statistics'] as Map<String, dynamic>? ?? data;
        } else if (data is List) {
          // Convert list to map format
          return {'statistics': data};
        } else {
          return {};
        }
      } else {
        throw Exception('Failed to get statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // AI Analysis API
  Future<Map<String, dynamic>> detectAnomalies({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analysis/anomalies?days=$days'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to detect anomalies: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeTrends({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analysis/trends?days=$days'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze trends: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> getEarlyWarningScore({int hours = 24}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analysis/early-warning-score?hours=$hours'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get early warning score: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> getHealthSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health-summary'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get health summary: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // Health Check
  Future<bool> isApiHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Data Export/Import
  Future<Map<String, dynamic>> exportData({String? patientId}) async {
    try {
      final queryParams = <String, String>{};
      if (patientId != null) queryParams['patientId'] = patientId;

      final uri = Uri.parse('$_baseUrl/export').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to export data: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<void> importData(Map<String, dynamic> data, {String? patientId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/import'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': data,
          'patientId': patientId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to import data: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
}
