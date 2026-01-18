import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/network/api_config.dart';
import 'package:finsquare_mobile_app/features/auth/data/auth_repository.dart';

/// Community Repository Provider
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(apiClientProvider));
});

/// Active Community Member Model (simplified for active community)
class ActiveCommunityMember {
  final String id;
  final String name;
  final String email;
  final String role;

  ActiveCommunityMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory ActiveCommunityMember.fromJson(Map<String, dynamic> json) {
    return ActiveCommunityMember(
      id: json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'MEMBER',
    );
  }
}

/// Active Community Model
class ActiveCommunity {
  final String id;
  final String name;
  final String role;
  final String? description;
  final String? logo;
  final String? color;
  final bool isDefault;
  final List<ActiveCommunityMember> members;

  ActiveCommunity({
    required this.id,
    required this.name,
    required this.role,
    this.description,
    this.logo,
    this.color,
    this.isDefault = false,
    this.members = const [],
  });

  /// Check if user is Admin
  bool get isAdmin => role == 'ADMIN';

  /// Check if user is Co-Admin
  bool get isCoAdmin => role == 'CO_ADMIN';

  /// Check if user has admin privileges (Admin or Co-Admin)
  bool get hasAdminPrivileges => isAdmin || isCoAdmin;

  factory ActiveCommunity.fromJson(Map<String, dynamic> json) {
    final membersList = json['members'] as List<dynamic>? ?? [];
    return ActiveCommunity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'MEMBER',
      description: json['description'],
      logo: json['logo'],
      color: json['color'],
      isDefault: json['isDefault'] ?? false,
      members: membersList
          .map((m) => ActiveCommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Join Community Response Model
class JoinCommunityResponse {
  final bool success;
  final String message;
  final UserData? user;
  final ActiveCommunity? activeCommunity;

  JoinCommunityResponse({
    required this.success,
    required this.message,
    this.user,
    this.activeCommunity,
  });

  factory JoinCommunityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return JoinCommunityResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: data?['user'] != null ? UserData.fromJson(data!['user']) : null,
      activeCommunity: data?['activeCommunity'] != null
          ? ActiveCommunity.fromJson(data!['activeCommunity'])
          : null,
    );
  }
}

/// Created Community Model
class CreatedCommunity {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String? color;
  final bool isRegistered;

  CreatedCommunity({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.color,
    this.isRegistered = false,
  });

  factory CreatedCommunity.fromJson(Map<String, dynamic> json) {
    return CreatedCommunity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logo: json['logo'],
      color: json['color'],
      isRegistered: json['isRegistered'] ?? false,
    );
  }
}

/// Create Community Response Model
class CreateCommunityResponse {
  static const String _inviteBaseUrl = 'https://finsquare-invite.netlify.app/invite';

  final bool success;
  final String message;
  final CreatedCommunity? community;
  final String? _rawInviteLink;
  final String? role;
  final UserData? user;

  CreateCommunityResponse({
    required this.success,
    required this.message,
    this.community,
    String? inviteLink,
    this.role,
    this.user,
  }) : _rawInviteLink = inviteLink;

  /// Get the invite link - ensures it uses the correct base URL
  String? get inviteLink {
    final raw = _rawInviteLink;
    if (raw == null) return null;

    // If already using correct URL, return as-is
    if (raw.startsWith('https://finsquare-invite.netlify.app')) {
      return raw;
    }

    // Extract token from various URL formats and reconstruct
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      // Get the last path segment as token
      final token = uri.pathSegments.last;
      if (token.isNotEmpty) {
        return '$_inviteBaseUrl/$token';
      }
    }

    // Fallback
    return raw;
  }

  factory CreateCommunityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return CreateCommunityResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      community: data?['community'] != null
          ? CreatedCommunity.fromJson(data!['community'])
          : null,
      inviteLink: data?['inviteLink'],
      role: data?['membership']?['role'],
      user: data?['user'] != null ? UserData.fromJson(data!['user']) : null,
    );
  }
}

/// Create Community Request Model
class CreateCommunityRequest {
  final String name;
  final String? description;
  final String? logo;
  final String? color;
  final bool isRegistered;
  final String? proofOfAddress;
  final String? cacDocument;
  final String? addressVerification;

