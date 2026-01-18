import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_creation_provider.dart';

class RegisterCommunityPage extends ConsumerStatefulWidget {
  const RegisterCommunityPage({super.key});

  @override
  ConsumerState<RegisterCommunityPage> createState() =>
      _RegisterCommunityPageState();
}

class _RegisterCommunityPageState extends ConsumerState<RegisterCommunityPage> {
  static const String proofOfAddress = 'Proof of address';
  static const String cacRegistration = 'CAC registration Certificate';
  static const String addressVerification = 'Address verification Document';

  Future<void> _pickDocument(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final notifier = ref.read(communityCreationProvider.notifier);

      // For now, just store the path locally
      // In production, you'd upload to Cloudinary/S3 here
      switch (documentType) {
        case proofOfAddress:
          notifier.setProofOfAddress(file.path);
          break;
        case cacRegistration:
          notifier.setCacDocument(file.path);
          break;
        case addressVerification:
          notifier.setAddressVerification(file.path);
          break;
      }
    }
  }

  String? _getDocumentPath(String documentType) {
    final state = ref.read(communityCreationProvider);
    switch (documentType) {
      case proofOfAddress:
        return state.proofOfAddressPath;
      case cacRegistration:
        return state.cacDocumentPath;
      case addressVerification:
        return state.addressVerificationPath;
      default:
        return null;
    }
  }

  Future<void> _createCommunity() async {
    final notifier = ref.read(communityCreationProvider.notifier);

    // Show loading overlay
    ref.showLoading('Uploading documents...');

    // First, upload any documents if community is registered
    final documentsUploaded = await notifier.uploadDocuments();
    if (!documentsUploaded) {
      ref.hideLoading();
      if (mounted) {
        final error = ref.read(communityCreationProvider).error;
        showErrorSnackbar(error ?? 'Failed to upload documents');
      }
      return;
    }

    // Update loading message
    ref.updateLoadingMessage('Creating community...');

    // Then create the community
    final success = await notifier.createCommunity();

    // Hide loading overlay
    ref.hideLoading();

    if (success && mounted) {
      context.push(AppRoutes.communityMembership);
    } else if (mounted) {
      final error = ref.read(communityCreationProvider).error;
      showErrorSnackbar(error ?? 'Failed to create community');
    }
  }

  void _showDisclaimerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable indicator
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.background),
                  ),
                ),
                child: Align(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(
                      height: 5,
                      width: 51,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disclaimer',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'By submitting this form, I hereby provide my consent to the terms and conditions associated with the use of the FinSquare app. Furthermore, I acknowledge and agree to the establishment of a digital wallet with 9PSB Bank. This wallet will be utilized for all transactions related to our regular group activities and corporate dealings, ensuring secure and efficient financial management. I understand the importance of adhering to these terms for a seamless experience with the app and wallet services.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Open Terms and Conditions URL
                        },
                        child: Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            color: AppColors.link,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(43),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _createCommunity();
                        },
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(43),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityCreationProvider);
    final notifier = ref.read(communityCreationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const AppBackButton(),
              const SizedBox(height: 20),
              FittedBox(
                child: Text(
                  'Are you Registered as a Community?',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please upload your registration documents.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              // Yes/No Toggle
              Row(
                children: [
                  _buildToggleButton('Yes', true, state.isRegistered, () {
                    notifier.setIsRegistered(true);
                  }),
                  const SizedBox(width: 18),
                  _buildToggleButton('No', false, state.isRegistered, () {
                    notifier.setIsRegistered(false);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              // Document upload sections
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (state.isRegistered) ...[
                        _buildDocumentUpload(
                          proofOfAddress,
                          state.proofOfAddressPath != null,
                        ),
                        const SizedBox(height: 30),
                        _buildDocumentUpload(
                          cacRegistration,
                          state.cacDocumentPath != null,
                        ),
                        const SizedBox(height: 30),
                        _buildDocumentUpload(
                          addressVerification,
                          state.addressVerificationPath != null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: state.isRegistered
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.areAllDocumentsUploaded
                                ? AppColors.primary
                                : AppColors.buttonInactive,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(43),
                            ),
                          ),
                          onPressed: state.areAllDocumentsUploaded
                              ? () => _showDisclaimerBottomSheet(context)
                              : null,
                          child: Text(
                            'Complete',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(43),
                            ),
                          ),
                          onPressed: () => _showDisclaimerBottomSheet(context),
                          child: Text(
                            "I'll do it later",
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(43),
                      ),
                    ),
                    onPressed: () => _showDisclaimerBottomSheet(context),
                    child: Text(
                      'Create Community',
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

  Widget _buildToggleButton(
    String text,
    bool value,
    bool currentValue,
    VoidCallback onTap,
  ) {
    final isSelected = currentValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 26),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isSelected ? AppColors.primary : AppColors.textDisabled,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String title, bool hasDocument) {
    return InkWell(
      onTap: () => _pickDocument(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasDocument ? AppColors.primary : AppColors.border,
                width: hasDocument ? 2 : 1,
              ),
            ),
            child: hasDocument
                ? Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/svgs/upload.svg'),
                            const SizedBox(height: 8),
                            Text(
                              'Document Uploaded',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Tap to re-upload',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
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
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/svgs/input.svg'),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload document',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.iconSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Kindly ensure your documents are of high resolution and under 2mb size. Supported formats: PDF, DOC, DOCX, JPG, PNG',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
