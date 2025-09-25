import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vital_sign.dart';

class VitalSignInputForm extends StatelessWidget {
  final VitalSignType type;
  final TextEditingController valueController;
  final TextEditingController secondaryValueController;
  final TextEditingController notesController;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const VitalSignInputForm({
    Key? key,
    required this.type,
    required this.valueController,
    required this.secondaryValueController,
    required this.notesController,
    required this.selectedDate,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter ${type.displayName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Date and Time Selection
            _buildDateTimeSelector(context),
            const SizedBox(height: 16),
            
            // Value Input Fields
            _buildValueInputs(),
            const SizedBox(height: 16),
            
            // Notes
            _buildNotesInput(),
            const SizedBox(height: 16),
            
            // Normal Range Indicator
            _buildNormalRangeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Date & Time',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            controller: TextEditingController(
              text: DateFormat('MMM dd, yyyy - HH:mm').format(selectedDate),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                );
                
                if (time != null) {
                  final newDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  onDateChanged(newDateTime);
                }
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(selectedDate),
            );
            
            if (time != null) {
              final newDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                time.hour,
                time.minute,
              );
              onDateChanged(newDateTime);
            }
          },
        ),
      ],
    );
  }

  Widget _buildValueInputs() {
    switch (type) {
      case VitalSignType.bloodPressure:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Systolic (mmHg)',
                  border: const OutlineInputBorder(),
                  suffixText: 'mmHg',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateBloodPressure(value, true),
              ),
            ),
            const SizedBox(width: 16),
            const Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: secondaryValueController,
                decoration: InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                  border: const OutlineInputBorder(),
                  suffixText: 'mmHg',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateBloodPressure(value, false),
              ),
            ),
          ],
        );
      
      case VitalSignType.temperature:
        return TextFormField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: 'Temperature',
            border: const OutlineInputBorder(),
            suffixText: type.unit,
            prefixIcon: const Icon(Icons.thermostat),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateTemperature,
        );
      
      case VitalSignType.heartRate:
        return TextFormField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: 'Heart Rate',
            border: const OutlineInputBorder(),
            suffixText: type.unit,
            prefixIcon: const Icon(Icons.favorite),
          ),
          keyboardType: TextInputType.number,
          validator: _validateHeartRate,
        );
      
      case VitalSignType.spO2:
        return TextFormField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: 'Oxygen Saturation',
            border: const OutlineInputBorder(),
            suffixText: type.unit,
            prefixIcon: const Icon(Icons.air),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateSpO2,
        );
      
      case VitalSignType.respiratoryRate:
        return TextFormField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: 'Respiratory Rate',
            border: const OutlineInputBorder(),
            suffixText: type.unit,
            prefixIcon: const Icon(Icons.airline_seat_flat),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateRespiratoryRate,
        );
    }
  }

  Widget _buildNotesInput() {
    return TextFormField(
      controller: notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
        hintText: 'Add any additional notes...',
      ),
      maxLines: 3,
      maxLength: 200,
    );
  }

  Widget _buildNormalRangeIndicator() {
    final range = VitalSign.normalRanges[type];
    if (range == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Normal Range: ${range['min']} - ${range['max']} ${type.unit}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validation Methods
  String? _validateBloodPressure(String? value, bool isSystolic) {
    if (value == null || value.isEmpty) {
      return isSystolic ? 'Systolic pressure is required' : 'Diastolic pressure is required';
    }
    
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    
    if (isSystolic) {
      if (num < 50 || num > 300) {
        return 'Systolic pressure should be between 50-300 mmHg';
      }
    } else {
      if (num < 30 || num > 200) {
        return 'Diastolic pressure should be between 30-200 mmHg';
      }
    }
    
    return null;
  }

  String? _validateTemperature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Temperature is required';
    }
    
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    
    if (num < 30.0 || num > 45.0) {
      return 'Temperature should be between 30.0-45.0°C';
    }
    
    return null;
  }

  String? _validateHeartRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Heart rate is required';
    }
    
    final num = int.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    
    if (num < 20 || num > 300) {
      return 'Heart rate should be between 20-300 bpm';
    }
    
    return null;
  }

  String? _validateSpO2(String? value) {
    if (value == null || value.isEmpty) {
      return 'SpO2 is required';
    }
    
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    
    if (num < 50 || num > 100) {
      return 'SpO2 should be between 50-100%';
    }
    
    return null;
  }

  String? _validateRespiratoryRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Respiratory rate is required';
    }
    
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    
    if (num < 5 || num > 60) {
      return 'Respiratory rate should be between 5-60 breaths/min';
    }
    
    return null;
  }
}