  CreateCommunityRequest({
    required this.name,
    this.description,
    this.logo,
    this.color,
    this.isRegistered = false,
    this.proofOfAddress,
    this.cacDocument,
    this.addressVerification,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (logo != null && logo!.isNotEmpty) 'logo': logo,
      if (color != null && color!.isNotEmpty) 'color': color,
      'isRegistered': isRegistered,
      if (proofOfAddress != null && proofOfAddress!.isNotEmpty)
        'proofOfAddress': proofOfAddress,
      if (cacDocument != null && cacDocument!.isNotEmpty)
        'cacDocument': cacDocument,
      if (addressVerification != null && addressVerification!.isNotEmpty)
        'addressVerification': addressVerification,
    };
  }
}

/// Invite Link Response Model
class InviteLinkResponse {
  static const String _inviteBaseUrl = 'https://finsquare-invite.netlify.app/invite';

  final bool success;
  final String message;
  final String? _rawInviteLink;
  final String? token;
  final String? joinType;
  final int? maxMembers;
  final int? usedCount;
  final String? communityName;

  InviteLinkResponse({
    required this.success,
    required this.message,
    String? inviteLink,
    this.token,
    this.joinType,
    this.maxMembers,
    this.usedCount,
    this.communityName,
  }) : _rawInviteLink = inviteLink;

  /// Get the invite link - constructs from token if backend doesn't provide full URL
  String? get inviteLink {
    final raw = _rawInviteLink;
    final tok = token;

    // If backend provides a valid invite link, use it
    if (raw != null && raw.startsWith('https://finsquare-invite.netlify.app')) {
      return raw;
    }
    // Otherwise construct from token
    if (tok != null && tok.isNotEmpty) {
      return '$_inviteBaseUrl/$tok';
    }
    // Fallback to whatever backend returned
    return raw;
  }

  factory InviteLinkResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return InviteLinkResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      inviteLink: data?['inviteLink'],
      token: data?['token'],
      joinType: data?['joinType'],
      maxMembers: data?['maxMembers'],
      usedCount: data?['usedCount'],
      communityName: data?['communityName'],
    );
  }
}

/// Email Invite Model
class EmailInvite {
  final String email;
  final String? name;
  final String? phone;

  EmailInvite({
    required this.email,
    this.name,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (name != null && name!.isNotEmpty) 'name': name,
    };
  }
}

/// Email Invite Result Model
class EmailInviteResult {
  final String email;
  final bool success;
  final String message;

  EmailInviteResult({
    required this.email,
    required this.success,
    required this.message,
  });

  factory EmailInviteResult.fromJson(Map<String, dynamic> json) {
    return EmailInviteResult(
      email: json['email'] ?? '',
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Community Name Availability Response Model
class CommunityNameAvailabilityResponse {
  final bool success;
  final bool available;
  final String? message;

  CommunityNameAvailabilityResponse({
    required this.success,
    required this.available,
    this.message,
  });

  factory CommunityNameAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return CommunityNameAvailabilityResponse(
      success: json['success'] ?? false,
      available: json['available'] ?? false,
      message: json['message'],
    );
  }
}

/// Send Invites Response Model
class SendInvitesResponse {
  final bool success;
  final String message;
  final List<EmailInviteResult> results;
  final int totalSent;
  final int totalFailed;

  SendInvitesResponse({
    required this.success,
    required this.message,
    required this.results,
    required this.totalSent,
    required this.totalFailed,
  });

  factory SendInvitesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final resultsList = data?['results'] as List<dynamic>? ?? [];
    final summary = data?['summary'] as Map<String, dynamic>?;

    return SendInvitesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      results: resultsList
          .map((r) => EmailInviteResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalSent: summary?['sent'] ?? 0,
      totalFailed: summary?['failed'] ?? 0,
    );
  }
}

/// Join Type Enum
enum JoinType {
  open,
  approvalRequired;

  static JoinType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return JoinType.open;
      case 'APPROVAL_REQUIRED':
        return JoinType.approvalRequired;
      default:
        return JoinType.open;
    }
  }

  String toApiString() {
    switch (this) {
      case JoinType.open:
        return 'OPEN';
      case JoinType.approvalRequired:
        return 'APPROVAL_REQUIRED';
    }
  }
}

/// Join Request Status Enum
enum JoinRequestStatus {
  pending,
  approved,
  rejected;

  static JoinRequestStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return JoinRequestStatus.pending;
      case 'APPROVED':
        return JoinRequestStatus.approved;
      case 'REJECTED':
        return JoinRequestStatus.rejected;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

/// Invite Link Config Model
class InviteLinkConfig {
  static const String _inviteBaseUrl = 'https://finsquare-invite.netlify.app/invite';

