import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';

class EnterNewPasswordPage extends StatefulWidget {
  const EnterNewPasswordPage({super.key});

  @override
  State<EnterNewPasswordPage> createState() => _EnterNewPasswordPageState();
}

class _EnterNewPasswordPageState extends State<EnterNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canReset {
    return _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
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
                  'Enter your New Password 😊',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'It must be different from the old password',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 40),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.iconSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  labelText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.iconSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                SizedBox(height: 250),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canReset ? AppColors.primary : AppColors.surfaceVariant,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(43),
                      ),
                    ),
                    onPressed: _canReset
                        ? () {
                            context.push(AppRoutes.resetPasswordSuccess);
                          }
                        : null,
                    child: Text(
                      'Reset Password',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _canReset
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
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
