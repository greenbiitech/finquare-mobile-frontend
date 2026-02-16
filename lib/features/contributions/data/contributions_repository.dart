import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/network/api_config.dart';

/// Contributions Repository Provider
final contributionsRepositoryProvider = Provider<ContributionsRepository>((ref) {
  return ContributionsRepository(ref.watch(apiClientProvider));
});

/// Refresh trigger for Contribution List
/// Increment this to force ContributionListPage to refresh its data
final contributionListRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Refresh trigger for Hub Page (Contributions section)
/// Increment this to force HubPage to refresh its Contribution data
final contributionHubRefreshTriggerProvider = StateProvider<int>((ref) => 0);

// =====================================================
// ENUMS
// =====================================================

/// Contribution Type Enum
enum ContributionType {
  fixed,
  target,
  flexible;

  static ContributionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FIXED':
        return ContributionType.fixed;
      case 'TARGET':
        return ContributionType.target;
      case 'FLEXIBLE':
        return ContributionType.flexible;
      default:
        return ContributionType.fixed;
    }
  }

  String toApiString() {
    switch (this) {
      case ContributionType.fixed:
        return 'FIXED';
      case ContributionType.target:
        return 'TARGET';
      case ContributionType.flexible:
        return 'FLEXIBLE';
    }
  }

  String get displayName {
    switch (this) {
      case ContributionType.fixed:
        return 'Fixed';
      case ContributionType.target:
        return 'Target';
      case ContributionType.flexible:
        return 'Flexible';
    }
  }

  String get description {
    switch (this) {
      case ContributionType.fixed:
        return 'Everyone contributes the same amount';
      case ContributionType.target:
        return 'Work towards a specific goal amount';
      case ContributionType.flexible:
        return 'Contribute any amount at will';
    }
  }
}

/// Contribution Status Enum
enum ContributionStatus {
  pendingInvites,
  active,
  completed,
  cancelled;

  static ContributionStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING_INVITES':
        return ContributionStatus.pendingInvites;
      case 'ACTIVE':
        return ContributionStatus.active;
      case 'COMPLETED':
        return ContributionStatus.completed;
      case 'CANCELLED':
        return ContributionStatus.cancelled;
      default:
        return ContributionStatus.pendingInvites;
    }
  }

  String get displayName {
    switch (this) {
      case ContributionStatus.pendingInvites:
        return 'Pending Invites';
      case ContributionStatus.active:
        return 'Active';
      case ContributionStatus.completed:
        return 'Completed';
      case ContributionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Recipient Type Enum
enum RecipientType {
  communityWallet,
  member;

  static RecipientType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMMUNITY_WALLET':
        return RecipientType.communityWallet;
      case 'MEMBER':
        return RecipientType.member;
      default:
        return RecipientType.communityWallet;
    }
  }

  String toApiString() {
    switch (this) {
      case RecipientType.communityWallet:
        return 'COMMUNITY_WALLET';
      case RecipientType.member:
        return 'MEMBER';
    }
  }

  String get displayName {
    switch (this) {
      case RecipientType.communityWallet:
        return 'Community Wallet';
      case RecipientType.member:
        return 'Member';
    }
  }
}

/// Participant Visibility Enum
enum ParticipantVisibility {
  viewAll,
  viewOwnOnly;

  static ParticipantVisibility fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VIEW_ALL':
        return ParticipantVisibility.viewAll;
      case 'VIEW_OWN_ONLY':
        return ParticipantVisibility.viewOwnOnly;
      default:
        return ParticipantVisibility.viewAll;
    }
  }

  String toApiString() {
    switch (this) {
      case ParticipantVisibility.viewAll:
        return 'VIEW_ALL';
      case ParticipantVisibility.viewOwnOnly:
        return 'VIEW_OWN_ONLY';
    }
  }

  String get displayName {
    switch (this) {
      case ParticipantVisibility.viewAll:
        return 'View All Contributions';
      case ParticipantVisibility.viewOwnOnly:
        return 'View Own Only';
    }
  }

  String get description {
    switch (this) {
      case ParticipantVisibility.viewAll:
        return 'Participants can see all contributions';
      case ParticipantVisibility.viewOwnOnly:
        return 'Participants can only see their own contributions';
    }
  }
}

