import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cloudinary configuration
class CloudinaryConfig {
  static const String cloudName = 'dtl7zqlqz';
  static const String uploadPreset = 'greencard_preset';
}

/// Upload result model
class UploadResult {
  final bool success;
  final String? url;
  final String? error;

  const UploadResult({
    required this.success,
    this.url,
    this.error,
  });

  factory UploadResult.success(String url) => UploadResult(
        success: true,
        url: url,
      );

  factory UploadResult.failure(String error) => UploadResult(
        success: false,
        error: error,
      );
}

/// Cloudinary upload service
class CloudinaryService {
  final CloudinaryPublic _cloudinary;

  CloudinaryService()
      : _cloudinary = CloudinaryPublic(
          CloudinaryConfig.cloudName,
          CloudinaryConfig.uploadPreset,
          cache: false,
        );

  /// Upload an image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<UploadResult> uploadImage(String filePath) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return UploadResult.success(response.secureUrl);
    } on CloudinaryException catch (e) {
      return UploadResult.failure(e.message ?? 'Failed to upload image');
    } catch (e) {
      return UploadResult.failure('Unexpected error: ${e.toString()}');
    }
  }

  /// Upload a document file to Cloudinary (PDF, DOC, etc.)
  /// Returns the secure URL of the uploaded document
  Future<UploadResult> uploadDocument(String filePath) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Auto,
        ),
      );
      return UploadResult.success(response.secureUrl);
    } on CloudinaryException catch (e) {
      return UploadResult.failure(e.message ?? 'Failed to upload document');
    } catch (e) {
      return UploadResult.failure('Unexpected error: ${e.toString()}');
    }
  }

  /// Upload multiple files to Cloudinary
  /// Returns a list of secure URLs
  Future<List<UploadResult>> uploadMultiple(
    List<String> filePaths, {
    CloudinaryResourceType resourceType = CloudinaryResourceType.Auto,
  }) async {
    final results = <UploadResult>[];
    for (final path in filePaths) {
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            path,
            resourceType: resourceType,
          ),
        );
        results.add(UploadResult.success(response.secureUrl));
      } on CloudinaryException catch (e) {
        results.add(UploadResult.failure(e.message ?? 'Failed to upload'));
      } catch (e) {
        results.add(UploadResult.failure('Unexpected error: ${e.toString()}'));
      }
    }
    return results;
  }
}

/// Provider for CloudinaryService
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
