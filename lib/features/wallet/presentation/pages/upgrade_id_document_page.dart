import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/services/cloudinary_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Upgrade ID Document Page
///
/// Third step in wallet upgrade flow.
/// User uploads their government-issued ID document.
class UpgradeIdDocumentPage extends ConsumerStatefulWidget {
  const UpgradeIdDocumentPage({super.key});

  @override
  ConsumerState<UpgradeIdDocumentPage> createState() => _UpgradeIdDocumentPageState();
}

class _UpgradeIdDocumentPageState extends ConsumerState<UpgradeIdDocumentPage> {
  final _idNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedIdType;
  DateTime? _expiryDate;
  String? _frontImagePath;
  String? _backImagePath;
  bool _isSubmitting = false;

  final List<Map<String, String>> _idTypes = [
    {'value': 'NIN_SLIP', 'label': 'NIN Slip'},
    {'value': 'VOTERS_CARD', 'label': "Voter's Card"},
    {'value': 'DRIVERS_LICENSE', 'label': "Driver's License"},
    {'value': 'INTERNATIONAL_PASSPORT', 'label': 'International Passport'},
  ];

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _selectedIdType != null &&
        _idNumberController.text.isNotEmpty &&
        _expiryDate != null &&
        _frontImagePath != null;
  }

  Future<void> _pickImage(bool isFront) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImagePath = image.path;
        } else {
          _backImagePath = image.path;
        }
      });
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

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime(now.year + 1),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
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
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _onSubmit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);

      // Upload front image
      showInfoSnackbar('Uploading ID document...');
      final frontResult = await cloudinary.uploadImage(_frontImagePath!);
      if (!frontResult.success) {
        showErrorSnackbar('Failed to upload front image: ${frontResult.error}');
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload back image if provided
      String? backUrl;
      if (_backImagePath != null) {
        final backResult = await cloudinary.uploadImage(_backImagePath!);
        if (!backResult.success) {
          showErrorSnackbar('Failed to upload back image: ${backResult.error}');
          setState(() => _isSubmitting = false);
          return;
        }
        backUrl = backResult.url;
      }

      // Submit to API
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.submitUpgradeIdDocument(
        idType: _selectedIdType!,
        idNumber: _idNumberController.text.trim(),
        expiryDate: DateFormat('yyyy-MM-dd').format(_expiryDate!),
        frontUrl: frontResult.url!,
        backUrl: backUrl,
      );

      if (!mounted) return;

      if (response.success) {
        final nextStep = response.data?['nextStep'] ?? 'FACE_VERIFICATION';
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
      case 'FACE_VERIFICATION':
        context.push(AppRoutes.upgradeFace);
        break;
      case 'ADDRESS':
        context.push(AppRoutes.upgradeAddress);
        break;
      default:
        context.push(AppRoutes.upgradeFace);
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
                _buildProgressIndicator(3, 5),
                const SizedBox(height: 20),
                Text(
                  'Upload ID Document',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide a valid government-issued ID document.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                  ),
                ),
                const SizedBox(height: 24),

                // ID Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedIdType,
                  decoration: InputDecoration(
                    labelText: 'ID Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.black),
                  items: _idTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedIdType = value);
                  },
                ),
                const SizedBox(height: 16),

                // ID Number
                CustomTextField(
                  controller: _idNumberController,
                  hintText: 'Enter ID number',
                  labelText: 'ID Number',
                ),
                const SizedBox(height: 16),

                // Expiry Date
                GestureDetector(
                  onTap: _selectExpiryDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
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
                              'Expiry Date',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                color: _subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _expiryDate != null
                                  ? DateFormat('dd MMM, yyyy').format(_expiryDate!)
                                  : 'Select date',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _expiryDate != null ? _mainTextColor : _subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.calendar_today_outlined, color: _subtitleColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Document Upload Section
                Text(
                  'Upload Document Photos',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Front of ID
                _buildImageUploadCard(
                  label: 'Front of ID *',
                  imagePath: _frontImagePath,
                  onTap: () => _pickImage(true),
                ),
                const SizedBox(height: 12),

                // Back of ID (Optional)
                _buildImageUploadCard(
                  label: 'Back of ID (Optional)',
                  imagePath: _backImagePath,
                  onTap: () => _pickImage(false),
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

  Widget _buildImageUploadCard({
    required String label,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath != null ? AppColors.primary : const Color(0xFFE0E0E0),
            width: imagePath != null ? 2 : 1,
          ),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(imagePath),
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
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(128),
                        ),
                        child: Text(
                          label,
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
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: _subtitleColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: _subtitleColor.withAlpha(179),
                    ),
                  ),
                ],
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