  final String token;
  final String _rawInviteLink;
  final JoinType joinType;
  final DateTime? expiresAt;
  final int? maxMembers;
  final int usedCount;
  final bool isActive;

  InviteLinkConfig({
    required this.token,
    required String inviteLink,
    required this.joinType,
    this.expiresAt,
    this.maxMembers,
    required this.usedCount,
    required this.isActive,
  }) : _rawInviteLink = inviteLink;

  /// Get the invite link - constructs from token if backend doesn't provide correct URL
  String get inviteLink {
    // If backend provides a valid invite link, use it
    if (_rawInviteLink.startsWith('https://finsquare-invite.netlify.app')) {
      return _rawInviteLink;
    }
    // Otherwise construct from token
    if (token.isNotEmpty) {
      return '$_inviteBaseUrl/$token';
    }
    // Fallback to whatever backend returned
    return _rawInviteLink;
  }

  factory InviteLinkConfig.fromJson(Map<String, dynamic> json) {
    return InviteLinkConfig(
      token: json['token'] ?? '',
      inviteLink: json['inviteLink'] ?? '',
      joinType: JoinType.fromString(json['joinType'] ?? 'OPEN'),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      maxMembers: json['maxMembers'],
      usedCount: json['usedCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Invite Link Config Response Model
class InviteLinkConfigResponse {
  final bool success;
  final String message;
  final InviteLinkConfig? config;

  InviteLinkConfigResponse({
    required this.success,
    required this.message,
    this.config,
  });

  factory InviteLinkConfigResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return InviteLinkConfigResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      config: data != null ? InviteLinkConfig.fromJson(data) : null,
    );
  }
}

/// Update Invite Link Config Request
class UpdateInviteLinkConfigRequest {
  final JoinType joinType;
  final DateTime? expiresAt;

  UpdateInviteLinkConfigRequest({
    required this.joinType,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'joinType': joinType.toApiString(),
      if (expiresAt != null)
        'expiresAt': expiresAt!.toIso8601String()
      else
        'expiresAt': null,
    };
  }
}

/// Invite Details Model (for public invite endpoint)
class InviteDetails {
  final String communityId;
  final String communityName;
  final String? communityLogo;
  final String? communityColor;
  final JoinType joinType;
  final bool isValid;
  final String? invalidReason;

  InviteDetails({
    required this.communityId,
    required this.communityName,
    this.communityLogo,
    this.communityColor,
    required this.joinType,
    required this.isValid,
    this.invalidReason,
  });

  factory InviteDetails.fromJson(Map<String, dynamic> json) {
    // Community data is nested under 'community' key
    final community = json['community'] as Map<String, dynamic>?;
    return InviteDetails(
      communityId: community?['id'] ?? json['communityId'] ?? '',
      communityName: community?['name'] ?? json['communityName'] ?? '',
      communityLogo: community?['logo'] ?? json['communityLogo'],
      communityColor: community?['color'] ?? json['communityColor'],
      joinType: JoinType.fromString(json['joinType'] ?? 'OPEN'),
      isValid: json['isValid'] ?? true,
      invalidReason: json['invalidReason'],
    );
  }
}

/// Invite Details Response Model
class InviteDetailsResponse {
  final bool success;
  final String message;
  final InviteDetails? invite;

  InviteDetailsResponse({
    required this.success,
    required this.message,
    this.invite,
  });

  factory InviteDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return InviteDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      invite: data != null ? InviteDetails.fromJson(data) : null,
    );
  }
}

/// Join Result Type
enum JoinResultType {
  joined,
  pendingApproval,
  alreadyMember,
  alreadyRequested;

  static JoinResultType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'JOINED':
        return JoinResultType.joined;
      case 'PENDING_APPROVAL':
        return JoinResultType.pendingApproval;
      case 'ALREADY_MEMBER':
        return JoinResultType.alreadyMember;
      case 'ALREADY_REQUESTED':
        return JoinResultType.alreadyRequested;
      default:
        return JoinResultType.joined;
    }
  }
}

/// Join Via Invite Response Model
class JoinViaInviteResponse {
  final bool success;
  final String message;
  final JoinResultType resultType;
  final ActiveCommunity? community;

  JoinViaInviteResponse({
    required this.success,
    required this.message,
    required this.resultType,
    this.community,
  });

  factory JoinViaInviteResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return JoinViaInviteResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      resultType: JoinResultType.fromString(data?['resultType'] ?? 'JOINED'),
      community: data?['community'] != null
          ? ActiveCommunity.fromJson(data!['community'])
          : null,
    );
  }
}

