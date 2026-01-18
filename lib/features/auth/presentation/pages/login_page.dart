import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/join_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canLogin {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  /// Check for pending invite token and clear it
  Future<String?> _checkPendingInvite() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: kPendingInviteTokenKey);
    if (token != null) {
      // Clear the pending token so it's not used again
      await storage.delete(key: kPendingInviteTokenKey);
    }
    return token;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    ref.showLoading('Signing in...');

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    ref.hideLoading();

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (!user.hasPasskey) {
          // User needs to create passkey
          context.go(AppRoutes.createPasskey);
        } else if (!user.hasPickedMembership) {
          // Check for pending invite first
          final pendingToken = await _checkPendingInvite();
          if (pendingToken != null && mounted) {
            context.go('${AppRoutes.joinCommunity}/$pendingToken');
          } else if (mounted) {
            context.go(AppRoutes.pickMembership);
          }
        } else {
          // User has completed setup, check for pending invite
          final pendingToken = await _checkPendingInvite();
          if (pendingToken != null && mounted) {
            context.go('${AppRoutes.joinCommunity}/$pendingToken');
          } else if (mounted) {
            showSuccessSnackbar('Login successful!');
            context.go(AppRoutes.home);
          }
        }
      }
    } else {
      final error = ref.read(authProvider).error;
      showErrorSnackbar(error ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60),
                AppBackButton(),
                SizedBox(height: 20),
                Text(
                  'Log in to begin',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'So glad to see you back, login to continue.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 60),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'e.g johndoe@email.com',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 30),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.iconSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.resetPassword);
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.buttonInactive,
                    ),
                  ),
                ),
                SizedBox(height: 200),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canLogin ? AppColors.primary : AppColors.surfaceVariant,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(43),
                      ),
                    ),
                    onPressed: _canLogin ? _login : null,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _canLogin
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.signup),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account?",
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.buttonInactive,
                      ),
                      children: [
                        TextSpan(
                          text: ' Create Account',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
