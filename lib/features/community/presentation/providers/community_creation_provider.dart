import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/services/cloudinary_service.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

/// Member to invite
class MemberToInvite {
  final String name;
  final String? email;
  final String? phone;

  MemberToInvite({
    required this.name,
    this.email,
    this.phone,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberToInvite &&
        other.name == name &&
        other.email == email &&
        other.phone == phone;
  }

  @override
  int get hashCode => name.hashCode ^ email.hashCode ^ phone.hashCode;
}

/// Name availability status
enum NameAvailabilityStatus {
  idle,
  checking,
  available,
  taken,
  tooShort,
  error,
}

/// Community Creation State
/// Holds all data collected during the community onboarding flow
class CommunityCreationState {
  // Step 1: Basic Info (OnboardCommunityPage)
  final String communityName;
  final String? description;
  final String? logoPath; // Local file path
  final String? logoUrl; // Uploaded URL
  final Color selectedColor;

  // Name availability check
  final NameAvailabilityStatus nameAvailabilityStatus;
  final String? nameAvailabilityMessage;

  // Step 2: Registration (RegisterCommunityPage)
  final bool isRegistered;
  final String? proofOfAddressPath;
  final String? proofOfAddressUrl;
  final String? cacDocumentPath;
  final String? cacDocumentUrl;
  final String? addressVerificationPath;
  final String? addressVerificationUrl;

  // Step 3: Created Community (After API call)
  final CreatedCommunity? createdCommunity;
  final String? inviteLink;

  // Step 4: Members to invite (InviteMembersPage)
  final List<MemberToInvite> membersToInvite;

  // UI State
  final bool isLoading;
  final String? error;
  final bool isCreated;

  const CommunityCreationState({
    this.communityName = '',
    this.description,
    this.logoPath,
    this.logoUrl,
    this.selectedColor = const Color(0xFFCD1919),
    this.nameAvailabilityStatus = NameAvailabilityStatus.idle,
    this.nameAvailabilityMessage,
    this.isRegistered = true,
    this.proofOfAddressPath,
    this.proofOfAddressUrl,
    this.cacDocumentPath,
    this.cacDocumentUrl,
    this.addressVerificationPath,
    this.addressVerificationUrl,
    this.createdCommunity,
    this.inviteLink,
    this.membersToInvite = const [],
    this.isLoading = false,
    this.error,
    this.isCreated = false,
  });

  CommunityCreationState copyWith({
    String? communityName,
    String? description,
    String? logoPath,
    String? logoUrl,
    Color? selectedColor,
    NameAvailabilityStatus? nameAvailabilityStatus,
    String? nameAvailabilityMessage,
    bool? isRegistered,
    String? proofOfAddressPath,
    String? proofOfAddressUrl,
    String? cacDocumentPath,
    String? cacDocumentUrl,
    String? addressVerificationPath,
    String? addressVerificationUrl,
    CreatedCommunity? createdCommunity,
    String? inviteLink,
    List<MemberToInvite>? membersToInvite,
    bool? isLoading,
    String? error,
    bool? isCreated,
    bool clearError = false,
    bool clearDescription = false,
    bool clearLogoPath = false,
    bool clearLogoUrl = false,
    bool clearNameAvailabilityMessage = false,
  }) {
    return CommunityCreationState(
      communityName: communityName ?? this.communityName,
      description: clearDescription ? null : (description ?? this.description),
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      selectedColor: selectedColor ?? this.selectedColor,
      nameAvailabilityStatus:
          nameAvailabilityStatus ?? this.nameAvailabilityStatus,
      nameAvailabilityMessage: clearNameAvailabilityMessage
          ? null
          : (nameAvailabilityMessage ?? this.nameAvailabilityMessage),
      isRegistered: isRegistered ?? this.isRegistered,
      proofOfAddressPath: proofOfAddressPath ?? this.proofOfAddressPath,
      proofOfAddressUrl: proofOfAddressUrl ?? this.proofOfAddressUrl,
      cacDocumentPath: cacDocumentPath ?? this.cacDocumentPath,
      cacDocumentUrl: cacDocumentUrl ?? this.cacDocumentUrl,
      addressVerificationPath:
          addressVerificationPath ?? this.addressVerificationPath,
      addressVerificationUrl:
          addressVerificationUrl ?? this.addressVerificationUrl,
      createdCommunity: createdCommunity ?? this.createdCommunity,
      inviteLink: inviteLink ?? this.inviteLink,
      membersToInvite: membersToInvite ?? this.membersToInvite,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCreated: isCreated ?? this.isCreated,
    );
  }

