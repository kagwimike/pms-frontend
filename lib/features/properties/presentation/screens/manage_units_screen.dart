import 'package:flutter/material.dart';

class ManageUnitsScreen extends StatelessWidget {
  const ManageUnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Units')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          final isVacant = index % 3 == 0; // Fake logic
          return Card(
            color: isVacant ? Colors.green.shade100 : Colors.red.shade100,
            child: Center(
              child: Text(
                'Unit ${index + 1}\n${isVacant ? "VACANT" : "OCCUPIED"}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
