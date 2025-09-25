import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vital_sign.dart';
import '../providers/vital_signs_provider.dart';
import '../widgets/vital_sign_input_form.dart';

class VitalSignInputScreen extends StatefulWidget {
  final VitalSignType? initialType;
  final VitalSign? existingVitalSign;

  const VitalSignInputScreen({
    Key? key,
    this.initialType,
    this.existingVitalSign,
  }) : super(key: key);

  @override
  State<VitalSignInputScreen> createState() => _VitalSignInputScreenState();
}

class _VitalSignInputScreenState extends State<VitalSignInputScreen> {
  VitalSignType _selectedType = VitalSignType.heartRate;
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _secondaryValueController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    if (widget.existingVitalSign != null) {
      _populateForm(widget.existingVitalSign!);
    }
  }

  void _populateForm(VitalSign vitalSign) {
    _selectedType = vitalSign.type;
    _valueController.text = vitalSign.value.toString();
    if (vitalSign.secondaryValue != null) {
      _secondaryValueController.text = vitalSign.secondaryValue.toString();
    }
    _notesController.text = vitalSign.notes ?? '';
    _selectedDate = vitalSign.timestamp;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _secondaryValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVitalSign() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<VitalSignsProvider>(context, listen: false);
    
    try {
      final vitalSign = VitalSign(
        id: widget.existingVitalSign?.id ?? '',
        type: _selectedType,
        value: double.parse(_valueController.text),
        secondaryValue: _secondaryValueController.text.isNotEmpty 
            ? double.tryParse(_secondaryValueController.text) 
            : null,
        timestamp: _selectedDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (widget.existingVitalSign != null) {
        await provider.updateVitalSign(vitalSign);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vital sign updated successfully')),
          );
        }
      } else {
        await provider.addVitalSign(vitalSign);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vital sign added successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingVitalSign != null 
            ? 'Edit Vital Sign' 
            : 'Add Vital Sign'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showVitalSignInfo,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vital Sign Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vital Sign Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<VitalSignType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select Type',
                        ),
                        items: VitalSignType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                            _valueController.clear();
                            _secondaryValueController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Vital Sign Input Form
              VitalSignInputForm(
                type: _selectedType,
                valueController: _valueController,
                secondaryValueController: _secondaryValueController,
                notesController: _notesController,
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _saveVitalSign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.existingVitalSign != null ? 'Update' : 'Save',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVitalSignInfo() {
    final range = VitalSign.normalRanges[_selectedType];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_selectedType.displayName} Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unit: ${_selectedType.unit}'),
            const SizedBox(height: 8),
            if (range != null) ...[
              Text('Normal Range: ${range['min']} - ${range['max']} ${_selectedType.unit}'),
              const SizedBox(height: 8),
            ],
            Text(_getVitalSignDescription(_selectedType)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getVitalSignDescription(VitalSignType type) {
    switch (type) {
      case VitalSignType.heartRate:
        return 'Heart rate measures the number of heartbeats per minute. Normal range is 60-100 bpm for adults.';
      case VitalSignType.bloodPressure:
        return 'Blood pressure measures the force of blood against artery walls. Normal range is 90-140/60-90 mmHg.';
      case VitalSignType.temperature:
        return 'Body temperature indicates the body\'s ability to generate and get rid of heat. Normal range is 36.1-37.2°C.';
      case VitalSignType.spO2:
        return 'SpO2 measures the oxygen saturation level in blood. Normal range is 95-100%.';
      case VitalSignType.respiratoryRate:
        return 'Respiratory rate measures the number of breaths per minute. Normal range is 12-20 breaths/min.';
    }
  }
}
