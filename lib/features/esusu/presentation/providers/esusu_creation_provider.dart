import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/services/cloudinary_service.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';

// Re-export CommissionType from repository for convenience
export 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart' show CommissionType;

/// Name availability status
enum EsusuNameAvailabilityStatus {
  idle,
  checking,
  available,
  taken,
  tooShort,
  error,
}

/// Esusu Creation State
/// Holds all data collected during the Esusu creation flow
class EsusuCreationState {
  // Community context
  final String? communityId;
  final String? communityName;
  final int? memberCount;

  // Screen 2: Create New (Basic Info)
  final String esusuName;
  final String? description;
  final String? iconPath; // Local file path
  final String? iconUrl; // Uploaded URL

  // Name availability check
  final EsusuNameAvailabilityStatus nameAvailabilityStatus;
  final String? nameAvailabilityMessage;

  // Screen 3: Configure
  final int? numberOfParticipants;
  final double? contributionAmount;
  final PaymentFrequency? frequency;
  final DateTime? participationDeadline;
  final DateTime? collectionDate;
  final bool takeCommission;
  final CommissionType commissionType;
  final int? commissionPercentage; // For percentage type (5, 10, 15... 50)
  final double? commissionAmount; // For cash type (fixed amount)

  // Screen 4: Participants
  final List<EsusuCommunityMember> availableMembers;
  final List<EsusuCommunityMember> selectedParticipants;

  // Screen 5: Payout Order
  final PayoutOrderType? payoutOrderType;

  // Admin's pre-selected slot (for FCFS when admin is participating)
  final int? adminSelectedSlot;

  // Created Esusu (after API call)
  final CreatedEsusu? createdEsusu;

  // UI State
  final bool isLoading;
  final String? error;
  final bool isCreated;

  const EsusuCreationState({
    this.communityId,
    this.communityName,
    this.memberCount,
    this.esusuName = '',
    this.description,
    this.iconPath,
    this.iconUrl,
    this.nameAvailabilityStatus = EsusuNameAvailabilityStatus.idle,
    this.nameAvailabilityMessage,
    this.numberOfParticipants,
    this.contributionAmount,
    this.frequency,
    this.participationDeadline,
    this.collectionDate,
    this.takeCommission = false,
    this.commissionType = CommissionType.cash,
    this.commissionPercentage,
    this.commissionAmount,
    this.availableMembers = const [],
    this.selectedParticipants = const [],
    this.payoutOrderType,
    this.adminSelectedSlot,
    this.createdEsusu,
    this.isLoading = false,
    this.error,
    this.isCreated = false,
  });

