import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:finsquare_mobile_app/features/splash/presentation/pages/splash_page.dart';
import 'package:finsquare_mobile_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/signup_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/verify_account_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/create_passkey_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/confirm_passkey_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/passkey_login_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/pick_membership_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/onboard_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/register_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/community_membership_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/invite_link_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/invite_members_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/individual_membership_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/welcome_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/join_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/login_page.dart';
import 'package:finsquare_mobile_app/features/community/presentation/pages/invite_settings_page.dart';
import 'package:finsquare_mobile_app/features/community/presentation/pages/join_requests_page.dart';
import 'package:finsquare_mobile_app/features/community/presentation/pages/community_members_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/verify_reset_password_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/enter_new_password_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/reset_password_success_page.dart';
import 'package:finsquare_mobile_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/activate_wallet_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/bvn_validation_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/select_verification_type_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/nin_validation_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/wallet_upgrade_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_identity_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_personal_info_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_id_document_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_face_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_address_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_utility_bill_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_signature_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/upgrade_pending_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/select_verification_method_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/verify_bvn_credentials_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/verify_otp_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/verify_personal_info_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/address_info_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/create_transaction_pin_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/confirm_transaction_pin_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/wallet_success_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/face_verification_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/confirm_photo_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/proof_of_address_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/top_up_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/withdrawal_success_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/wallet_transfer_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/wallet_transfer_amount_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/transfer_success_page.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/hub/presentation/pages/create_hub_page.dart';
import 'package:finsquare_mobile_app/features/dues/presentation/pages/dues_welcome_page.dart';
import 'package:finsquare_mobile_app/features/dues/presentation/pages/dues_warning_page.dart';
import 'package:finsquare_mobile_app/features/dues/presentation/pages/create_new_dues_page.dart';
import 'package:finsquare_mobile_app/features/dues/presentation/pages/configure_dues_page.dart';
import 'package:finsquare_mobile_app/features/dues/presentation/pages/dues_success_page.dart';
import 'package:finsquare_mobile_app/features/dues/data/models/due_creation_data.dart';
import 'package:finsquare_mobile_app/features/community/presentation/pages/manage_community_page.dart';
import 'package:finsquare_mobile_app/features/community/presentation/pages/members_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/community_wallet_setup_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/esusu_welcome_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/create_esusu_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/configure_esusu_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/add_participants_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/select_payout_order_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/esusu_success_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/esusu_list_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/esusu_detail_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/active_esusu_detail_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/esusu_invitation_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/slot_selection_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/esusu_waiting_room_page.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/pages/admin_slot_selection_page.dart';
import 'package:finsquare_mobile_app/features/notifications/presentation/pages/hub_notifications_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contributions_welcome_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/create_contribution_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/configure_contribution_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/add_participants_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contribution_success_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contributions_list_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contribution_detail_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contribution_payment_page.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contribution_payment_success_page.dart';

part 'app_router.g.dart';

