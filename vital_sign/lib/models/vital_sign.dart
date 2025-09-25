
enum VitalSignType {
  heartRate,
  bloodPressure,
  temperature,
  spO2,
  respiratoryRate,
}

extension VitalSignTypeExtension on VitalSignType {
  String get displayName {
    switch (this) {
      case VitalSignType.heartRate:
        return 'Heart Rate';
      case VitalSignType.bloodPressure:
        return 'Blood Pressure';
      case VitalSignType.temperature:
        return 'Temperature';
      case VitalSignType.spO2:
        return 'SpO₂';
      case VitalSignType.respiratoryRate:
        return 'Respiratory Rate';
    }
  }

  String get unit {
    switch (this) {
      case VitalSignType.heartRate:
        return 'bpm';
      case VitalSignType.bloodPressure:
        return 'mmHg';
      case VitalSignType.temperature:
        return '°C';
      case VitalSignType.spO2:
        return '%';
      case VitalSignType.respiratoryRate:
        return 'breaths/min';
    }
  }
}

class VitalSign {
  final String id;
  final VitalSignType type;
  final double value;
  final double? secondaryValue; // For blood pressure (diastolic)
  final DateTime timestamp;
  final String? notes;
  final bool isAnomaly;
  final double? confidence;

  VitalSign({
    required this.id,
    required this.type,
    required this.value,
    this.secondaryValue,
    required this.timestamp,
    this.notes,
    this.isAnomaly = false,
    this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'secondaryValue': secondaryValue,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'isAnomaly': isAnomaly,
      'confidence': confidence,
    };
  }

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: VitalSignType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VitalSignType.heartRate,
      ),
      value: (json['value'] ?? 0.0).toDouble(),
      secondaryValue: json['secondary_value']?.toDouble() ?? json['secondaryValue']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes']?.toString(),
      isAnomaly: json['is_anomaly'] ?? json['isAnomaly'] ?? false,
      confidence: json['confidence']?.toDouble(),
    );
  }

  VitalSign copyWith({
    String? id,
    VitalSignType? type,
    double? value,
    double? secondaryValue,
    DateTime? timestamp,
    String? notes,
    bool? isAnomaly,
    double? confidence,
  }) {
    return VitalSign(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      isAnomaly: isAnomaly ?? this.isAnomaly,
      confidence: confidence ?? this.confidence,
    );
  }

  // Normal ranges for different vital signs
  static Map<VitalSignType, Map<String, double>> normalRanges = {
    VitalSignType.heartRate: {'min': 60.0, 'max': 100.0},
    VitalSignType.bloodPressure: {'min': 90.0, 'max': 140.0}, // Systolic
    VitalSignType.temperature: {'min': 36.1, 'max': 37.2}, // Celsius
    VitalSignType.spO2: {'min': 95.0, 'max': 100.0},
    VitalSignType.respiratoryRate: {'min': 12.0, 'max': 20.0},
  };

  bool get isNormal {
    final range = normalRanges[type];
    if (range == null) return true;
    
    if (type == VitalSignType.bloodPressure) {
      // For blood pressure, check both systolic and diastolic
      final diastolicRange = {'min': 60.0, 'max': 90.0};
      return value >= range['min']! && 
             value <= range['max']! && 
             (secondaryValue == null || 
              (secondaryValue! >= diastolicRange['min']! && 
               secondaryValue! <= diastolicRange['max']!));
    }
    
    return value >= range['min']! && value <= range['max']!;
  }


  String get formattedValue {
    if (type == VitalSignType.bloodPressure && secondaryValue != null) {
      return '${value.toInt()}/${secondaryValue!.toInt()}';
    }
    return '${value.toStringAsFixed(type == VitalSignType.temperature ? 1 : 0)}';
  }

  String get unit => type.unit;
}

class VitalSignAlert {
  final String id;
  final VitalSignType type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRequired;

  VitalSignAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.actionRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionRequired': actionRequired,
    };
  }

  factory VitalSignAlert.fromJson(Map<String, dynamic> json) {
    return VitalSignAlert(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: VitalSignType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VitalSignType.heartRate,
      ),
      message: json['message']?.toString() ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.low,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      actionRequired: json['actionRequired']?.toString() ?? json['action_required']?.toString(),
    );
  }
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}
