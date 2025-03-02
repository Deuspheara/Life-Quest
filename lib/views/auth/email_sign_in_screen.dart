import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:life_quest/views/auth/profile_creation_screen.dart';
import 'package:life_quest/views/home/home_screen.dart';

final isSignUpModeProvider = StateProvider<bool>((ref) => false);

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Track successful sign-in
      AnalyticsService.trackEvent('auth_sign_in', properties: {'method': 'email'});

      if (response.user != null) {
        // Check if user has a profile
        final profile = await ref.read(currentUserProfileProvider.future);

        if (!mounted) return;

        if (profile != null) {
          // User has a profile, update auth state
          ref.read(authStateProvider.notifier).state = AuthState.authenticated;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
        } else {
          // User needs to create a profile
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileCreationScreen(),
            ),
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('Email sign-in failed', e);
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Track successful sign-up
      AnalyticsService.trackEvent('auth_sign_up', properties: {'method': 'email'});

      if (!mounted) return;

      if (response.user != null) {
        // Navigate to profile creation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileCreationScreen(),
          ),
        );
      }
    } catch (e) {
      ErrorHandler.logError('Email sign-up failed', e);
      setState(() {
        _errorMessage = 'Failed to create account. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = ref.watch(isSignUpModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSignUp ? 'Create Account' : 'Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  isSignUp
                      ? 'Create your account'
                      : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSignUp
                      ? 'Sign up to get started with Life Quest'
                      : 'Sign in to continue your quest journey',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.mediumText,
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),

                if (_errorMessage.isNotEmpty)
                  const SizedBox(height: 24),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: isSignUp ? 'Create a password' : 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (isSignUp && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sign in/up button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (isSignUp ? _signUpWithEmail : _signInWithEmail),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(isSignUp ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: 16),

                // Toggle sign in/up
                TextButton(
                  onPressed: () {
                    ref.read(isSignUpModeProvider.notifier).state = !isSignUp;
                  },
                  child: Text(
                    isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}