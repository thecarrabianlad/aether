import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._(); // Private constructor

  static final SupabaseService instance = SupabaseService._();
  final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://tqyapdjqrgktxlexiqpx.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxeWFwZGpxcmdrdHhsZXhpcXB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDMwMDksImV4cCI6MjEwMDIxOTAwOX0.Z_9nb1ibz3EvQNHZhYpXGxQzHIqcaI-wujdBproM3Dw',
    );
  }
}