  /// Get color as hex string (e.g., "#CD1919")
  String get colorHex {
    return '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Check if all required documents are uploaded
  bool get areAllDocumentsUploaded {
    if (!isRegistered) return true;
    return proofOfAddressPath != null &&
        cacDocumentPath != null &&
        addressVerificationPath != null;
  }

  /// Check if basic info is complete
  bool get isBasicInfoComplete {
    return communityName.trim().length >= 3;
  }

  /// Check if basic info is complete and name is available
  bool get isBasicInfoCompleteAndAvailable {
    return communityName.trim().length >= 3 &&
        nameAvailabilityStatus == NameAvailabilityStatus.available;
  }
}

/// Community Creation Notifier
class CommunityCreationNotifier extends StateNotifier<CommunityCreationState> {
  final CommunityRepository _repository;
  final CloudinaryService _cloudinaryService;

  CommunityCreationNotifier(this._repository, this._cloudinaryService)
      : super(const CommunityCreationState());

  // =====================
  // Step 1: Basic Info
  // =====================

  void setCommunityName(String name) {
    state = state.copyWith(communityName: name);
  }

  void setDescription(String? description) {
    if (description == null || description.isEmpty) {
      state = state.copyWith(clearDescription: true);
    } else {
      state = state.copyWith(description: description);
    }
  }

  void setLogoPath(String? path) {
    if (path == null || path.isEmpty) {
      state = state.copyWith(clearLogoPath: true);
    } else {
      state = state.copyWith(logoPath: path);
    }
  }

  void setLogoUrl(String? url) {
    if (url == null || url.isEmpty) {
      state = state.copyWith(clearLogoUrl: true);
    } else {
      state = state.copyWith(logoUrl: url);
    }
  }

  void setSelectedColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  /// Check if community name is available
  Future<void> checkCommunityNameAvailability(String name) async {
    final trimmedName = name.trim();

    // If name is too short, don't check availability
    if (trimmedName.length < 3) {
      state = state.copyWith(
        nameAvailabilityStatus: NameAvailabilityStatus.tooShort,
        clearNameAvailabilityMessage: true,
      );
      return;
    }

    // Set checking status
    state = state.copyWith(
      nameAvailabilityStatus: NameAvailabilityStatus.checking,
      clearNameAvailabilityMessage: true,
    );

    try {
      final response = await _repository.checkCommunityNameAvailability(trimmedName);

      if (response.success) {
        state = state.copyWith(
          nameAvailabilityStatus: response.available
              ? NameAvailabilityStatus.available
              : NameAvailabilityStatus.taken,
          nameAvailabilityMessage: response.message,
        );
      } else {
        state = state.copyWith(
          nameAvailabilityStatus: NameAvailabilityStatus.error,
          nameAvailabilityMessage: response.message ?? 'Failed to check availability',
        );
      }
    } catch (e) {
      state = state.copyWith(
        nameAvailabilityStatus: NameAvailabilityStatus.error,
        nameAvailabilityMessage: 'Failed to check availability',
      );
    }
  }

  /// Reset name availability status
  void resetNameAvailability() {
    state = state.copyWith(
      nameAvailabilityStatus: NameAvailabilityStatus.idle,
      clearNameAvailabilityMessage: true,
    );
  }

  /// Upload logo image to Cloudinary
  Future<bool> uploadLogo() async {
    if (state.logoPath == null || state.logoPath!.isEmpty) {
      return true; // No logo to upload, that's OK
    }

    // Already uploaded
    if (state.logoUrl != null && state.logoUrl!.isNotEmpty) {
      return true;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _cloudinaryService.uploadImage(state.logoPath!);

    if (result.success && result.url != null) {
      state = state.copyWith(isLoading: false, logoUrl: result.url);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Failed to upload logo',
      );
      return false;
    }
  }

  // =====================
  // Step 2: Registration
  // =====================

  void setIsRegistered(bool value) {
    state = state.copyWith(isRegistered: value);
  }

  void setProofOfAddress(String? path, {String? url}) {
    state = state.copyWith(
      proofOfAddressPath: path,
      proofOfAddressUrl: url,
    );
  }

  void setCacDocument(String? path, {String? url}) {
    state = state.copyWith(
      cacDocumentPath: path,
      cacDocumentUrl: url,
    );
  }

  void setAddressVerification(String? path, {String? url}) {
    state = state.copyWith(
      addressVerificationPath: path,
      addressVerificationUrl: url,
    );
  }

