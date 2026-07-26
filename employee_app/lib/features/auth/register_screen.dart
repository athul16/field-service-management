import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'login_screen.dart';

/// Two-step self-registration: (1) name + phone + optional email, then
/// (2) the SMS code the worker receives. Kept intentionally simple —
/// most workers using this app are not technical.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.sendOtp(_phoneController.text.trim());
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _error = 'Could not send code. Check the phone number and try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _error = 'Enter the code we texted you.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.verifyOtpAndCreateProfile(
        phone: _phoneController.text.trim(),
        otpCode: _otpController.text.trim(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );
      // AuthGate listens for the sign-in event and will swap to HomeShell.
    } catch (e) {
      setState(() => _error = 'That code didn\'t work. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_codeSent) ..._buildDetailsStep(),
                if (_codeSent) ..._buildCodeStep(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_codeSent ? _verifyAndRegister : _sendCode),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_codeSent ? 'Verify & finish' : 'Send code'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailsStep() {
    return [
      const Text(
        'Enter your name and phone number to get started.',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Full name'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Phone number',
          hintText: '+1 555 123 4567',
        ),
        validator: (v) => (v == null || v.trim().length < 7) ? 'Enter a valid phone number' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email (optional)'),
      ),
    ];
  }

  List<Widget> _buildCodeStep() {
    return [
      Text(
        'We texted a code to ${_phoneController.text.trim()}.',
        style: const TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '6-digit code'),
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
