import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/user_profile.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userProfileAsync = ref.read(currentUserProfileProvider);
    
    userProfileAsync.whenData((profile) {
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _displayNameController.text = profile.displayName;
          _usernameController.text = profile.username;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update display name if changed
      if (_displayNameController.text != _userProfile?.displayName) {
        await _authService.updateUserProfile(
          displayName: _displayNameController.text,
        );
      }
      
      // Update avatar if selected
      if (_selectedImage != null) {
        await _authService.updateUserAvatar(_selectedImage!);
      }
      
      // Track event
      await AnalyticsService.trackEvent('profile_updated');
      
      // Refresh user profile data
      ref.invalidate(currentUserProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('User profile not found'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                
                // Avatar section
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Avatar display with proper fallback chain
                      _selectedImage != null 
                        ? CircleAvatar(
                            radius: 60,
                            backgroundImage: FileImage(_selectedImage!),
                          )
                        : profile.avatarUrl != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: NetworkImage(profile.avatarUrl!),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      
                      // Edit icon
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // User information form
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasChanges = value != profile.displayName;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Username (non-editable but properly displayed)
                TextField(
                  controller: _usernameController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_circle_outlined),
                    helperText: 'Username cannot be changed',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enhanced Stats information
                _buildStatsCard(profile),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Stats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber.shade300,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${profile.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Level progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Experience',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${profile.experience} / ${profile.experienceForNextLevel} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Experience progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: profile.levelProgress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
          
          const Divider(height: 1),
          
          // Detailed stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildEnhancedStatRow(
                  'Quests Completed', 
                  'Coming soon',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildEnhancedStatRow(
                  'Achievements Earned', 
                  'Coming soon',
                  Icons.emoji_events_outlined,
                  Colors.amber,
                ),
                _buildEnhancedStatRow(
                  'Account Created', 
                  DateFormat.yMMMMd().format(profile.createdAt),
                  Icons.calendar_today_outlined,
                  AppColors.info,
                ),
              ],
            )
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedStatRow(String label, String value, IconData icon, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