/// Route paths as constants for type-safe navigation
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String passkeyLogin = '/passkey-login';
  static const String signup = '/signup';
  static const String verifyAccount = '/verify-account';
  static const String createPasskey = '/create-passkey';
  static const String confirmPasskey = '/confirm-passkey';
  static const String pickMembership = '/pick-membership';
  static const String onboardCommunity = '/onboard-community';
  static const String registerCommunity = '/register-community';
  static const String communityMembership = '/community-membership';
  static const String inviteLink = '/invite-link';
  static const String inviteMembers = '/invite-members';
  static const String individualMembership = '/individual-membership';
  static const String welcomeCommunity = '/welcome-community';
  static const String resetPassword = '/reset-password';
  static const String verifyResetPassword = '/verify-reset-password';
  static const String enterNewPassword = '/enter-new-password';
  static const String resetPasswordSuccess = '/reset-password-success';
  static const String joinCommunity = '/join-community';
  static const String inviteSettings = '/invite-settings';
  static const String joinRequests = '/join-requests';
  static const String communityMembers = '/community-members';
  static const String home = '/home';

  // Wallet routes
  static const String activateWallet = '/activate-wallet';
  static const String selectVerificationType = '/select-verification-type';
  static const String bvnValidation = '/bvn-validation';
  static const String ninValidation = '/nin-validation';
  static const String selectVerificationMethod = '/select-verification-method';
  static const String verifyBvnCredentials = '/verify-bvn-credentials';
  static const String verifyOtp = '/verify-otp';
  static const String verifyPersonalInfo = '/verify-personal-info';
  static const String addressInfo = '/address-info';
  static const String faceVerification = '/face-verification';
  static const String confirmPhoto = '/confirm-photo';
  static const String proofOfAddress = '/proof-of-address';
  static const String createTransactionPin = '/create-transaction-pin';
  static const String confirmTransactionPin = '/confirm-transaction-pin';
  static const String walletSuccess = '/wallet-success';
  static const String topUp = '/top-up';
  static const String withdraw = '/withdraw';
  static const String withdrawalSuccess = '/withdrawal-success';

  // Wallet Transfer routes
  static const String walletTransfer = '/wallet-transfer';
  static const String walletTransferAmount = '/wallet-transfer-amount';
  static const String transferSuccess = '/transfer-success';

  // Wallet Upgrade routes
  static const String walletUpgrade = '/wallet-upgrade';
  static const String upgradeIdentity = '/upgrade-identity';
  static const String upgradePersonalInfo = '/upgrade-personal-info';
  static const String upgradeIdDocument = '/upgrade-id-document';
  static const String upgradeFace = '/upgrade-face';
  static const String upgradeAddress = '/upgrade-address';
  static const String upgradeUtilityBill = '/upgrade-utility-bill';
  static const String upgradeSignature = '/upgrade-signature';
  static const String upgradePending = '/upgrade-pending';

  // Hub routes
  static const String createHub = '/create-hub';
  static const String hubNotifications = '/hub-notifications';

  // Dues routes
  static const String duesWelcome = '/dues-welcome';
  static const String duesWarning = '/dues-warning';
  static const String createNewDues = '/create-new-dues';
  static const String configureDues = '/configure-dues';
  static const String duesSuccess = '/dues-success';

  // Contributions routes
  static const String contributionsList = '/contributions-list';
  static const String contributionDetail = '/contribution-detail';
  static const String contributionPayment = '/contribution-payment';
  static const String contributionPaymentSuccess = '/contribution-payment-success';
  static const String contributionsWelcome = '/contributions-welcome';
  static const String createContribution = '/create-contribution';
  static const String configureContribution = '/configure-contribution';
  static const String contributionAddParticipants = '/contribution-add-participants';
  static const String contributionSuccess = '/contribution-success';

  // Esusu routes
  static const String esusuList = '/esusu-list';
  static const String esusuDetail = '/esusu-detail';
  static const String activeEsusuDetail = '/active-esusu-detail';
  static const String esusuInvitation = '/esusu-invitation';
  static const String esusuSlotSelection = '/esusu-slot-selection';
  static const String esusuWaitingRoom = '/esusu-waiting-room';
  static const String esusuWelcome = '/esusu-welcome';
  static const String createEsusu = '/create-esusu';
  static const String configureEsusu = '/configure-esusu';
  static const String addParticipants = '/add-participants';
  static const String selectPayoutOrder = '/select-payout-order';
  static const String adminSlotSelection = '/admin-slot-selection';
  static const String esusuSuccess = '/esusu-success';

  // Community management routes
  static const String manageCommunity = '/manage-community';
  static const String communityMembersList = '/community-members-list';
  static const String communityWalletSetup = '/community-wallet-setup';

  // Dashboard alias
  static const String dashboard = '/home';
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Handle deep links from custom scheme
    redirect: (context, state) {
      final uri = state.uri;

      // Handle finsquare://invite/{token} deep links
      if (uri.scheme == 'finsquare' || uri.toString().startsWith('finsquare://')) {
        // Parse the token from the URI
        String? token;

        if (uri.host == 'invite' && uri.pathSegments.isNotEmpty) {
          token = uri.pathSegments.first;
        } else if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'invite') {
          token = uri.pathSegments[1];
        }

        if (token != null && token.isNotEmpty) {
          return '${AppRoutes.joinCommunity}/$token';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.passkeyLogin,
        name: 'passkeyLogin',
        builder: (context, state) => const PasskeyLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyAccount,
        name: 'verifyAccount',
        builder: (context, state) => const VerifyAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.createPasskey,
        name: 'createPasskey',
        builder: (context, state) => const CreatePasskeyPage(),
      ),
      GoRoute(
        path: AppRoutes.confirmPasskey,
        name: 'confirmPasskey',
        builder: (context, state) {
          final pin = state.extra as String;
          return ConfirmPasskeyPage(pin: pin);
        },
      ),
      GoRoute(
        path: AppRoutes.pickMembership,
        name: 'pickMembership',
        builder: (context, state) => const PickMembershipPage(),
      ),
      GoRoute(
        path: AppRoutes.onboardCommunity,
        name: 'onboardCommunity',
        builder: (context, state) => const OnboardCommunityPage(),
      ),
      GoRoute(
        path: AppRoutes.registerCommunity,
        name: 'registerCommunity',
        builder: (context, state) => const RegisterCommunityPage(),
      ),
      GoRoute(
        path: AppRoutes.communityMembership,
        name: 'communityMembership',
        builder: (context, state) => const CommunityMembershipPage(),
      ),
      GoRoute(
        path: AppRoutes.inviteLink,
        name: 'inviteLink',
        builder: (context, state) => const InviteLinkPage(),
      ),
      // Invite link options for existing community (from Members page)
      GoRoute(
        path: '${AppRoutes.inviteLink}/:communityId',
        name: 'inviteLinkWithCommunity',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return InviteLinkPage(communityId: communityId);
        },
      ),
      GoRoute(
        path: AppRoutes.inviteMembers,
        name: 'inviteMembers',
        builder: (context, state) => const InviteMembersPage(),
      ),
      // Invite members for existing community (from Members page)
      GoRoute(
        path: '${AppRoutes.inviteMembers}/:communityId',
        name: 'inviteMembersWithCommunity',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return InviteMembersPage(communityId: communityId);
        },
      ),
      GoRoute(
        path: AppRoutes.individualMembership,
        name: 'individualMembership',
        builder: (context, state) => const IndividualMembershipPage(),
      ),
      GoRoute(
        path: AppRoutes.welcomeCommunity,
        name: 'welcomeCommunity',
        builder: (context, state) => const WelcomeCommunityPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyResetPassword,
        name: 'verifyResetPassword',
        builder: (context, state) => const VerifyResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.enterNewPassword,
        name: 'enterNewPassword',
        builder: (context, state) => const EnterNewPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPasswordSuccess,
        name: 'resetPasswordSuccess',
        builder: (context, state) => const ResetPasswordSuccessPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) {
          final initialIndex = state.extra as int? ?? 0;
          return DashboardPage(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '${AppRoutes.joinCommunity}/:token',
        name: 'joinCommunity',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return JoinCommunityPage(inviteToken: token);
        },
      ),
      GoRoute(
        path: '${AppRoutes.inviteSettings}/:communityId',
        name: 'inviteSettings',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return InviteSettingsPage(communityId: communityId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.joinRequests}/:communityId',
        name: 'joinRequests',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return JoinRequestsPage(communityId: communityId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.communityMembers}/:communityId',
        name: 'communityMembers',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return CommunityMembersPage(communityId: communityId);
        },
      ),
      // Wallet routes
      GoRoute(
        path: AppRoutes.activateWallet,
        name: 'activateWallet',
        builder: (context, state) => const ActivateWalletPage(),
      ),
      GoRoute(
        path: AppRoutes.selectVerificationType,
        name: 'selectVerificationType',
        builder: (context, state) => const SelectVerificationTypePage(),
      ),
      GoRoute(
        path: AppRoutes.bvnValidation,
        name: 'bvnValidation',
        builder: (context, state) => const BvnValidationPage(),
      ),
      GoRoute(
        path: AppRoutes.ninValidation,
        name: 'ninValidation',
        builder: (context, state) => const NinValidationPage(),
      ),
      GoRoute(
        path: AppRoutes.selectVerificationMethod,
        name: 'selectVerificationMethod',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final methodsList = extra?['methods'] as List<dynamic>? ?? [];
          return SelectVerificationMethodPage(
            sessionId: extra?['sessionId'] ?? '',
            methods: methodsList
                .whereType<BvnMethodOption>()
                .toList(),
            isUpgrade: extra?['isUpgrade'] ?? false,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.verifyBvnCredentials,
        name: 'verifyBvnCredentials',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerifyBvnCredentialsPage(
            sessionId: extra?['sessionId'] ?? '',
            method: extra?['method'] ?? '',
            isUpgrade: extra?['isUpgrade'] ?? false,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerifyOtpPage(
            sessionId: extra?['sessionId'] ?? '',
            method: extra?['method'] ?? '',
            isUpgrade: extra?['isUpgrade'] ?? false,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.verifyPersonalInfo,
        name: 'verifyPersonalInfo',
        builder: (context, state) {
          final extra = state.extra;
          // Handle both WalletSetupProgress (resume flow) and Map (BVN validation flow)
          if (extra is WalletSetupProgress) {
            return VerifyPersonalInfoPage(progress: extra);
          } else if (extra is Map<String, dynamic>) {
            final bvnDataMap = extra['bvnData'] as Map<String, dynamic>?;
            if (bvnDataMap != null) {
              return VerifyPersonalInfoPage(
                bvnData: BvnData(
                  firstName: bvnDataMap['firstName'],
                  lastName: bvnDataMap['lastName'],
                  middleName: bvnDataMap['middleName'],
                  phoneNumber: bvnDataMap['phoneNumber'],
                  dateOfBirth: bvnDataMap['dateOfBirth'],
                  gender: bvnDataMap['gender'],
                ),
              );
            }
          }
          return const VerifyPersonalInfoPage();
        },
      ),
      GoRoute(
        path: AppRoutes.addressInfo,
        name: 'addressInfo',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddressInfoPage(
            progress: extra?['progress'] as WalletSetupProgress?,
            occupation: extra?['occupation'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.faceVerification,
        name: 'faceVerification',
        builder: (context, state) => const FaceVerificationPage(),
      ),
      GoRoute(
        path: AppRoutes.confirmPhoto,
        name: 'confirmPhoto',
        builder: (context, state) {
          final filePath = state.extra as String;
          return ConfirmPhotoPage(filePath: filePath);
        },
      ),
      GoRoute(
        path: AppRoutes.proofOfAddress,
        name: 'proofOfAddress',
        builder: (context, state) => const ProofOfAddressPage(),
      ),
      GoRoute(
        path: AppRoutes.createTransactionPin,
        name: 'createTransactionPin',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateTransactionPinPage(
            verificationType: extra?['verificationType'] as String?,
            verificationData: extra?['verificationData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.confirmTransactionPin,
        name: 'confirmTransactionPin',
        builder: (context, state) {
          final extra = state.extra;
          // Handle both old format (String) and new format (Map)
          if (extra is String) {
            return ConfirmTransactionPinPage(firstPin: extra);
          }
          final extraMap = extra as Map<String, dynamic>?;
          return ConfirmTransactionPinPage(
            firstPin: extraMap?['firstPin'] as String? ?? '',
            verificationType: extraMap?['verificationType'] as String?,
            verificationData: extraMap?['verificationData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.walletSuccess,
        name: 'walletSuccess',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WalletSuccessPage(
            accountNumber: extra?['accountNumber'],
            accountName: extra?['accountName'],
          );
        },
      ),
      // Wallet Transfer routes
      GoRoute(
        path: AppRoutes.walletTransfer,
        name: 'walletTransfer',
        builder: (context, state) => const WalletTransferPage(),
      ),
      GoRoute(
        path: AppRoutes.walletTransferAmount,
        name: 'walletTransferAmount',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WalletTransferAmountPage(
            recipientUserId: extra?['recipientUserId'] ?? '',
            recipientName: extra?['recipientName'] ?? '',
            recipientMaskedEmail: extra?['recipientMaskedEmail'],
            recipientAvatar: extra?['recipientAvatar'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.transferSuccess,
        name: 'transferSuccess',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TransferSuccessPage(
            recipientName: extra?['recipientName'] ?? '',
            amount: extra?['amount'] ?? 0.0,
          );
        },
      ),
      // Wallet Upgrade routes
      GoRoute(
        path: AppRoutes.walletUpgrade,
        name: 'walletUpgrade',
        builder: (context, state) => const WalletUpgradePage(),
      ),
      GoRoute(
        path: AppRoutes.upgradeIdentity,
        name: 'upgradeIdentity',
        builder: (context, state) => const UpgradeIdentityPage(),
      ),
      GoRoute(
        path: AppRoutes.upgradePersonalInfo,
        name: 'upgradePersonalInfo',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return UpgradePersonalInfoPage(
            bvnData: extra?['bvnData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.upgradeIdDocument,
        name: 'upgradeIdDocument',
        builder: (context, state) => const UpgradeIdDocumentPage(),
      ),
      GoRoute(
        path: AppRoutes.upgradeFace,
        name: 'upgradeFace',
        builder: (context, state) => const UpgradeFacePage(),
      ),
      GoRoute(
        path: AppRoutes.upgradeAddress,
        name: 'upgradeAddress',
        builder: (context, state) => const UpgradeAddressPage(),
      ),
      GoRoute(
        path: AppRoutes.upgradeUtilityBill,
        name: 'upgradeUtilityBill',
        builder: (context, state) => const UpgradeUtilityBillPage(),
      ),
      GoRoute(
        path: AppRoutes.upgradeSignature,
        name: 'upgradeSignature',
        builder: (context, state) => const UpgradeSignaturePage(),
      ),
      GoRoute(
        path: AppRoutes.upgradePending,
        name: 'upgradePending',
        builder: (context, state) => const UpgradePendingPage(),
      ),
      GoRoute(
        path: AppRoutes.topUp,
        name: 'topUp',
        builder: (context, state) => const TopUpPage(),
      ),
      GoRoute(
        path: AppRoutes.withdrawalSuccess,
        name: 'withdrawalSuccess',
        builder: (context, state) => const WithdrawalSuccessPage(),
      ),
      // Hub routes
      GoRoute(
        path: AppRoutes.createHub,
        name: 'createHub',
        builder: (context, state) => const CreateHubPage(),
      ),
      GoRoute(
        path: '${AppRoutes.hubNotifications}/:communityId',
        name: 'hubNotifications',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return HubNotificationsPage(communityId: communityId);
        },
      ),
      // Dues routes
      GoRoute(
        path: AppRoutes.duesWelcome,
        name: 'duesWelcome',
        builder: (context, state) => const DuesWelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.duesWarning,
        name: 'duesWarning',
        builder: (context, state) => const DuesWarningPage(),
      ),
      GoRoute(
        path: AppRoutes.createNewDues,
        name: 'createNewDues',
        builder: (context, state) => const CreateNewDuesPage(),
      ),
      GoRoute(
        path: AppRoutes.configureDues,
        name: 'configureDues',
        builder: (context, state) {
          final dueData = state.extra as DueCreationData?;
          return ConfigureDuesPage(dueData: dueData);
        },
      ),
      GoRoute(
        path: AppRoutes.duesSuccess,
        name: 'duesSuccess',
        builder: (context, state) {
          final dueData = state.extra as DueCreationData?;
          return DuesSuccessPage(dueData: dueData);
        },
      ),
      // Contributions routes
      GoRoute(
        path: AppRoutes.contributionsList,
        name: 'contributionsList',
        builder: (context, state) => const ContributionsListPage(),
      ),
      GoRoute(
        path: '${AppRoutes.contributionDetail}/:contributionId',
        name: 'contributionDetail',
        builder: (context, state) {
          final contributionId = state.pathParameters['contributionId'] ?? '';
          final contributionName = state.uri.queryParameters['name'] ?? 'Contribution';
          final extra = state.extra as Map<String, dynamic>?;
          return ContributionDetailPage(
            contributionId: contributionId,
            contributionName: contributionName,
            contributionType: extra?['contributionType'] ?? PaymentContributionType.flexible,
            recipientName: extra?['recipientName'] ?? '',
            fixedAmount: extra?['fixedAmount'],
            targetAmount: extra?['targetAmount'],
            contributedSoFar: extra?['contributedSoFar'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contributionPayment,
        name: 'contributionPayment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ContributionPaymentPage(
            contributionId: extra?['contributionId'] ?? '',
            contributionName: extra?['contributionName'] ?? 'Contribution',
            recipientName: extra?['recipientName'] ?? '',
            amount: extra?['amount'] ?? 0.0,
            contributionType: extra?['contributionType'] ?? PaymentContributionType.fixed,
            contributedSoFar: extra?['contributedSoFar'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contributionPaymentSuccess,
        name: 'contributionPaymentSuccess',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ContributionPaymentSuccessPage(
            contributionName: extra?['contributionName'] ?? 'Contribution',
            recipientName: extra?['recipientName'] ?? '',
            amount: extra?['amount'] ?? 0.0,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contributionsWelcome,
        name: 'contributionsWelcome',
        builder: (context, state) => const ContributionsWelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.createContribution,
        name: 'createContribution',
        builder: (context, state) => const CreateContributionPage(),
      ),
      GoRoute(
        path: AppRoutes.configureContribution,
        name: 'configureContribution',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ConfigureContributionPage(
            contributionType: extra?['contributionType'] as ContributionType?,
            contributionName: extra?['contributionName'] as String?,
            contributionDescription: extra?['contributionDescription'] as String?,
            imagePath: extra?['imagePath'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contributionAddParticipants,
        name: 'contributionAddParticipants',
        builder: (context, state) => const ContributionAddParticipantsPage(),
      ),
      GoRoute(
        path: AppRoutes.contributionSuccess,
        name: 'contributionSuccess',
        builder: (context, state) => const ContributionSuccessPage(),
      ),
      // Esusu routes
      GoRoute(
        path: AppRoutes.esusuList,
        name: 'esusuList',
        builder: (context, state) => const EsusuListPage(),
      ),
      GoRoute(
        path: '${AppRoutes.esusuDetail}/:esusuId',
        name: 'esusuDetail',
        builder: (context, state) {
          final esusuId = state.pathParameters['esusuId'] ?? '';
          final esusuName = state.uri.queryParameters['name'] ?? 'Esusu';
          return EsusuDetailPage(esusuId: esusuId, esusuName: esusuName);
        },
      ),
      GoRoute(
        path: '${AppRoutes.activeEsusuDetail}/:esusuId',
        name: 'activeEsusuDetail',
        builder: (context, state) {
          final esusuId = state.pathParameters['esusuId'] ?? '';
          final esusuName = state.uri.queryParameters['name'] ?? 'Esusu';
          return ActiveEsusuDetailPage(esusuId: esusuId, esusuName: esusuName);
        },
      ),
      GoRoute(
        path: '${AppRoutes.esusuInvitation}/:esusuId',
        name: 'esusuInvitation',
        builder: (context, state) {
          final esusuId = state.pathParameters['esusuId'] ?? '';
          final esusuName = state.uri.queryParameters['name'] ?? 'Esusu';
          return EsusuInvitationPage(esusuId: esusuId, esusuName: esusuName);
        },
      ),
      GoRoute(
        path: '${AppRoutes.esusuSlotSelection}/:esusuId',
        name: 'esusuSlotSelection',
        builder: (context, state) {
          final esusuId = state.pathParameters['esusuId'] ?? '';
          final esusuName = state.uri.queryParameters['name'] ?? 'Esusu';
          final isAdmin = state.uri.queryParameters['isAdmin'] == 'true';
          return SlotSelectionPage(esusuId: esusuId, esusuName: esusuName, isAdmin: isAdmin);
        },
      ),
      GoRoute(
        path: '${AppRoutes.esusuWaitingRoom}/:esusuId',
        name: 'esusuWaitingRoom',
        builder: (context, state) {
          final esusuId = state.pathParameters['esusuId'] ?? '';
          final esusuName = state.uri.queryParameters['name'] ?? 'Esusu';
          return EsusuWaitingRoomPage(esusuId: esusuId, esusuName: esusuName);
        },
      ),
      GoRoute(
        path: AppRoutes.esusuWelcome,
        name: 'esusuWelcome',
        builder: (context, state) => const EsusuWelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.createEsusu,
        name: 'createEsusu',
        builder: (context, state) => const CreateEsusuPage(),
      ),
      GoRoute(
        path: AppRoutes.configureEsusu,
        name: 'configureEsusu',
        builder: (context, state) => const ConfigureEsusuPage(),
      ),
      GoRoute(
        path: AppRoutes.addParticipants,
        name: 'addParticipants',
        builder: (context, state) => const AddParticipantsPage(),
      ),
      GoRoute(
        path: AppRoutes.selectPayoutOrder,
        name: 'selectPayoutOrder',
        builder: (context, state) => const SelectPayoutOrderPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSlotSelection,
        name: 'adminSlotSelection',
        builder: (context, state) => const AdminSlotSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.esusuSuccess,
        name: 'esusuSuccess',
        builder: (context, state) => const EsusuSuccessPage(),
      ),
      // Community management routes
      GoRoute(
        path: '${AppRoutes.manageCommunity}/:communityId',
        name: 'manageCommunity',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return ManageCommunityPage(communityId: communityId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.communityMembersList}/:communityId',
        name: 'communityMembersList',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return MembersPage(communityId: communityId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.communityWalletSetup}/:communityId',
        name: 'communityWalletSetup',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return CommunityWalletSetupPage(communityId: communityId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
