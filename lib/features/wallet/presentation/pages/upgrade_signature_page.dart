import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/services/cloudinary_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Upgrade Signature Page
///
/// Required for Tier 3 upgrade.
/// User draws their signature on a canvas.
class UpgradeSignaturePage extends ConsumerStatefulWidget {
  const UpgradeSignaturePage({super.key});

  @override
  ConsumerState<UpgradeSignaturePage> createState() => _UpgradeSignaturePageState();
}

class _UpgradeSignaturePageState extends ConsumerState<UpgradeSignaturePage> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSubmitting = false;

  bool get _hasSignature => _strokes.isNotEmpty;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke = [..._currentStroke, details.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(_currentStroke);
        _currentStroke = [];
      });
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<String?> _saveSignatureToFile() async {
    try {
      final boundary = _signatureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _onSubmit() async {
    if (!_hasSignature || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Save signature to file
      showInfoSnackbar('Saving signature...');
      final signaturePath = await _saveSignatureToFile();

      if (signaturePath == null) {
        showErrorSnackbar('Failed to save signature');
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload to cloudinary
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final uploadResult = await cloudinary.uploadImage(signaturePath);

      if (!uploadResult.success) {
        showErrorSnackbar('Failed to upload: ${uploadResult.error}');
        setState(() => _isSubmitting = false);
        return;
      }

      // Submit to API
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.submitUpgradeSignature(uploadResult.url!);

      if (!mounted) return;

      if (response.success) {
        context.go(AppRoutes.upgradePending);
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

  @override
  Widget build(BuildContext context) {
    final canSubmit = _hasSignature && !_isSubmitting;

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
              _buildProgressIndicator(7, 7),
              const SizedBox(height: 20),
              Text(
                'Add Your Signature',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Draw your signature in the box below using your finger.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _subtitleColor,
                ),
              ),
              const SizedBox(height: 24),

              // Signature Canvas
              Expanded(
                child: RepaintBoundary(
                  key: _signatureKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Clear button
              if (_hasSignature)
                Center(
                  child: TextButton.icon(
                    onPressed: _clearSignature,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(
                      'Clear Signature',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: _subtitleColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your signature will be used for account verification purposes.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: _subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
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

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}
