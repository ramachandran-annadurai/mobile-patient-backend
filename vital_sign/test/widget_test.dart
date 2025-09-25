import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vital_signs_monitor/main.dart';
import 'package:vital_signs_monitor/providers/vital_signs_provider.dart';
import 'package:vital_signs_monitor/models/vital_sign.dart';

void main() {
  group('Vital Signs Monitor Tests', () {
    testWidgets('App should start with login screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VitalSignsProvider()),
          ],
          child: MaterialApp(
            home: const LoginScreen(),
          ),
        ),
      );

      // Verify that the login screen is displayed
      expect(find.text('Vital Signs Monitor'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('Login form validation should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VitalSignsProvider()),
          ],
          child: MaterialApp(
            home: const LoginScreen(),
          ),
        ),
      );

      // Try to submit empty form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Should switch between login and registration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VitalSignsProvider()),
          ],
          child: MaterialApp(
            home: const LoginScreen(),
          ),
        ),
      );

      // Initially should be in login mode
      expect(find.text('Sign in to continue'), findsOneWidget);

      // Tap Sign Up button
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Should switch to registration mode
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });

  group('VitalSign Model Tests', () {
    test('VitalSign should create correctly', () {
      final vitalSign = VitalSign(
        id: 'test-id',
        type: VitalSignType.heartRate,
        value: 75.0,
        timestamp: DateTime.now(),
      );

      expect(vitalSign.id, 'test-id');
      expect(vitalSign.type, VitalSignType.heartRate);
      expect(vitalSign.value, 75.0);
      expect(vitalSign.isNormal, true);
    });

    test('VitalSign should detect abnormal values', () {
      final vitalSign = VitalSign(
        id: 'test-id',
        type: VitalSignType.heartRate,
        value: 150.0, // Abnormal heart rate
        timestamp: DateTime.now(),
      );

      expect(vitalSign.isNormal, false);
    });

    test('Blood pressure should handle both values', () {
      final vitalSign = VitalSign(
        id: 'test-id',
        type: VitalSignType.bloodPressure,
        value: 120.0, // Systolic
        secondaryValue: 80.0, // Diastolic
        timestamp: DateTime.now(),
      );

      expect(vitalSign.formattedValue, '120/80');
      expect(vitalSign.isNormal, true);
    });

    test('VitalSign should serialize to JSON', () {
      final vitalSign = VitalSign(
        id: 'test-id',
        type: VitalSignType.temperature,
        value: 37.0,
        timestamp: DateTime(2023, 1, 1, 12, 0),
        notes: 'Test note',
      );

      final json = vitalSign.toJson();
      expect(json['id'], 'test-id');
      expect(json['type'], 'temperature');
      expect(json['value'], 37.0);
      expect(json['notes'], 'Test note');
    });

    test('VitalSign should deserialize from JSON', () {
      final json = {
        'id': 'test-id',
        'type': 'spO2',
        'value': 98.0,
        'timestamp': '2023-01-01T12:00:00.000Z',
        'notes': 'Test note',
        'isAnomaly': false,
        'confidence': 0.9,
      };

      final vitalSign = VitalSign.fromJson(json);
      expect(vitalSign.id, 'test-id');
      expect(vitalSign.type, VitalSignType.spO2);
      expect(vitalSign.value, 98.0);
      expect(vitalSign.notes, 'Test note');
      expect(vitalSign.isAnomaly, false);
      expect(vitalSign.confidence, 0.9);
    });
  });

  group('VitalSignType Tests', () {
    test('All vital sign types should have display names', () {
      for (final type in VitalSignType.values) {
        expect(type.displayName.isNotEmpty, true);
        expect(type.unit.isNotEmpty, true);
      }
    });

    test('Normal ranges should be defined for all types', () {
      for (final type in VitalSignType.values) {
        expect(VitalSign.normalRanges.containsKey(type), true);
        final range = VitalSign.normalRanges[type]!;
        expect(range['min'], isNotNull);
        expect(range['max'], isNotNull);
        expect(range['min'] < range['max'], true);
      }
    });
  });

  group('AlertSeverity Tests', () {
    test('Alert severity should have display names', () {
      for (final severity in AlertSeverity.values) {
        expect(severity.displayName.isNotEmpty, true);
      }
    });
  });
}
