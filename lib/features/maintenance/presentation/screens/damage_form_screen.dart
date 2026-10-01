import 'package:flutter/material.dart';

class DamageFormScreen extends StatelessWidget {
  const DamageFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Damages')),
      body: const Center(child: Text('Damage reporting form.')),
    );
  }
}
