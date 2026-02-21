import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Upgrade Personal Info Page
///
/// Second step in wallet upgrade flow.
/// User confirms their personal information (prefilled from BVN) and answers PEP question.
/// BVN fields are read-only, only PEP can be answered.
class UpgradePersonalInfoPage extends ConsumerStatefulWidget {
  const UpgradePersonalInfoPage({
    super.key,
    this.bvnData,
  });

  /// BVN data from verification (firstName, lastName, middleName, phoneNumber, dateOfBirth, gender)
  final Map<String, dynamic>? bvnData;

  @override
  ConsumerState<UpgradePersonalInfoPage> createState() => _UpgradePersonalInfoPageState();
}

class _UpgradePersonalInfoPageState extends ConsumerState<UpgradePersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _selectedGender;
  bool _isPep = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  /// True if BVN data is present - fields should be read-only
  bool _hasBvnData = false;

  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    // Check if BVN data is passed from verification
    final bvnData = widget.bvnData;

    if (bvnData != null && bvnData.isNotEmpty) {
      // Use BVN data - fields will be read-only
      _hasBvnData = true;
      _firstNameController.text = bvnData['firstName'] ?? '';
      _lastNameController.text = bvnData['lastName'] ?? '';
      _middleNameController.text = bvnData['middleName'] ?? '';
      _phoneController.text = bvnData['phoneNumber'] ?? '';

      // Parse date of birth (format: yyyy-MM-dd or similar)
      final dobString = bvnData['dateOfBirth'] as String?;
      if (dobString != null && dobString.isNotEmpty) {
        try {
          _dateOfBirth = DateTime.parse(dobString);
        } catch (e) {
          // Try alternative format
          try {
            _dateOfBirth = DateFormat('dd-MM-yyyy').parse(dobString);
          } catch (_) {
            // Leave as null if parsing fails
          }
        }
      }

      // Set gender
      final gender = bvnData['gender'] as String?;
      if (gender != null && gender.isNotEmpty) {
        // Normalize gender (Male/Female)
        _selectedGender = gender.toLowerCase() == 'male' ? 'Male' : 'Female';
      }

      // Get email from user profile
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user != null) {
        _emailController.text = user.email;
      }
    } else {
      // Fallback to user data from auth provider
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user != null) {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
      }
    }

    setState(() => _isLoading = false);
  }

  bool get _isValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _dateOfBirth != null &&
        _selectedGender != null;
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18), // Must be at least 18
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

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _onSubmit() async {
    if (!_isValid || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.submitUpgradePersonalInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        gender: _selectedGender!,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        isPep: _isPep,
      );

      if (!mounted) return;

      if (response.success) {
        final nextStep = response.data?['nextStep'] ?? 'ID_DOCUMENT';
        _navigateToStep(nextStep);
      } else {
        showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to submit. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _navigateToStep(String step) {
    switch (step) {
      case 'ID_DOCUMENT':
        context.push(AppRoutes.upgradeIdDocument);
        break;
      case 'FACE_VERIFICATION':
        context.push(AppRoutes.upgradeFace);
        break;
      default:
        context.push(AppRoutes.upgradeIdDocument);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canSubmit = _isValid && !_isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const AppBackButton(),
                  const SizedBox(height: 22),
                  _buildProgressIndicator(2, 5),
                  const SizedBox(height: 20),
                  Text(
                    'Confirm Your Details',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please verify your personal information is correct.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // First Name (read-only if BVN data present)
                  CustomTextField(
                    controller: _firstNameController,
                    hintText: 'Enter first name',
                    labelText: 'First Name',
                    readOnly: _hasBvnData,
                    enabled: !_hasBvnData,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Last Name (read-only if BVN data present)
                  CustomTextField(
                    controller: _lastNameController,
                    hintText: 'Enter last name',
                    labelText: 'Last Name',
                    readOnly: _hasBvnData,
                    enabled: !_hasBvnData,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Middle Name (read-only if BVN data present)
                  if (_middleNameController.text.isNotEmpty || !_hasBvnData)
                    Column(
                      children: [
                        CustomTextField(
                          controller: _middleNameController,
                          hintText: 'Enter middle name (optional)',
                          labelText: 'Middle Name',
                          readOnly: _hasBvnData,
                          enabled: !_hasBvnData,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Email (always from user profile)
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter email address',
                    labelText: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    enabled: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number (read-only if BVN data present)
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'Enter phone number',
                    labelText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    readOnly: _hasBvnData,
                    enabled: !_hasBvnData,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth (read-only if BVN data present)
                  GestureDetector(
                    onTap: _hasBvnData ? null : _selectDateOfBirth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _hasBvnData ? const Color(0xFFF5F5F5) : null,
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date of Birth',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  color: _subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dateOfBirth != null
                                    ? DateFormat('dd MMM, yyyy').format(_dateOfBirth!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _dateOfBirth != null ? _mainTextColor : _subtitleColor,
                                ),
                              ),
                            ],
                          ),
                          if (!_hasBvnData)
                            Icon(Icons.calendar_today_outlined, color: _subtitleColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender (read-only if BVN data present)
                  _hasBvnData
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        color: _subtitleColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedGender ?? '',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _mainTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.black),
                          items: _genderOptions.map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                        ),
                  const SizedBox(height: 24),

                  // PEP Question
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you a Politically Exposed Person (PEP)?',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _mainTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A PEP is someone who holds a prominent public position or is closely associated with one.',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: _subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPepOption('Yes', true),
                            const SizedBox(width: 16),
                            _buildPepOption('No', false),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
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
              backgroundColor: canSubmit ? AppColors.primary : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: canSubmit ? _onSubmit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: canSubmit ? Colors.white : AppColors.textDisabled,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPepOption(String label, bool value) {
    final isSelected = _isPep == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPep = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(25) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : _mainTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isCompleted = index < current - 1;
        final isCurrent = index == current - 1;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
