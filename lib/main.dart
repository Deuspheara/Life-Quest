import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/app.dart';
import 'package:life_quest/initializers/achievement_initializer.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load();

    // Initialize Supabase
    await SupabaseService.initialize(
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // Initialize achievements
    final achievementInitializer = AchievementInitializer();
    await achievementInitializer.initializeAchievements();

    // Run the app
    runApp(const ProviderScope(child: LifeQuestApp()));
  } catch (e) {
    ErrorHandler.logError('Error initializing app', e);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}