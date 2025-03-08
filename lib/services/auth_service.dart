import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/services/supabase_service.dart';
import 'package:life_quest/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:life_quest/utils/error_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:io';

enum AuthState { initial, authenticated, unauthenticated }

final authStateProvider = StateProvider<AuthState>((ref) {
  return SupabaseService.client.auth.currentSession != null
      ? AuthState.authenticated
      : AuthState.unauthenticated;
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return null;

  try {
    final data = await SupabaseService.profiles
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(data);
  } catch (e) {
    ErrorHandler.logError('Failed to fetch user profile', e);
    return null;
  }
});

class AuthService {
  final supabase.SupabaseClient _client = SupabaseService.client;

  // Sign in with phone number (step 1)
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );
    } catch (e) {
      ErrorHandler.logError('Phone sign-in failed', e);
      rethrow;
    }
  }

  // Verify OTP code (step 2)
  Future<supabase.AuthResponse> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: supabase.OtpType.sms,
      );

      return response;
    } catch (e) {
      ErrorHandler.logError('OTP verification failed', e);
      rethrow;
    }
  }

  // Sign in with email and password
  Future<supabase.AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      ErrorHandler.logError('Email sign-in failed', e);
      rethrow;
    }
  }

  // Sign up with email and password
  Future<supabase.AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      ErrorHandler.logError('Email sign-up failed', e);
      rethrow;
    }
  }


  // Modified signInWithGoogle method
  Future<void> signInWithGoogle() async {
    try {

      const webClientId = '273563265618-inqp40n9d1mbosvvmvelqko4pkipkuob.apps.googleusercontent.com';
      const iosClientId = '273563265618-bcn7bmbgf1fi6on7sddic0p2rtsl62eq.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      // Clear any previous sign-in state
      await googleSignIn.signOut();

      // Add debug logging
      print("Starting Google Sign-In process");

      // Use signIn with a timeout to prevent indefinite freezing
      final googleUser = await googleSignIn.signIn()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        print("Google Sign-In timed out");
        throw Exception('Google sign-in timed out');
      });

      print("Google Sign-In completed: ${googleUser?.email}");

      if (googleUser == null) {
        print("Sign-in was cancelled by user");
        throw Exception('Google sign-in cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      print("Got authentication tokens");

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found');
      }
      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      // Sign in with Supabase
      print("Signing in with Supabase using Google tokens");
      await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      print("Supabase sign-in completed");
    } catch (e) {
      print("Detailed Google sign-in error: $e");
      ErrorHandler.logError('Google sign-in failed', e);
      rethrow;
    }
  }

  // Sign in with Apple (native iOS/macOS)
  Future<void> signInWithApple() async {
    try {
      // Generate a random nonce
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const supabase.AuthException('Could not find ID Token from Apple credential');
      }

      await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (e) {
      ErrorHandler.logError('Apple sign-in failed', e);
      rethrow;
    }
  }

  // Helper to generate a random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // OAuth sign-in for web/Android platforms
  Future<void> signInWithOAuthProvider(supabase.OAuthProvider provider) async {
    try {
      await _client.auth.signInWithOAuth(
        provider,
        redirectTo: 'fr.deuspheara.lifequest://login-callback/',
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
      );
    } catch (e) {
      ErrorHandler.logError('OAuth sign-in failed', e);
      rethrow;
    }
  }

  // Create or update user profile
  Future<void> createUserProfile(String username, String displayName) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      await SupabaseService.profiles.upsert({
        'id': user.id,
        'username': username,
        'display_name': displayName,
        'level': 1,
        'experience': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Profile creation failed', e);
      rethrow;
    }
  }

  // Update user profile information
  Future<void> updateUserProfile({String? displayName}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (displayName != null) {
        updates['display_name'] = displayName;
      }
      
      await SupabaseService.profiles
        .update(updates)
        .eq('id', user.id);
    } catch (e) {
      ErrorHandler.logError('Profile update failed', e);
      rethrow;
    }
  }

  // Update user avatar with improved organization and cleanup
 // Update user avatar with improved organization and cleanup
  Future<void> updateUserAvatar(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      // User-specific avatar folder path
      final avatarFolderPath = '${user.id}';
      
      // Get current user profile to check if they have an existing avatar
      final userData = await SupabaseService.profiles
          .select('avatar_url')
          .eq('id', user.id)
          .single();
      
      final currentAvatarUrl = userData['avatar_url'] as String?;
      
      // Delete old avatar if it exists
      if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
        try {
          // Extract filename from the URL - assumes URL format with filename at the end
          final oldAvatarPath = currentAvatarUrl.split('/').last;
          if (oldAvatarPath.isNotEmpty) {
            await SupabaseService.avatarBucket.remove([
              '$avatarFolderPath/$oldAvatarPath'
            ]);
          }
        } catch (e) {
          // Log but continue - failure to delete old avatar shouldn't prevent upload of new one
          ErrorHandler.logError('Failed to delete old avatar', e);
        }
      }
      
      // Create a new filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = 'jpg'; // Assuming we're standardizing on jpg format
      final fileName = 'avatar_$timestamp.$fileExtension';
      final fullPath = '$avatarFolderPath/$fileName';
      
      // Upload new avatar to the user's folder
      await SupabaseService.avatarBucket.upload(
        fullPath,
        imageFile,
        fileOptions: const supabase.FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      // Get the public URL for the uploaded avatar
      final avatarUrl = await SupabaseService.avatarBucket.createSignedUrl(
        fullPath,
        60 * 60 * 24 * 365 * 10, // 10 years expiry
      );
      
      // Update user profile with new avatar URL
      await SupabaseService.profiles
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
        
    } catch (e) {
      ErrorHandler.logError('Avatar update failed', e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      ErrorHandler.logError('Sign out failed', e);
      rethrow;
    }
  }

  // Delete account and all user data
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      // Delete user data from various tables
      await SupabaseService.userAchievements.delete().eq('user_id', user.id);
      await SupabaseService.quests.delete().eq('user_id', user.id);
      await SupabaseService.profiles.delete().eq('id', user.id);

      // Delete user account
      await _client.auth.admin.deleteUser(user.id);
      await _client.auth.signOut();
    } catch (e) {
      ErrorHandler.logError('Account deletion failed', e);
      rethrow;
    }
  }
}