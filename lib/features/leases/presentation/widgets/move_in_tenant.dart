import 'package:flutter/material.dart';

class MoveInTenant extends StatefulWidget {
  final int unitId;
  const MoveInTenant({super.key, required this.unitId});

  @override
  State<MoveInTenant> createState() => _MoveInTenantState();
}

class _MoveInTenantState extends State<MoveInTenant> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Simulate linking tenant to unit
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant moved in successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Move In Tenant to Unit ${widget.unitId}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenantNameController,
                decoration: const InputDecoration(labelText: 'Tenant Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Move In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