/// Join Request User Model
class JoinRequestUser {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;

  JoinRequestUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
  });

  factory JoinRequestUser.fromJson(Map<String, dynamic> json) {
    return JoinRequestUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }
}

/// Join Request Model
class JoinRequest {
  final String id;
  final String communityId;
  final String userId;
  final JoinRequestStatus status;
  final JoinRequestUser user;
  final DateTime createdAt;
  final DateTime? respondedAt;

  JoinRequest({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.status,
    required this.user,
    required this.createdAt,
    this.respondedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      userId: json['userId'] ?? '',
      status: JoinRequestStatus.fromString(json['status'] ?? 'PENDING'),
      user: JoinRequestUser.fromJson(json['user'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
    );
  }
}

/// Join Requests Response Model
class JoinRequestsResponse {
  final bool success;
  final String message;
  final List<JoinRequest> requests;
  final int total;

  JoinRequestsResponse({
    required this.success,
    required this.message,
    required this.requests,
    required this.total,
  });

  factory JoinRequestsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final requestsList = data?['requests'] as List<dynamic>? ?? [];

    return JoinRequestsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      requests: requestsList
          .map((r) => JoinRequest.fromJson(r as Map<String, dynamic>))
          .toList(),
      total: data?['total'] ?? requestsList.length,
    );
  }
}

/// Join Request Action Response Model
class JoinRequestActionResponse {
  final bool success;
  final String message;
  final JoinRequest? request;

  JoinRequestActionResponse({
    required this.success,
    required this.message,
    this.request,
  });

  factory JoinRequestActionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return JoinRequestActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      request: data?['request'] != null
          ? JoinRequest.fromJson(data!['request'])
          : null,
    );
  }
}

/// User Join Request Status Response Model
class UserJoinRequestStatusResponse {
  final bool success;
  final String message;
  final bool hasRequest;
  final JoinRequestStatus? status;
  final DateTime? createdAt;

  UserJoinRequestStatusResponse({
    required this.success,
    required this.message,
    required this.hasRequest,
    this.status,
    this.createdAt,
  });

  factory UserJoinRequestStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return UserJoinRequestStatusResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      hasRequest: data?['hasRequest'] ?? false,
      status: data?['status'] != null
          ? JoinRequestStatus.fromString(data!['status'])
          : null,
      createdAt: data?['createdAt'] != null
          ? DateTime.parse(data!['createdAt'])
          : null,
    );
  }
}

