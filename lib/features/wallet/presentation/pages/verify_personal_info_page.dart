import 'package:flutter/material.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);
const Color _primary300 = Color(0xFFBBBBBB); // Colors/Primary/300

/// Verify Personal Information Page
///
/// Fifth step in wallet setup flow.
/// Displays user's personal information from BVN (read-only).
/// User can select their occupation.
class VerifyPersonalInfoPage extends ConsumerStatefulWidget {
  const VerifyPersonalInfoPage({
    super.key,
    this.progress,
    this.bvnData,
  });

  final WalletSetupProgress? progress;
  final BvnData? bvnData; // BVN data from OTP verification

  @override
  ConsumerState<VerifyPersonalInfoPage> createState() =>
      _VerifyPersonalInfoPageState();
}

class _VerifyPersonalInfoPageState
    extends ConsumerState<VerifyPersonalInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _selectedGender = 'Male';
  String? _selectedOccupation;
  WalletSetupProgress? _progress;
  bool _isLoading = true;

  final List<String> _occupations = const [
    'Student',
    'Employed',
    'Self-Employed',
    'Business Owner',
    'Civil Servant',
    'Retired',
    'Unemployed',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    // Always fetch progress from API to get nameMatchesBvn for name mismatch check
    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final progress = await walletRepo.getSetupProgress();
      _progress = progress;

      // If BVN data was passed directly (from OTP verification), use it for display
      // but keep the progress for nameMatchesBvn check
      if (widget.bvnData != null) {
        _populateFromBvnData(widget.bvnData!);
      } else {
        _populateFromProgress(progress);
      }
    } catch (e) {
      // If fetch fails but we have bvnData, use it
      if (widget.bvnData != null) {
        _populateFromBvnData(widget.bvnData!);
      } else if (_progress != null) {
        _populateFromProgress(_progress!);
      } else {
        // Keep placeholder data if everything fails
        _nameController.text = '';
        _phoneController.text = '';
        _dobController.text = '';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateFromBvnData(BvnData bvn) {
    _nameController.text = bvn.fullName;
    _phoneController.text = bvn.phoneNumber ?? '';
    _dobController.text = bvn.dateOfBirth ?? '';
    _selectedGender = (bvn.gender?.toLowerCase() == 'female') ? 'Female' : 'Male';
  }

  void _populateFromProgress(WalletSetupProgress progress) {
    final bvn = progress.bvnData;
    _nameController.text = bvn.fullName;
    _phoneController.text = bvn.phoneNumber ?? '';
    _dobController.text = bvn.dateOfBirth ?? '';
    _selectedGender = (bvn.gender?.toLowerCase() == 'female') ? 'Female' : 'Male';
    _selectedOccupation = progress.occupation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Only require name and gender - phone and DOB may be empty from BVN provider
  bool get _isValid =>
      _nameController.text.isNotEmpty &&
      _selectedGender.isNotEmpty;

  Future<void> _onNext() async {
    if (!_isValid) return;

    // Pass progress and selected occupation to address page
    context.push(
      AppRoutes.addressInfo,
      extra: {
        'progress': _progress,
        'occupation': _selectedOccupation,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to exit'),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        // Progress bar
                        SvgPicture.asset('assets/svgs/pagination_dots_2.svg'),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Verify your Personal Information 😊',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _mainTextColor,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Please confirm that your personal information, is accurate.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF606060),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name (read-only)
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'e.g John Doe',
                        labelText: 'First & Last Name',
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),

                      // Phone (read-only)
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'e.g 0812345689',
                        labelText: 'Phone number',
                        readOnly: true,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth (read-only)
                      _buildDatePickerField(context),

                      // Gender
                      const SizedBox(height: 5),
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF595959),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildGenderButton('Male'),
                          const SizedBox(width: 10),
                          _buildGenderButton('Female'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Occupation dropdown
                      _buildOccupationDropdown(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isValid ? AppColors.primary : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: _isValid ? _onNext : null,
            child: Text(
              'Next',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isValid ? Colors.white : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _dobController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          hintText: 'e.g 1999-04-27',
          hintStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: Colors.grey,
          ),
          labelStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset('assets/svgs/calendar.svg'),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String value) {
    final isSelected = _selectedGender.toLowerCase() == value.toLowerCase();
    return Expanded(
      child: GestureDetector(
        // Gender is read-only from BVN
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? _primary300 : const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isSelected ? AppColors.primary : const Color(0xFFA4A4A4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccupationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedOccupation,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select Occupation',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 30,
        color: Colors.black,
      ),
      isDense: true,
      items: _occupations.map((occupation) {
        return DropdownMenuItem(
          value: occupation,
          child: Text(
            occupation,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOccupation = value;
        });
      },
    );
  }
}
