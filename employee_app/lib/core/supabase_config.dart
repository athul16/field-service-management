import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase initialization so the rest of the app never has to
/// touch environment variables directly.
class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Copy .env.example to .env and fill in your project values.',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Shorthand accessor used throughout the services layer.
  static SupabaseClient get client => Supabase.instance.client;
}
