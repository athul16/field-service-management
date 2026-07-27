import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/phone_country.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';

/// Worker login: country code + phone number + PIN, set up for them by the owner.
/// There is no self-registration — accounts are created and PINs are
/// issued from the owner dashboard.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _configService = ConfigService();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  List<PhoneCountry> _countries = [];
  PhoneCountry? _selectedCountry;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final (countries, defaultCountry) = await _configService.getPhoneConfig();
      setState(() {
        _countries = countries;
        _selectedCountry =
            countries.where((c) => c.iso2 == defaultCountry).firstOrNull ?? countries.firstOrNull;
      });
    } catch (_) {
      // Non-fatal — the country dropdown just stays empty; login itself will
      // still fail clearly if the phone can't be assembled.
    }
  }

  Future<void> _logIn() async {
    final country = _selectedCountry;
    final digits = _phoneController.text.trim();
    if (country == null) {
      setState(() => _error = 'Could not load country codes. Check your connection and try again.');
      return;
    }
    if (digits.length != country.nationalLength) {
      setState(() => _error = 'Enter a ${country.nationalLength}-digit phone number for ${country.name}.');
      return;
    }
    if (_pinController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your PIN.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signInWithPin(
        phone: '${country.dialCode}$digits',
        pin: _pinController.text.trim(),
      );
      // AuthGate listens for the token and will swap to HomeShell.
    } on ApiException catch (e) {
      setState(() => _error = e.statusCode == 401 ? 'Wrong phone number or PIN. Try again.' : e.message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Check your connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Enter your phone number and PIN', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<PhoneCountry>(
                      initialValue: _selectedCountry,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Code'),
                      items: _countries
                          .map((c) => DropdownMenuItem(value: c, child: Text('${c.dialCode} ${c.iso2}')))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCountry = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        hintText: _selectedCountry != null ? '0' * _selectedCountry!.nationalLength : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'PIN'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _logIn,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