/// Community Member User Model
class CommunityMemberUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phoneNumber;
  final DateTime? createdAt;

  CommunityMemberUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phoneNumber,
    this.createdAt,
  });

  factory CommunityMemberUser.fromJson(Map<String, dynamic> json) {
    return CommunityMemberUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

/// Community Member Model
class CommunityMember {
  final String id;
  final String role;
  final DateTime joinedAt;
  final bool isActive;
  final CommunityMemberUser user;

  CommunityMember({
    required this.id,
    required this.role,
    required this.joinedAt,
    required this.isActive,
    required this.user,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['id'] ?? '',
      role: json['role'] ?? 'MEMBER',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      user: CommunityMemberUser.fromJson(json['user'] ?? {}),
    );
  }
}

/// Community Members Response Model
class CommunityMembersResponse {
  final bool success;
  final String message;
  final String communityId;
  final String communityName;
  final int totalMembers;
  final List<CommunityMember> members;
  final List<PendingInvite> pendingInvites;

  CommunityMembersResponse({
    required this.success,
    required this.message,
    required this.communityId,
    required this.communityName,
    required this.totalMembers,
    required this.members,
    this.pendingInvites = const [],
  });

  factory CommunityMembersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final membersList = data?['members'] as List<dynamic>? ?? [];
    final invitesList = data?['pendingInvites'] as List<dynamic>? ?? [];

    return CommunityMembersResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      communityId: data?['communityId'] ?? '',
      communityName: data?['communityName'] ?? '',
      totalMembers: data?['totalMembers'] ?? 0,
      members: membersList
          .map((m) => CommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      pendingInvites: invitesList
          .map((i) => PendingInvite.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// User Community Model (for my-communities endpoint)
class UserCommunity {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String? color;
  final String role;
  final bool isDefault;
  final DateTime joinedAt;

  UserCommunity({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.color,
    required this.role,
    required this.isDefault,
    required this.joinedAt,
  });

  factory UserCommunity.fromJson(Map<String, dynamic> json) {
    return UserCommunity(
      id: json['id'] ?? json['communityId'] ?? '',
      name: json['name'] ?? json['communityName'] ?? '',
      description: json['description'],
      logo: json['logo'],
      color: json['color'],
      role: json['role'] ?? 'MEMBER',
      isDefault: json['isDefault'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  /// Check if user is admin of this community
  bool get isAdmin => role == 'ADMIN';

  /// Check if user is co-admin of this community
  bool get isCoAdmin => role == 'CO_ADMIN';

  /// Check if user has admin privileges (admin or co-admin)
  bool get hasAdminPrivileges => isAdmin || isCoAdmin;
}

/// My Communities Response Model
class MyCommunitiesResponse {
  final bool success;
  final String message;
  final List<UserCommunity> communities;

  MyCommunitiesResponse({
    required this.success,
    required this.message,
    required this.communities,
  });

  factory MyCommunitiesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<dynamic> communitiesList = [];

    if (data is List) {
      communitiesList = data;
    } else if (data is Map<String, dynamic>) {
      communitiesList = data['communities'] as List<dynamic>? ?? [];
    }

    return MyCommunitiesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      communities: communitiesList
          .map((c) => UserCommunity.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Switch Community Response Model
class SwitchCommunityResponse {
  final bool success;
  final String message;
  final ActiveCommunity? activeCommunity;

  SwitchCommunityResponse({
    required this.success,
    required this.message,
    this.activeCommunity,
  });

  factory SwitchCommunityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return SwitchCommunityResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      activeCommunity: data?['activeCommunity'] != null
          ? ActiveCommunity.fromJson(data!['activeCommunity'])
          : (data != null ? ActiveCommunity.fromJson(data) : null),
    );
  }
}

/// Pending Invite Model
class PendingInvite {
  final String id;
  final String? name;
  final String email;
  final String status;
  final DateTime invitedAt;
  final DateTime? expiresAt;

  PendingInvite({
    required this.id,
    this.name,
    required this.email,
    required this.status,
    required this.invitedAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt != null) {
      return DateTime.now().isAfter(expiresAt!);
    }
    // Default 30 minutes expiry from invitedAt
    return DateTime.now().isAfter(invitedAt.add(const Duration(minutes: 30)));
  }

  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    return PendingInvite(
      id: json['id'] ?? json['inviteId'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      status: json['status'] ?? 'PENDING',
      invitedAt: json['invitedAt'] != null
          ? DateTime.parse(json['invitedAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }
}

/// Add Co-Admins Response Model
class AddCoAdminsResponse {
  final bool success;
  final String message;

  AddCoAdminsResponse({
    required this.success,
    required this.message,
  });

  factory AddCoAdminsResponse.fromJson(Map<String, dynamic> json) {
    return AddCoAdminsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Remove Co-Admin Response Model
class RemoveCoAdminResponse {
  final bool success;
  final String message;

  RemoveCoAdminResponse({
    required this.success,
    required this.message,
  });

  factory RemoveCoAdminResponse.fromJson(Map<String, dynamic> json) {
    return RemoveCoAdminResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Community Repository
class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository(this._apiClient);

  /// Check community name availability
  Future<CommunityNameAvailabilityResponse> checkCommunityNameAvailability(
    String name,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.checkCommunityName(name),
    );
    return CommunityNameAvailabilityResponse.fromJson(response.data);
  }

  /// Create a new community
  Future<CreateCommunityResponse> createCommunity(
    CreateCommunityRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.createCommunity,
      data: request.toJson(),
    );
    return CreateCommunityResponse.fromJson(response.data);
  }

  /// Join the default FinSquare community
  Future<JoinCommunityResponse> joinDefaultCommunity() async {
    final response = await _apiClient.post(
      ApiEndpoints.joinDefaultCommunity,
    );
    return JoinCommunityResponse.fromJson(response.data);
  }

  /// Get active community
  Future<ActiveCommunity?> getActiveCommunity() async {
    final response = await _apiClient.get(
      ApiEndpoints.activeCommunity,
    );
    final data = response.data['data'];
    if (data != null) {
      return ActiveCommunity.fromJson(data);
    }
    return null;
  }

  /// Get invite link for a community
  Future<InviteLinkResponse> getInviteLink(String communityId) async {
    final response = await _apiClient.get(
      ApiEndpoints.getInviteLink(communityId),
    );
    return InviteLinkResponse.fromJson(response.data);
  }

  /// Send email invites
  Future<SendInvitesResponse> sendEmailInvites(
    String communityId,
    List<EmailInvite> invites,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendEmailInvites(communityId),
      data: {
        'invites': invites.map((e) => e.toJson()).toList(),
      },
    );
    return SendInvitesResponse.fromJson(response.data);
  }

  // =====================================================
  // COMMUNITY MEMBERS (Admin)
  // =====================================================

  /// Get community members
  Future<CommunityMembersResponse> getCommunityMembers(
    String communityId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.getCommunityMembers(communityId),
    );
    return CommunityMembersResponse.fromJson(response.data);
  }

  // =====================================================
  // INVITE LINK CONFIGURATION (Admin)
  // =====================================================

  /// Get invite link configuration
  Future<InviteLinkConfigResponse> getInviteLinkConfig(
    String communityId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.getInviteLinkConfig(communityId),
    );
    return InviteLinkConfigResponse.fromJson(response.data);
  }

  /// Update invite link configuration
  Future<InviteLinkConfigResponse> updateInviteLinkConfig(
    String communityId,
    UpdateInviteLinkConfigRequest request,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.updateInviteLinkConfig(communityId),
      data: request.toJson(),
    );
    return InviteLinkConfigResponse.fromJson(response.data);
  }

  /// Regenerate invite link
  Future<InviteLinkConfigResponse> regenerateInviteLink(
    String communityId,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.regenerateInviteLink(communityId),
    );
    return InviteLinkConfigResponse.fromJson(response.data);
  }

  // =====================================================
  // JOIN REQUESTS (Admin)
  // =====================================================

  /// Get join requests for a community
  Future<JoinRequestsResponse> getJoinRequests(
    String communityId, {
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _apiClient.get(
      ApiEndpoints.getJoinRequests(communityId),
      queryParameters: queryParams,
    );
    return JoinRequestsResponse.fromJson(response.data);
  }

  /// Approve a join request
  Future<JoinRequestActionResponse> approveJoinRequest(
    String requestId,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.approveJoinRequest(requestId),
    );
    return JoinRequestActionResponse.fromJson(response.data);
  }

  /// Reject a join request
  Future<JoinRequestActionResponse> rejectJoinRequest(
    String requestId,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.rejectJoinRequest(requestId),
    );
    return JoinRequestActionResponse.fromJson(response.data);
  }

  // =====================================================
  // PUBLIC INVITE ENDPOINTS
  // =====================================================

  /// Get invite details by token (public)
  Future<InviteDetailsResponse> getInviteDetails(String token) async {
    final response = await _apiClient.get(
      ApiEndpoints.getInviteDetails(token),
    );
    return InviteDetailsResponse.fromJson(response.data);
  }

  /// Join community via invite link
  Future<JoinViaInviteResponse> joinViaInvite(String token) async {
    final response = await _apiClient.post(
      ApiEndpoints.joinViaInvite(token),
    );
    return JoinViaInviteResponse.fromJson(response.data);
  }

  /// Get user's join request status for a community
  Future<UserJoinRequestStatusResponse> getJoinRequestStatus(
    String communityId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.getJoinRequestStatus(communityId),
    );
    return UserJoinRequestStatusResponse.fromJson(response.data);
  }

  // =====================================================
  // USER'S COMMUNITIES
  // =====================================================

  /// Get all communities the user is a member of
  Future<MyCommunitiesResponse> getMyCommunities() async {
    final response = await _apiClient.get(
      ApiEndpoints.myCommunities,
    );
    return MyCommunitiesResponse.fromJson(response.data);
  }

  /// Switch active community
  Future<SwitchCommunityResponse> switchActiveCommunity(
    String communityId,
  ) async {
    final response = await _apiClient.patch(
      ApiEndpoints.switchActiveCommunity(communityId),
    );
    return SwitchCommunityResponse.fromJson(response.data);
  }

  // =====================================================
  // COMMUNITY MEMBERS MANAGEMENT
  // =====================================================

  /// Add co-admins to community
  Future<AddCoAdminsResponse> addCoAdmins(
    String communityId,
    List<String> userIds,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.addCoAdmins,
      data: {
        'communityId': communityId,
        'userIds': userIds,
      },
    );
    return AddCoAdminsResponse.fromJson(response.data);
  }

  /// Remove co-admin from community
  Future<RemoveCoAdminResponse> removeCoAdmin(
    String communityId,
    String userId,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.removeAdmin,
      data: {
        'communityId': communityId,
        'userId': userId,
      },
    );
    return RemoveCoAdminResponse.fromJson(response.data);
  }
}
