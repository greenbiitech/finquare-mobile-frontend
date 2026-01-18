import 'dart:io';

import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

/// Face Verification Page
///
/// Part of wallet setup flow.
/// User captures or uploads a photo for face verification.
class FaceVerificationPage extends ConsumerStatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  ConsumerState<FaceVerificationPage> createState() =>
      _FaceVerificationPageState();
}

class _FaceVerificationPageState extends ConsumerState<FaceVerificationPage> {
  final ImagePicker picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
      context.push(AppRoutes.confirmPhoto, extra: picked.path);
    }
  }

  Future<void> _openCamera() async {
    // Navigate to liveness check screen
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _LivenessCheckScreen(),
      ),
    );

    if (result != null && mounted) {
      context.push(AppRoutes.confirmPhoto, extra: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _FaceVerificationCardWidget(
        asset: 'assets/svgs/lightbulb-02.svg',
        word: 'Choose a brightly lit spot.',
      ),
      _FaceVerificationCardWidget(
        asset: 'assets/svgs/face-id.svg',
        word: 'Angle your face towards the light.',
      ),
      _FaceVerificationCardWidget(
        asset: 'assets/svgs/fluent-emoji-high-contrast_sunglasses.svg',
        word: 'Ensure your face is fully visible.',
      ),
      _FaceVerificationCardWidget(
        asset: 'assets/svgs/emoji-happy.svg',
        word: 'Remain in a steady position.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to exit'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  // Progress bar
                  SvgPicture.asset('assets/svgs/pagination_dots_3.svg'),
              const SizedBox(height: 20),

              // Title
              Text(
                'Face Verification 🔐',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Follow these steps to verify your identity with face authentication!',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF606060),
                ),
              ),
              const SizedBox(height: 30),
              Align(child: SvgPicture.asset('assets/svgs/face.svg')),
              const SizedBox(height: 40),
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
              const SizedBox(height: 11),
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
      ),
    );
  }
}

class _FaceVerificationCardWidget extends StatelessWidget {
  const _FaceVerificationCardWidget({
    required this.asset,
    required this.word,
  });

  final String asset;
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
          SvgPicture.asset(asset, height: 28, width: 28),
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

/// Liveness Check Screen
///
/// Uses face_camera package to detect a live face and auto-capture.
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
        message: 'Center your face in the square',
        messageStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
