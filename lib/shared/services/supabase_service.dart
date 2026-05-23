import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase client access for the entire app.
/// Call [initialize] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  /// Initialize the Supabase client.
  /// [url] and [anonKey] should come from your environment config or
  /// be passed in directly during main() initialization.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Global Supabase client instance. Use this for all queries.
  static SupabaseClient get client => Supabase.instance.client;
}
