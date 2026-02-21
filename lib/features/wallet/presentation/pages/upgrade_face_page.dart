import 'dart:io';

import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

/// Upgrade Face Page
///
/// Fourth step in wallet upgrade flow.
/// User captures or uploads a selfie for face verification.
class UpgradeFacePage extends ConsumerStatefulWidget {
  const UpgradeFacePage({super.key});

  @override
  ConsumerState<UpgradeFacePage> createState() => _UpgradeFacePageState();
}

class _UpgradeFacePageState extends ConsumerState<UpgradeFacePage> {
  final ImagePicker _picker = ImagePicker();
  String? _capturedImagePath;
  bool _isSubmitting = false;

  Future<void> _pickImageFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      setState(() => _capturedImagePath = picked.path);
    }
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _LivenessCheckScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() => _capturedImagePath = result);
    }
  }

  Future<void> _onSubmit() async {
    if (_capturedImagePath == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);

      // Upload face image
      showInfoSnackbar('Uploading photo...');
      final uploadResult = await cloudinary.uploadImage(_capturedImagePath!);

      if (!uploadResult.success) {
        showErrorSnackbar('Failed to upload photo: ${uploadResult.error}');
        setState(() => _isSubmitting = false);
        return;
      }

      // Submit to API
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.submitUpgradeFace(uploadResult.url!);

      if (!mounted) return;

      if (response.success) {
        final nextStep = response.data?['nextStep'] ?? 'ADDRESS';
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
      case 'ADDRESS':
        context.push(AppRoutes.upgradeAddress);
        break;
      case 'UTILITY_BILL':
        context.push(AppRoutes.upgradeUtilityBill);
        break;
      case 'SUBMITTED':
        context.go(AppRoutes.upgradePending);
        break;
      default:
        context.push(AppRoutes.upgradeAddress);
    }
  }

  void _retake() {
    setState(() => _capturedImagePath = null);
  }

  @override
  Widget build(BuildContext context) {
    // If image is captured, show confirmation view
    if (_capturedImagePath != null) {
      return _buildConfirmationView();
    }

    // Otherwise show capture options
    return _buildCaptureView();
  }

  Widget _buildCaptureView() {
    final items = [
      _FaceVerificationCardWidget(
        icon: Icons.lightbulb_outline,
        word: 'Choose a brightly lit spot.',
      ),
      _FaceVerificationCardWidget(
        icon: Icons.face,
        word: 'Angle your face towards the light.',
      ),
      _FaceVerificationCardWidget(
        icon: Icons.remove_red_eye_outlined,
        word: 'Ensure your face is fully visible.',
      ),
      _FaceVerificationCardWidget(
        icon: Icons.accessibility_new,
        word: 'Remain in a steady position.',
      ),
    ];

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
                _buildProgressIndicator(4, 5),
                const SizedBox(height: 20),
                Text(
                  'Face Verification',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please take a clear selfie to verify your identity.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: _subtitleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                GridView.count(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.65,
                  children: items,
                ),
                const SizedBox(height: 30),
                // Open Camera button
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
                    onPressed: _openCamera,
                    child: Text(
                      'Open Camera',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Upload Photo button
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
                    onPressed: _pickImageFromGallery,
                    child: Text(
                      'Upload a Photo',
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
        ),
      ),
    );
  }

  Widget _buildConfirmationView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              const AppBackButton(),
              const SizedBox(height: 22),
              _buildProgressIndicator(4, 5),
              const SizedBox(height: 20),
              Text(
                'Confirm Your Photo',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure your face is clearly visible and well-lit.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _subtitleColor,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_capturedImagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                onPressed: _isSubmitting ? null : _onSubmit,
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
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(43),
                  ),
                ),
                onPressed: _isSubmitting ? null : _retake,
                child: Text(
                  'Retake Photo',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

class _FaceVerificationCardWidget extends StatelessWidget {
  const _FaceVerificationCardWidget({
    required this.icon,
    required this.word,
  });

  final IconData icon;
  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF3F3F3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: _mainTextColor),
          const SizedBox(height: 10),
          Text(
            word,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          )
        ],
      ),
    );
  }
}

/// Liveness Check Screen for face capture
class _LivenessCheckScreen extends StatefulWidget {
  const _LivenessCheckScreen();

  @override
  State<_LivenessCheckScreen> createState() => _LivenessCheckScreenState();
}

class _LivenessCheckScreenState extends State<_LivenessCheckScreen> {
  late FaceCameraController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FaceCameraController(
      autoCapture: true,
      defaultCameraLens: CameraLens.front,
      onCapture: (File? image) {
        if (image != null) {
          Navigator.pop(context, image.path);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SmartFaceCamera(
        controller: _controller,
        message: 'Center your face in the frame',
        messageStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
