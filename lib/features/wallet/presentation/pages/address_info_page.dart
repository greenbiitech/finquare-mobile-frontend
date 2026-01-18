import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

/// Address Information Page
///
/// Sixth step in wallet setup flow.
/// User provides their residential address information.
class AddressInfoPage extends ConsumerStatefulWidget {
  const AddressInfoPage({super.key, this.progress, this.occupation});

  final WalletSetupProgress? progress;
  final String? occupation;

  @override
  ConsumerState<AddressInfoPage> createState() => _AddressInfoPageState();
}

class _AddressInfoPageState extends ConsumerState<AddressInfoPage> {
  List<String> states = [];
  List<String> lgas = [];
  String? selectedState;
  String? selectedLga;
  final addressController = TextEditingController();

  bool isLoadingStates = true;
  bool isLoadingLgas = false;
  bool _isSubmitting = false;
  WalletSetupProgress? _progress;
  String? _occupation;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
    _occupation = widget.occupation;

    // Pre-fill address if resuming
    if (_progress != null && _progress!.addressData.address != null) {
      addressController.text = _progress!.addressData.address!;
      selectedState = _progress!.addressData.state;
      selectedLga = _progress!.addressData.lga;
    }

    fetchStates();
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<void> fetchStates() async {
    try {
      final response =
          await http.get(Uri.parse('https://nga-states-lga.onrender.com/fetch'));

      if (response.statusCode == 200) {
        setState(() {
          states = List<String>.from(json.decode(response.body));
          isLoadingStates = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingStates = false;
      });
    }
  }

  Future<void> fetchLgas(String state) async {
    setState(() {
      isLoadingLgas = true;
      lgas = [];
      selectedLga = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://nga-states-lga.onrender.com/?state=$state'),
      );

      if (response.statusCode == 200) {
        setState(() {
          lgas = List<String>.from(json.decode(response.body));
          isLoadingLgas = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingLgas = false;
      });
    }
  }

  bool get _isValid =>
      addressController.text.isNotEmpty &&
      (selectedLga ?? '').isNotEmpty &&
      (selectedState ?? '').isNotEmpty;

  Future<void> _onNext() async {
    if (!_isValid) return;

    // Check if names match BVN
    final nameMatchesBvn = _progress?.nameMatchesBvn ?? true;

    if (!nameMatchesBvn) {
      // Show warning dialog
      final shouldProceed = await _showNameMismatchDialog();
      if (shouldProceed != true) return;
    }

    // Proceed with API call
    await _submitStep2(syncWithBvn: !nameMatchesBvn);
  }

  Future<bool?> _showNameMismatchDialog() {
    final bvnName = _progress?.bvnData.fullName ?? '';
    final userName =
        '${_progress?.userFirstName ?? ''} ${_progress?.userLastName ?? ''}'
            .trim();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Name Mismatch',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account name doesn\'t match your BVN name.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Account Name:',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              userName,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BVN Name:',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              bvnName,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your account name will be updated to match your BVN.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitStep2({required bool syncWithBvn}) async {
    setState(() => _isSubmitting = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final request = CompleteStep2Request(
        address: addressController.text.trim(),
        state: selectedState!,
        lga: selectedLga!,
        occupation: _occupation,
        syncWithBvn: syncWithBvn,
      );

      final response = await walletRepo.completeStep2(request);

      if (!mounted) return;

      if (response.success) {
        context.push(AppRoutes.faceVerification);
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to save address information. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Back button
              const AppBackButton(),
              const SizedBox(height: 22),
              // Progress bar
              SvgPicture.asset('assets/svgs/pagination_dots_2.svg'),
              const SizedBox(height: 20),

              // Title
              Text(
                'Provide your Address Information 😊',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Please share your complete address details, including street name, city, and zip code.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF606060),
                ),
              ),
              const SizedBox(height: 20),

              // House Address
              CustomTextField(
                controller: addressController,
                hintText: 'e.g 24 kalu road maryland street',
                labelText: 'House Address',
              ),
              const SizedBox(height: 20),

              // State Dropdown
              DropdownButtonFormField<String>(
                value: selectedState,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select State',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 30,
                  color: Colors.black,
                ),
                isDense: true,
                items: states.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: isLoadingStates
                    ? null
                    : (value) {
                        setState(() {
                          selectedState = value;
                        });
                        if (value != null) {
                          fetchLgas(value);
                        }
                      },
              ),
              const SizedBox(height: 20),

              // LGA Dropdown
              DropdownButtonFormField<String>(
                value: selectedLga,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select LGA',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 30,
                  color: Colors.black,
                ),
                isDense: true,
                items: lgas.map((lga) {
                  return DropdownMenuItem(
                    value: lga,
                    child: Text(lga),
                  );
                }).toList(),
                onChanged: (selectedState == null || isLoadingLgas)
                    ? null
                    : (value) {
                        setState(() {
                          selectedLga = value;
                        });
                      },
              ),
              ],
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
                  _isValid && !_isSubmitting
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: (_isValid && !_isSubmitting) ? _onNext : null,
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
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
}
