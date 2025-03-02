import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Database references
  static final profiles = client.from('profiles');
  static final quests = client.from('quests');
  static final achievements = client.from('achievements');
  static final userAchievements = client.from('user_achievements');

  // Storage references
  static final avatarBucket = client.storage.from('avatars');
}

// Create a provider to access the Supabase client
final supabaseClientProvider = riverpod.Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});