  /// Upload all documents to Cloudinary
  Future<bool> uploadDocuments() async {
    if (!state.isRegistered) {
      return true; // No documents needed
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Upload proof of address
    if (state.proofOfAddressPath != null &&
        state.proofOfAddressPath!.isNotEmpty &&
        (state.proofOfAddressUrl == null || state.proofOfAddressUrl!.isEmpty)) {
      final result =
          await _cloudinaryService.uploadDocument(state.proofOfAddressPath!);
      if (result.success && result.url != null) {
        state = state.copyWith(proofOfAddressUrl: result.url);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Failed to upload Proof of Address',
        );
        return false;
      }
    }

    // Upload CAC document
    if (state.cacDocumentPath != null &&
        state.cacDocumentPath!.isNotEmpty &&
        (state.cacDocumentUrl == null || state.cacDocumentUrl!.isEmpty)) {
      final result =
          await _cloudinaryService.uploadDocument(state.cacDocumentPath!);
      if (result.success && result.url != null) {
        state = state.copyWith(cacDocumentUrl: result.url);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Failed to upload CAC Document',
        );
        return false;
      }
    }

    // Upload address verification
    if (state.addressVerificationPath != null &&
        state.addressVerificationPath!.isNotEmpty &&
        (state.addressVerificationUrl == null ||
            state.addressVerificationUrl!.isEmpty)) {
      final result =
          await _cloudinaryService.uploadDocument(state.addressVerificationPath!);
      if (result.success && result.url != null) {
        state = state.copyWith(addressVerificationUrl: result.url);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Failed to upload Address Verification',
        );
        return false;
      }
    }

    state = state.copyWith(isLoading: false);
    return true;
  }

  // =====================
  // Step 3: Create Community
  // =====================

  /// Create the community on the server
  Future<bool> createCommunity() async {
    if (!state.isBasicInfoComplete) {
      state = state.copyWith(error: 'Community name is required');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final request = CreateCommunityRequest(
        name: state.communityName.trim(),
        description: state.description?.trim(),
        logo: state.logoUrl,
        color: state.colorHex,
        isRegistered: state.isRegistered,
        proofOfAddress: state.proofOfAddressUrl,
        cacDocument: state.cacDocumentUrl,
        addressVerification: state.addressVerificationUrl,
      );

      final response = await _repository.createCommunity(request);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          isCreated: true,
          createdCommunity: response.community,
          inviteLink: response.inviteLink,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // =====================
  // Step 4: Invite Members
  // =====================

  void addMember(MemberToInvite member) {
    final updated = [...state.membersToInvite, member];
    state = state.copyWith(membersToInvite: updated);
  }

  void removeMember(int index) {
    final updated = [...state.membersToInvite];
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = state.copyWith(membersToInvite: updated);
    }
  }

  void clearMembers() {
    state = state.copyWith(membersToInvite: []);
  }

  void addMembersFromCsv(List<MemberToInvite> members) {
    final updated = [...state.membersToInvite, ...members];
    state = state.copyWith(membersToInvite: updated);
  }

  /// Send invites to all added members
  Future<SendInvitesResponse?> sendInvites() async {
    if (state.createdCommunity == null) {
      state = state.copyWith(error: 'Community not created yet');
      return null;
    }

    if (state.membersToInvite.isEmpty) {
      state = state.copyWith(error: 'No members to invite');
      return null;
    }

    // Filter members with valid emails
    final invites = state.membersToInvite
        .where((m) => m.email != null && m.email!.isNotEmpty)
        .map((m) => EmailInvite(email: m.email!, name: m.name))
        .toList();

    if (invites.isEmpty) {
      state = state.copyWith(error: 'No valid email addresses to send invites');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.sendEmailInvites(
        state.createdCommunity!.id,
        invites,
      );

      state = state.copyWith(isLoading: false);
      return response;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send invites',
      );
      return null;
    }
  }

  /// Get invite link (creates one if needed)
  Future<String?> getInviteLink() async {
    if (state.inviteLink != null) {
      return state.inviteLink;
    }

    if (state.createdCommunity == null) {
      return null;
    }

    try {
      final response = await _repository.getInviteLink(
        state.createdCommunity!.id,
      );

      if (response.success && response.inviteLink != null) {
        state = state.copyWith(inviteLink: response.inviteLink);
        return response.inviteLink;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // =====================
  // Utility
  // =====================

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const CommunityCreationState();
  }
}

/// Community Creation Provider
final communityCreationProvider =
    StateNotifierProvider<CommunityCreationNotifier, CommunityCreationState>(
        (ref) {
  return CommunityCreationNotifier(
    ref.watch(communityRepositoryProvider),
    ref.watch(cloudinaryServiceProvider),
  );
});
