import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// NIN Validation Page
///
/// Alternative to BVN for Tier 1 wallet creation.
/// User enters their 11-digit National Identification Number (NIN) and Date of Birth.
/// DOB is required to verify ownership of the NIN.
/// Unlike BVN, NIN verification is a single step (no OTP required).
/// After verification, proceeds directly to Transaction PIN creation.
class NinValidationPage extends ConsumerStatefulWidget {
  const NinValidationPage({super.key});

  @override
  ConsumerState<NinValidationPage> createState() => _NinValidationPageState();
}

class _NinValidationPageState extends ConsumerState<NinValidationPage> {
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ninController.addListener(() => setState(() {}));
    _dobController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ninController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // NIN regex validation (exactly 11 digits)
  bool get _isValidNin {
    final nin = _ninController.text.trim();
    return RegExp(r'^\d{11}$').hasMatch(nin);
  }

  bool get _isValidDob {
    return _selectedDate != null;
  }

  void _showError(String message) {
    showErrorSnackbar(message);
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDate ?? DateTime(now.year - 25);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 16), // Must be at least 16 years old
      helpText: 'Select your date of birth',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _mainTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _onContinue() async {
    if (!_isValidNin || !_isValidDob) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Format date as YYYY-MM-DD for API
      final formattedDob = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final response = await walletRepo.lookupNin(
        _ninController.text.trim(),
        formattedDob,
      );

      if (!mounted) return;

      if (response.success) {
        // NIN verification successful - go directly to PIN creation
        // Store NIN data for later use
        context.push(
          AppRoutes.createTransactionPin,
          extra: {
            'verificationType': 'NIN',
            'verificationData': {
              'nin': response.data?.nin,
              'firstName': response.data?.firstName,
              'lastName': response.data?.lastName,
              'middleName': response.data?.middleName,
            },
          },
        );
      } else {
        _showError(response.message ?? 'Failed to verify NIN');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to verify NIN. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _isValidNin && _isValidDob && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const AppBackButton(),
                  const SizedBox(height: 22),
                  SvgPicture.asset('assets/svgs/pagination_dots.svg'),
                  const SizedBox(height: 15),
                  Text(
                    'NIN Verification',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Enter your NIN and date of birth to verify your identity',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // NIN Field
                  CustomTextField(
                    controller: _ninController,
                    hintText: '11 digits',
                    labelText: 'National Identification Number (NIN)',
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      return RegExp(r'^\d{11}$').hasMatch(value)
                          ? null
                          : 'Please enter a valid NIN with exactly 11 digits';
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date of Birth Field
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _dobController,
                        hintText: 'DD/MM/YYYY',
                        labelText: 'Date of Birth',
                        keyboardType: TextInputType.none,
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: _subtitleColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: _subtitleColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your date of birth must match the one linked to your NIN for verification.',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: _subtitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Benefits callout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Verification',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NIN verification is instant - no OTP required. Your wallet will be created right after you set your PIN.',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canContinue ? AppColors.primary : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: canContinue ? _onContinue : null,
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Verify NIN',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: canContinue
                          ? AppColors.textOnPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
