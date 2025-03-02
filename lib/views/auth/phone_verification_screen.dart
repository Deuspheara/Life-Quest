import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/constants/app_strings.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/utils/error_handler.dart';
import 'package:life_quest/views/auth/profile_creation_screen.dart';
import 'package:phone_number/phone_number.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

final phoneVerificationStateProvider = StateProvider<PhoneVerificationState>((ref) {
  return PhoneVerificationState.enterPhone;
});

enum PhoneVerificationState {
  enterPhone,
  enterOtp,
}

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _formattedPhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Format phone number
      final PhoneNumberUtil plugin = PhoneNumberUtil();
      String rawNumber = _phoneController.text.trim();

      // Add a default region code if none provided
      if (!rawNumber.startsWith('+')) {
        rawNumber = '+1$rawNumber'; // Default to US
      }

      final bool isValid = await plugin.validate(rawNumber);

      if (!isValid) {
        setState(() {
          _errorMessage = 'Please enter a valid phone number';
          _isLoading = false;
        });
        return;
      }

      _formattedPhone = rawNumber;

      // Send OTP
      await _authService.signInWithPhone(_formattedPhone);

      // Move to OTP verification step
      ref.read(phoneVerificationStateProvider.notifier).state =
          PhoneVerificationState.enterOtp;
    } catch (e) {
      ErrorHandler.logError('Phone verification failed', e);
      setState(() {
        _errorMessage = 'Failed to send verification code. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.verifyOTP(
          _formattedPhone,
          _otpController.text.trim()
      );

      if (response.session != null) {
        // Navigate to profile creation
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileCreationScreen(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
        });
      }
    } catch (e) {
      ErrorHandler.logError('OTP verification failed', e);
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(phoneVerificationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          verificationState == PhoneVerificationState.enterPhone
              ? 'Phone Verification'
              : 'Enter Verification Code',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkText,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and description
              Text(
                verificationState == PhoneVerificationState.enterPhone
                    ? 'Enter your phone number'
                    : 'Verify your phone',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                verificationState == PhoneVerificationState.enterPhone
                    ? "We'll send you a verification code to confirm your identity."
                : 'Enter the 6-digit code we sent to $_formattedPhone',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.mediumText,
                ),
              ),
              const SizedBox(height: 32),

              // Error message if any
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Phone input or OTP input based on state
              if (verificationState == PhoneVerificationState.enterPhone)
                _buildPhoneInput()
              else
                _buildOtpInput(),

              const Spacer(),

              // Privacy policy note
              const Text(
                'By continuing, you agree to our Privacy Policy and Terms of Service.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mediumText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Primary action button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (verificationState == PhoneVerificationState.enterPhone
                    ? _verifyPhone
                    : _verifyOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
                    : Text(
                  verificationState == PhoneVerificationState.enterPhone
                      ? 'Send Code'
                      : 'Verify',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'Phone number',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpController,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 50,
            fieldWidth: 40,
            activeFillColor: Colors.white,
            inactiveFillColor: Colors.white,
            selectedFillColor: Colors.white,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.lightGrey,
            selectedColor: AppColors.primary,
          ),
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: Colors.transparent,
          enableActiveFill: true,
          keyboardType: TextInputType.number,
          onCompleted: (_) {
            // Auto-verify when all digits are entered
            if (!_isLoading) {
              _verifyOtp();
            }
          },
          onChanged: (value) {
            // Do nothing on change
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
            // Reset to phone input state
            ref.read(phoneVerificationStateProvider.notifier).state =
                PhoneVerificationState.enterPhone;
          },
          child: Text(
            'Change phone number',
            style: TextStyle(
              color: _isLoading ? AppColors.mediumText : AppColors.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
            setState(() {
              _isLoading = true;
            });
            try {
              await _authService.signInWithPhone(_formattedPhone);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code resent successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              setState(() {
                _errorMessage = 'Failed to resend code. Please try again.';
              });
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
          child: Text(
            'Resend code',
            style: TextStyle(
              color: _isLoading ? AppColors.mediumText : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}