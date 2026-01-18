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
  static const String bvnValidation = '/bvn-validation';
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

  // Hub routes
  static const String createHub = '/create-hub';

  // Dues routes
  static const String duesWelcome = '/dues-welcome';
  static const String duesWarning = '/dues-warning';
  static const String createNewDues = '/create-new-dues';
  static const String configureDues = '/configure-dues';
  static const String duesSuccess = '/dues-success';

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
        path: AppRoutes.bvnValidation,
        name: 'bvnValidation',
        builder: (context, state) => const BvnValidationPage(),
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
        builder: (context, state) => const CreateTransactionPinPage(),
      ),
      GoRoute(
        path: AppRoutes.confirmTransactionPin,
        name: 'confirmTransactionPin',
        builder: (context, state) {
          final firstPin = state.extra as String;
          return ConfirmTransactionPinPage(firstPin: firstPin);
        },
      ),
      GoRoute(
        path: AppRoutes.walletSuccess,
        name: 'walletSuccess',
        builder: (context, state) => const WalletSuccessPage(),
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
