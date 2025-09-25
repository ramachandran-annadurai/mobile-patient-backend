import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

// Medication dosage model
class MedicationDosage {
  final String dosage;
  final String time;
  final String frequency;
  final bool reminderEnabled;
  final String? nextDoseTime;
  final String? specialInstructions;

  MedicationDosage({
    required this.dosage,
    required this.time,
    required this.frequency,
    this.reminderEnabled = false,
    this.nextDoseTime,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'dosage': dosage,
      'time': time,
      'frequency': frequency,
      'reminder_enabled': reminderEnabled,
      'next_dose_time': nextDoseTime,
      'special_instructions': specialInstructions,
    };
  }
}

class PatientMedicationTrackingScreen extends StatefulWidget {
  final String date;

  const PatientMedicationTrackingScreen({
    super.key,
    required this.date,
  });

  @override
  State<PatientMedicationTrackingScreen> createState() =>
      _PatientMedicationTrackingScreenState();
}

class _PatientMedicationTrackingScreenState
    extends State<PatientMedicationTrackingScreen> {
  final TextEditingController _medicationNameController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _prescribedByController = TextEditingController();

  bool _isSaving = false;
  String _successMessage = '';
  String _errorMessage = '';
  int? _currentPregnancyWeek;
  bool _isLoadingPregnancyWeek = true;

  // OCR Upload related variables
  bool _isUploading = false;
  String? _uploadedFileName;

  String _selectedMedicationType = 'prescription';
  final List<String> _sideEffects = [];
  final TextEditingController _sideEffectController = TextEditingController();

  // Multiple dosages support
  final List<MedicationDosage> _dosages = [];

  @override
  void initState() {
    super.initState();
    _loadPatientPregnancyWeek();
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _notesController.dispose();
    _prescribedByController.dispose();
    _sideEffectController.dispose();
    super.dispose();
  }

  // Load patient's pregnancy week when screen initializes
  Future<void> _loadPatientPregnancyWeek() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userInfo = await authProvider.getCurrentUserInfo();

      if (userInfo['userId'] != null) {
        final apiService = ApiService();
        final profileResponse =
            await apiService.getProfile(patientId: userInfo['userId']!);

        if (profileResponse.containsKey('pregnancy_week') &&
            profileResponse['pregnancy_week'] != null) {
          setState(() {
            _currentPregnancyWeek =
                int.tryParse(profileResponse['pregnancy_week'].toString());
          });
          print('🔍 Loaded pregnancy week: $_currentPregnancyWeek');
        }
      }
    } catch (e) {
      print('⚠️ Could not load pregnancy week: $e');
    } finally {
      setState(() {
        _isLoadingPregnancyWeek = false;
      });
    }
  }

  Future<void> _saveMedicationLog() async {
    if (_medicationNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter medication name';
      });
      return;
    }

    // Validate based on mode
    if (_dosages.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one dosage';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userInfo = await authProvider.getCurrentUserInfo();

      final pregnancyWeek = _currentPregnancyWeek ?? 20;

      // Save medication log with dosages using existing API
      final medicationData = {
        'patient_id': userInfo['userId'] ?? 'unknown',
        'medication_name': _medicationNameController.text.trim(),
        'dosages': _dosages.map((d) => d.toJson()).toList(),
        'date_taken': widget.date,
        'notes': _notesController.text.trim(),
        'prescribed_by': _prescribedByController.text.trim(),
        'medication_type': _selectedMedicationType,
        'side_effects': _sideEffects,
        'pregnancy_week': pregnancyWeek,
      };

      // Debug logging
      print('🔍 ===== MEDICATION DATA DEBUG =====');
      print('🔍 Medication Name: ${medicationData['medication_name']}');
      print('🔍 Dosages Count: ${(medicationData['dosages'] as List).length}');
      print('🔍 Dosages: ${medicationData['dosages']}');
      print('🔍 ===== END DEBUG =====');

      final apiService = ApiService();
      final saveResult = await apiService.saveMedicationLog(medicationData);

      setState(() {
        _isSaving = false;
        if (saveResult.containsKey('success') &&
            saveResult['success'] == true) {
          _successMessage = 'Medication log saved successfully!';
          _clearForm();
        } else {
          _errorMessage =
              saveResult['message'] ?? 'Failed to save medication log';
        }
      });

      // Show success message
      if (_successMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error saving medication log: $e';
      });
    }
  }

  void _clearForm() {
    _medicationNameController.clear();
    _notesController.clear();
    _prescribedByController.clear();
    _sideEffectController.clear();
    setState(() {
      _selectedMedicationType = 'prescription';
      _dosages.clear();
      _sideEffects.clear();
      _successMessage = '';
      _errorMessage = '';
      _uploadedFileName = null;
    });
  }

  // Upload prescription document for OCR processing
  Future<void> _uploadPrescriptionDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png', 'bmp', 'tiff'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        final fileName = file.name;

        if (fileBytes == null) {
          _showErrorSnackBar('Failed to read file');
          return;
        }

        setState(() {
          _isUploading = true;
          _errorMessage = '';
        });

        // Get current user info
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userInfo = await authProvider.getCurrentUserInfo();
        final patientId = userInfo['userId'] ?? 'unknown';

        // Process with OCR
        final apiService = ApiService();
        final ocrResult = await apiService.processPrescriptionDocument(
          patientId,
          _medicationNameController.text.trim().isNotEmpty
              ? _medicationNameController.text.trim()
              : 'Prescription Document',
          fileBytes,
          fileName,
        );

        if (ocrResult['success'] == true) {
          setState(() {
            _uploadedFileName = fileName;
            _isUploading = false;
          });

          // Auto-fill medication name if empty
          if (_medicationNameController.text.trim().isEmpty) {
            _medicationNameController.text = 'Prescription Document';
          }

          // Show extracted text in a dialog
          _showExtractedTextDialog(ocrResult);
        } else {
          setState(() {
            _isUploading = false;
            _errorMessage =
                ocrResult['message'] ?? 'Failed to process document';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error uploading file: $e';
      });
    }
  }

  // Show N8N webhook results and parsed medications in a dialog
  void _showExtractedTextDialog(Map<String, dynamic> ocrResult) {
    final webhookResults = ocrResult['n8n_webhook_results'] ?? {};
    final webhookSuccess = webhookResults['webhook_success'] ?? false;
    final webhookCalls = webhookResults['webhook_calls'] ?? [];
    final successfulCalls = webhookResults['successful_calls'] ?? 0;
    final failedCalls = webhookResults['failed_calls'] ?? 0;
    final parsedMedications = ocrResult['parsed_medications'] ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                webhookSuccess ? Icons.check_circle : Icons.error,
                color: webhookSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(webhookSuccess
                  ? 'N8N Webhook Success'
                  : 'N8N Webhook Failed'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // File info
                Text(
                  'File: ${ocrResult['filename'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Service: ${ocrResult['processing_details']?['service_used'] ?? 'Unknown'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Parsed Medications Section
                if (parsedMedications.isNotEmpty) ...[
                  Text(
                    'Parsed Medications: (${parsedMedications.length} found)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Display each medication in a card
                  ...parsedMedications.asMap().entries.map((entry) {
                    final index = entry.key;
                    final medication = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medication,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Medication ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              // Edit button for each medication
                              IconButton(
                                onPressed: () =>
                                    _editMedication(medication, index),
                                icon: Icon(Icons.edit,
                                    color: Colors.blue[600], size: 18),
                                tooltip: 'Edit Medication',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Medication details in a structured format
                          _buildMedicationField('Name',
                              medication['medicationName'] ?? 'Not specified'),
                          _buildMedicationField('Purpose',
                              medication['purpose'] ?? 'Not specified'),
                          _buildMedicationField('Dosage',
                              medication['dosage'] ?? 'Not specified'),
                          _buildMedicationField(
                              'Route', medication['route'] ?? 'Not specified'),
                          _buildMedicationField('Frequency',
                              medication['frequency'] ?? 'Not specified'),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Save medications to database
                _saveMedicationsToDatabase(parsedMedications);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  // Save medications to database
  Future<void> _saveMedicationsToDatabase(List<dynamic> medications) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Saving medications to database...'),
              ],
            ),
          );
        },
      );

      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientId = authProvider.patientId;

      if (patientId == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save each medication individually using existing medication log API
      final apiService = ApiService();
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < medications.length; i++) {
        final med = medications[i];
        final medicationData = {
          'patient_id': patientId,
          'medication_name': med['medicationName'] ?? 'Unknown',
          'is_prescription_mode': true,
          'prescription_details': 'Medication ${i + 1} from N8N OCR processing',
          'dosages': [
            {
              'medication_name': med['medicationName'] ?? 'Unknown',
              'purpose': med['purpose'] ?? 'Not specified',
              'dosage': med['dosage'] ?? 'Not specified',
              'route': med['route'] ?? 'oral',
              'frequency': med['frequency'] ?? 'Not specified',
              'source': 'n8n_ocr_processing',
              'created_at': DateTime.now().toIso8601String(),
            }
          ],
        };

        try {
          final response = await apiService.saveMedicationLog(medicationData);
          if (response['success'] == true) {
            successCount++;
          } else {
            failCount++;
            print(
                '❌ Failed to save medication ${i + 1}: ${response['message']}');
          }
        } catch (e) {
          failCount++;
          print('❌ Error saving medication ${i + 1}: $e');
        }
      }

      Navigator.of(context).pop(); // Close loading dialog

      // Show results based on success/failure counts
      if (successCount > 0 && failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ All $successCount medications saved successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (successCount > 0 && failCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('⚠️ $successCount medications saved, $failCount failed'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save any medications'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error saving medications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving medications: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Edit medication method
  void _editMedication(Map<String, dynamic> medication, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController =
            TextEditingController(text: medication['medicationName'] ?? '');
        final purposeController =
            TextEditingController(text: medication['purpose'] ?? '');
        final dosageController =
            TextEditingController(text: medication['dosage'] ?? '');
        final routeController =
            TextEditingController(text: medication['route'] ?? '');
        final frequencyController =
            TextEditingController(text: medication['frequency'] ?? '');

        return AlertDialog(
          title: Text('Edit Medication ${index + 1}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: routeController,
                  decoration: const InputDecoration(
                    labelText: 'Route',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the medication data
                medication['medicationName'] = nameController.text;
                medication['purpose'] = purposeController.text;
                medication['dosage'] = dosageController.text;
                medication['route'] = routeController.text;
                medication['frequency'] = frequencyController.text;

                // Trigger UI update
                setState(() {});

                Navigator.of(context).pop();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Medication ${index + 1} updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build medication field display
  Widget _buildMedicationField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Auto-fill form fields based on extracted text
  void _autoFillFromExtractedText(String extractedText) {
    // Simple pattern matching to extract medication information
    final text = extractedText.toLowerCase();

    // Try to extract medication name
    if (_medicationNameController.text.trim().isEmpty) {
      final medicationPatterns = [
        RegExp(r'medication[:\s]+([a-zA-Z0-9\s]+)', caseSensitive: false),
        RegExp(r'medicine[:\s]+([a-zA-Z0-9\s]+)', caseSensitive: false),
        RegExp(r'drug[:\s]+([a-zA-Z0-9\s]+)', caseSensitive: false),
      ];

      for (final pattern in medicationPatterns) {
        final match = pattern.firstMatch(extractedText);
        if (match != null) {
          _medicationNameController.text = match.group(1)?.trim() ?? '';
          break;
        }
      }
    }

    // Try to extract prescribed by
    if (_prescribedByController.text.trim().isEmpty) {
      final doctorPatterns = [
        RegExp(r'dr\.?\s+([a-zA-Z\s]+)', caseSensitive: false),
        RegExp(r'doctor[:\s]+([a-zA-Z\s]+)', caseSensitive: false),
        RegExp(r'prescribed by[:\s]+([a-zA-Z\s]+)', caseSensitive: false),
      ];

      for (final pattern in doctorPatterns) {
        final match = pattern.firstMatch(extractedText);
        if (match != null) {
          _prescribedByController.text = match.group(1)?.trim() ?? '';
          break;
        }
      }
    }

    // Try to extract dosage information
    final dosagePatterns = [
      RegExp(r'(\d+\s*(?:mg|g|ml|tablets?|capsules?))', caseSensitive: false),
      RegExp(r'dosage[:\s]+([a-zA-Z0-9\s]+)', caseSensitive: false),
    ];

    for (final pattern in dosagePatterns) {
      final match = pattern.firstMatch(extractedText);
      if (match != null) {
        // Add as a dosage
        final dosage = MedicationDosage(
          dosage: match.group(1)?.trim() ?? match.group(0)?.trim() ?? '',
          time: '08:00', // Default time
          frequency: 'Once daily', // Default frequency
        );
        setState(() {
          _dosages.add(dosage);
        });
        break;
      }
    }

    // Add extracted text to notes
    if (_notesController.text.trim().isEmpty) {
      _notesController.text =
          'Extracted from prescription document:\n$extractedText';
    }

    setState(() {});
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addSideEffect() {
    if (_sideEffectController.text.trim().isNotEmpty) {
      setState(() {
        _sideEffects.add(_sideEffectController.text.trim());
        _sideEffectController.clear();
      });
    }
  }

  void _removeSideEffect(int index) {
    setState(() {
      _sideEffects.removeAt(index);
    });
  }

  // Add new dosage
  void _addDosage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final dosageController = TextEditingController();
        final timeController = TextEditingController();
        final frequencyController = TextEditingController();
        final instructionsController = TextEditingController();
        bool reminderEnabled = false;
        String? nextDoseTime;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Dosage'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage *',
                        hintText: 'e.g., 500mg, 1 tablet',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: timeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Time *',
                              hintText: 'Select time',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                timeController.text =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          child: const Text('Pick Time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: frequencyController,
                      decoration: const InputDecoration(
                        labelText: 'Frequency *',
                        hintText:
                            'e.g., Once daily, Twice daily, Every 8 hours',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions',
                        hintText: 'Take with food, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: reminderEnabled,
                          onChanged: (value) {
                            setState(() {
                              reminderEnabled = value!;
                            });
                          },
                        ),
                        const Text('Enable Reminder'),
                      ],
                    ),
                    if (reminderEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Next Dose Time',
                                hintText: 'Select reminder time',
                              ),
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    nextDoseTime =
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (dosageController.text.trim().isNotEmpty &&
                        timeController.text.trim().isNotEmpty &&
                        frequencyController.text.trim().isNotEmpty) {
                      final dosage = MedicationDosage(
                        dosage: dosageController.text.trim(),
                        time: timeController.text.trim(),
                        frequency: frequencyController.text.trim(),
                        reminderEnabled: reminderEnabled,
                        nextDoseTime: nextDoseTime,
                        specialInstructions: instructionsController.text.trim(),
                      );
                      this.setState(() {
                        _dosages.add(dosage);
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Remove dosage
  void _removeDosage(int index) {
    setState(() {
      _dosages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'View Dosage Schedule',
            onPressed: () {
              Navigator.pushNamed(context, '/medication-dosage-list');
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Medication History',
            onPressed: () {
              // TODO: Navigate to medication history
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Form',
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.medication,
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
                                  'Daily Medication Log',
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
                                  'Track your medications and dosages',
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${AppDateUtils.formatDate(widget.date)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (_isLoadingPregnancyWeek)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else if (_currentPregnancyWeek != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Text(
                                'Week $_currentPregnancyWeek',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Medication Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medication Details',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),

                              // Medication Name
                              TextFormField(
                                controller: _medicationNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Medication Name *',
                                  hintText: 'Enter medication name...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.medication),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Upload Prescription Document Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isUploading
                                      ? null
                                      : _uploadPrescriptionDocument,
                                  icon: _isUploading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.upload_file),
                                  label: Text(_isUploading
                                      ? 'Processing...'
                                      : 'Upload Prescription Document'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),

                              // Upload status
                              if (_uploadedFileName != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Document processed: $_uploadedFileName',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Error message
                              if (_errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.red.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Multiple Dosages Section
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Dosages',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addDosage,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Dosage'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (_dosages.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No dosages added yet. Click "Add Dosage" to get started.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _dosages.length,
                                  itemBuilder: (context, index) {
                                    final dosage = _dosages[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(
                                          '${dosage.dosage} at ${dosage.time}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Frequency: ${dosage.frequency}'),
                                            if (dosage.specialInstructions
                                                    ?.isNotEmpty ==
                                                true)
                                              Text(
                                                  'Instructions: ${dosage.specialInstructions}'),
                                            if (dosage.reminderEnabled)
                                              const Text(
                                                  '🔔 Reminder enabled for next dose'),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _removeDosage(index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 16),

                              // Medication Type
                              DropdownButtonFormField<String>(
                                value: _selectedMedicationType,
                                decoration: const InputDecoration(
                                  labelText: 'Medication Type',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'prescription',
                                      child: Text('Prescription')),
                                  DropdownMenuItem(
                                      value: 'over_the_counter',
                                      child: Text('Over the Counter')),
                                  DropdownMenuItem(
                                      value: 'supplement',
                                      child: Text('Supplement')),
                                  DropdownMenuItem(
                                      value: 'vitamin', child: Text('Vitamin')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMedicationType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Prescribed By
                              TextFormField(
                                controller: _prescribedByController,
                                decoration: const InputDecoration(
                                  labelText: 'Prescribed By',
                                  hintText: 'Doctor name or clinic',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Notes
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Additional Notes',
                                  hintText:
                                      'Any special instructions or notes...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.note),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Side Effects
                              Text(
                                'Side Effects (if any)',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sideEffectController,
                                      decoration: const InputDecoration(
                                        labelText: 'Add Side Effect',
                                        hintText: 'Enter side effect...',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.warning),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _addSideEffect,
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                              if (_sideEffects.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children:
                                      _sideEffects.asMap().entries.map((entry) {
                                    return Chip(
                                      label: Text(entry.value),
                                      onDeleted: () =>
                                          _removeSideEffect(entry.key),
                                      deleteIcon: const Icon(Icons.close),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Reminder Note
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info,
                                        color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Reminders are automatically set for each dosage when enabled. Check your dosage list above for reminder status.',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Button Row for Daily Tracking and Medication Dosage Details
                              Row(
                                children: [
                                  // Daily Tracking Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Navigate to daily tracking details screen
                                          Navigator.pushNamed(context,
                                              '/patient-daily-tracking-details');
                                        },
                                        icon: const Icon(Icons.track_changes),
                                        label: const Text('Daily Tracking'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Medication Dosage Details Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Navigate to medication dosage list screen
                                          Navigator.pushNamed(context,
                                              '/medication-dosage-list');
                                        },
                                        icon: const Icon(Icons.medication),
                                        label: const Text('Dosage Details'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isSaving ? null : _saveMedicationLog,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(_isSaving
                                      ? 'Saving...'
                                      : 'Save Medication Log'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
