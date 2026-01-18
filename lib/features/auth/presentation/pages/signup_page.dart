import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool acceptedTerms = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showErrorSnackbar('Passwords do not match');
      return;
    }

    ref.showLoading('Creating your account...');

    final success = await ref.read(authProvider.notifier).signup(
          email: emailController.text.trim(),
          phoneNumber: phoneNumberController.text.trim(),
          password: passwordController.text,
          firstName: nameController.text.trim(),
          lastName: lastNameController.text.trim(),
        );

    ref.hideLoading();

    if (success && mounted) {
      showSuccessSnackbar('Account created! Please verify your email.');
      context.push(AppRoutes.verifyAccount);
    } else {
      final error = ref.read(authProvider).error;
      showErrorSnackbar(error ?? 'Failed to create account');
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed back button at top
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: AppBackButton(),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Let's get you started",
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Register to Be part of a community building wealth',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF606060),
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildTextField(
                        controller: nameController,
                        hintText: 'E.g John',
                        labelText: 'First Name',
                        validator: _validateName,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: lastNameController,
                        hintText: 'E.g Doe',
                        labelText: 'Last Name',
                        validator: _validateName,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Email',
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: phoneNumberController,
                        hintText: 'Phone Number',
                        labelText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: passwordController,
                        labelText: 'Password',
                        hintText: 'Password',
                        obscurePassword: _obscurePassword,
                        onToggle: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: _validatePassword,
                      ),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Confirm Password',
                        obscurePassword: _obscureConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 20),
                      _buildTermsAndConditions(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.login);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account?',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4A4A4A),
                            ),
                            children: [
                              TextSpan(
                                text: ' Sign in',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        errorMaxLines: 3,
        label: Text(
          labelText,
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required bool obscurePassword,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscurePassword,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          errorMaxLines: 3,
          label: Text(
            labelText,
            style: TextStyle(fontFamily: AppTextStyles.fontFamily),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.iconSecondary,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              TextSpan(text: 'I have read, understood and agreed to the '),
              TextSpan(
                text: 'terms and conditions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // TODO: Open terms and conditions
                  },
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'privacy policy.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // TODO: Open privacy policy
                  },
              ),
            ],
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        value: acceptedTerms,
        onChanged: (value) {
          setState(() {
            acceptedTerms = value!;
          });
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: acceptedTerms ? AppColors.primary : AppColors.surfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(43),
          ),
        ),
        onPressed: acceptedTerms ? _handleSignup : null,
        child: Text(
          'Create Account',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: acceptedTerms ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
