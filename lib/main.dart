import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:life_quest/app.dart';
import 'package:life_quest/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize PostHog for analytics
  final config = PostHogConfig(dotenv.env['POSTHOOK_API_KEY']!);
  config.debug = true;
  config.captureApplicationLifecycleEvents = true;
  config.host = 'https://eu.i.posthog.com'; // or 'https://us.i.posthog.com'
  await Posthog().setup(config);

  runApp(
    const ProviderScope(
      child: LifeQuestApp(),
    ),
  );
}