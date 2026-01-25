import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/providers/esusu_creation_provider.dart';

// Esusu brand colors
const Color _esusuPurple = Color(0xFF8B20E9);
const Color _esusuLightPurple = Color(0xFFEBDAFB);

class CreateEsusuPage extends ConsumerStatefulWidget {
  const CreateEsusuPage({super.key});

  @override
  ConsumerState<CreateEsusuPage> createState() => _CreateEsusuPageState();
}

class _CreateEsusuPageState extends ConsumerState<CreateEsusuPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with existing state values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(esusuCreationProvider);
      if (state.esusuName.isNotEmpty) {
        _nameController.text = state.esusuName;
      }
      if (state.description != null && state.description!.isNotEmpty) {
        _descriptionController.text = state.description!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onNameChanged(String value) {
    final notifier = ref.read(esusuCreationProvider.notifier);
    notifier.setEsusuName(value);

    // Debounce name availability check
    _debounceTimer?.cancel();
    if (value.trim().length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        notifier.checkNameAvailability(value);
      });
    } else {
      notifier.resetNameAvailability();
    }
  }

  void _onDescriptionChanged(String value) {
    ref.read(esusuCreationProvider.notifier).setDescription(value);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Image Source',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _esusuLightPurple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.camera_alt, color: _esusuPurple),
              ),
              title: Text(
                'Camera',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  ref.read(esusuCreationProvider.notifier).setIconPath(image.path);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _esusuLightPurple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.photo_library, color: _esusuPurple),
              ),
              title: Text(
                'Gallery',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  ref.read(esusuCreationProvider.notifier).setIconPath(image.path);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleNext() {
    final state = ref.read(esusuCreationProvider);

    if (!state.isBasicInfoComplete) {
      return;
    }

    if (state.nameAvailabilityStatus == EsusuNameAvailabilityStatus.taken) {
      return;
    }

    // If still checking, wait for result
    if (state.nameAvailabilityStatus == EsusuNameAvailabilityStatus.checking) {
      return;
    }

    // Save the data to provider
    ref.read(esusuCreationProvider.notifier).setEsusuName(_nameController.text);
    ref.read(esusuCreationProvider.notifier).setDescription(_descriptionController.text);

    context.push(AppRoutes.configureEsusu);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esusuCreationProvider);
    final isFormValid = state.isBasicInfoComplete &&
        state.nameAvailabilityStatus != EsusuNameAvailabilityStatus.taken &&
        state.nameAvailabilityStatus != EsusuNameAvailabilityStatus.checking;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Create new',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Expanded scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Icon/Picture picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: state.iconPath != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(state.iconPath!),
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: _esusuPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                decoration: BoxDecoration(
                                  color: _esusuLightPurple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/svgs/hub/esusu.svg',
                                      width: 47.85,
                                      height: 56.36,
                                    ),
                                    Text(
                                      '+ add picture/icon',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _esusuPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 25),

                      // Esusu Name field
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Esusu Name',
                        hintText: 'e.g. Esusu for Rent',
                        textCapitalization: TextCapitalization.words,
                        maxLength: 50,
                        onChanged: _onNameChanged,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Name availability status
                          _buildNameAvailabilityIndicator(state),
                          // Character count
                          Text(
                            '${_nameController.text.length}/50',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _nameController.text.length > 45
                                  ? AppColors.warning
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      CustomTextField(
                        controller: _descriptionController,
                        labelText: 'Description (Optional)',
                        hintText: 'enter more details here',
                        maxLength: 200,
                        maxLines: 4,
                        minLines: 4,
                        onChanged: _onDescriptionChanged,
                      ),
                      if (_descriptionController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_descriptionController.text.length}/200',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _descriptionController.text.length > 180
                                  ? AppColors.warning
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
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
              backgroundColor: isFormValid ? _esusuPurple : Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: isFormValid ? _handleNext : null,
            child: state.nameAvailabilityStatus ==
                    EsusuNameAvailabilityStatus.checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameAvailabilityIndicator(EsusuCreationState state) {
    switch (state.nameAvailabilityStatus) {
      case EsusuNameAvailabilityStatus.checking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _esusuPurple,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Checking...',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        );
      case EsusuNameAvailabilityStatus.available:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Available',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.green,
              ),
            ),
          ],
        );
      case EsusuNameAvailabilityStatus.taken:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              state.nameAvailabilityMessage ?? 'Name already in use',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
          ],
        );
      case EsusuNameAvailabilityStatus.tooShort:
        return Text(
          'Min 3 characters',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textDisabled,
          ),
        );
      case EsusuNameAvailabilityStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              state.nameAvailabilityMessage ?? 'Error checking',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.orange,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
