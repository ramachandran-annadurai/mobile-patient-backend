import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vital_signs_provider.dart';
import '../models/vital_sign.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Alerts', icon: Icon(Icons.notifications)),
            Tab(text: 'Unread', icon: Icon(Icons.notifications_active)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Alerts')),
              const PopupMenuItem(value: 'critical', child: Text('Critical Only')),
              const PopupMenuItem(value: 'high', child: Text('High & Critical')),
              const PopupMenuItem(value: 'medium', child: Text('Medium & Above')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<VitalSignsProvider>(context, listen: false).refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsList(false),
          _buildAlertsList(true),
        ],
      ),
    );
  }

  Widget _buildAlertsList(bool unreadOnly) {
    return Consumer<VitalSignsProvider>(
      builder: (context, provider, child) {
        List<VitalSignAlert> alerts = provider.alerts;

        // Apply filters
        if (unreadOnly) {
          alerts = alerts.where((alert) => !alert.isRead).toList();
        }

        if (_selectedFilter != 'all') {
          alerts = alerts.where((alert) {
            switch (_selectedFilter) {
              case 'critical':
                return alert.severity == AlertSeverity.critical;
              case 'high':
                return alert.severity == AlertSeverity.high || 
                       alert.severity == AlertSeverity.critical;
              case 'medium':
                return alert.severity == AlertSeverity.medium ||
                       alert.severity == AlertSeverity.high ||
                       alert.severity == AlertSeverity.critical;
              default:
                return true;
            }
          }).toList();
        }

        if (alerts.isEmpty) {
          return _buildEmptyState(unreadOnly);
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildAlertCard(alert, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool unreadOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unreadOnly ? Icons.notifications_off : Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            unreadOnly ? 'No unread alerts' : 'No alerts yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unreadOnly 
                ? 'All alerts have been read'
                : 'Alerts will appear here when vital signs are abnormal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(VitalSignAlert alert, VitalSignsProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _showAlertDetails(alert, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(alert.severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSeverityIcon(alert.severity),
                      color: _getSeverityColor(alert.severity),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDateTime(alert.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!alert.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getSeverityColor(alert.severity),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: TextStyle(
                  fontSize: 14,
                  color: alert.isRead ? Colors.grey.shade700 : Colors.black87,
                ),
              ),
              if (alert.actionRequired != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.actionRequired!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(alert.severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.severity.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getSeverityColor(alert.severity),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (!alert.isRead)
                        TextButton(
                          onPressed: () => _markAsRead(alert, provider),
                          child: const Text('Mark as Read'),
                        ),
                      IconButton(
                        onPressed: () => _deleteAlert(alert, provider),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(VitalSignAlert alert, VitalSignsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getSeverityIcon(alert.severity),
              color: _getSeverityColor(alert.severity),
            ),
            const SizedBox(width: 8),
            Text(alert.type.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Severity: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.severity.displayName,
                    style: TextStyle(
                      color: _getSeverityColor(alert.severity),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Time: ${_formatDateTime(alert.timestamp)}'),
            if (alert.actionRequired != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action Required:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.actionRequired!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!alert.isRead)
            TextButton(
              onPressed: () {
                _markAsRead(alert, provider);
                Navigator.of(context).pop();
              },
              child: const Text('Mark as Read'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markAsRead(VitalSignAlert alert, VitalSignsProvider provider) {
    provider.markAlertAsRead(alert.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert marked as read')),
    );
  }

  void _deleteAlert(VitalSignAlert alert, VitalSignsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAlert(alert.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alert deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
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

  IconData _getSeverityIcon(AlertSeverity severity) {
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
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
