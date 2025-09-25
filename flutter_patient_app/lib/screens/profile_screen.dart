import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    print('🔄 Loading profile data...');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientId = authProvider.patientId;

      print('🆔 Patient ID: $patientId');

      if (patientId == null) {
        print('❌ Patient ID not found');
        _showErrorSnackBar('Patient ID not found');
        return;
      }

      print('📡 Calling API service...');
      final response = await _apiService.getProfile(patientId: patientId);

      print('📥 API Response: $response');

      if (response.containsKey('error')) {
        print('❌ API Error: ${response['error']}');
        _showErrorSnackBar(response['error']);
      } else {
        print('✅ Profile data loaded successfully');
        setState(() {
          _profileData = response['profile'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Exception loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load profile: $e');
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

  Future<void> _navigateToEditProfile() async {
    print('🔍 Navigating to Edit Profile Screen...');
    print('📊 Profile Data: $_profileData');

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(currentProfile: _profileData),
        ),
      );

      print('✅ Navigation result: $result');

      if (result == true) {
        // Profile was updated, reload the data
        print('🔄 Reloading profile data...');
        _loadProfileData();
      }
    } catch (e) {
      print('❌ Navigation error: $e');
      _showErrorSnackBar('Failed to open edit profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings functionality can be added here
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date of Birth
                      if (_profileData!['date_of_birth'] != null)
                        _buildInfoCard(
                            'Date of Birth', _profileData!['date_of_birth']),

                      const SizedBox(height: 16),

                      // Health Information Card
                      _buildHealthInfoCard(),

                      const SizedBox(height: 16),

                      // Account Information Card
                      _buildAccountInfoCard(),

                      const SizedBox(height: 16),

                      // Emergency Contact Card
                      _buildEmergencyContactCard(),

                      const SizedBox(height: 32),

                      // Edit Profile Button
                      ElevatedButton(
                        onPressed: () {
                          print('🔘 Edit Profile button pressed!');
                          _navigateToEditProfile();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildHealthInfoCard() {
    return _buildCard(
      'Health Information',
      [
        _buildInfoRow('Blood Type', _profileData!['blood_type'] ?? 'Not set'),
        _buildInfoRow('Height', '${_profileData!['height'] ?? 'Not set'} cm'),
        _buildInfoRow('Weight', '${_profileData!['weight'] ?? 'Not set'} kg'),
        _buildInfoRow(
            'Pregnancy Status', _profileData!['pregnancy_status'] ?? 'Not set'),
      ],
      Icons.favorite,
      Colors.red,
    );
  }

  Widget _buildAccountInfoCard() {
    return _buildCard(
      'Account Information',
      [
        _buildInfoRow('Patient ID', _profileData!['patient_id'] ?? 'Not set'),
        _buildInfoRow('Status', _profileData!['status'] ?? 'Not set'),
        _buildInfoRow('Email Verified',
            _profileData!['email_verified'] == true ? 'Yes' : 'No'),
        _buildInfoRow('Profile Completed',
            _formatDate(_profileData!['profile_completed_at'])),
        _buildInfoRow(
            'Last Updated', _formatDate(_profileData!['last_updated'])),
      ],
      Icons.person,
      AppColors.primary,
    );
  }

  Widget _buildEmergencyContactCard() {
    return _buildCard(
      'Emergency Contact',
      [
        _buildInfoRow(
            'Name', _profileData!['emergency_contact_name'] ?? 'Not set'),
        _buildInfoRow(
            'Phone', _profileData!['emergency_contact_phone'] ?? 'Not set'),
        _buildInfoRow('Relationship',
            _profileData!['emergency_contact_relationship'] ?? 'Not set'),
      ],
      Icons.emergency,
      Colors.red,
    );
  }

  Widget _buildCard(
      String title, List<Widget> children, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not set';
    try {
      if (date is String) {
        return date;
      }
      return date.toString();
    } catch (e) {
      return 'Not set';
    }
  }
}