  EsusuCreationState copyWith({
    String? communityId,
    String? communityName,
    int? memberCount,
    String? esusuName,
    String? description,
    String? iconPath,
    String? iconUrl,
    EsusuNameAvailabilityStatus? nameAvailabilityStatus,
    String? nameAvailabilityMessage,
    int? numberOfParticipants,
    double? contributionAmount,
    PaymentFrequency? frequency,
    DateTime? participationDeadline,
    DateTime? collectionDate,
    bool? takeCommission,
    CommissionType? commissionType,
    int? commissionPercentage,
    double? commissionAmount,
    List<EsusuCommunityMember>? availableMembers,
    List<EsusuCommunityMember>? selectedParticipants,
    PayoutOrderType? payoutOrderType,
    int? adminSelectedSlot,
    CreatedEsusu? createdEsusu,
    bool? isLoading,
    String? error,
    bool? isCreated,
    bool clearError = false,
    bool clearAdminSelectedSlot = false,
    bool clearDescription = false,
    bool clearIconPath = false,
    bool clearIconUrl = false,
    bool clearNameAvailabilityMessage = false,
    bool clearCommissionPercentage = false,
    bool clearCommissionAmount = false,
  }) {
    return EsusuCreationState(
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      memberCount: memberCount ?? this.memberCount,
      esusuName: esusuName ?? this.esusuName,
      description: clearDescription ? null : (description ?? this.description),
      iconPath: clearIconPath ? null : (iconPath ?? this.iconPath),
      iconUrl: clearIconUrl ? null : (iconUrl ?? this.iconUrl),
      nameAvailabilityStatus:
          nameAvailabilityStatus ?? this.nameAvailabilityStatus,
      nameAvailabilityMessage: clearNameAvailabilityMessage
          ? null
          : (nameAvailabilityMessage ?? this.nameAvailabilityMessage),
      numberOfParticipants: numberOfParticipants ?? this.numberOfParticipants,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      frequency: frequency ?? this.frequency,
      participationDeadline:
          participationDeadline ?? this.participationDeadline,
      collectionDate: collectionDate ?? this.collectionDate,
      takeCommission: takeCommission ?? this.takeCommission,
      commissionType: commissionType ?? this.commissionType,
      commissionPercentage: clearCommissionPercentage
          ? null
          : (commissionPercentage ?? this.commissionPercentage),
      commissionAmount: clearCommissionAmount
          ? null
          : (commissionAmount ?? this.commissionAmount),
      availableMembers: availableMembers ?? this.availableMembers,
      selectedParticipants: selectedParticipants ?? this.selectedParticipants,
      payoutOrderType: payoutOrderType ?? this.payoutOrderType,
      adminSelectedSlot: clearAdminSelectedSlot
          ? null
          : (adminSelectedSlot ?? this.adminSelectedSlot),
      createdEsusu: createdEsusu ?? this.createdEsusu,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCreated: isCreated ?? this.isCreated,
    );
  }

  // =====================
  // Computed Properties
  // =====================

  /// Check if basic info (Screen 2) is complete
  bool get isBasicInfoComplete => esusuName.trim().length >= 3;

  /// Check if basic info is complete and name is available
  bool get isBasicInfoCompleteAndAvailable =>
      esusuName.trim().length >= 3 &&
      nameAvailabilityStatus == EsusuNameAvailabilityStatus.available;

  /// Check if configure (Screen 3) is complete
  bool get isConfigureComplete {
    // Basic requirements
    if (numberOfParticipants == null || numberOfParticipants! < 3) return false;
    if (contributionAmount == null || contributionAmount! < 100) return false;
    if (frequency == null) return false;
    if (participationDeadline == null) return false;
    if (collectionDate == null) return false;

    // Commission validation if enabled
    if (takeCommission) {
      if (commissionType == CommissionType.percentage) {
        if (commissionPercentage == null) return false;
        if (commissionPercentage! < 5 || commissionPercentage! > 50) return false;
      } else {
        // Cash type
        if (commissionAmount == null || commissionAmount! <= 0) return false;
      }
    }

    return true;
  }

  /// Check if participants (Screen 4) is complete
  bool get isParticipantsComplete =>
      numberOfParticipants != null &&
      selectedParticipants.length == numberOfParticipants;

  /// Check if payout order (Screen 5) is selected
  bool get isPayoutOrderSelected => payoutOrderType != null;

  /// Check if admin (current user) is participating in the Esusu
  bool get isAdminParticipating =>
      selectedParticipants.any((p) => p.isCurrentUser);

  /// Check if admin needs to select slot during creation
  /// This is true when: (1) Admin is participating AND (2) Payout order is FCFS
  bool get adminNeedsSlotSelection =>
      isAdminParticipating &&
      payoutOrderType == PayoutOrderType.firstComeFirstServed;

  /// Calculate total pool
  double get totalPool {
    if (numberOfParticipants == null || contributionAmount == null) return 0;
    return numberOfParticipants! * contributionAmount!;
  }

  /// Calculate platform fee (1.5%)
  double get platformFee => totalPool * 0.015;

