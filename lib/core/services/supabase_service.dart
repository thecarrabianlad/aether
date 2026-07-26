import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._(); // Private constructor

  static final SupabaseService instance = SupabaseService._();
  final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final publishableKey = dotenv.env['SUPABASE_ANON_KEY']; // Renamed from anonKey

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL is missing from .env');
    }
    if (publishableKey == null || publishableKey.isEmpty) { // Using publishableKey
      throw Exception('SUPABASE_ANON_KEY is missing from .env');
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey); // Using publishableKey
  }
}

