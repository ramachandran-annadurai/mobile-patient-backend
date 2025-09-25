import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? currentProfile;
  
  const EditProfileScreen({super.key, this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Controllers for form fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _pregnancyWeekController = TextEditingController();
  final _expectedDeliveryController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Dropdown values
  String _selectedGender = '';
  String _selectedPregnancyStatus = '';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    if (widget.currentProfile != null) {
      _firstNameController.text = widget.currentProfile!['first_name'] ?? '';
      _lastNameController.text = widget.currentProfile!['last_name'] ?? '';
      _dateOfBirthController.text = widget.currentProfile!['date_of_birth'] ?? '';
      _selectedGender = widget.currentProfile!['gender'] ?? '';
      _bloodTypeController.text = widget.currentProfile!['blood_type'] ?? '';
      _heightController.text = widget.currentProfile!['height'] ?? '';
      _weightController.text = widget.currentProfile!['weight'] ?? '';
      _selectedPregnancyStatus = widget.currentProfile!['pregnancy_status'] ?? '';
      _pregnancyWeekController.text = widget.currentProfile!['pregnancy_week'] ?? '';
      _expectedDeliveryController.text = widget.currentProfile!['expected_delivery_date'] ?? '';
      _emergencyNameController.text = widget.currentProfile!['emergency_contact_name'] ?? '';
      _emergencyPhoneController.text = widget.currentProfile!['emergency_contact_phone'] ?? '';
      _emergencyRelationshipController.text = widget.currentProfile!['emergency_contact_relationship'] ?? '';
      _addressController.text = widget.currentProfile!['address'] ?? '';
      _cityController.text = widget.currentProfile!['city'] ?? '';
      _stateController.text = widget.currentProfile!['state'] ?? '';
      _zipCodeController.text = widget.currentProfile!['zip_code'] ?? '';
      _phoneController.text = widget.currentProfile!['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pregnancyWeekController.dispose();
    _expectedDeliveryController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientId = authProvider.patientId;
      
      if (patientId == null) {
        _showErrorSnackBar('Patient ID not found');
        return;
      }

      final profileData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'gender': _selectedGender,
        'blood_type': _bloodTypeController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'pregnancy_status': _selectedPregnancyStatus,
        'pregnancy_week': _pregnancyWeekController.text.trim(),
        'expected_delivery_date': _expectedDeliveryController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'emergency_contact_relationship': _emergencyRelationshipController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip_code': _zipCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final response = await _apiService.editProfile(
        patientId: patientId,
        profileData: profileData,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey('error')) {
        _showErrorSnackBar(response['error']);
      } else {
        _showSuccessSnackBar('Profile updated successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to update profile: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: 'Enter first name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Enter last name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _dateOfBirthController,
                labelText: 'Date of Birth',
                hintText: 'DD/MM/YYYY',
                prefixIcon: Icons.calendar_today,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Date of birth is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedGender.isEmpty ? null : _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other'].map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Health Information Section
              _buildSectionHeader('Health Information', Icons.favorite),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _bloodTypeController,
                      labelText: 'Blood Type',
                      hintText: 'e.g., O+',
                      prefixIcon: Icons.bloodtype,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Blood type is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      labelText: 'Height (cm)',
                      hintText: 'e.g., 175',
                      prefixIcon: Icons.height,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Height is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      labelText: 'Weight (kg)',
                      hintText: 'e.g., 70',
                      prefixIcon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Weight is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPregnancyStatus.isEmpty ? null : _selectedPregnancyStatus,
                      decoration: const InputDecoration(
                        labelText: 'Pregnancy Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['No', 'Yes'].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPregnancyStatus = newValue ?? '';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_selectedPregnancyStatus == 'Yes') ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _pregnancyWeekController,
                        labelText: 'Pregnancy Week',
                        hintText: 'e.g., 24',
                        prefixIcon: Icons.pregnant_woman,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _expectedDeliveryController,
                        labelText: 'Expected Delivery',
                        hintText: 'DD/MM/YYYY',
                        prefixIcon: Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact', Icons.emergency),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _emergencyNameController,
                labelText: 'Emergency Contact Name',
                hintText: 'Enter emergency contact name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Emergency contact name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _emergencyPhoneController,
                      labelText: 'Emergency Contact Phone',
                      hintText: 'Enter phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Emergency contact phone is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _emergencyRelationshipController,
                      labelText: 'Relationship',
                      hintText: 'e.g., Brother',
                      prefixIcon: Icons.family_restroom,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Relationship is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information', Icons.contact_phone),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _addressController,
                labelText: 'Address',
                hintText: 'Enter your address',
                prefixIcon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      labelText: 'City',
                      hintText: 'Enter city',
                      prefixIcon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      labelText: 'State',
                      hintText: 'Enter state',
                      prefixIcon: Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _zipCodeController,
                      labelText: 'ZIP Code',
                      hintText: 'Enter ZIP code',
                      prefixIcon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Update Profile Button
              LoadingButton(
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
                text: 'Update Profile',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
