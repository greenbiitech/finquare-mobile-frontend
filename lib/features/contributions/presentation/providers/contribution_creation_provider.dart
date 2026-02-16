import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/services/cloudinary_service.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';

// Re-export types from repository for convenience
export 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart'
    show
        ContributionType,
        RecipientType,
        ParticipantVisibility,
        ContributionStatus,
        ContributionInviteStatus,
        ContributionCommunityMember,
        CreatedContribution;

/// Contribution Creation State
/// Holds all data collected during the Contribution creation flow
class ContributionCreationState {
  // Community context
  final String? communityId;
  final String? communityName;
  final int? memberCount;

  // Screen 1: Create New (Basic Info)
  final String contributionName;
  final String? description;
  final String? iconPath; // Local file path
  final String? iconUrl; // Uploaded URL

  // Screen 2: Configure
  final ContributionType? type;
  final double? amount; // For Fixed (contribution amount) or Target (target amount)
  final DateTime? startDate;
  final DateTime? deadline;
  final RecipientType recipientType;
  final String? recipientId;
  final String? recipientName;
  final ParticipantVisibility visibility;
  final bool notifyRecipient;

  // Screen 3: Participants
  final List<ContributionCommunityMember> availableMembers;
  final List<ContributionCommunityMember> selectedParticipants;

  // Created Contribution (after API call)
  final CreatedContribution? createdContribution;

  // UI State
  final bool isLoading;
  final String? error;
  final bool isCreated;

  const ContributionCreationState({
    this.communityId,
    this.communityName,
    this.memberCount,
    this.contributionName = '',
    this.description,
    this.iconPath,
    this.iconUrl,
    this.type,
    this.amount,
    this.startDate,
    this.deadline,
    this.recipientType = RecipientType.communityWallet,
    this.recipientId,
    this.recipientName,
    this.visibility = ParticipantVisibility.viewAll,
    this.notifyRecipient = false,
    this.availableMembers = const [],
    this.selectedParticipants = const [],
    this.createdContribution,
    this.isLoading = false,
    this.error,
    this.isCreated = false,
  });

  ContributionCreationState copyWith({
    String? communityId,
    String? communityName,
    int? memberCount,
    String? contributionName,
    String? description,
    String? iconPath,
    String? iconUrl,
    ContributionType? type,
    double? amount,
    DateTime? startDate,
    DateTime? deadline,
    RecipientType? recipientType,
    String? recipientId,
    String? recipientName,
    ParticipantVisibility? visibility,
    bool? notifyRecipient,
    List<ContributionCommunityMember>? availableMembers,
    List<ContributionCommunityMember>? selectedParticipants,
    CreatedContribution? createdContribution,
    bool? isLoading,
    String? error,
    bool? isCreated,
    bool clearError = false,
    bool clearDescription = false,
    bool clearIconPath = false,
    bool clearIconUrl = false,
    bool clearAmount = false,
    bool clearDeadline = false,
    bool clearRecipientId = false,
    bool clearRecipientName = false,
  }) {
    return ContributionCreationState(
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      memberCount: memberCount ?? this.memberCount,
      contributionName: contributionName ?? this.contributionName,
      description: clearDescription ? null : (description ?? this.description),
      iconPath: clearIconPath ? null : (iconPath ?? this.iconPath),
      iconUrl: clearIconUrl ? null : (iconUrl ?? this.iconUrl),
      type: type ?? this.type,
      amount: clearAmount ? null : (amount ?? this.amount),
      startDate: startDate ?? this.startDate,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      recipientType: recipientType ?? this.recipientType,
      recipientId: clearRecipientId ? null : (recipientId ?? this.recipientId),
      recipientName: clearRecipientName ? null : (recipientName ?? this.recipientName),
      visibility: visibility ?? this.visibility,
      notifyRecipient: notifyRecipient ?? this.notifyRecipient,
      availableMembers: availableMembers ?? this.availableMembers,
      selectedParticipants: selectedParticipants ?? this.selectedParticipants,
      createdContribution: createdContribution ?? this.createdContribution,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCreated: isCreated ?? this.isCreated,
    );
  }

