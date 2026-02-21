import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/services/cloudinary_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Upgrade Utility Bill Page
///
/// Required for Tier 3 upgrade.
/// User uploads a utility bill as proof of address.
class UpgradeUtilityBillPage extends ConsumerStatefulWidget {
  const UpgradeUtilityBillPage({super.key});

  @override
  ConsumerState<UpgradeUtilityBillPage> createState() => _UpgradeUtilityBillPageState();
}

class _UpgradeUtilityBillPageState extends ConsumerState<UpgradeUtilityBillPage> {
  final ImagePicker _picker = ImagePicker();

  String? _selectedBillType;
  String? _billImagePath;
  bool _isSubmitting = false;

  final List<Map<String, String>> _billTypes = [
    {'value': 'ELECTRICITY', 'label': 'Electricity Bill'},
    {'value': 'WATER', 'label': 'Water Bill'},
    {'value': 'WASTE', 'label': 'Waste Management Bill'},
    {'value': 'INTERNET', 'label': 'Internet/Cable Bill'},
    {'value': 'OTHER', 'label': 'Other Utility Bill'},
  ];

  bool get _isValid {
    return _selectedBillType != null && _billImagePath != null;
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _billImagePath = image.path);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);

      // Upload bill image
      showInfoSnackbar('Uploading utility bill...');
      final uploadResult = await cloudinary.uploadImage(_billImagePath!);

      if (!uploadResult.success) {
        showErrorSnackbar('Failed to upload: ${uploadResult.error}');
        setState(() => _isSubmitting = false);
        return;
      }

      // Submit to API
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.submitUpgradeUtilityBill(
        billType: _selectedBillType!,
        billUrl: uploadResult.url!,
      );

      if (!mounted) return;

      if (response.success) {
        final nextStep = response.data?['nextStep'] ?? 'SIGNATURE';
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
      case 'SIGNATURE':
        context.push(AppRoutes.upgradeSignature);
        break;
      case 'SUBMITTED':
        context.go(AppRoutes.upgradePending);
        break;
      default:
        context.push(AppRoutes.upgradeSignature);
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
                _buildProgressIndicator(6, 7),
                const SizedBox(height: 20),
                Text(
                  'Utility Bill',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a recent utility bill (within 3 months) as proof of address.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Bill Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBillType,
                  decoration: InputDecoration(
                    labelText: 'Bill Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.black),
                  items: _billTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBillType = value);
                  },
                ),
                const SizedBox(height: 24),

                // Upload Section
                Text(
                  'Upload Bill Document',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _billImagePath != null ? AppColors.primary : const Color(0xFFE0E0E0),
                        width: _billImagePath != null ? 2 : 1,
                      ),
                    ),
                    child: _billImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(_billImagePath!),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(128),
                                    ),
                                    child: Text(
                                      'Tap to change',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: _subtitleColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to upload utility bill',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'JPEG, PNG or PDF',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  color: _subtitleColor.withAlpha(179),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The utility bill should be dated within the last 3 months and show your full name and address.',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
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
