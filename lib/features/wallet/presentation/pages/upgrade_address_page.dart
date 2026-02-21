import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Upgrade Address Page
///
/// Fifth step in wallet upgrade flow.
/// User provides their residential address.
class UpgradeAddressPage extends ConsumerStatefulWidget {
  const UpgradeAddressPage({super.key});

  @override
  ConsumerState<UpgradeAddressPage> createState() => _UpgradeAddressPageState();
}

class _UpgradeAddressPageState extends ConsumerState<UpgradeAddressPage> {
  final _houseNumberController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _landmarkController = TextEditingController();

  List<String> _states = [];
  List<String> _lgas = [];
  String? _selectedState;
  String? _selectedLga;

  bool _isLoadingStates = true;
  bool _isLoadingLgas = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStates();
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _streetNameController.dispose();
    _cityController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http.get(
        Uri.parse('https://nga-states-lga.onrender.com/fetch'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _states = List<String>.from(json.decode(response.body));
          _isLoadingStates = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingStates = false);
    }
  }

  Future<void> _fetchLgas(String state) async {
    setState(() {
      _isLoadingLgas = true;
      _lgas = [];
      _selectedLga = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://nga-states-lga.onrender.com/?state=$state'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _lgas = List<String>.from(json.decode(response.body));
          _isLoadingLgas = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLgas = false);
    }
  }

  bool get _isValid {
    return _streetNameController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _selectedState != null &&
        _selectedLga != null;
  }

  Future<void> _onSubmit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.submitUpgradeAddress(
        houseNumber: _houseNumberController.text.trim().isEmpty
            ? null
            : _houseNumberController.text.trim(),
        streetName: _streetNameController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState!,
        lga: _selectedLga!,
        nearestLandmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        final nextStep = response.data?['nextStep'];
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

  void _navigateToStep(String? step) {
    switch (step) {
      case 'UTILITY_BILL':
        context.push(AppRoutes.upgradeUtilityBill);
        break;
      case 'SIGNATURE':
        context.push(AppRoutes.upgradeSignature);
        break;
      case 'SUBMITTED':
        context.go(AppRoutes.upgradePending);
        break;
      default:
        // Tier 2 upgrade complete - go to pending
        context.go(AppRoutes.upgradePending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _isValid && !_isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                const AppBackButton(),
                const SizedBox(height: 22),
                _buildProgressIndicator(5, 5),
                const SizedBox(height: 20),
                Text(
                  'Residential Address',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your current residential address.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                  ),
                ),
                const SizedBox(height: 24),

                // House Number (Optional)
                CustomTextField(
                  controller: _houseNumberController,
                  hintText: 'e.g. 42',
                  labelText: 'House Number (Optional)',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),

                // Street Name
                CustomTextField(
                  controller: _streetNameController,
                  hintText: 'e.g. Adeola Odeku Street',
                  labelText: 'Street Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Street name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City
                CustomTextField(
                  controller: _cityController,
                  hintText: 'e.g. Victoria Island',
                  labelText: 'City',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // State Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
                  items: _states.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: _isLoadingStates
                      ? null
                      : (value) {
                          setState(() => _selectedState = value);
                          if (value != null) {
                            _fetchLgas(value);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // LGA Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedLga,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Local Government Area',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
                  items: _lgas.map((lga) {
                    return DropdownMenuItem(
                      value: lga,
                      child: Text(lga),
                    );
                  }).toList(),
                  onChanged: (_selectedState == null || _isLoadingLgas)
                      ? null
                      : (value) {
                          setState(() => _selectedLga = value);
                        },
                ),
                const SizedBox(height: 16),

                // Nearest Landmark (Optional)
                CustomTextField(
                  controller: _landmarkController,
                  hintText: 'e.g. Near Access Bank',
                  labelText: 'Nearest Landmark (Optional)',
                ),
                const SizedBox(height: 100),
              ],
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
