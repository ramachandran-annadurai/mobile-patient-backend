# Vital Signs Monitor

A comprehensive Flutter mobile application for monitoring and analyzing vital signs with AI-powered anomaly detection, real-time alerts, and secure data management.

## 🎯 Features

### Core Functionality
- **Manual Vital Signs Input**: Enter heart rate, blood pressure, temperature, SpO₂, and respiratory rate
- **Real-time Visualization**: Interactive charts and graphs for trend analysis
- **AI-Powered Analysis**: Anomaly detection and early warning score calculation
- **Alert System**: Smart notifications for abnormal readings
- **Secure Data Storage**: Encrypted local storage with MongoDB integration

### Advanced Features
- **Trend Analysis**: Statistical analysis of vital signs over time
- **Early Warning Score (EWS)**: Clinical scoring system for risk assessment
- **Predictive Analytics**: AI-based predictions for future readings
- **Data Export/Import**: Backup and restore functionality
- **Multi-patient Support**: Support for multiple patient profiles

## 🏗️ Architecture

### Technology Stack
- **Frontend**: Flutter (Dart)
- **Database**: MongoDB with patients_v2 collection
- **State Management**: Provider pattern
- **Charts**: fl_chart library
- **Security**: AES encryption, SHA-256 hashing
- **Notifications**: flutter_local_notifications

### Project Structure
```
lib/
├── config/                 # Configuration management
├── models/                 # Data models
├── providers/              # State management
├── screens/                # UI screens
├── services/               # Business logic
├── widgets/                # Reusable UI components
└── main.dart              # Application entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- MongoDB instance
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vital_signs_monitor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Copy `config.env` and update with your MongoDB connection details
   - Update encryption keys and other configuration values

4. **Run the application**
   ```bash
   flutter run
   ```

### Configuration

Update the `config.env` file with your settings:

```env
# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017
MONGODB_DATABASE=vital_signs_db
MONGODB_COLLECTION=patients_v2

# Security Configuration
ENCRYPTION_KEY=your_32_character_encryption_key_here
JWT_SECRET=your_jwt_secret_key_here

# AI Analysis Configuration
AI_ANALYSIS_ENABLED=true
ANOMALY_DETECTION_SENSITIVITY=2.0
```

## 📱 Usage

### First Time Setup
1. Launch the app
2. Create a new account or sign in
3. Grant necessary permissions for notifications

### Adding Vital Signs
1. Tap the "+" button on the home screen
2. Select the vital sign type
3. Enter the value(s) and timestamp
4. Add optional notes
5. Save the entry

### Viewing Data
- **Home Screen**: Quick overview and recent readings
- **Dashboard**: Detailed charts and statistics
- **Alerts**: View and manage notifications
- **Trends**: AI analysis and predictions

## 🔒 Security Features

### Data Protection
- **AES Encryption**: All sensitive data encrypted at rest
- **Secure Storage**: Encrypted SharedPreferences for credentials
- **Data Validation**: Input sanitization and validation
- **Audit Logging**: Security event tracking

### Authentication
- **Local Authentication**: Secure user login system
- **Session Management**: Automatic session refresh
- **Password Hashing**: SHA-256 password protection

## 🤖 AI Features

### Anomaly Detection
- **Statistical Analysis**: Z-score based anomaly detection
- **Confidence Scoring**: AI confidence levels for predictions
- **Historical Comparison**: 30-day rolling window analysis

### Early Warning Score
- **Clinical Scoring**: Standard EWS calculation
- **Risk Assessment**: Low, Medium, High, Critical risk levels
- **Real-time Monitoring**: Continuous risk evaluation

### Trend Analysis
- **Linear Regression**: Slope calculation for trends
- **Predictive Modeling**: Future value predictions
- **Recommendation Engine**: AI-generated health recommendations

## 📊 Data Models

### VitalSign
```dart
class VitalSign {
  final String id;
  final VitalSignType type;
  final double value;
  final double? secondaryValue; // For blood pressure
  final DateTime timestamp;
  final String? notes;
  final bool isAnomaly;
  final double? confidence;
}
```

### VitalSignAlert
```dart
class VitalSignAlert {
  final String id;
  final VitalSignType type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRequired;
}
```

## 🔧 API Reference

### DatabaseService
- `insertVitalSign()`: Add new vital sign entry
- `getVitalSigns()`: Retrieve vital signs with filtering
- `updateVitalSign()`: Modify existing entry
- `deleteVitalSign()`: Remove entry

### AIAnalysisService
- `analyzeVitalSign()`: Detect anomalies
- `calculateEarlyWarningScore()`: Compute EWS
- `analyzeTrends()`: Trend analysis
- `predictNextValue()`: Future predictions

### SecurityService
- `encryptData()`: Encrypt sensitive data
- `authenticateUser()`: User authentication
- `createSession()`: Session management
- `logSecurityEvent()`: Audit logging

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Review the code comments

## 🔮 Future Enhancements

- **IoT Device Integration**: MQTT/REST API for device connectivity
- **Cloud Sync**: Multi-device synchronization
- **Advanced Analytics**: Machine learning models
- **Telemedicine**: Healthcare provider integration
- **Wearable Support**: Smartwatch and fitness tracker integration

## 📈 Performance

- **Optimized Queries**: Efficient MongoDB operations
- **Caching**: Smart data caching strategies
- **Memory Management**: Proper resource cleanup
- **Background Processing**: Non-blocking AI analysis

---

**Note**: This application is for educational and personal use. For medical applications, consult with healthcare professionals and ensure compliance with relevant regulations.
