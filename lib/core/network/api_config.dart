/// API Configuration
class ApiConfig {
  // Production API URL
  static const String baseUrl = 'https://api.thegreencard.app/api/v1';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// API Endpoints
class ApiEndpoints {
  // Auth
  static const String signup = '/auth/signup';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String login = '/auth/login';
  static const String loginPasskey = '/auth/login-passkey';
  static const String createPasskey = '/auth/create-passkey';
  static const String requestReset = '/auth/request-reset';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String resendResetOtp = '/auth/resend-reset-otp';
  static const String me = '/auth/me';

  // Communities
  static const String createCommunity = '/communities';
  static const String joinDefaultCommunity = '/communities/join-default';
  static const String activeCommunity = '/communities/active';
  static const String myCommunities = '/communities/my-communities';

  /// Switch active community: /communities/switch-active/{communityId}
  static String switchActiveCommunity(String communityId) =>
      '/communities/switch-active/$communityId';

  /// Check community name availability: /communities/check-name/{name}
  static String checkCommunityName(String name) => '/communities/check-name/$name';

  /// Get invite link for a community: /communities/{communityId}/invite-link
  static String getInviteLink(String communityId) => '/communities/$communityId/invite-link';

  /// Send email invites: /communities/{communityId}/invites/email
  static String sendEmailInvites(String communityId) => '/communities/$communityId/invites/email';

  /// Get invite link config: /communities/{communityId}/invite-link/config
  static String getInviteLinkConfig(String communityId) =>
      '/communities/$communityId/invite-link/config';

  /// Update invite link config: /communities/{communityId}/invite-link/config
  static String updateInviteLinkConfig(String communityId) =>
      '/communities/$communityId/invite-link/config';

  /// Regenerate invite link: /communities/{communityId}/invite-link/regenerate
  static String regenerateInviteLink(String communityId) =>
      '/communities/$communityId/invite-link/regenerate';

  /// Get community members: /communities/{communityId}/members
  static String getCommunityMembers(String communityId) =>
      '/communities/$communityId/members';

  /// Add co-admins: /communities/add-co-admins
  static const String addCoAdmins = '/communities/add-co-admins';

  /// Remove co-admin: /communities/remove-admin
  static const String removeAdmin = '/communities/remove-admin';

  /// Get join requests: /communities/{communityId}/join-requests
  static String getJoinRequests(String communityId) =>
      '/communities/$communityId/join-requests';

  /// Approve join request: /communities/join-requests/{requestId}/approve
  static String approveJoinRequest(String requestId) =>
      '/communities/join-requests/$requestId/approve';

  /// Reject join request: /communities/join-requests/{requestId}/reject
  static String rejectJoinRequest(String requestId) =>
      '/communities/join-requests/$requestId/reject';

  // Invites (public endpoints)
  /// Get invite details by token: /invites/{token}
  static String getInviteDetails(String token) => '/invites/$token';

  /// Join via invite link: /invites/{token}/join
  static String joinViaInvite(String token) => '/invites/$token/join';

  /// Get user's join request status: /invites/{communityId}/request-status
  static String getJoinRequestStatus(String communityId) =>
      '/invites/$communityId/request-status';

  // Notifications
  static const String updateDeviceToken = '/notifications/device-token';

  // Wallet
  static const String walletSetupProgress = '/wallet/setup/progress';
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletStep2Complete = '/wallet/step2/complete';
  static const String walletStep3Complete = '/wallet/step3/complete';
  static const String walletStep4Complete = '/wallet/step4/complete';
  static const String walletStep4Skip = '/wallet/step4/skip';
  static const String walletStep5Complete = '/wallet/step5/complete';
  static const String walletBanks = '/wallet/banks';
  static const String walletResolveAccount = '/wallet/resolve-account';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletTransfer = '/wallet/transfer';

  // BVN Validation
  static const String bvnInitiate = '/wallet/bvn/initiate';
  static const String bvnVerify = '/wallet/bvn/verify';
  static const String bvnDetails = '/wallet/bvn/details';

  // Debug Endpoints (for testing deposit flow)
  static const String walletWebhookLogs = '/wallet/webhook-logs';
  static const String walletDebug = '/wallet/debug-wallet';
  static const String walletTestDeposit = '/wallet/test-deposit';
}
