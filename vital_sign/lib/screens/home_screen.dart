import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vital_signs_provider.dart';
import '../models/vital_sign.dart';
import 'vital_sign_input_screen.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import '../widgets/vital_sign_card.dart';
import '../widgets/quick_stats_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<VitalSignsProvider>(context, listen: false);
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vital Signs Monitor'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<VitalSignsProvider>(context, listen: false).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/alerts');
            },
          ),
        ],
      ),
      body: Consumer<VitalSignsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  const QuickStatsWidget(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Vital Signs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Vital Signs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/dashboard');
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Vital Signs Grid
                  _buildVitalSignsGrid(provider),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Alerts
                  if (provider.alerts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Alerts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/alerts');
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildRecentAlerts(provider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VitalSignInputScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Vital Sign'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildVitalSignsGrid(VitalSignsProvider provider) {
    final recentVitals = provider.getRecentVitalSigns(limit: 6);
    
    if (recentVitals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No vital signs recorded yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first vital sign',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: recentVitals.length,
      itemBuilder: (context, index) {
        final vitalSign = recentVitals[index];
        return VitalSignCard(
          vitalSign: vitalSign,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VitalSignInputScreen(
                  existingVitalSign: vitalSign,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    color: Colors.red,
                    onTap: () => _navigateToInput(VitalSignType.heartRate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.monitor_heart,
                    label: 'Blood Pressure',
                    color: Colors.blue,
                    onTap: () => _navigateToInput(VitalSignType.bloodPressure),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    color: Colors.orange,
                    onTap: () => _navigateToInput(VitalSignType.temperature),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.air,
                    label: 'SpO₂',
                    color: Colors.green,
                    onTap: () => _navigateToInput(VitalSignType.spO2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts(VitalSignsProvider provider) {
    final recentAlerts = provider.alerts.take(3).toList();
    
    return Column(
      children: recentAlerts.map((alert) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _getAlertColor(alert.severity).withOpacity(0.1),
          child: ListTile(
            leading: Icon(
              _getAlertIcon(alert.severity),
              color: _getAlertColor(alert.severity),
            ),
            title: Text(
              alert.message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${alert.type.displayName} • ${_formatDateTime(alert.timestamp)}',
            ),
            trailing: alert.isRead 
                ? null 
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getAlertColor(alert.severity),
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () {
              Navigator.pushNamed(context, '/alerts');
            },
          ),
        );
      }).toList(),
    );
  }

  void _navigateToInput(VitalSignType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VitalSignInputScreen(initialType: type),
      ),
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.blue;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.purple;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info;
      case AlertSeverity.medium:
        return Icons.warning;
      case AlertSeverity.high:
        return Icons.error;
      case AlertSeverity.critical:
        return Icons.dangerous;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
