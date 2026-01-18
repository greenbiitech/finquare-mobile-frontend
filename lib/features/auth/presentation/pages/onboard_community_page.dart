import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_creation_provider.dart';

class OnboardCommunityPage extends ConsumerStatefulWidget {
  const OnboardCommunityPage({super.key});

  @override
  ConsumerState<OnboardCommunityPage> createState() =>
      _OnboardCommunityPageState();
}

class _OnboardCommunityPageState extends ConsumerState<OnboardCommunityPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing state values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(communityCreationProvider);
      if (state.communityName.isNotEmpty) {
        _nameController.text = state.communityName;
        // Check availability for existing name
        _checkNameAvailability(state.communityName);
      }
      if (state.description != null && state.description!.isNotEmpty) {
        _descriptionController.text = state.description!;
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkNameAvailability(String name) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (name.trim().length >= 3) {
        ref.read(communityCreationProvider.notifier).checkCommunityNameAvailability(name);
      }
    });
  }

  Future<void> _handleNext() async {
    final notifier = ref.read(communityCreationProvider.notifier);

    // Show loading overlay
    ref.showLoading('Uploading logo...');

    // Upload logo if one was selected
    final success = await notifier.uploadLogo();

    // Hide loading overlay
    ref.hideLoading();

    if (success && mounted) {
      context.push(AppRoutes.registerCommunity);
    } else if (mounted) {
      final error = ref.read(communityCreationProvider).error;
      showErrorSnackbar(error ?? 'Failed to upload logo');
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      ref.read(communityCreationProvider.notifier).setLogoPath(image.path);
    }
  }

  Future<void> _showColorPicker() async {
    final currentColor = ref.read(communityCreationProvider).selectedColor;
    Color tempColor = currentColor;

    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Select Color',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) => tempColor = color,
              enableAlpha: false,
              labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(12)),
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: tempColor,
                foregroundColor:
                    useWhiteForeground(tempColor) ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      ref.read(communityCreationProvider.notifier).setSelectedColor(pickedColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityCreationProvider);
    final notifier = ref.read(communityCreationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 20),
                  Text(
                    'Onboard your Community',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Add Logo
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: state.logoPath != null
                      ? Stack(
                          children: [
                            Container(
                              width: 134,
                              height: 134,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(state.logoPath!)),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: state.selectedColor,
                                  width: 3,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: state.selectedColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : SvgPicture.asset('assets/svgs/add_logo.svg'),
                ),
              ),
              const SizedBox(height: 25),
              // Community Name
              CustomTextField(
                controller: _nameController,
                hintText: 'e.g Old boys association',
                labelText: 'Community Name *',
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                onChanged: (value) {
                  notifier.setCommunityName(value);
                  _checkNameAvailability(value);
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name availability status
                  _buildNameAvailabilityStatus(state.nameAvailabilityStatus),
                  // Character count
                  Text(
                    '${state.communityName.length}/50',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: state.communityName.length > 45
                          ? AppColors.warning
                          : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Description
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Brief description of your community',
                labelText: 'Description (Optional)',
                maxLength: 200,
                maxLines: 3,
                onChanged: (value) {
                  notifier.setDescription(value);
                },
              ),
              if (state.description != null &&
                  state.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${state.description!.length}/200',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: state.description!.length > 180
                          ? AppColors.warning
                          : AppColors.textDisabled,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Colors
              Text(
                'Colors',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: _showColorPicker,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 24,
                        decoration: BoxDecoration(
                          color: state.selectedColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        state.colorHex,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down_outlined, size: 25),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isBasicInfoCompleteAndAvailable
                  ? AppColors.primary
                  : AppColors.buttonInactive,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: state.isBasicInfoCompleteAndAvailable ? _handleNext : null,
            child: Text(
              'Next',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameAvailabilityStatus(NameAvailabilityStatus status) {
    switch (status) {
      case NameAvailabilityStatus.idle:
      case NameAvailabilityStatus.tooShort:
        return const SizedBox.shrink();
      case NameAvailabilityStatus.checking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Checking...',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case NameAvailabilityStatus.available:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              'Available',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
        );
      case NameAvailabilityStatus.taken:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel,
              size: 14,
              color: AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Name already taken',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        );
      case NameAvailabilityStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              'Could not verify',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ],
        );
    }
  }
}
