import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());
  
  // Example controllers
  final _workspaceController = TextEditingController();
  final _ownerDetailsController = TextEditingController();

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 4) {
        setState(() => _currentStep++);
      } else {
        _submitRegistration();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitRegistration() async {
    // API Call to register
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Complete')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _previousStep,
        steps: [
          Step(
            title: const Text('Workspace'),
            content: Form(
              key: _formKeys[0],
              child: TextFormField(
                controller: _workspaceController,
                decoration: const InputDecoration(labelText: 'Workspace Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Owner Details'),
            content: Form(
              key: _formKeys[1],
              child: TextFormField(
                controller: _ownerDetailsController,
                decoration: const InputDecoration(labelText: 'Owner Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Location'),
            content: Form(
              key: _formKeys[2],
              child: const Text('Location details form here...'),
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Account Details'),
            content: Form(
              key: _formKeys[3],
              child: const Text('Email & password form here...'),
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Review'),
            content: Form(
              key: _formKeys[4],
              child: const Text('Review all details and submit.'),
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }
}
