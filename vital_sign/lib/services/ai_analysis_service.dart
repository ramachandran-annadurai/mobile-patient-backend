import 'dart:math';
import '../models/vital_sign.dart';
import 'database_service.dart';

class AIAnalysisService {
  static final AIAnalysisService _instance = AIAnalysisService._internal();
  factory AIAnalysisService() => _instance;
  AIAnalysisService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Anomaly Detection using Statistical Methods
  Future<VitalSign> analyzeVitalSign(VitalSign vitalSign) async {
    // Get historical data for comparison
    final historicalData = await _databaseService.getVitalSigns(
      type: vitalSign.type,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      limit: 100,
    );

    if (historicalData.isEmpty) {
      // No historical data, use normal ranges
      return vitalSign.copyWith(
        isAnomaly: !vitalSign.isNormal,
        confidence: vitalSign.isNormal ? 0.8 : 0.6,
      );
    }

    // Calculate statistical measures
    final values = historicalData.map((v) => v.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final standardDeviation = sqrt(variance);

    // Z-score calculation
    final zScore = (vitalSign.value - mean) / standardDeviation;
    
    // Determine if it's an anomaly (Z-score > 2 or < -2)
    final isAnomaly = zScore.abs() > 2.0;
    
    // Calculate confidence based on Z-score
    final confidence = _calculateConfidence(zScore);

    // Check for critical values
    final isCritical = _isCriticalValue(vitalSign);

    return vitalSign.copyWith(
      isAnomaly: isAnomaly || isCritical,
      confidence: confidence,
    );
  }

  // Early Warning Score (EWS) calculation
  Future<Map<String, dynamic>> calculateEarlyWarningScore(List<VitalSign> recentVitals) async {
    int totalScore = 0;
    Map<String, int> scores = {};

    for (final vital in recentVitals) {
      final score = _getEWSScore(vital);
      scores[vital.type.name] = score;
      totalScore += score;
    }

    // Determine risk level
    String riskLevel;
    if (totalScore >= 7) {
      riskLevel = 'High Risk';
    } else if (totalScore >= 5) {
      riskLevel = 'Medium Risk';
    } else if (totalScore >= 3) {
      riskLevel = 'Low Risk';
    } else {
      riskLevel = 'Normal';
    }

    return {
      'totalScore': totalScore,
      'riskLevel': riskLevel,
      'scores': scores,
      'timestamp': DateTime.now(),
    };
  }

  // Trend Analysis
  Future<Map<String, dynamic>> analyzeTrends(VitalSignType type, {int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final vitalSigns = await _databaseService.getVitalSigns(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    if (vitalSigns.length < 3) {
      return {
        'trend': 'Insufficient Data',
        'slope': 0.0,
        'confidence': 0.0,
        'recommendation': 'Collect more data for trend analysis',
      };
    }

    // Sort by timestamp
    vitalSigns.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate linear regression slope
    final slope = _calculateSlope(vitalSigns);
    
    // Determine trend direction
    String trend;
    if (slope > 0.1) {
      trend = 'Increasing';
    } else if (slope < -0.1) {
      trend = 'Decreasing';
    } else {
      trend = 'Stable';
    }

    // Calculate trend confidence
    final confidence = _calculateTrendConfidence(vitalSigns, slope);

    // Generate recommendation
    final recommendation = _generateTrendRecommendation(type, trend, slope);

    return {
      'trend': trend,
      'slope': slope,
      'confidence': confidence,
      'recommendation': recommendation,
      'dataPoints': vitalSigns.length,
    };
  }

  // Predictive Analysis
  Future<Map<String, dynamic>> predictNextValue(VitalSignType type) async {
    final recentData = await _databaseService.getVitalSigns(
      type: type,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      limit: 20,
    );

    if (recentData.length < 3) {
      return {
        'predictedValue': null,
        'confidence': 0.0,
        'message': 'Insufficient data for prediction',
      };
    }

    // Sort by timestamp
    recentData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Simple linear prediction
    final slope = _calculateSlope(recentData);
    final lastValue = recentData.last.value;
    final lastTimestamp = recentData.last.timestamp;
    final nextTimestamp = DateTime.now().add(const Duration(hours: 1));
    
    final timeDiff = nextTimestamp.difference(lastTimestamp).inHours;
    final predictedValue = lastValue + (slope * timeDiff);

    // Calculate prediction confidence
    final confidence = _calculatePredictionConfidence(recentData);

    return {
      'predictedValue': predictedValue,
      'confidence': confidence,
      'nextCheckTime': nextTimestamp,
      'basedOnDataPoints': recentData.length,
    };
  }

  // Helper Methods
  double _calculateConfidence(double zScore) {
    // Convert Z-score to confidence (0-1)
    final absZScore = zScore.abs();
    if (absZScore <= 1.0) return 0.9;
    if (absZScore <= 2.0) return 0.7;
    if (absZScore <= 3.0) return 0.5;
    return 0.3;
  }

  bool _isCriticalValue(VitalSign vitalSign) {
    switch (vitalSign.type) {
      case VitalSignType.heartRate:
        return vitalSign.value < 40 || vitalSign.value > 150;
      case VitalSignType.bloodPressure:
        return vitalSign.value > 180 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 110);
      case VitalSignType.temperature:
        return vitalSign.value < 35.0 || vitalSign.value > 39.0;
      case VitalSignType.spO2:
        return vitalSign.value < 90;
      case VitalSignType.respiratoryRate:
        return vitalSign.value < 8 || vitalSign.value > 30;
    }
  }

  int _getEWSScore(VitalSign vitalSign) {
    switch (vitalSign.type) {
      case VitalSignType.heartRate:
        if (vitalSign.value < 40 || vitalSign.value > 130) return 3;
        if (vitalSign.value < 50 || vitalSign.value > 110) return 2;
        if (vitalSign.value < 60 || vitalSign.value > 100) return 1;
        return 0;
      
      case VitalSignType.bloodPressure:
        if (vitalSign.value > 160 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 100)) return 3;
        if (vitalSign.value > 140 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 90)) return 2;
        if (vitalSign.value > 120 || (vitalSign.secondaryValue != null && vitalSign.secondaryValue! > 80)) return 1;
        return 0;
      
      case VitalSignType.temperature:
        if (vitalSign.value < 35.0 || vitalSign.value > 38.5) return 3;
        if (vitalSign.value < 36.0 || vitalSign.value > 38.0) return 2;
        if (vitalSign.value < 36.5 || vitalSign.value > 37.5) return 1;
        return 0;
      
      case VitalSignType.spO2:
        if (vitalSign.value < 90) return 3;
        if (vitalSign.value < 95) return 2;
        if (vitalSign.value < 97) return 1;
        return 0;
      
      case VitalSignType.respiratoryRate:
        if (vitalSign.value < 8 || vitalSign.value > 25) return 3;
        if (vitalSign.value < 10 || vitalSign.value > 22) return 2;
        if (vitalSign.value < 12 || vitalSign.value > 20) return 1;
        return 0;
    }
  }

