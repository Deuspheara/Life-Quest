import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  
  // Supabase table references
  static SupabaseQueryBuilder get profiles => client.from('profiles');
  static SupabaseQueryBuilder get quests => client.from('quests');
  static SupabaseQueryBuilder get achievements => client.from('achievements');
  static SupabaseQueryBuilder get userAchievements => client.from('user_achievements');


  // Storage references
  static final avatarBucket = client.storage.from('avatars');

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }
}

// Create a provider to access the Supabase client
final supabaseClientProvider = riverpod.Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});