  // =====================
  // Computed Properties
  // =====================

  /// Check if basic info (Screen 1) is complete
  bool get isBasicInfoComplete => contributionName.trim().length >= 3;

  /// Check if configure (Screen 2) is complete
  bool get isConfigureComplete {
    if (type == null) return false;
    if (startDate == null) return false;

    // Fixed type requires contribution amount
    if (type == ContributionType.fixed && (amount == null || amount! < 100)) {
      return false;
    }

    // Target type requires target amount
    if (type == ContributionType.target && (amount == null || amount! < 100)) {
      return false;
    }

    // Flexible type doesn't require amount

    // If recipient is a member, we need recipientId
    if (recipientType == RecipientType.member && recipientId == null) {
      return false;
    }

    return true;
  }

  /// Check if participants (Screen 3) is complete - at least 1 participant
  bool get isParticipantsComplete => selectedParticipants.isNotEmpty;

  /// Check if all screens are complete
  bool get isReadyToCreate =>
      isBasicInfoComplete && isConfigureComplete && isParticipantsComplete;

  /// Get participants count
  int get participantCount => selectedParticipants.length;

  /// Check if amount field should be shown
  bool get showAmountField =>
      type == ContributionType.fixed || type == ContributionType.target;

  /// Get amount label based on type
  String get amountLabel {
    switch (type) {
      case ContributionType.fixed:
        return 'Contribution Amount';
      case ContributionType.target:
        return 'Target Amount';
      default:
        return 'Amount';
    }
  }

  /// Get eligible members (those with active wallets)
  List<ContributionCommunityMember> get eligibleMembers =>
      availableMembers.where((m) => m.hasActiveWallet).toList();

  /// Get ineligible members (those without active wallets)
  List<ContributionCommunityMember> get ineligibleMembers =>
      availableMembers.where((m) => !m.hasActiveWallet).toList();
}

/// Contribution Creation Notifier
class ContributionCreationNotifier extends StateNotifier<ContributionCreationState> {
  final ContributionsRepository _repository;
  final CloudinaryService _cloudinaryService;

  ContributionCreationNotifier(this._repository, this._cloudinaryService)
      : super(const ContributionCreationState());

  // =====================
  // Community Context
  // =====================

  void setCommunityContext({
    required String communityId,
    required String communityName,
    required int memberCount,
  }) {
    state = state.copyWith(
      communityId: communityId,
      communityName: communityName,
      memberCount: memberCount,
    );
  }

  // =====================
  // Screen 1: Basic Info
  // =====================

  void setContributionName(String name) {
    state = state.copyWith(contributionName: name);
  }

  void setDescription(String? description) {
    if (description == null || description.isEmpty) {
      state = state.copyWith(clearDescription: true);
    } else {
      state = state.copyWith(description: description);
    }
  }

  void setIconPath(String? path) {
    if (path == null || path.isEmpty) {
      state = state.copyWith(clearIconPath: true);
    } else {
      state = state.copyWith(iconPath: path);
    }
  }

  /// Upload icon image to Cloudinary
  Future<bool> uploadIcon() async {
    if (state.iconPath == null || state.iconPath!.isEmpty) {
      return true; // No icon to upload, that's OK
    }

    // Already uploaded
    if (state.iconUrl != null && state.iconUrl!.isNotEmpty) {
      return true;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _cloudinaryService.uploadImage(state.iconPath!);

    if (result.success && result.url != null) {
      state = state.copyWith(isLoading: false, iconUrl: result.url);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Failed to upload icon',
      );
      return false;
    }
  }

  // =====================
  // Screen 2: Configure
  // =====================

  void setType(ContributionType type) {
    // Clear amount when switching to flexible (no amount needed)
    if (type == ContributionType.flexible) {
      state = state.copyWith(type: type, clearAmount: true);
    } else {
      state = state.copyWith(type: type);
    }
  }

