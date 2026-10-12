import 'package:flutter/material.dart';
import '../../models/communication/chat_session.dart';
import 'chat_view.dart';

class ChatDetailScreen extends StatelessWidget {
  final ChatSession session;

  const ChatDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatView(
        session: session,
        isMobile: true,
        onBack: () => Navigator.of(context).pop(),
      ),
    );
  }
}
