class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._internal();

  AppConfig._internal();

  // MongoDB Configuration
  String get mongodbUri => 'mongodb://localhost:27017';
  String get mongodbDatabase => 'vital_signs_db';
  String get mongodbCollection => 'patients_v2';

  // Application Configuration
  String get appName => 'Vital Signs Monitor';
  String get appVersion => '1.0.0';
  bool get debugMode => true;


  // API Configuration
  String get apiBaseUrl => 'http://localhost:8000';
  int get apiTimeout => 30000;

  // Notification Configuration
  bool get notificationEnabled => true;
  int get alertThresholdHigh => 7;
  int get alertThresholdMedium => 5;
  int get alertThresholdLow => 3;

  // Data Retention
  int get dataRetentionDays => 365;
  int get backupIntervalHours => 24;

  // AI Analysis Configuration
  bool get aiAnalysisEnabled => true;
  double get anomalyDetectionSensitivity => 2.0;
  int get trendAnalysisDays => 7;
  double get predictionConfidenceThreshold => 0.7;

  Future<void> loadConfig() async {
    // Configuration loaded from hardcoded values
  }

  void validateConfig() {
    // Configuration validation
  }
}
