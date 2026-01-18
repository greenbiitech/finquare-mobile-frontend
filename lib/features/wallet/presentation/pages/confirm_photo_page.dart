import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);
const Color _primary300 = Color(0xFFBBBBBB);

// Cloudinary configuration
final _cloudinary = CloudinaryPublic('dtl7zqlqz', 'greencard_preset', cache: false);

/// Confirm Photo Page
///
/// Part of wallet setup flow.
/// User confirms the captured/uploaded photo before submission.
class ConfirmPhotoPage extends ConsumerStatefulWidget {
  const ConfirmPhotoPage({super.key, required this.filePath});

  final String filePath;

  @override
  ConsumerState<ConfirmPhotoPage> createState() => _ConfirmPhotoPageState();
}

class _ConfirmPhotoPageState extends ConsumerState<ConfirmPhotoPage> {
  bool _isUploading = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _uploadedUrl;

  @override
  void initState() {
    super.initState();
    // Auto-upload when page loads
    _uploadToCloudinary();
  }

  Future<void> _uploadToCloudinary() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          widget.filePath,
          resourceType: CloudinaryResourceType.Image,
        ),
        onProgress: (count, total) {
          setState(() {
            _uploadProgress = (count / total) * 100;
          });
        },
      );

      setState(() {
        _uploadedUrl = response.secureUrl;
      });
    } on CloudinaryException catch (e) {
      if (mounted) {
        _showErrorSnackbar('Upload failed: ${e.message}');
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (_uploadedUrl == null) {
      _showErrorSnackbar('Please wait for the photo to upload');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final request = CompleteStep3Request(photoUrl: _uploadedUrl!);
      final response = await walletRepo.completeStep3(request);

      if (!mounted) return;

      if (response.success) {
        context.push(AppRoutes.proofOfAddress);
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to save photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final canSubmit = !_isUploading && !_isSubmitting && _uploadedUrl != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const AppBackButton(),
                  const SizedBox(height: 15),
                  SvgPicture.asset('assets/svgs/pagination_dots_3.svg'),
                  const SizedBox(height: 20),
                  Text(
                    'Confirm Photo',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check that your face is clear and in the frame before moving on!',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF606060),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _ConfirmPhotoWidget(
                    filePath: widget.filePath,
                    uploadedUrl: _uploadedUrl,
                    maxWidth: screenWidth * 0.85,
                  ),
                  const SizedBox(height: 30),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSubmit
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
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
                              'Submit',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: canSubmit
                                    ? Colors.white
                                    : AppColors.textDisabled,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  // Take another photo button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F6F8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(43),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : () => context.pop(),
                      child: Text(
                        'Take another photo',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _mainTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            // Upload progress overlay
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(128),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _uploadProgress / 100,
                          strokeWidth: 6,
                          color: AppColors.primary,
                          backgroundColor: Colors.white.withAlpha(77),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_uploadProgress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading photo...',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmPhotoWidget extends StatelessWidget {
  const _ConfirmPhotoWidget({
    required this.filePath,
    required this.maxWidth,
    this.uploadedUrl,
  });

  final String filePath;
  final double maxWidth;
  final String? uploadedUrl;

  @override
  Widget build(BuildContext context) {
    final double outerSize = maxWidth;
    final double middleSize = outerSize * 0.88;
    final double innerSize = outerSize * 0.78;

    // Use uploaded URL if available, otherwise use local file
    final imageProvider = uploadedUrl != null
        ? NetworkImage(uploadedUrl!) as ImageProvider
        : FileImage(File(filePath));

    return Align(
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _primary300,
        ),
        alignment: Alignment.center,
        child: Container(
          height: middleSize,
          width: middleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary300,
          ),
          alignment: Alignment.center,
          child: Container(
            height: innerSize,
            width: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