  double _calculateSlope(List<VitalSign> vitalSigns) {
    if (vitalSigns.length < 2) return 0.0;

    final n = vitalSigns.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble(); // Time index
      final y = vitalSigns[i].value;
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  double _calculateTrendConfidence(List<VitalSign> vitalSigns, double slope) {
    if (vitalSigns.length < 3) return 0.0;

    // Calculate R-squared for trend confidence
    final mean = vitalSigns.map((v) => v.value).reduce((a, b) => a + b) / vitalSigns.length;
    double ssRes = 0, ssTot = 0;

    for (int i = 0; i < vitalSigns.length; i++) {
      final predicted = mean + slope * i;
      final actual = vitalSigns[i].value;
      
      ssRes += pow(actual - predicted, 2);
      ssTot += pow(actual - mean, 2);
    }

    if (ssTot == 0) return 0.0;
    return max(0.0, min(1.0, 1 - (ssRes / ssTot)));
  }

  double _calculatePredictionConfidence(List<VitalSign> vitalSigns) {
    if (vitalSigns.length < 3) return 0.0;

    // Calculate variance in recent data
    final values = vitalSigns.map((v) => v.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    // Lower variance = higher confidence
    final normalizedVariance = min(1.0, variance / 100.0);
    return max(0.1, 1.0 - normalizedVariance);
  }

  String _generateTrendRecommendation(VitalSignType type, String trend, double slope) {
    switch (type) {
      case VitalSignType.heartRate:
        if (trend == 'Increasing') {
          return 'Heart rate is trending upward. Consider stress management and physical activity monitoring.';
        } else if (trend == 'Decreasing') {
          return 'Heart rate is trending downward. Monitor for signs of fatigue or medication effects.';
        }
        return 'Heart rate is stable. Continue current monitoring routine.';
      
      case VitalSignType.bloodPressure:
        if (trend == 'Increasing') {
          return 'Blood pressure is trending upward. Consider lifestyle modifications and medical consultation.';
        } else if (trend == 'Decreasing') {
          return 'Blood pressure is trending downward. Monitor for dizziness or weakness.';
        }
        return 'Blood pressure is stable. Continue current management plan.';
      
      case VitalSignType.temperature:
        if (trend == 'Increasing') {
          return 'Temperature is trending upward. Monitor for signs of infection or inflammation.';
        } else if (trend == 'Decreasing') {
          return 'Temperature is trending downward. Monitor for hypothermia or metabolic issues.';
        }
        return 'Temperature is stable. Continue current monitoring.';
      
      case VitalSignType.spO2:
        if (trend == 'Decreasing') {
          return 'SpO2 is trending downward. Monitor breathing and consider medical evaluation.';
        }
        return 'SpO2 is stable. Continue current monitoring routine.';
      
      case VitalSignType.respiratoryRate:
        if (trend == 'Increasing') {
          return 'Respiratory rate is trending upward. Monitor for respiratory distress.';
        } else if (trend == 'Decreasing') {
          return 'Respiratory rate is trending downward. Monitor for respiratory depression.';
        }
        return 'Respiratory rate is stable. Continue current monitoring.';
    }
  }
}
