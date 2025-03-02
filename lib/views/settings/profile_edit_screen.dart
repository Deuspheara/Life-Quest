import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/models/user_profile.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/services/analytics_service.dart';

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
                
                // Stats information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Level', '${profile.level}'),
                        const Divider(),
                        _buildStatRow('Experience', '${profile.experience} / ${profile.experienceForNextLevel} XP'),
                        const Divider(),
                        _buildStatRow('Quests Completed', 'Coming soon'),
                        const Divider(),
                        _buildStatRow('Account Created', 'Coming soon'),
                      ],
                    ),
                  ),
                ),
                
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
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
