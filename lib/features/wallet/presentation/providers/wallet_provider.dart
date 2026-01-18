import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

/// Keys for local storage
const String _walletCacheKey = 'wallet_cache';

/// Wallet state - single source of truth for wallet data
class WalletState {
  final String balance;
  final String accountNumber;
  final String accountName;
  final String? walletId;
  final bool isLoading;
  final bool isFirstLoad;
  final String? error;
  final DateTime? lastUpdated;

  const WalletState({
    this.balance = '0.00',
    this.accountNumber = '',
    this.accountName = '',
    this.walletId,
    this.isLoading = false,
    this.isFirstLoad = true,
    this.error,
    this.lastUpdated,
  });

  /// Check if wallet data is available
  bool get hasWallet => accountNumber.isNotEmpty;

  /// Check if cache is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inMinutes > 5;
  }

  WalletState copyWith({
    String? balance,
    String? accountNumber,
    String? accountName,
    String? walletId,
    bool? isLoading,
    bool? isFirstLoad,
    String? error,
    DateTime? lastUpdated,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      walletId: walletId ?? this.walletId,
      isLoading: isLoading ?? this.isLoading,
      isFirstLoad: isFirstLoad ?? this.isFirstLoad,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() => {
        'balance': balance,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'walletId': walletId,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  /// Create from JSON cache
  factory WalletState.fromJson(Map<String, dynamic> json) {
    return WalletState(
      balance: json['balance'] ?? '0.00',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      walletId: json['walletId'],
      isFirstLoad: false, // If we have cache, it's not first load
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'])
          : null,
    );
  }
}

/// Wallet provider - manages wallet state across the app
class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;

  WalletNotifier(this._repository) : super(const WalletState()) {
    _loadFromCache();
  }

  /// Load cached wallet data from local storage
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_walletCacheKey);

      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        state = WalletState.fromJson(json);
      }
    } catch (e) {
      // Ignore cache errors, will fetch fresh
    }
  }

  /// Save wallet data to local storage
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_walletCacheKey, jsonEncode(state.toJson()));
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Fetch balance from server (shows loading indicator)
  Future<void> fetchBalance() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getBalance();

      state = state.copyWith(
        balance: response.balance,
        accountNumber: response.accountNumber,
        accountName: response.accountName,
        walletId: response.walletId,
        isLoading: false,
        isFirstLoad: false,
        lastUpdated: DateTime.now(),
      );

      await _saveToCache();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh balance silently (no loading indicator for UI)
  /// Used for background refreshes, pull-to-refresh already handled
  Future<void> refreshBalanceSilently() async {
    try {
      final response = await _repository.getBalance();

      state = state.copyWith(
        balance: response.balance,
        accountNumber: response.accountNumber,
        accountName: response.accountName,
        walletId: response.walletId,
        isFirstLoad: false,
        lastUpdated: DateTime.now(),
      );

      await _saveToCache();
    } catch (e) {
      // Silent refresh - don't update error state
      // Keep showing cached data
    }
  }

  /// Refresh balance with loading indicator (for pull-to-refresh)
  Future<void> refreshBalance() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getBalance();

      state = state.copyWith(
        balance: response.balance,
        accountNumber: response.accountNumber,
        accountName: response.accountName,
        walletId: response.walletId,
        isLoading: false,
        isFirstLoad: false,
        lastUpdated: DateTime.now(),
      );

      await _saveToCache();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update balance locally (optimistic update)
  void updateBalanceOptimistic(String newBalance) {
    state = state.copyWith(balance: newBalance);
  }

  /// Clear wallet data (on logout)
  Future<void> clearWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_walletCacheKey);
    } catch (e) {
      // Ignore
    }
    state = const WalletState();
  }

  /// Set wallet data directly (e.g., from auth response)
  void setWalletFromAuth({
    required String balance,
    required String accountNumber,
    required String accountName,
    String? walletId,
  }) {
    final wasFirstLoad = state.isFirstLoad;
    state = state.copyWith(
      balance: balance,
      accountNumber: accountNumber,
      accountName: accountName,
      walletId: walletId,
      isFirstLoad: wasFirstLoad && state.balance == '0.00',
      lastUpdated: DateTime.now(),
    );
    _saveToCache();
  }
}

/// Provider for wallet state
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repository);
});

/// Convenience provider to check if user has a wallet
final hasWalletProvider = Provider<bool>((ref) {
  return ref.watch(walletProvider).hasWallet;
});

/// Convenience provider for just the balance
final walletBalanceProvider = Provider<String>((ref) {
  return ref.watch(walletProvider).balance;
});
