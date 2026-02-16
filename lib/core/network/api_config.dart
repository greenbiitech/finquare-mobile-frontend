/// API Configuration
class ApiConfig {
  // Local development URL (10.0.2.2 for Android Emulator -> host localhost)
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

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

  /// Switch active community: /communities/{communityId}/switch
  static String switchCommunity(String communityId) =>
      '/communities/$communityId/switch';

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

  /// Get co-admins for signatory selection: /communities/{communityId}/co-admins
  static String getCoAdmins(String communityId) =>
      '/communities/$communityId/co-admins';

  /// Check wallet creation eligibility: /communities/{communityId}/wallet-eligibility
  static String getWalletEligibility(String communityId) =>
      '/communities/$communityId/wallet-eligibility';

  /// Get community wallet: /communities/{communityId}/wallet
  static String getCommunityWallet(String communityId) =>
      '/communities/$communityId/wallet';

  /// Create community wallet: /communities/{communityId}/wallet
  static String createCommunityWallet(String communityId) =>
      '/communities/$communityId/wallet';

  /// Add co-admins: /communities/{communityId}/add-co-admins
  static String addCoAdmins(String communityId) =>
      '/communities/$communityId/add-co-admins';

  /// Remove co-admin: /communities/{communityId}/remove-co-admin
  static String removeCoAdmin(String communityId) =>
      '/communities/$communityId/remove-co-admin';

  /// Remove member: /communities/{communityId}/remove-member
  static String removeMember(String communityId) =>
      '/communities/$communityId/remove-member';

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
  static const String walletLookupRecipient = '/wallet/lookup-recipient';
  static const String walletInternalTransfer = '/wallet/internal-transfer';

  // BVN Validation
  static const String bvnInitiate = '/wallet/bvn/initiate';
  static const String bvnVerify = '/wallet/bvn/verify';
  static const String bvnDetails = '/wallet/bvn/details';

  // NIN Validation (Tier 1)
  static const String ninLookup = '/wallet/nin/lookup';

  // Tier-based Wallet Creation
  static const String walletTier1Complete = '/wallet/tier1/complete';

  // Wallet Upgrade (Tier 2/3)
  static const String upgradeStatus = '/wallet/upgrade/status';
  static const String upgradeStart = '/wallet/upgrade/start';
  static const String upgradeIdentity = '/wallet/upgrade/identity';
  static const String upgradePersonalInfo = '/wallet/upgrade/personal-info';
  static const String upgradeIdDocument = '/wallet/upgrade/id-document';
  static const String upgradeFace = '/wallet/upgrade/face';
  static const String upgradeAddress = '/wallet/upgrade/address';
  static const String upgradeUtilityBill = '/wallet/upgrade/utility-bill';
  static const String upgradeSignature = '/wallet/upgrade/signature';
  static const String upgradeCancel = '/wallet/upgrade/cancel';

  // Upgrade BVN Validation (with OTP)
  static const String upgradeBvnInitiate = '/wallet/upgrade/bvn/initiate';
  static const String upgradeBvnVerify = '/wallet/upgrade/bvn/verify';
  static const String upgradeBvnDetails = '/wallet/upgrade/bvn/details';

  // Debug Endpoints (for testing deposit flow)
  static const String walletWebhookLogs = '/wallet/webhook-logs';
  static const String walletDebug = '/wallet/debug-wallet';
  static const String walletTestDeposit = '/wallet/test-deposit';

  // Withdrawal Account
  static const String withdrawalAccount = '/withdrawals/account';
  static const String withdrawalAccountMe = '/withdrawals/account/me';

  // Esusu
  static const String esusu = '/esusu';

  /// Check Esusu creation eligibility: /esusu/{communityId}/eligibility
  static String esusuEligibility(String communityId) =>
      '/esusu/$communityId/eligibility';

  /// Check Esusu name availability: /esusu/check-name/{communityId}/{name}
  static String esusuCheckName(String communityId, String name) =>
      '/esusu/check-name/$communityId/$name';

  /// Get community members for Esusu participant selection: /esusu/{communityId}/members
  static String esusuCommunityMembers(String communityId) =>
      '/esusu/$communityId/members';

  /// Get Esusu count for Hub display: /esusu/hub-count/{communityId}
  static String esusuHubCount(String communityId) =>
      '/esusu/hub-count/$communityId';

  /// Get Esusu list: /esusu/list/{communityId}
  static String esusuList(String communityId) =>
      '/esusu/list/$communityId';

  /// Get Esusu invitation details: /esusu/{esusuId}/invitation
  static String esusuInvitationDetails(String esusuId) =>
      '/esusu/$esusuId/invitation';

  /// Respond to Esusu invitation: /esusu/{esusuId}/respond
  static String esusuRespondInvitation(String esusuId) =>
      '/esusu/$esusuId/respond';

  /// Get slot details for FCFS: /esusu/{esusuId}/slots
  static String esusuSlotDetails(String esusuId) => '/esusu/$esusuId/slots';

  /// Select a slot for FCFS: /esusu/{esusuId}/select-slot
  static String esusuSelectSlot(String esusuId) => '/esusu/$esusuId/select-slot';

  /// Get waiting room details: /esusu/{esusuId}/waiting-room
  static String esusuWaitingRoom(String esusuId) => '/esusu/$esusuId/waiting-room';

  /// Send reminders to pending participants: /esusu/{esusuId}/remind
  static String esusuRemind(String esusuId) => '/esusu/$esusuId/remind';

  // Contributions
  static const String contributions = '/contributions';

  /// Check Contribution creation eligibility: /contributions/{communityId}/eligibility
  static String contributionEligibility(String communityId) =>
      '/contributions/$communityId/eligibility';

  /// Get community members for participant selection: /contributions/{communityId}/members
  static String contributionCommunityMembers(String communityId) =>
      '/contributions/$communityId/members';

  /// Get Contribution count for Hub display: /contributions/hub-count/{communityId}
  static String contributionHubCount(String communityId) =>
      '/contributions/hub-count/$communityId';

  /// Get Contribution list: /contributions/list/{communityId}
  static String contributionList(String communityId) =>
      '/contributions/list/$communityId';

  /// Get pending invitations: /contributions/invitations/{communityId}
  static String contributionPendingInvitations(String communityId) =>
      '/contributions/invitations/$communityId';

  /// Get Contribution details: /contributions/{contributionId}
  static String contributionDetails(String contributionId) =>
      '/contributions/$contributionId';

  /// Respond to Contribution invitation: /contributions/{contributionId}/respond
  static String contributionRespondInvitation(String contributionId) =>
      '/contributions/$contributionId/respond';

  /// Make a contribution payment: /contributions/{contributionId}/contribute
  static String contributionContribute(String contributionId) =>
      '/contributions/$contributionId/contribute';
}
