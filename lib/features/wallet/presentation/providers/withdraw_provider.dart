import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

/// Provider for the list of banks
final bankListProvider = FutureProvider<List<Bank>>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getBanks();
});

/// State for withdrawal page
class WithdrawState {
  final bool isLoading;
  final bool isResolving;
  final String? error;
  final String? successMessage;
  final ResolveAccountResponse? resolvedAccount; // Contains accountName if resolved
  final bool isAccountResolved;

  const WithdrawState({
    this.isLoading = false,
    this.isResolving = false,
    this.error,
    this.successMessage,
    this.resolvedAccount,
    this.isAccountResolved = false,
  });

  factory WithdrawState.initial() => const WithdrawState();

  WithdrawState copyWith({
    bool? isLoading,
    bool? isResolving,
    String? error,
    String? successMessage,
    ResolveAccountResponse? resolvedAccount,
    bool? isAccountResolved,
  }) {
    return WithdrawState(
      isLoading: isLoading ?? this.isLoading,
      isResolving: isResolving ?? this.isResolving,
      error: error, // If null passed, keeps old error. If explicit null needed, use logic
      successMessage: successMessage,
      resolvedAccount: resolvedAccount ?? this.resolvedAccount,
      isAccountResolved: isAccountResolved ?? this.isAccountResolved,
    );
  }
  
  // Clear error convenience
  WithdrawState clearError() =>  WithdrawState(
    isLoading: isLoading,
    isResolving: isResolving,
    error: null,
    successMessage: successMessage,
    resolvedAccount: resolvedAccount,
    isAccountResolved: isAccountResolved,
  );
}

class WithdrawController extends StateNotifier<WithdrawState> {
  final WalletRepository _repository;

  WithdrawController(this._repository) : super(const WithdrawState());

  /// Resolve account name
  Future<void> resolveAccount(String accountNumber, String bankCode) async {
    if (accountNumber.length < 10) return;
    
    state = state.copyWith(isResolving: true, error: null, isAccountResolved: false);

    try {
      final response = await _repository.resolveAccount(accountNumber, bankCode);
      if (response.success) {
        state = state.copyWith(
          isResolving: false,
          resolvedAccount: response,
          isAccountResolved: true,
        );
      } else {
        state = state.copyWith(
          isResolving: false,
          error: response.message,
          isAccountResolved: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isResolving: false,
        error: 'Failed to resolve account: ${e.toString()}',
      );
    }
  }

  /// Reset resolution state (e.g. when user changes text)
  void resetResolution() {
    state = state.copyWith(
      isAccountResolved: false,
      resolvedAccount: null,
      error: null,
    );
  }

  /// Submit withdrawal
  Future<bool> withdraw({
    required double amount,
    required String destinationAccountNumber,
    required String destinationBankCode,
    required String destinationAccountName,
    required String narration,
    required String transactionPin,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final response = await _repository.withdraw(
        amount: amount,
        destinationAccountNumber: destinationAccountNumber,
        destinationBankCode: destinationBankCode,
        destinationAccountName: destinationAccountName,
        narration: narration,
        transactionPin: transactionPin,
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Withdrawal failed: ${e.toString()}',
      );
      return false;
    }
  }
}

final withdrawProvider = StateNotifierProvider<WithdrawController, WithdrawState>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WithdrawController(repository);
});
