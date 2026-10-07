import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunicationInboxScreen extends StatefulWidget {
  const CommunicationInboxScreen({super.key});

  @override
  State<CommunicationInboxScreen> createState() => _CommunicationInboxScreenState();
}

class _CommunicationInboxScreenState extends State<CommunicationInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        elevation: 0,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoadingSessions) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null) {
            return Center(
              child: Text(
                chatProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (chatProvider.sessions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: chatProvider.sessions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final session = chatProvider.sessions[index];
              final tenantName = session.tenant?['first_name'] ?? 'Unknown Tenant';
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    tenantName[0].toUpperCase(),
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.subject ?? 'General Support',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeago.format(session.updatedAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tenant: $tenantName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(session: session),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Normally opens a modal to select a tenant and start a new chat
          // For now, let's just trigger a test session creation
          _showNewChatDialog(context);
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No active conversations',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final subjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start New Conversation'),
          content: TextField(
            controller: subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Dummy tenantId for testing. In reality, select from a dropdown.
                context.read<ChatProvider>().createSession(1, subject: subjectController.text);
                Navigator.pop(context);
              },
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }
}
