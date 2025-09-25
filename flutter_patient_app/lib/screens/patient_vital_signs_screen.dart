import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PatientVitalSignsScreen extends StatefulWidget {
  const PatientVitalSignsScreen({super.key});

  @override
  State<PatientVitalSignsScreen> createState() =>
      _PatientVitalSignsScreenState();
}

class _PatientVitalSignsScreenState extends State<PatientVitalSignsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _vitalSigns = [];
  bool _isLoading = false;
  String? _patientId;

  // OCR Results
  bool _isOcrLoading = false;

  // Form controllers
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _spO2Controller = TextEditingController();
  final TextEditingController _respiratoryRateController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVitalSigns();
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _temperatureController.dispose();
    _spO2Controller.dispose();
    _respiratoryRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVitalSigns() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userInfo = await authProvider.getCurrentUserInfo();
      _patientId = userInfo['userId'];

      if (_patientId != null) {
        final response = await _apiService.getVitalSignsHistory(_patientId!);
        if (response['success'] == true) {
          setState(() {
            _vitalSigns =
                List<Map<String, dynamic>>.from(response['vital_signs'] ?? []);
          });
        } else {
          final errorMessage =
              response['message'] ?? response['error'] ?? 'Unknown error';
          _showSnackBar(
              'Failed to load vital signs: $errorMessage', Colors.red);
        }
      } else {
        _showSnackBar('Patient ID not found. Please log in again.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error loading vital signs: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recordVitalSign() async {
    if (_patientId == null) {
      _showSnackBar('Patient ID not found', Colors.red);
      return;
    }

    // Validate at least one vital sign is entered
    if (_heartRateController.text.isEmpty &&
        _systolicController.text.isEmpty &&
        _diastolicController.text.isEmpty &&
        _temperatureController.text.isEmpty &&
        _spO2Controller.text.isEmpty &&
        _respiratoryRateController.text.isEmpty) {
      _showSnackBar('Please enter at least one vital sign', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Record heart rate if provided
      if (_heartRateController.text.isNotEmpty) {
        await _recordSingleVitalSign(
            'heartRate', double.parse(_heartRateController.text));
      }

      // Record blood pressure if provided
      if (_systolicController.text.isNotEmpty &&
          _diastolicController.text.isNotEmpty) {
        await _recordSingleVitalSign(
            'bloodPressure',
            double.parse(_systolicController.text),
            double.parse(_diastolicController.text));
      }

      // Record temperature if provided
      if (_temperatureController.text.isNotEmpty) {
        await _recordSingleVitalSign(
            'temperature', double.parse(_temperatureController.text));
      }

      // Record SpO2 if provided
      if (_spO2Controller.text.isNotEmpty) {
        await _recordSingleVitalSign(
            'spO2', double.parse(_spO2Controller.text));
      }

      // Record respiratory rate if provided
      if (_respiratoryRateController.text.isNotEmpty) {
        await _recordSingleVitalSign(
            'respiratoryRate', double.parse(_respiratoryRateController.text));
      }

      _showSnackBar('Vital signs recorded successfully!', Colors.green);
      _clearForm();
      _loadVitalSigns();
    } catch (e) {
      _showSnackBar('Error recording vital signs: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recordSingleVitalSign(String type, double value,
      [double? secondaryValue]) async {
    final vitalData = {
      'patient_id': _patientId,
      'type': type,
      'value': value,
      'secondary_value': secondaryValue,
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
    };

    final response = await _apiService.recordVitalSign(vitalData);
    if (response['success'] != true) {
      final errorMessage = response['message'] ??
          response['error'] ??
          'Failed to record vital sign';
      throw Exception(errorMessage);
    }
  }

  void _clearForm() {
    _heartRateController.clear();
    _systolicController.clear();
    _diastolicController.clear();
    _temperatureController.clear();
    _spO2Controller.clear();
    _respiratoryRateController.clear();
    _notesController.clear();
  }

  Future<void> _uploadVitalOcrDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'txt',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'bmp',
          'tiff'
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        setState(() {
          _isOcrLoading = true;
        });

        Map<String, dynamic> response;

        try {
          // Platform-specific approach with fallback
          if (kIsWeb) {
            // Web platform - always use bytes
            print('🌐 Web platform detected - using bytes approach');
            if (file.bytes != null) {
              print('📄 File bytes available: ${file.bytes!.length} bytes');
              final base64String = _bytesToBase64(file.bytes!);
              print(
                  '🔄 Converted to base64: ${base64String.length} characters');
              response = await _apiService.processVitalOcrBase64(base64String);
            } else {
              throw Exception('File bytes not available on web platform');
            }
          } else {
            // Mobile platform - try file path first, fallback to bytes
            if (file.path != null) {
              print('📱 Mobile platform - using file path approach');
              print('📁 File path: ${file.path}');
              response = await _apiService.uploadVitalOcrDocument(
                file.path!,
                file.name,
              );
            } else if (file.bytes != null) {
              print('📱 Mobile platform - fallback to bytes approach');
              print('📄 File bytes available: ${file.bytes!.length} bytes');
              final base64String = _bytesToBase64(file.bytes!);
              print(
                  '🔄 Converted to base64: ${base64String.length} characters');
              response = await _apiService.processVitalOcrBase64(base64String);
            } else {
              throw Exception('Neither file bytes nor file path are available');
            }
          }

          setState(() {
            _isOcrLoading = false;
          });

          if (response['success'] == true) {
            _showOcrResultsDialog(response);
          } else {
            _showSnackBar(
              'OCR processing failed: ${response['message'] ?? 'Unknown error'}',
              Colors.red,
            );
          }
        } catch (apiError) {
          print('❌ API Error: $apiError');

          // Try alternative approach if first one fails
          if (file.bytes != null && file.path != null) {
            print('🔄 Trying alternative approach...');
            try {
              setState(() {
                _isOcrLoading = true;
              });

              // Try the other method
              if (apiError.toString().contains('base64') ||
                  apiError.toString().contains('bytes')) {
                // If base64 failed, try file path
                print('🔄 Retrying with file path approach');
                response = await _apiService.uploadVitalOcrDocument(
                  file.path!,
                  file.name,
                );
              } else {
                // If file path failed, try base64
                print('🔄 Retrying with base64 approach');
                final base64String = _bytesToBase64(file.bytes!);
                response =
                    await _apiService.processVitalOcrBase64(base64String);
              }

              setState(() {
                _isOcrLoading = false;
              });

              if (response['success'] == true) {
                _showOcrResultsDialog(response);
              } else {
                _showSnackBar(
                  'OCR processing failed: ${response['message'] ?? 'Unknown error'}',
                  Colors.red,
                );
              }
            } catch (retryError) {
              setState(() {
                _isOcrLoading = false;
              });
              _showSnackBar(
                  'Upload failed after retry: $retryError', Colors.red);
            }
          } else {
            setState(() {
              _isOcrLoading = false;
            });
            _showSnackBar('Upload failed: $apiError', Colors.red);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isOcrLoading = false;
      });
      print('❌ Upload error: $e');
      _showSnackBar('Error uploading document: $e', Colors.red);
    }
  }

  void _showOcrResultsDialog(Map<String, dynamic> ocrResults) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${ocrResults['filename'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'File Type: ${ocrResults['file_type'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Text Elements: ${ocrResults['text_count'] ?? 0}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Extracted Text:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    ocrResults['extracted_text'] ?? 'No text extracted',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (ocrResults['results'] != null) ...[
                const Text(
                  'Detailed Results:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: (ocrResults['results'] as List).length,
                    itemBuilder: (context, index) {
                      final result = ocrResults['results'][index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          result['text'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          'Confidence: ${(result['confidence'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _extractVitalSignsFromOcr(ocrResults);
            },
            child: const Text('Use Results'),
          ),
        ],
      ),
    );
  }

  void _extractVitalSignsFromOcr(Map<String, dynamic> ocrResults) {
    final extractedText = ocrResults['extracted_text'] ?? '';
    if (extractedText.isEmpty) {
      _showSnackBar('No text extracted from document', Colors.orange);
      return;
    }

    // Extract vital signs from text using regex patterns
    final vitalSigns = _parseVitalSignsFromText(extractedText);

    if (vitalSigns.isEmpty) {
      _showSnackBar('No vital signs found in document', Colors.orange);
      return;
    }

    // Populate form fields with extracted vital signs
    _populateFormWithVitalSigns(vitalSigns);

    _showSnackBar(
      'Extracted ${vitalSigns.length} vital signs from document',
      Colors.green,
    );
  }

  Map<String, dynamic> _parseVitalSignsFromText(String text) {
    final vitalSigns = <String, dynamic>{};

    // Heart Rate patterns
    final heartRatePatterns = [
      RegExp(r'heart\s*rate[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'hr[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*bpm', caseSensitive: false),
      RegExp(r'pulse[:\s]*(\d+)', caseSensitive: false),
    ];

    for (final pattern in heartRatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitalSigns['heartRate'] = int.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Blood Pressure patterns
    final bpPatterns = [
      RegExp(r'blood\s*pressure[:\s]*(\d+)[/\-](\d+)', caseSensitive: false),
      RegExp(r'bp[:\s]*(\d+)[/\-](\d+)', caseSensitive: false),
      RegExp(r'(\d+)[/\-](\d+)\s*mmhg', caseSensitive: false),
    ];

    for (final pattern in bpPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitalSigns['systolic'] = int.tryParse(match.group(1) ?? '');
        vitalSigns['diastolic'] = int.tryParse(match.group(2) ?? '');
        break;
      }
    }

    // Temperature patterns
    final tempPatterns = [
      RegExp(r'temperature[:\s]*(\d+\.?\d*)\s*°?[cf]', caseSensitive: false),
      RegExp(r'temp[:\s]*(\d+\.?\d*)\s*°?[cf]', caseSensitive: false),
      RegExp(r'(\d+\.?\d*)\s*°?[cf]', caseSensitive: false),
    ];

    for (final pattern in tempPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitalSigns['temperature'] = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // SpO2 patterns
    final spo2Patterns = [
      RegExp(r'spo2[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'oxygen\s*saturation[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*%', caseSensitive: false),
    ];

    for (final pattern in spo2Patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitalSigns['spO2'] = int.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Respiratory Rate patterns
    final rrPatterns = [
      RegExp(r'respiratory\s*rate[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'breathing\s*rate[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'rr[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*breaths?/min', caseSensitive: false),
    ];

    for (final pattern in rrPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitalSigns['respiratoryRate'] = int.tryParse(match.group(1) ?? '');
        break;
      }
    }

    return vitalSigns;
  }

  void _populateFormWithVitalSigns(Map<String, dynamic> vitalSigns) {
    if (vitalSigns['heartRate'] != null) {
      _heartRateController.text = vitalSigns['heartRate'].toString();
    }
    if (vitalSigns['systolic'] != null) {
      _systolicController.text = vitalSigns['systolic'].toString();
    }
    if (vitalSigns['diastolic'] != null) {
      _diastolicController.text = vitalSigns['diastolic'].toString();
    }
    if (vitalSigns['temperature'] != null) {
      _temperatureController.text = vitalSigns['temperature'].toString();
    }
    if (vitalSigns['spO2'] != null) {
      _spO2Controller.text = vitalSigns['spO2'].toString();
    }
    if (vitalSigns['respiratoryRate'] != null) {
      _respiratoryRateController.text =
          vitalSigns['respiratoryRate'].toString();
    }
  }

  String _bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vital Signs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalysis,
            tooltip: 'View Analysis',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.favorite_border,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vital Signs Tracking',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Monitor your vital signs and health metrics',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Record New Vital Signs
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record New Vital Signs',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Heart Rate
                          TextFormField(
                            controller: _heartRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Heart Rate (BPM)',
                              hintText: 'e.g., 75',
                              prefixIcon: Icon(Icons.favorite),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Blood Pressure
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _systolicController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Systolic (mmHg)',
                                    hintText: 'e.g., 120',
                                    prefixIcon: Icon(Icons.bloodtype),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _diastolicController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Diastolic (mmHg)',
                                    hintText: 'e.g., 80',
                                    prefixIcon: Icon(Icons.bloodtype),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Temperature and SpO2
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _temperatureController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Temperature (°C)',
                                    hintText: 'e.g., 36.5',
                                    prefixIcon: Icon(Icons.thermostat),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _spO2Controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'SpO2 (%)',
                                    hintText: 'e.g., 98',
                                    prefixIcon: Icon(Icons.air),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Respiratory Rate
                          TextFormField(
                            controller: _respiratoryRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Respiratory Rate (breaths/min)',
                              hintText: 'e.g., 16',
                              prefixIcon: Icon(Icons.air),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'Any additional notes...',
                              prefixIcon: Icon(Icons.note),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Upload Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isOcrLoading
                                  ? null
                                  : _uploadVitalOcrDocument,
                              icon: _isOcrLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(_isOcrLoading
                                  ? 'Processing...'
                                  : 'Upload Document'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Divider
                          const Divider(),
                          const SizedBox(height: 8),

                          // Record Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _recordVitalSign,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Record Vital Signs',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Vital Signs
                  if (_vitalSigns.isNotEmpty) ...[
                    Text(
                      'Recent Vital Signs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vitalSigns.length,
                      itemBuilder: (context, index) {
                        final vital = _vitalSigns[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getVitalSignColor(vital['type'])
                                  .withOpacity(0.1),
                              child: Icon(
                                _getVitalSignIcon(vital['type']),
                                color: _getVitalSignColor(vital['type']),
                              ),
                            ),
                            title: Text(
                              _getVitalSignTitle(vital['type']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _formatVitalSignValue(vital),
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              _formatTimestamp(vital['timestamp']),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Color _getVitalSignColor(String type) {
    switch (type) {
      case 'heartRate':
        return Colors.red;
      case 'bloodPressure':
        return Colors.blue;
      case 'temperature':
        return Colors.orange;
      case 'spO2':
        return Colors.green;
      case 'respiratoryRate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getVitalSignIcon(String type) {
    switch (type) {
      case 'heartRate':
        return Icons.favorite;
      case 'bloodPressure':
        return Icons.bloodtype;
      case 'temperature':
        return Icons.thermostat;
      case 'spO2':
        return Icons.air;
      case 'respiratoryRate':
        return Icons.air;
      default:
        return Icons.health_and_safety;
    }
  }

  String _getVitalSignTitle(String type) {
    switch (type) {
      case 'heartRate':
        return 'Heart Rate';
      case 'bloodPressure':
        return 'Blood Pressure';
      case 'temperature':
        return 'Temperature';
      case 'spO2':
        return 'SpO2';
      case 'respiratoryRate':
        return 'Respiratory Rate';
      default:
        return type;
    }
  }

  String _formatVitalSignValue(Map<String, dynamic> vital) {
    final value = vital['value'];
    final secondaryValue = vital['secondary_value'];

    if (secondaryValue != null) {
      return '${value.toInt()}/${secondaryValue.toInt()}';
    } else {
      return '${value.toString()}${_getVitalSignUnit(vital['type'])}';
    }
  }

  String _getVitalSignUnit(String type) {
    switch (type) {
      case 'heartRate':
        return ' BPM';
      case 'bloodPressure':
        return ' mmHg';
      case 'temperature':
        return '°C';
      case 'spO2':
        return '%';
      case 'respiratoryRate':
        return ' breaths/min';
      default:
        return '';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.parse(timestamp.toString());
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _showAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vital Signs Analysis'),
        content: const Text('AI analysis feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
