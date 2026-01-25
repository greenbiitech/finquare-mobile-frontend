import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/network/api_config.dart';

/// Esusu Repository Provider
final esusuRepositoryProvider = Provider<EsusuRepository>((ref) {
  return EsusuRepository(ref.watch(apiClientProvider));
});

// =====================================================
// ENUMS
// =====================================================

/// Payment Frequency Enum
enum PaymentFrequency {
  weekly,
  monthly,
  quarterly;

  static PaymentFrequency fromString(String value) {
    switch (value.toUpperCase()) {
      case 'WEEKLY':
        return PaymentFrequency.weekly;
      case 'MONTHLY':
        return PaymentFrequency.monthly;
      case 'QUARTERLY':
        return PaymentFrequency.quarterly;
      default:
        return PaymentFrequency.monthly;
    }
  }

  String toApiString() {
    switch (this) {
      case PaymentFrequency.weekly:
        return 'WEEKLY';
      case PaymentFrequency.monthly:
        return 'MONTHLY';
      case PaymentFrequency.quarterly:
        return 'QUARTERLY';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
    }
  }
}

/// Payout Order Type Enum
enum PayoutOrderType {
  random,
  firstComeFirstServed;

  static PayoutOrderType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RANDOM':
        return PayoutOrderType.random;
      case 'FIRST_COME_FIRST_SERVED':
        return PayoutOrderType.firstComeFirstServed;
      default:
        return PayoutOrderType.random;
    }
  }

  String toApiString() {
    switch (this) {
      case PayoutOrderType.random:
        return 'RANDOM';
      case PayoutOrderType.firstComeFirstServed:
        return 'FIRST_COME_FIRST_SERVED';
    }
  }

  String get displayName {
    switch (this) {
      case PayoutOrderType.random:
        return 'Random Ballot';
      case PayoutOrderType.firstComeFirstServed:
        return 'First Come, First Served';
    }
  }

  String get description {
    switch (this) {
      case PayoutOrderType.random:
        return 'System randomly assigns payout order when Esusu starts';
      case PayoutOrderType.firstComeFirstServed:
        return 'First to accept invitation gets first payout';
    }
  }
}

/// Esusu Status Enum
enum EsusuStatus {
  pendingMembers,
  readyToStart,
  active,
  completed,
  cancelled,
  paused;

  static EsusuStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING_MEMBERS':
        return EsusuStatus.pendingMembers;
      case 'READY_TO_START':
        return EsusuStatus.readyToStart;
      case 'ACTIVE':
        return EsusuStatus.active;
      case 'COMPLETED':
        return EsusuStatus.completed;
      case 'CANCELLED':
        return EsusuStatus.cancelled;
      case 'PAUSED':
        return EsusuStatus.paused;
      default:
        return EsusuStatus.pendingMembers;
    }
  }
}

// =====================================================
// ELIGIBILITY MODELS
// =====================================================

/// Eligibility Reason
enum EsusuIneligibilityReason {
  notAdmin,
  insufficientMembers,
  noCommunityWallet,
  defaultCommunity,
  none;

  static EsusuIneligibilityReason fromString(String? value) {
    switch (value) {
      case 'NOT_ADMIN':
        return EsusuIneligibilityReason.notAdmin;
      case 'INSUFFICIENT_MEMBERS':
        return EsusuIneligibilityReason.insufficientMembers;
      case 'NO_COMMUNITY_WALLET':
        return EsusuIneligibilityReason.noCommunityWallet;
      case 'DEFAULT_COMMUNITY':
        return EsusuIneligibilityReason.defaultCommunity;
      default:
        return EsusuIneligibilityReason.none;
    }
  }
}

/// Esusu Eligibility Response Model
class EsusuEligibilityResponse {
  final bool success;
  final String communityId;
  final String communityName;
  final bool canCreateEsusu;
  final bool isAdmin;
  final int? memberCount;
  final bool? hasCommunityWallet;
  final EsusuIneligibilityReason reason;
  final String? message;

  EsusuEligibilityResponse({
    required this.success,
    required this.communityId,
    required this.communityName,
    required this.canCreateEsusu,
    required this.isAdmin,
    this.memberCount,
    this.hasCommunityWallet,
    required this.reason,
    this.message,
  });