  void setAmount(double? amount) {
    if (amount == null) {
      state = state.copyWith(clearAmount: true);
    } else {
      state = state.copyWith(amount: amount);
    }
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void setDeadline(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDeadline: true);
    } else {
      state = state.copyWith(deadline: date);
    }
  }

  void setRecipientType(RecipientType type) {
    // Clear recipient details when switching to community wallet
    if (type == RecipientType.communityWallet) {
      state = state.copyWith(
        recipientType: type,
        clearRecipientId: true,
        clearRecipientName: true,
      );
    } else {
      state = state.copyWith(recipientType: type);
    }
  }

  void setRecipient(String id, String name) {
    state = state.copyWith(recipientId: id, recipientName: name);
  }

  void setVisibility(ParticipantVisibility visibility) {
    state = state.copyWith(visibility: visibility);
  }

  void setNotifyRecipient(bool value) {
    state = state.copyWith(notifyRecipient: value);
  }

  // =====================
  // Screen 3: Participants
  // =====================

  /// Load community members for selection
  Future<void> loadCommunityMembers() async {
    if (state.communityId == null) {
      state = state.copyWith(error: 'Community not selected');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response =
          await _repository.getCommunityMembers(state.communityId!);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          availableMembers: response.members,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load members',
      );
    }
  }

  void addParticipant(ContributionCommunityMember member) {
    // Check if member is eligible (has wallet)
    if (!member.hasActiveWallet) {
      return;
    }

    // Check if already selected
    if (state.selectedParticipants.any((p) => p.id == member.id)) {
      return;
    }

    final updated = [...state.selectedParticipants, member];
    state = state.copyWith(selectedParticipants: updated);
  }

  void removeParticipant(String memberId) {
    final updated =
        state.selectedParticipants.where((p) => p.id != memberId).toList();
    state = state.copyWith(selectedParticipants: updated);
  }

  void toggleParticipant(ContributionCommunityMember member) {
    if (state.selectedParticipants.any((p) => p.id == member.id)) {
      removeParticipant(member.id);
    } else {
      addParticipant(member);
    }
  }

  void addAllEligibleMembers() {
    final eligible = state.availableMembers.where((m) => m.hasActiveWallet).toList();
    state = state.copyWith(selectedParticipants: eligible);
  }

  void clearParticipants() {
    state = state.copyWith(selectedParticipants: []);
  }

  // =====================
  // Create Contribution
  // =====================

  /// Create the Contribution on the server
  Future<bool> createContribution() async {
    if (state.communityId == null) {
      state = state.copyWith(error: 'Community not selected');
      return false;
    }

    if (!state.isBasicInfoComplete) {
      state = state.copyWith(error: 'Please complete basic info');
      return false;
    }

    if (!state.isConfigureComplete) {
      state = state.copyWith(error: 'Please complete configuration');
      return false;
    }

    if (!state.isParticipantsComplete) {
      state = state.copyWith(error: 'Please select at least one participant');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Upload icon if needed
      if (state.iconPath != null &&
          state.iconPath!.isNotEmpty &&
          (state.iconUrl == null || state.iconUrl!.isEmpty)) {
        final uploadSuccess = await uploadIcon();
        if (!uploadSuccess) {
          return false;
        }
      }

      final request = CreateContributionRequest(
        communityId: state.communityId!,
        name: state.contributionName.trim(),
        description: state.description?.trim(),
        imageUrl: state.iconUrl,
        type: state.type!,
        amount: state.amount,
        startDate: state.startDate!,
        deadline: state.deadline,
        recipientType: state.recipientType,
        recipientId: state.recipientType == RecipientType.member
            ? state.recipientId
            : null,
        visibility: state.visibility,
        notifyRecipient: state.notifyRecipient,
        participants: state.selectedParticipants
            .map((m) => ContributionParticipant(memberId: m.id))
            .toList(),
      );

      final response = await _repository.createContribution(request);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          isCreated: true,
          createdContribution: response.contribution,
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
  // Utility
  // =====================

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const ContributionCreationState();
  }
}

/// Contribution Creation Provider
final contributionCreationProvider =
    StateNotifierProvider<ContributionCreationNotifier, ContributionCreationState>((ref) {
  return ContributionCreationNotifier(
    ref.watch(contributionsRepositoryProvider),
    ref.watch(cloudinaryServiceProvider),
  );
});
