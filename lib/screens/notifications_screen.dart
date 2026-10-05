import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isOwner;

  const NotificationsScreen({Key? key, required this.isOwner}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _apiService.getNotifications(limit: 50);
      setState(() {
        _notifications = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _apiService.markNotificationAsRead(id);
      _fetchNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_REFUNDED':
        return Icons.check_circle_outline;
      case 'PAYMENT_FAILED':
      case 'PAYMENT_REVERSED':
      case 'PAYMENT_UNMATCHED':
        return Icons.error_outline;
      case 'INVOICE_CREATED':
      case 'INVOICE_DUE_SOON':
      case 'INVOICE_OVERDUE':
        return Icons.receipt_long;
      case 'LEASE_CREATED':
      case 'LEASE_RENEWED':
        return Icons.description_outlined;
      case 'LEASE_EXPIRING':
      case 'LEASE_EXPIRED':
      case 'LEASE_RENEWAL_REMINDER':
        return Icons.warning_amber_rounded;
      case 'MAINTENANCE_CREATED':
      case 'MAINTENANCE_ASSIGNED':
      case 'MAINTENANCE_UPDATED':
      case 'MAINTENANCE_COMPLETED':
        return Icons.build_circle_outlined;
      case 'MAINTENANCE_SLA_WARNING':
      case 'MAINTENANCE_SLA_BREACHED':
        return Icons.timer_off_outlined;
      case 'INSPECTION_SCHEDULED':
      case 'INSPECTION_COMPLETED':
        return Icons.fact_check_outlined;
      case 'DAMAGE_REPORTED':
        return Icons.broken_image_outlined;
      case 'DOCUMENT_EXPIRING':
        return Icons.file_present_outlined;
      case 'UNIT_VACANT':
      case 'UNIT_OCCUPIED':
        return Icons.meeting_room_outlined;
      case 'TENANT_CREATED':
        return Icons.person_add_alt_1;
      case 'ANNOUNCEMENT_CREATED':
        return Icons.campaign;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_REFUNDED':
      case 'MAINTENANCE_COMPLETED':
      case 'LEASE_RENEWED':
      case 'INSPECTION_COMPLETED':
      case 'UNIT_OCCUPIED':
        return AppTheme.teal;
      case 'PAYMENT_FAILED':
      case 'PAYMENT_REVERSED':
      case 'PAYMENT_UNMATCHED':
      case 'INVOICE_OVERDUE':
      case 'LEASE_EXPIRED':
      case 'MAINTENANCE_SLA_BREACHED':
      case 'DAMAGE_REPORTED':
        return Colors.red;
      case 'INVOICE_DUE_SOON':
      case 'LEASE_EXPIRING':
      case 'LEASE_RENEWAL_REMINDER':
      case 'MAINTENANCE_SLA_WARNING':
      case 'DOCUMENT_EXPIRING':
      case 'UNIT_VACANT':
        return Colors.orange;
      case 'MAINTENANCE_CREATED':
      case 'MAINTENANCE_ASSIGNED':
      case 'MAINTENANCE_UPDATED':
      case 'INSPECTION_SCHEDULED':
        return Colors.blue;
      default:
        return AppTheme.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNotifications,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No notifications yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final isRead = notif['read'] == true;
          final dateStr = notif['created_at'];
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          final dateFormatted = date != null ? DateFormat('MMM d, yyyy • h:mm a').format(date) : '';
          
          final type = notif['type'];

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isRead ? Colors.grey.shade200 : _getColorForType(type).withOpacity(0.5),
                width: 1,
              ),
            ),
            color: isRead ? Colors.white : _getColorForType(type).withOpacity(0.05),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isRead ? Colors.grey.shade100 : _getColorForType(type).withOpacity(0.1),
                child: Icon(
                  _getIconForType(type),
                  color: isRead ? Colors.grey : _getColorForType(type),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notif['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? Colors.black87 : Colors.black,
                      ),
                    ),
                  ),
                  if (dateFormatted.isNotEmpty)
                    Text(
                      dateFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: isRead ? Colors.grey : Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  notif['message'] ?? '',
                  style: TextStyle(
                    color: isRead ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
              ),
              trailing: isRead
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                      tooltip: 'Mark as read',
                      onPressed: () => _markAsRead(notif['id'].toString()),
                    ),
            ),
          );
        },
      ),
    );
  }
}