/// Contribution Invite Status Enum
enum ContributionInviteStatus {
  invited,
  accepted,
  declined;

  static ContributionInviteStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INVITED':
        return ContributionInviteStatus.invited;
      case 'ACCEPTED':
        return ContributionInviteStatus.accepted;
      case 'DECLINED':
        return ContributionInviteStatus.declined;
      default:
        return ContributionInviteStatus.invited;
    }
  }

  String get displayName {
    switch (this) {
      case ContributionInviteStatus.invited:
        return 'Invited';
      case ContributionInviteStatus.accepted:
        return 'Accepted';
      case ContributionInviteStatus.declined:
        return 'Declined';
    }
  }
}

// =====================================================
// ELIGIBILITY MODELS
// =====================================================

/// Eligibility Reason
enum ContributionIneligibilityReason {
  notAdmin,
  noCommunityWallet,
  none;

  static ContributionIneligibilityReason fromString(String? value) {
    switch (value) {
      case 'NOT_ADMIN':
        return ContributionIneligibilityReason.notAdmin;
      case 'NO_COMMUNITY_WALLET':
        return ContributionIneligibilityReason.noCommunityWallet;
      default:
        return ContributionIneligibilityReason.none;
    }
  }
}

/// Contribution Eligibility Response Model
class ContributionEligibilityResponse {
  final bool success;
  final String communityId;
  final String communityName;
  final bool canCreateContribution;
  final bool isAdmin;
  final bool? hasCommunityWallet;
  final ContributionIneligibilityReason reason;
  final String? message;

  ContributionEligibilityResponse({
    required this.success,
    required this.communityId,
    required this.communityName,
    required this.canCreateContribution,
    required this.isAdmin,
    this.hasCommunityWallet,
    required this.reason,
    this.message,
  });

  factory ContributionEligibilityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return ContributionEligibilityResponse(
      success: json['success'] ?? false,
      communityId: data?['communityId'] ?? '',
      communityName: data?['communityName'] ?? '',
      canCreateContribution: data?['canCreateContribution'] ?? false,
      isAdmin: data?['isAdmin'] ?? false,
      hasCommunityWallet: data?['hasCommunityWallet'],
      reason: ContributionIneligibilityReason.fromString(data?['reason']),
      message: data?['message'],
    );
  }
}

// =====================================================
// COMMUNITY MEMBERS MODELS
// =====================================================

/// Contribution Community Member Model
class ContributionCommunityMember {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? photo;
  final String role;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool hasActiveWallet;

  ContributionCommunityMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.photo,
    required this.role,
    required this.isAdmin,
    this.isCurrentUser = false,
    this.hasActiveWallet = false,
  });

  /// Check if member is eligible for Contribution participation
  bool get isEligibleForContribution => hasActiveWallet;

  factory ContributionCommunityMember.fromJson(Map<String, dynamic> json) {
    return ContributionCommunityMember(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      photo: json['photo'],
      role: json['role'] ?? 'MEMBER',
      isAdmin: json['isAdmin'] ?? false,
      isCurrentUser: json['isCurrentUser'] ?? false,
      hasActiveWallet: json['hasActiveWallet'] ?? false,
    );
  }
}

/// Contribution Community Members Response Model
class ContributionCommunityMembersResponse {
  final bool success;
  final String message;
  final List<ContributionCommunityMember> members;
  final int totalCount;

  ContributionCommunityMembersResponse({
    required this.success,
    required this.message,
    required this.members,
    required this.totalCount,
  });

  factory ContributionCommunityMembersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final membersList = data?['members'] as List<dynamic>? ?? [];

    return ContributionCommunityMembersResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      members: membersList
          .map((m) => ContributionCommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      totalCount: data?['totalCount'] ?? 0,
    );
  }
}