  /// Calculate commission
  double get commission {
    if (!takeCommission) return 0;

    if (commissionType == CommissionType.percentage) {
      if (commissionPercentage == null) return 0;
      return totalPool * commissionPercentage! / 100;
    } else {
      // Cash type - fixed amount
      return commissionAmount ?? 0;
    }
  }

  /// Calculate net payout per cycle
  double get netPayout => totalPool - platformFee - commission;

  /// Get minimum collection date (participation deadline + 24 hours)
  DateTime? get minimumCollectionDate {
    if (participationDeadline == null) return null;
    return participationDeadline!.add(const Duration(hours: 24));
  }

  /// Max participants based on community member count
  int get maxParticipants => memberCount ?? 3;
}

/// Esusu Creation Notifier
class EsusuCreationNotifier extends StateNotifier<EsusuCreationState> {
  final EsusuRepository _repository;
  final CloudinaryService _cloudinaryService;

  EsusuCreationNotifier(this._repository, this._cloudinaryService)
      : super(const EsusuCreationState());

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
  // Screen 2: Basic Info
  // =====================

  void setEsusuName(String name) {
    state = state.copyWith(esusuName: name);
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

  /// Check if Esusu name is available in the community
  Future<void> checkNameAvailability(String name) async {
    final trimmedName = name.trim();

    if (state.communityId == null) {
      state = state.copyWith(
        nameAvailabilityStatus: EsusuNameAvailabilityStatus.error,
        nameAvailabilityMessage: 'Community not selected',
      );
      return;
    }

    if (trimmedName.length < 3) {
      state = state.copyWith(
        nameAvailabilityStatus: EsusuNameAvailabilityStatus.tooShort,
        clearNameAvailabilityMessage: true,
      );
      return;
    }

    state = state.copyWith(
      nameAvailabilityStatus: EsusuNameAvailabilityStatus.checking,
      clearNameAvailabilityMessage: true,
    );

    try {
      final response = await _repository.checkNameAvailability(
        state.communityId!,
        trimmedName,
      );

      if (response.success) {
        state = state.copyWith(
          nameAvailabilityStatus: response.available
              ? EsusuNameAvailabilityStatus.available
              : EsusuNameAvailabilityStatus.taken,
          nameAvailabilityMessage: response.message,
        );
      } else {
        state = state.copyWith(
          nameAvailabilityStatus: EsusuNameAvailabilityStatus.error,
          nameAvailabilityMessage:
              response.message ?? 'Failed to check availability',
        );
      }
    } catch (e) {
      state = state.copyWith(
        nameAvailabilityStatus: EsusuNameAvailabilityStatus.error,
        nameAvailabilityMessage: 'Failed to check availability',
      );
    }
  }

  void resetNameAvailability() {
    state = state.copyWith(
      nameAvailabilityStatus: EsusuNameAvailabilityStatus.idle,
      clearNameAvailabilityMessage: true,
    );
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
  // Screen 3: Configure
  // =====================

  void setNumberOfParticipants(int count) {
    // Clear selected participants if count changes
    if (state.numberOfParticipants != count) {
      state = state.copyWith(
        numberOfParticipants: count,
        selectedParticipants: [],
      );
    } else {
      state = state.copyWith(numberOfParticipants: count);
    }
  }

  void setContributionAmount(double amount) {
    state = state.copyWith(contributionAmount: amount);
  }

  void setFrequency(PaymentFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void setParticipationDeadline(DateTime date) {
    // If collection date is before the new minimum, update it
    final minCollectionDate = date.add(const Duration(hours: 24));
    if (state.collectionDate != null &&
        state.collectionDate!.isBefore(minCollectionDate)) {
      state = state.copyWith(
        participationDeadline: date,
        collectionDate: minCollectionDate,
      );
    } else {
      state = state.copyWith(participationDeadline: date);
    }
  }

  void setCollectionDate(DateTime date) {
    state = state.copyWith(collectionDate: date);
  }

  void setTakeCommission(bool value) {
    if (!value) {
      state = state.copyWith(
        takeCommission: false,
        clearCommissionPercentage: true,
        clearCommissionAmount: true,
      );
    } else {
      state = state.copyWith(takeCommission: true);
    }
  }

  void setCommissionType(CommissionType type) {
    // Clear the other commission value when switching types
    if (type == CommissionType.cash) {
      state = state.copyWith(
        commissionType: type,
        clearCommissionPercentage: true,
      );
    } else {
      state = state.copyWith(
        commissionType: type,
        clearCommissionAmount: true,
      );
    }
  }

  void setCommissionPercentage(int? percentage) {
    if (percentage == null) {
      state = state.copyWith(clearCommissionPercentage: true);
    } else {
      state = state.copyWith(commissionPercentage: percentage);
    }
  }

  void setCommissionAmount(double? amount) {
    if (amount == null) {
      state = state.copyWith(clearCommissionAmount: true);
    } else {
      state = state.copyWith(commissionAmount: amount);
    }
  }

  // =====================
  // Screen 4: Participants
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

  void addParticipant(EsusuCommunityMember member) {
    if (state.numberOfParticipants == null) return;

    // Check if already at max
    if (state.selectedParticipants.length >= state.numberOfParticipants!) {
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

  void toggleParticipant(EsusuCommunityMember member) {
    if (state.selectedParticipants.any((p) => p.id == member.id)) {
      removeParticipant(member.id);
    } else {
      addParticipant(member);
    }
  }

  void clearParticipants() {
    state = state.copyWith(selectedParticipants: []);
  }

  // =====================
  // Screen 5: Payout Order
  // =====================

  void setPayoutOrderType(PayoutOrderType type) {
    // Clear admin slot if switching away from FCFS
    if (type != PayoutOrderType.firstComeFirstServed) {
      state = state.copyWith(
        payoutOrderType: type,
        clearAdminSelectedSlot: true,
      );
    } else {
      state = state.copyWith(payoutOrderType: type);
    }
  }

  void setAdminSelectedSlot(int? slot) {
    if (slot == null) {
      state = state.copyWith(clearAdminSelectedSlot: true);
    } else {
      state = state.copyWith(adminSelectedSlot: slot);
    }
  }

  // =====================
  // Create Esusu
  // =====================

  /// Create the Esusu on the server
  Future<bool> createEsusu() async {
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
      state = state.copyWith(error: 'Please select all participants');
      return false;
    }

    if (!state.isPayoutOrderSelected) {
      state = state.copyWith(error: 'Please select payout order');
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

      final request = CreateEsusuRequest(
        communityId: state.communityId!,
        name: state.esusuName.trim(),
        description: state.description?.trim(),
        iconUrl: state.iconUrl,
        numberOfParticipants: state.numberOfParticipants!,
        contributionAmount: state.contributionAmount!,
        frequency: state.frequency!,
        participationDeadline: state.participationDeadline!,
        collectionDate: state.collectionDate!,
        takeCommission: state.takeCommission,
        commissionType: state.takeCommission ? state.commissionType : null,
        commissionPercentage: state.takeCommission && state.commissionType == CommissionType.percentage
            ? state.commissionPercentage
            : null,
        commissionAmount: state.takeCommission && state.commissionType == CommissionType.cash
            ? state.commissionAmount
            : null,
        payoutOrderType: state.payoutOrderType!,
        participants: state.selectedParticipants
            .map((m) => EsusuParticipant(userId: m.id))
            .toList(),
        adminSlot: state.adminSelectedSlot,
      );

      final response = await _repository.createEsusu(request);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          isCreated: true,
          createdEsusu: response.esusu,
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
    state = const EsusuCreationState();
  }
}

/// Esusu Creation Provider
final esusuCreationProvider =
    StateNotifierProvider<EsusuCreationNotifier, EsusuCreationState>((ref) {
  return EsusuCreationNotifier(
    ref.watch(esusuRepositoryProvider),
    ref.watch(cloudinaryServiceProvider),
  );
});