  factory EsusuEligibilityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return EsusuEligibilityResponse(
      success: json['success'] ?? false,
      communityId: data?['communityId'] ?? '',
      communityName: data?['communityName'] ?? '',
      canCreateEsusu: data?['canCreateEsusu'] ?? false,
      isAdmin: data?['isAdmin'] ?? false,
      memberCount: data?['memberCount'],
      hasCommunityWallet: data?['hasCommunityWallet'],
      reason: EsusuIneligibilityReason.fromString(data?['reason']),
      message: data?['message'],
    );
  }
}

// =====================================================
// NAME AVAILABILITY MODELS
// =====================================================

/// Esusu Name Availability Response Model
class EsusuNameAvailabilityResponse {
  final bool success;
  final bool available;
  final String? message;

  EsusuNameAvailabilityResponse({
    required this.success,
    required this.available,
    this.message,
  });

  factory EsusuNameAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return EsusuNameAvailabilityResponse(
      success: json['success'] ?? false,
      available: data?['available'] ?? false,
      message: data?['message'],
    );
  }
}

// =====================================================
// COMMUNITY MEMBERS MODELS
// =====================================================

/// Esusu Community Member Model
class EsusuCommunityMember {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? photo;
  final String role;
  final bool isAdmin;

  EsusuCommunityMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.photo,
    required this.role,
    required this.isAdmin,
  });

  factory EsusuCommunityMember.fromJson(Map<String, dynamic> json) {
    return EsusuCommunityMember(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      photo: json['photo'],
      role: json['role'] ?? 'MEMBER',
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}

/// Esusu Community Members Response Model
class EsusuCommunityMembersResponse {
  final bool success;
  final String message;
  final List<EsusuCommunityMember> members;
  final int totalCount;

  EsusuCommunityMembersResponse({
    required this.success,
    required this.message,
    required this.members,
    required this.totalCount,
  });

  factory EsusuCommunityMembersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final membersList = data?['members'] as List<dynamic>? ?? [];

    return EsusuCommunityMembersResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      members: membersList
          .map((m) => EsusuCommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      totalCount: data?['totalCount'] ?? 0,
    );
  }
}

// =====================================================
// CREATE ESUSU MODELS
// =====================================================

/// Participant to add to Esusu
class EsusuParticipant {
  final String userId;

  EsusuParticipant({required this.userId});

  Map<String, dynamic> toJson() => {'userId': userId};
}

/// Create Esusu Request Model
class CreateEsusuRequest {
  final String communityId;
  final String name;
  final String? description;
  final String? iconUrl;
  final int numberOfParticipants;
  final double contributionAmount;
  final PaymentFrequency frequency;
  final DateTime participationDeadline;
  final DateTime collectionDate;
  final bool takeCommission;
  final int? commissionPercentage;
  final PayoutOrderType payoutOrderType;
  final List<EsusuParticipant> participants;

  CreateEsusuRequest({
    required this.communityId,
    required this.name,
    this.description,
    this.iconUrl,
    required this.numberOfParticipants,
    required this.contributionAmount,
    required this.frequency,
    required this.participationDeadline,
    required this.collectionDate,
    required this.takeCommission,
    this.commissionPercentage,
    required this.payoutOrderType,
    required this.participants,
  });

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (iconUrl != null && iconUrl!.isNotEmpty) 'iconUrl': iconUrl,
      'numberOfParticipants': numberOfParticipants,
      'contributionAmount': contributionAmount,
      'frequency': frequency.toApiString(),
      'participationDeadline': participationDeadline.toIso8601String(),
      'collectionDate': collectionDate.toIso8601String(),
      'takeCommission': takeCommission,
      if (takeCommission && commissionPercentage != null)
        'commissionPercentage': commissionPercentage,
      'payoutOrderType': payoutOrderType.toApiString(),
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}

/// Esusu Summary Model
class EsusuSummary {
  final double totalPool;
  final double platformFee;
  final double commission;
  final double netPayout;

  EsusuSummary({
    required this.totalPool,
    required this.platformFee,
    required this.commission,
    required this.netPayout,
  });

