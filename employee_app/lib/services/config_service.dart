import '../core/api_client.dart';
import '../models/phone_country.dart';

/// Public app config (no auth needed) — currently just the phone country list the login
/// screen's country-code selector renders from, so the same set stays in sync with whatever
/// the backend supports without hardcoding it a second time here.
class ConfigService {
  final _client = ApiClient.instance;

  Future<(List<PhoneCountry>, String?)> getPhoneConfig() async {
    final response = await _client.get('/api/config') as Map<String, dynamic>;
    final countries = (response['phoneCountries'] as List)
        .map((c) => PhoneCountry.fromMap(c as Map<String, dynamic>))
        .toList();
    final defaultCountry = response['defaultCountry'] as String?;
    return (countries, defaultCountry);
  }
}
