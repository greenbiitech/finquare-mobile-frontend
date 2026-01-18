import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';

/// Community State
class CommunityState {
  final bool isLoading;
  final String? error;
  final ActiveCommunity? activeCommunity;
  final List<UserCommunity> myCommunities;

  const CommunityState({
    this.isLoading = false,
    this.error,
    this.activeCommunity,
    this.myCommunities = const [],
  });

  /// Communities where user is ADMIN (created by user)
  List<UserCommunity> get userCommunitiesCreated {
    return myCommunities.where((c) => c.isAdmin).toList();
  }

  /// User's role in active community
  String? get userRoleInActiveCommunity {
    return activeCommunity?.role;
  }

  CommunityState copyWith({
    bool? isLoading,
    String? error,
    ActiveCommunity? activeCommunity,
    List<UserCommunity>? myCommunities,
    bool clearError = false,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeCommunity: activeCommunity ?? this.activeCommunity,
      myCommunities: myCommunities ?? this.myCommunities,
    );
  }
}

/// Community Notifier
class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;

  CommunityNotifier(this._repository) : super(const CommunityState());

  /// Join the default FinSquare community
  Future<bool> joinDefaultCommunity() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.joinDefaultCommunity();

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          activeCommunity: response.activeCommunity,
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

  /// Fetch active community from server
  Future<void> fetchActiveCommunity() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final activeCommunity = await _repository.getActiveCommunity();
      state = state.copyWith(
        isLoading: false,
        activeCommunity: activeCommunity,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch community',
      );
    }
  }

  /// Fetch all communities user is a member of
  Future<void> fetchMyCommunities() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.getMyCommunities();
      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          myCommunities: response.communities,
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
        error: 'Failed to fetch communities',
      );
    }
  }

  /// Fetch all community data (active community + user's communities)
  Future<void> fetchAllCommunityData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Fetch both in parallel
      final results = await Future.wait([
        _repository.getActiveCommunity(),
        _repository.getMyCommunities(),
      ]);

      final activeCommunity = results[0] as ActiveCommunity?;
      final myCommunitiesResponse = results[1] as MyCommunitiesResponse;

      state = state.copyWith(
        isLoading: false,
        activeCommunity: activeCommunity,
        myCommunities: myCommunitiesResponse.success
            ? myCommunitiesResponse.communities
            : state.myCommunities,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch community data',
      );
    }
  }

  /// Switch active community
  Future<bool> switchActiveCommunity(String communityId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.switchActiveCommunity(communityId);
      if (response.success) {
        // Refresh all community data after switching
        await fetchAllCommunityData();
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
        error: 'Failed to switch community',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Community Provider
final communityProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier(
    ref.watch(communityRepositoryProvider),
  );
});
