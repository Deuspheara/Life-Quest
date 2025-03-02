import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_theme.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/views/auth/onboarding_screen.dart';
import 'package:life_quest/views/home/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class LifeQuestApp extends ConsumerStatefulWidget {
  const LifeQuestApp({Key? key}) : super(key: key);

  @override
  ConsumerState<LifeQuestApp> createState() => _LifeQuestAppState();
}

class _LifeQuestAppState extends ConsumerState<LifeQuestApp> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;
      if (event == supabase.AuthChangeEvent.signedIn) {
        ref.read(authStateProvider.notifier).state = AuthState.authenticated;
      } else if (event == supabase.AuthChangeEvent.signedOut ||
          event == supabase.AuthChangeEvent.userDeleted) {
        ref.read(authStateProvider.notifier).state = AuthState.unauthenticated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Life Quest',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: authState == AuthState.authenticated
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}