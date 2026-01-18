import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

// Cloudinary configuration
final _cloudinary = CloudinaryPublic('dtl7zqlqz', 'greencard_preset', cache: false);

/// Proof of Address Page
///
/// Part of wallet setup flow.
/// User uploads a utility bill as proof of address or can skip this step.
class ProofOfAddressPage extends ConsumerStatefulWidget {
  const ProofOfAddressPage({super.key});

  @override
  ConsumerState<ProofOfAddressPage> createState() => _ProofOfAddressPageState();
}

class _ProofOfAddressPageState extends ConsumerState<ProofOfAddressPage> {
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isSkipping = false;
  double _uploadProgress = 0.0;
  String _fileName = '';
  String _filePath = '';
  String? _uploadedUrl;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _fileName = result.files.single.name;
        _filePath = result.files.single.path!;
        _uploadedUrl = null; // Reset uploaded URL when new file is picked
      });

      // Auto-upload when file is selected
      _uploadToCloudinary();
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_filePath.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _filePath,
          resourceType: CloudinaryResourceType.Auto,
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
        _showError('Upload failed: ${e.message}');
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (_uploadedUrl == null) {
      _showError('Please wait for the document to upload');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final request = CompleteStep4Request(proofOfAddressUrl: _uploadedUrl!);
      final response = await walletRepo.completeStep4(request);

      if (!mounted) return;

      if (response.success) {
        context.push(AppRoutes.createTransactionPin);
      } else {
        _showError(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save document. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _onSkip() async {
    setState(() {
      _isSkipping = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.skipStep4();

      if (!mounted) return;

      if (response.success) {
        context.push(AppRoutes.createTransactionPin);
      } else {
        _showError(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to skip. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSkipping = false;
        });
      }
    }
  }

  void _showError(String message) {
    showErrorSnackbar(message);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_isUploading && !_isSubmitting && !_isSkipping && _uploadedUrl != null;
    final isProcessing = _isUploading || _isSubmitting || _isSkipping;

    return Scaffold(
      backgroundColor: Colors.white,
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to exit'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                // Progress bar
                SvgPicture.asset('assets/svgs/pagination_dots_4.svg'),
            const SizedBox(height: 20),

            // Title
            Text(
              'Proof of Address',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _mainTextColor,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Upload a recent utility bill (electricity, water, waste) not older than 3 months, showing your address.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF606060),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Utility Bill',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _mainTextColor,
              ),
            ),
            const SizedBox(height: 10),
            // File picker
            GestureDetector(
              onTap: isProcessing ? null : _pickFile,
              child: _fileName.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _uploadedUrl != null
                              ? AppColors.primary
                              : const Color(0xFFBBBBBB),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isUploading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: _uploadProgress / 100,
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          else if (_uploadedUrl != null)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            )
                          else
                            Icon(
                              Icons.error_outline,
                              color: Colors.orange,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _fileName,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    color: const Color(0xFF606060),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_isUploading)
                                  Text(
                                    '${_uploadProgress.toStringAsFixed(0)}% uploading...',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!_isUploading)
                            Text(
                              'Change',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _mainTextColor,
                              ),
                            ),
                        ],
                      ),
                    )
                  : SvgPicture.asset('assets/svgs/input.svg'),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF8D8C95),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Kindly ensure your pictures are of high resolution and under 2mb size.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF606060),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
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
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: canSubmit ? Colors.white : AppColors.textDisabled,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Skip button
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
                onPressed: isProcessing ? null : _onSkip,
                child: _isSkipping
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Skip for later',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _mainTextColor,
                        ),
                      ),
              ),
            ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