  factory EsusuSummary.fromJson(Map<String, dynamic> json) {
    return EsusuSummary(
      totalPool: (json['totalPool'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      netPayout: (json['netPayout'] ?? 0).toDouble(),
    );
  }
}

/// Created Esusu Model
class CreatedEsusu {
  final String id;
  final String name;
  final String? description;
  final EsusuStatus status;
  final int numberOfParticipants;
  final double contributionAmount;
  final PaymentFrequency frequency;
  final DateTime participationDeadline;
  final DateTime collectionDate;
  final bool takeCommission;
  final int? commissionPercentage;
  final PayoutOrderType payoutOrderType;
  final EsusuSummary summary;
  final String communityName;
  final DateTime createdAt;

  CreatedEsusu({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.numberOfParticipants,
    required this.contributionAmount,
    required this.frequency,
    required this.participationDeadline,
    required this.collectionDate,
    required this.takeCommission,
    this.commissionPercentage,
    required this.payoutOrderType,
    required this.summary,
    required this.communityName,
    required this.createdAt,
  });

  factory CreatedEsusu.fromJson(Map<String, dynamic> json) {
    return CreatedEsusu(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      status: EsusuStatus.fromString(json['status'] ?? 'PENDING_MEMBERS'),
      numberOfParticipants: json['numberOfParticipants'] ?? 0,
      contributionAmount: (json['contributionAmount'] ?? 0).toDouble(),
      frequency: PaymentFrequency.fromString(json['frequency'] ?? 'MONTHLY'),
      participationDeadline: DateTime.parse(
          json['participationDeadline'] ?? DateTime.now().toIso8601String()),
      collectionDate: DateTime.parse(
          json['collectionDate'] ?? DateTime.now().toIso8601String()),
      takeCommission: json['takeCommission'] ?? false,
      commissionPercentage: json['commissionPercentage'],
      payoutOrderType:
          PayoutOrderType.fromString(json['payoutOrderType'] ?? 'RANDOM'),
      summary: EsusuSummary.fromJson(json['summary'] ?? {}),
      communityName: json['communityName'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Create Esusu Response Model
class CreateEsusuResponse {
  final bool success;
  final String message;
  final CreatedEsusu? esusu;

  CreateEsusuResponse({
    required this.success,
    required this.message,
    this.esusu,
  });

  factory CreateEsusuResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return CreateEsusuResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      esusu: data != null ? CreatedEsusu.fromJson(data) : null,
    );
  }
}

// =====================================================
// REPOSITORY
// =====================================================

/// Esusu Repository
class EsusuRepository {
  final ApiClient _apiClient;

  EsusuRepository(this._apiClient);

  /// Check Esusu creation eligibility for a community
  Future<EsusuEligibilityResponse> checkEligibility(String communityId) async {
    final response = await _apiClient.get(
      ApiEndpoints.esusuEligibility(communityId),
    );
    return EsusuEligibilityResponse.fromJson(response.data);
  }

  /// Check if an Esusu name is available in the community
  Future<EsusuNameAvailabilityResponse> checkNameAvailability(
    String communityId,
    String name,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.esusuCheckName(communityId, name),
    );
    return EsusuNameAvailabilityResponse.fromJson(response.data);
  }

  /// Get community members for participant selection
  Future<EsusuCommunityMembersResponse> getCommunityMembers(
    String communityId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.esusuCommunityMembers(communityId),
    );
    return EsusuCommunityMembersResponse.fromJson(response.data);
  }

  /// Create a new Esusu
  Future<CreateEsusuResponse> createEsusu(CreateEsusuRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.esusu,
      data: request.toJson(),
    );
    return CreateEsusuResponse.fromJson(response.data);
  }

  /// Get Esusu count for Hub display
  Future<EsusuHubCountResponse> getHubCount(String communityId) async {
    final response = await _apiClient.get(
      ApiEndpoints.esusuHubCount(communityId),
    );
    return EsusuHubCountResponse.fromJson(response.data);
  }

  /// Get Esusu list
  Future<EsusuListResponse> getEsusuList(
    String communityId, {
    bool archived = false,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.esusuList(communityId)}${archived ? '?archived=true' : ''}',
    );
    return EsusuListResponse.fromJson(response.data);
  }
}

// =====================================================
// HUB COUNT MODELS
// =====================================================

/// Esusu Hub Count Response Model
class EsusuHubCountResponse {
  final bool success;
  final int total;
  final int active;
  final int pendingMembers;
  final int? pendingInvitation;
  final bool isAdmin;

  EsusuHubCountResponse({
    required this.success,
    required this.total,
    required this.active,
    required this.pendingMembers,
    this.pendingInvitation,
    required this.isAdmin,
  });

