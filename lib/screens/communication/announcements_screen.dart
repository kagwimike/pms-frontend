import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/auth_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final token = _authService.accessToken;
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/communication/announcements'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _announcements = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String targetAudience = 'ALL';
    bool sendSms = false;
    bool sendEmail = true;
    bool isSubmitting = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while submitting
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitBroadcast() async {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                setDialogState(() => error = 'Please fill out both the title and content to broadcast.');
                return;
              }

              setDialogState(() { isSubmitting = true; error = null; });
              try {
                final token = _authService.accessToken;
                final response = await http.post(
                  Uri.parse('${AppConfig.apiBaseUrl}/communication/announcements'),
                  headers: {
                    'Content-Type': 'application/json',
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                  body: json.encode({
                    'title': titleController.text,
                    'content': contentController.text,
                    'target_audience': targetAudience,
                    'send_via_email': sendEmail,
                    'send_via_sms': sendSms,
                    'send_now': true,
                  }),
                );

                if (response.statusCode == 201) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Broadcast sent successfully! Users will receive it shortly.'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  _fetchAnnouncements();
                } else {
                  setDialogState(() {
                    error = 'Failed to send broadcast. Server responded with an error.';
                    isSubmitting = false;
                  });
                }
              } catch (e) {
                setDialogState(() {
                  error = 'Network error: Please check your connection and try again.';
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Create Announcement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.red.shade50,
                        child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                      maxLines: 4,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: targetAudience,
                      decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('Everyone')),
                        DropdownMenuItem(value: 'TENANTS', child: Text('All Tenants')),
                        DropdownMenuItem(value: 'OWNERS', child: Text('All Owners')),
                        DropdownMenuItem(value: 'VENDORS', child: Text('All Vendors')),
                      ],
                      onChanged: isSubmitting ? null : (val) {
                        setDialogState(() => targetAudience = val!);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Send via Email'),
                      value: sendEmail,
                      onChanged: isSubmitting ? null : (val) => setDialogState(() => sendEmail = val!),
                    ),
                    CheckboxListTile(
                      title: const Text('Send via SMS'),
                      value: sendSms,
                      onChanged: isSubmitting ? null : (val) => setDialogState(() => sendSms = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitBroadcast,
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                  child: isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Broadcast Now'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements & Broadcasts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements found.'))
              : ListView.builder(
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(label: Text(item['status'] ?? 'UNKNOWN', style: const TextStyle(fontSize: 10))),
                                const SizedBox(width: 8),
                                Text('Audience: ${item['target_audience']}', style: const TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.campaign),
        label: const Text('New Broadcast'),
      ),
    );
  }
}
