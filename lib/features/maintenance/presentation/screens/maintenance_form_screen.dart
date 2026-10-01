import 'package:flutter/material.dart';
import '../../../../core/auth/auth_storage.dart';


class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  bool _isTenant = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await AuthStorage.getRole();
    if (mounted) {
      setState(() {
        _isTenant = role == 'tenant';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    if (!_isTenant) {
      return Scaffold(
        appBar: AppBar(title: const Text('Maintenance Request')),
        body: const Center(child: Text('Only tenants can create maintenance requests.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Maintenance Request')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Form to submit maintenance issues.'),
      ),
    );
  }
}