// =====================================================
// CREATE CONTRIBUTION MODELS
// =====================================================

/// Participant to add to Contribution
class ContributionParticipant {
  final String userId;

  ContributionParticipant({required this.userId});

  Map<String, dynamic> toJson() => {'userId': userId};
}

/// Create Contribution Request Model
class CreateContributionRequest {
  final String communityId;
  final String name;
  final String? description;
  final String? imageUrl;
  final ContributionType type;
  final double? amount;
  final DateTime startDate;
  final DateTime? deadline;
  final RecipientType recipientType;
  final String? recipientId;
  final ParticipantVisibility visibility;
  final bool notifyRecipient;
  final List<ContributionParticipant> participants;

  CreateContributionRequest({
    required this.communityId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.type,
    this.amount,
    required this.startDate,
    this.deadline,
    required this.recipientType,
    this.recipientId,
    required this.visibility,
    required this.notifyRecipient,
    required this.participants,
  });

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      'type': type.toApiString(),
      if (amount != null) 'amount': amount,
      'startDate': startDate.toIso8601String(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'recipientType': recipientType.toApiString(),
      if (recipientType == RecipientType.member && recipientId != null)
        'recipientId': recipientId,
      'visibility': visibility.toApiString(),
      'notifyRecipient': notifyRecipient,
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}

/// Created Contribution Model
class CreatedContribution {
  final String id;
  final String name;
  final String? description;
  final ContributionType type;
  final ContributionStatus status;
  final double? amount;
  final DateTime startDate;
  final DateTime? deadline;
  final RecipientType recipientType;
  final ParticipantVisibility visibility;
  final String inviteCode;
  final int participantCount;
  final String communityName;
  final DateTime createdAt;

  CreatedContribution({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    this.amount,
    required this.startDate,
    this.deadline,
    required this.recipientType,
    required this.visibility,
    required this.inviteCode,
    required this.participantCount,
    required this.communityName,
    required this.createdAt,
  });

  factory CreatedContribution.fromJson(Map<String, dynamic> json) {
    return CreatedContribution(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      type: ContributionType.fromString(json['type'] ?? 'FIXED'),
      status: ContributionStatus.fromString(json['status'] ?? 'PENDING_INVITES'),
      amount: json['amount'] != null ? (json['amount']).toDouble() : null,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      recipientType: RecipientType.fromString(json['recipientType'] ?? 'COMMUNITY_WALLET'),
      visibility: ParticipantVisibility.fromString(json['visibility'] ?? 'VIEW_ALL'),
      inviteCode: json['inviteCode'] ?? '',
      participantCount: json['participantCount'] ?? 0,
      communityName: json['communityName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Create Contribution Response Model
class CreateContributionResponse {
  final bool success;
  final String message;
  final CreatedContribution? contribution;

  CreateContributionResponse({
    required this.success,
    required this.message,
    this.contribution,
  });

  factory CreateContributionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return CreateContributionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      contribution: data != null ? CreatedContribution.fromJson(data) : null,
    );
  }
}

// =====================================================
// HUB COUNT MODELS
// =====================================================

/// Contribution Hub Count Response Model
class ContributionHubCountResponse {
  final bool success;
  final int total;
  final int active;
  final int? pendingInvitation;
  final bool isAdmin;

  ContributionHubCountResponse({
    required this.success,
    required this.total,
    required this.active,
    this.pendingInvitation,
    required this.isAdmin,
  });

  factory ContributionHubCountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return ContributionHubCountResponse(
      success: json['success'] ?? false,
      total: data?['total'] ?? 0,
      active: data?['active'] ?? 0,
      pendingInvitation: data?['pendingInvitation'],
      isAdmin: data?['isAdmin'] ?? false,
    );
  }
}

// =====================================================
// CONTRIBUTION LIST MODELS
// =====================================================

/// Contribution List Item Model
class ContributionListItem {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final ContributionType type;
  final ContributionStatus status;
  final ContributionInviteStatus? inviteStatus;
  final double? amount;
  final double totalContributed;
  final DateTime startDate;
  final DateTime? deadline;
  final int? daysRemaining;
  final double progress;
  final int participantCount;
  final int acceptedCount;
  final int pendingCount;
  final bool isCreator;
  final String creatorName;
  final bool isParticipant;

  ContributionListItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.type,
    required this.status,
    this.inviteStatus,
    this.amount,
    required this.totalContributed,
    required this.startDate,
    this.deadline,
    this.daysRemaining,
    required this.progress,
    required this.participantCount,
    required this.acceptedCount,
    required this.pendingCount,
    required this.isCreator,
    required this.creatorName,
    this.isParticipant = true,
  });

  factory ContributionListItem.fromJson(Map<String, dynamic> json) {
    return ContributionListItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      type: ContributionType.fromString(json['type'] ?? 'FIXED'),
      status: ContributionStatus.fromString(json['status'] ?? 'PENDING_INVITES'),
      inviteStatus: json['inviteStatus'] != null
          ? ContributionInviteStatus.fromString(json['inviteStatus'])
          : null,
      amount: json['amount'] != null ? (json['amount']).toDouble() : null,
      totalContributed: (json['totalContributed'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      daysRemaining: json['daysRemaining'],
      progress: (json['progress'] ?? 0).toDouble(),
      participantCount: json['participantCount'] ?? 0,
      acceptedCount: json['acceptedCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      isCreator: json['isCreator'] ?? false,
      creatorName: json['creatorName'] ?? '',
      isParticipant: json['isParticipant'] ?? true,
    );
  }
}

/// Contribution List Response Model
class ContributionListResponse {
  final bool success;
  final List<ContributionListItem> contributions;
  final bool isAdmin;

  ContributionListResponse({
    required this.success,
    required this.contributions,
    required this.isAdmin,
  });

  factory ContributionListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final contributionsList = data?['contributions'] as List<dynamic>? ?? [];

    return ContributionListResponse(
      success: json['success'] ?? false,
      contributions: contributionsList
          .map((e) => ContributionListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAdmin: data?['isAdmin'] ?? false,
    );
  }
}

// =====================================================
// PENDING INVITATIONS MODELS
// =====================================================

/// Pending Invitation Item Model
class PendingInvitationItem {
  final String contributionId;
  final String contributionName;
  final ContributionType type;
  final double? amount;
  final DateTime? deadline;
  final String creatorName;
  final DateTime invitedAt;

  PendingInvitationItem({
    required this.contributionId,
    required this.contributionName,
    required this.type,
    this.amount,
    this.deadline,
    required this.creatorName,
    required this.invitedAt,
  });

  factory PendingInvitationItem.fromJson(Map<String, dynamic> json) {
    return PendingInvitationItem(
      contributionId: json['contributionId'] ?? '',
      contributionName: json['contributionName'] ?? '',
      type: ContributionType.fromString(json['type'] ?? 'FIXED'),
      amount: json['amount'] != null ? (json['amount']).toDouble() : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      creatorName: json['creatorName'] ?? '',
      invitedAt: DateTime.parse(json['invitedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Pending Invitations Response Model
class PendingInvitationsResponse {
  final bool success;
  final List<PendingInvitationItem> invitations;

  PendingInvitationsResponse({
    required this.success,
    required this.invitations,
  });

  factory PendingInvitationsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final invitationsList = data?['invitations'] as List<dynamic>? ?? [];

    return PendingInvitationsResponse(
      success: json['success'] ?? false,
      invitations: invitationsList
          .map((e) => PendingInvitationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// =====================================================
// CONTRIBUTION DETAILS MODELS
// =====================================================

/// Contribution Participant Detail
class ContributionParticipantDetail {
  final String id;
  final String fullName;
  final String? photo;
  final ContributionInviteStatus inviteStatus;
  final double totalContributed;
  final int entryCount;

  ContributionParticipantDetail({
    required this.id,
    required this.fullName,
    this.photo,
    required this.inviteStatus,
    required this.totalContributed,
    required this.entryCount,
  });

  factory ContributionParticipantDetail.fromJson(Map<String, dynamic> json) {
    return ContributionParticipantDetail(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      photo: json['photo'],
      inviteStatus: ContributionInviteStatus.fromString(json['inviteStatus'] ?? 'INVITED'),
      totalContributed: (json['totalContributed'] ?? 0).toDouble(),
      entryCount: json['entryCount'] ?? 0,
    );
  }
}

/// Contribution Details Model
class ContributionDetails {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final ContributionType type;
  final ContributionStatus status;
  final double? amount;
  final double totalContributed;
  final DateTime startDate;
  final DateTime? deadline;
  final int? daysRemaining;
  final double progress;
  final RecipientType recipientType;
  final String? recipientName;
  final ParticipantVisibility visibility;
  final bool notifyRecipient;
  final String inviteCode;
  final String creatorId;
  final String creatorName;
  final bool isCreator;
  final bool isParticipant;
  final ContributionInviteStatus? myInviteStatus;
  final double? myTotalContributed;
  final List<ContributionParticipantDetail> participants;
  final DateTime createdAt;

  ContributionDetails({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.type,
    required this.status,
    this.amount,
    required this.totalContributed,
    required this.startDate,
    this.deadline,
    this.daysRemaining,
    required this.progress,
    required this.recipientType,
    this.recipientName,
    required this.visibility,
    required this.notifyRecipient,
    required this.inviteCode,
    required this.creatorId,
    required this.creatorName,
    required this.isCreator,
    required this.isParticipant,
    this.myInviteStatus,
    this.myTotalContributed,
    required this.participants,
    required this.createdAt,
  });

  factory ContributionDetails.fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List<dynamic>? ?? [];

    return ContributionDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      type: ContributionType.fromString(json['type'] ?? 'FIXED'),
      status: ContributionStatus.fromString(json['status'] ?? 'PENDING_INVITES'),
      amount: json['amount'] != null ? (json['amount']).toDouble() : null,
      totalContributed: (json['totalContributed'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      daysRemaining: json['daysRemaining'],
      progress: (json['progress'] ?? 0).toDouble(),
      recipientType: RecipientType.fromString(json['recipientType'] ?? 'COMMUNITY_WALLET'),
      recipientName: json['recipientName'],
      visibility: ParticipantVisibility.fromString(json['visibility'] ?? 'VIEW_ALL'),
      notifyRecipient: json['notifyRecipient'] ?? false,
      inviteCode: json['inviteCode'] ?? '',
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      isCreator: json['isCreator'] ?? false,
      isParticipant: json['isParticipant'] ?? false,
      myInviteStatus: json['myInviteStatus'] != null
          ? ContributionInviteStatus.fromString(json['myInviteStatus'])
          : null,
      myTotalContributed: json['myTotalContributed'] != null
          ? (json['myTotalContributed']).toDouble()
          : null,
      participants: participantsList
          .map((p) => ContributionParticipantDetail.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Contribution Details Response Model
class ContributionDetailsResponse {
  final bool success;
  final ContributionDetails? contribution;

  ContributionDetailsResponse({
    required this.success,
    this.contribution,
  });

  factory ContributionDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return ContributionDetailsResponse(
      success: json['success'] ?? false,
      contribution: data != null ? ContributionDetails.fromJson(data) : null,
    );
  }
}

// =====================================================
// INVITATION RESPONSE MODELS
// =====================================================

/// Response from accepting/declining a contribution invitation
class ContributionInvitationResponse {
  final bool success;
  final String message;
  final bool accepted;
  final String? contributionId;
  final String? contributionName;

  ContributionInvitationResponse({
    required this.success,
    required this.message,
    required this.accepted,
    this.contributionId,
    this.contributionName,
  });

  factory ContributionInvitationResponse.fromJson(Map<String, dynamic> json, bool accepted) {
    final data = json['data'] as Map<String, dynamic>?;

    return ContributionInvitationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accepted: accepted,
      contributionId: data?['contributionId'],
      contributionName: data?['contributionName'],
    );
  }
}

// =====================================================
// REPOSITORY
// =====================================================

/// Contributions Repository
class ContributionsRepository {
  final ApiClient _apiClient;

  ContributionsRepository(this._apiClient);

  /// Check Contribution creation eligibility for a community
  Future<ContributionEligibilityResponse> checkEligibility(String communityId) async {
    final response = await _apiClient.get(
      ApiEndpoints.contributionEligibility(communityId),
    );
    return ContributionEligibilityResponse.fromJson(response.data);
  }

  /// Get community members for participant selection
  Future<ContributionCommunityMembersResponse> getCommunityMembers(
    String communityId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.contributionCommunityMembers(communityId),
    );
    return ContributionCommunityMembersResponse.fromJson(response.data);
  }

  /// Create a new Contribution
  Future<CreateContributionResponse> createContribution(CreateContributionRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.contributions,
      data: request.toJson(),
    );
    return CreateContributionResponse.fromJson(response.data);
  }

  /// Get Contribution count for Hub display
  Future<ContributionHubCountResponse> getHubCount(String communityId) async {
    final response = await _apiClient.get(
      ApiEndpoints.contributionHubCount(communityId),
    );
    return ContributionHubCountResponse.fromJson(response.data);
  }

  /// Get Contribution list
  Future<ContributionListResponse> getContributionList(
    String communityId, {
    bool archived = false,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.contributionList(communityId)}${archived ? '?archived=true' : ''}',
    );
    return ContributionListResponse.fromJson(response.data);
  }

  /// Get pending invitations for the current user
  Future<PendingInvitationsResponse> getPendingInvitations(String communityId) async {
    final response = await _apiClient.get(
      ApiEndpoints.contributionPendingInvitations(communityId),
    );
    return PendingInvitationsResponse.fromJson(response.data);
  }

  /// Get Contribution details
  Future<ContributionDetailsResponse> getContributionDetails(String contributionId) async {
    final response = await _apiClient.get(
      ApiEndpoints.contributionDetails(contributionId),
    );
    return ContributionDetailsResponse.fromJson(response.data);
  }

  /// Respond to Contribution invitation (accept or decline)
  Future<ContributionInvitationResponse> respondToInvitation(
    String contributionId, {
    required bool accept,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.contributionRespondInvitation(contributionId),
      data: {'response': accept ? 'ACCEPT' : 'DECLINE'},
    );
    return ContributionInvitationResponse.fromJson(response.data, accept);
  }

  /// Make a contribution payment
  Future<MakeContributionResponse> makeContribution(
    String contributionId, {
    required double amount,
    required String transactionPin,
    String? narration,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.contributionContribute(contributionId),
      data: {
        'amount': amount,
        'transactionPin': transactionPin,
        if (narration != null && narration.isNotEmpty) 'narration': narration,
      },
    );
    return MakeContributionResponse.fromJson(response.data);
  }
}

// =====================================================
// MAKE CONTRIBUTION RESPONSE MODEL
// =====================================================

/// Response from making a contribution payment
class MakeContributionResponse {
  final bool success;
  final String message;
  final String? entryId;
  final String? contributionId;
  final String? contributionName;
  final double? amount;
  final String? transactionRef;
  final String? recipientName;

  MakeContributionResponse({
    required this.success,
    required this.message,
    this.entryId,
    this.contributionId,
    this.contributionName,
    this.amount,
    this.transactionRef,
    this.recipientName,
  });

  factory MakeContributionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return MakeContributionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      entryId: data?['entryId'],
      contributionId: data?['contributionId'],
      contributionName: data?['contributionName'],
      amount: data?['amount'] != null ? (data!['amount']).toDouble() : null,
      transactionRef: data?['transactionRef'],
      recipientName: data?['recipientName'],
    );
  }
}
