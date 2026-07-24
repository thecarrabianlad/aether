import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._(); // Private constructor

  static final SupabaseService instance = SupabaseService._();
  final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL is missing from .env');
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is missing from .env');
    }

    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