  factory EsusuHubCountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return EsusuHubCountResponse(
      success: json['success'] ?? false,
      total: data?['total'] ?? 0,
      active: data?['active'] ?? 0,
      pendingMembers: data?['pendingMembers'] ?? 0,
      pendingInvitation: data?['pendingInvitation'],
      isAdmin: data?['isAdmin'] ?? false,
    );
  }
}

// =====================================================
// ESUSU LIST MODELS
// =====================================================

/// Esusu List Item Model
class EsusuListItem {
  final String id;
  final String name;
  final EsusuStatus status;
  final EsusuInviteStatus? inviteStatus;
  final int? slotNumber;
  final String? iconUrl;
  final double contributionAmount;
  final PaymentFrequency frequency;
  final int numberOfParticipants;
  final int currentCycle;
  final int totalCycles;
  final DateTime? nextPayoutDate;
  final int? daysUntilPayout;
  final double progress;
  final int? acceptedCount;
  final int? pendingCount;
  final DateTime participationDeadline;
  final bool isCreator;
  final String creatorName;

  EsusuListItem({
    required this.id,
    required this.name,
    required this.status,
    this.inviteStatus,
    this.slotNumber,
    this.iconUrl,
    required this.contributionAmount,
    required this.frequency,
    required this.numberOfParticipants,
    required this.currentCycle,
    required this.totalCycles,
    this.nextPayoutDate,
    this.daysUntilPayout,
    required this.progress,
    this.acceptedCount,
    this.pendingCount,
    required this.participationDeadline,
    required this.isCreator,
    required this.creatorName,
  });

  factory EsusuListItem.fromJson(Map<String, dynamic> json) {
    return EsusuListItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: EsusuStatus.fromString(json['status'] ?? 'PENDING_MEMBERS'),
      inviteStatus: json['inviteStatus'] != null
          ? EsusuInviteStatus.fromString(json['inviteStatus'])
          : null,
      slotNumber: json['slotNumber'],
      iconUrl: json['iconUrl'],
      contributionAmount: (json['contributionAmount'] ?? 0).toDouble(),
      frequency: PaymentFrequency.fromString(json['frequency'] ?? 'MONTHLY'),
      numberOfParticipants: json['numberOfParticipants'] ?? 0,
      currentCycle: json['currentCycle'] ?? 0,
      totalCycles: json['totalCycles'] ?? 0,
      nextPayoutDate: json['nextPayoutDate'] != null
          ? DateTime.parse(json['nextPayoutDate'])
          : null,
      daysUntilPayout: json['daysUntilPayout'],
      progress: (json['progress'] ?? 0).toDouble(),
      acceptedCount: json['acceptedCount'],
      pendingCount: json['pendingCount'],
      participationDeadline: DateTime.parse(
          json['participationDeadline'] ?? DateTime.now().toIso8601String()),
      isCreator: json['isCreator'] ?? false,
      creatorName: json['creatorName'] ?? '',
    );
  }
}

/// Esusu Invite Status Enum
enum EsusuInviteStatus {
  invited,
  accepted,
  declined,
  expired;

  static EsusuInviteStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INVITED':
        return EsusuInviteStatus.invited;
      case 'ACCEPTED':
        return EsusuInviteStatus.accepted;
      case 'DECLINED':
        return EsusuInviteStatus.declined;
      case 'EXPIRED':
        return EsusuInviteStatus.expired;
      default:
        return EsusuInviteStatus.invited;
    }
  }

  String get displayName {
    switch (this) {
      case EsusuInviteStatus.invited:
        return 'Invited';
      case EsusuInviteStatus.accepted:
        return 'Accepted';
      case EsusuInviteStatus.declined:
        return 'Declined';
      case EsusuInviteStatus.expired:
        return 'Expired';
    }
  }
}

/// Esusu List Response Model
class EsusuListResponse {
  final bool success;
  final List<EsusuListItem> esusus;
  final bool isAdmin;

  EsusuListResponse({
    required this.success,
    required this.esusus,
    required this.isAdmin,
  });

  factory EsusuListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final esususList = data?['esusus'] as List<dynamic>? ?? [];

    return EsusuListResponse(
      success: json['success'] ?? false,
      esusus: esususList
          .map((e) => EsusuListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAdmin: data?['isAdmin'] ?? false,
    );
  }
}
