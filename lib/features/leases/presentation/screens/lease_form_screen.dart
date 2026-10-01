import 'package:flutter/material.dart';

class LeaseFormScreen extends StatelessWidget {
  const LeaseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Lease')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Lease form implementation: Cascading dropdowns (Property -> Vacant Units).'),
      ),
    );
  }
}
