import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

/// Community Wallet Setup State
class CommunityWalletState {
  final bool isLoading;
  final String? error;
  final List<CoAdmin> coAdmins;
  final CommunityWalletEligibility? eligibility;
  final bool walletCreated;
  final String? walletId;

  const CommunityWalletState({
    this.isLoading = false,
    this.error,
    this.coAdmins = const [],
    this.eligibility,
    this.walletCreated = false,
    this.walletId,
  });

  CommunityWalletState copyWith({
    bool? isLoading,
    String? error,
    List<CoAdmin>? coAdmins,
    CommunityWalletEligibility? eligibility,
    bool? walletCreated,
    String? walletId,
  }) {
    return CommunityWalletState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      coAdmins: coAdmins ?? this.coAdmins,
      eligibility: eligibility ?? this.eligibility,
      walletCreated: walletCreated ?? this.walletCreated,
      walletId: walletId ?? this.walletId,
    );
  }
}

/// Community Wallet Notifier
class CommunityWalletNotifier extends StateNotifier<CommunityWalletState> {
  final WalletRepository _repository;
  final Ref _ref;

  CommunityWalletNotifier(this._repository, this._ref) : super(const CommunityWalletState());

  /// Get current user info (admin)
  Map<String, String> get adminInfo {
    final authState = _ref.read(authProvider);
    final user = authState.user;
    return {
      'name': user?.fullName ?? 'Admin',
      'email': user?.email ?? '',
    };
  }

  /// Fetch co-admins for a community
  Future<void> fetchCoAdmins(String communityId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final coAdmins = await _repository.getCoAdmins(communityId);
      state = state.copyWith(isLoading: false, coAdmins: coAdmins);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Check wallet eligibility
  Future<void> checkEligibility(String communityId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final eligibility = await _repository.checkWalletEligibility(communityId);
      state = state.copyWith(isLoading: false, eligibility: eligibility);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create community wallet
  Future<bool> createWallet({
    required String communityId,
    required List<String> signatoryIds,
    required String approvalRule,
    required String transactionPin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = CreateCommunityWalletRequest(
        signatoryIds: signatoryIds,
        approvalRule: approvalRule,
        transactionPin: transactionPin,
      );
      final response = await _repository.createCommunityWallet(communityId, request);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          walletCreated: true,
          walletId: response.walletId,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const CommunityWalletState();
  }
}

/// Provider for community wallet setup
final communityWalletProvider = StateNotifierProvider<CommunityWalletNotifier, CommunityWalletState>((ref) {
  return CommunityWalletNotifier(
    ref.watch(walletRepositoryProvider),
    ref,
  );
});
