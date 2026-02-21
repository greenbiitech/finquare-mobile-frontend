import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

/// State for recipient lookup
class RecipientState {
  final bool isSearching;
  final String? error;
  final RecipientLookupResponse? recipient;
  final bool isFound;

  const RecipientState({
    this.isSearching = false,
    this.error,
    this.recipient,
    this.isFound = false,
  });

  factory RecipientState.initial() => const RecipientState();

  RecipientState copyWith({
    bool? isSearching,
    String? error,
    RecipientLookupResponse? recipient,
    bool? isFound,
  }) {
    return RecipientState(
      isSearching: isSearching ?? this.isSearching,
      error: error,
      recipient: recipient ?? this.recipient,
      isFound: isFound ?? this.isFound,
    );
  }

  RecipientState clearError() => RecipientState(
    isSearching: isSearching,
    error: null,
    recipient: recipient,
    isFound: isFound,
  );

  RecipientState reset() => const RecipientState();
}

/// State for internal transfer
class InternalTransferState {
  final bool isProcessing;
  final String? error;
  final InternalTransferResponse? response;
  final bool isSuccess;

  const InternalTransferState({
    this.isProcessing = false,
    this.error,
    this.response,
    this.isSuccess = false,
  });

  factory InternalTransferState.initial() => const InternalTransferState();

  InternalTransferState copyWith({
    bool? isProcessing,
    String? error,
    InternalTransferResponse? response,
    bool? isSuccess,
  }) {
    return InternalTransferState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      response: response ?? this.response,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  InternalTransferState clearError() => InternalTransferState(
    isProcessing: isProcessing,
    error: null,
    response: response,
    isSuccess: isSuccess,
  );

  InternalTransferState reset() => const InternalTransferState();
}

/// Controller for recipient lookup
class RecipientController extends StateNotifier<RecipientState> {
  final WalletRepository _repository;

  RecipientController(this._repository) : super(const RecipientState());

  /// Lookup recipient by email or phone
  Future<void> lookupRecipient(String identifier) async {
    if (identifier.trim().isEmpty) return;

    state = state.copyWith(isSearching: true, error: null, isFound: false);

    try {
      final response = await _repository.lookupRecipient(identifier.trim());
      if (response.success && response.userId != null) {
        state = state.copyWith(
          isSearching: false,
          recipient: response,
          isFound: true,
        );
      } else {
        state = state.copyWith(
          isSearching: false,
          error: response.message ?? 'User not found',
          isFound: false,
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to find recipient';
      if (e.toString().contains('No FinSquare account')) {
        errorMessage = 'No FinSquare account found with this email or phone number';
      } else if (e.toString().contains('cannot transfer to yourself')) {
        errorMessage = 'You cannot transfer to yourself';
      } else if (e.toString().contains('does not have an active wallet')) {
        errorMessage = 'Recipient does not have an active wallet';
      }
      state = state.copyWith(
        isSearching: false,
        error: errorMessage,
      );
    }
  }

  /// Reset state
  void reset() {
    state = const RecipientState();
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }
}

/// Controller for internal transfer
class InternalTransferController extends StateNotifier<InternalTransferState> {
  final WalletRepository _repository;

  InternalTransferController(this._repository) : super(const InternalTransferState());

  /// Execute internal transfer
  /// Returns a tuple-like result: (success, errorMessage)
  Future<(bool, String?)> transfer({
    required String recipientUserId,
    required double amount,
    String? narration,
    required String transactionPin,
  }) async {
    if (!mounted) return (false, 'Transfer cancelled');

    state = state.copyWith(isProcessing: true, error: null, isSuccess: false);

    try {
      final response = await _repository.internalTransfer(
        recipientUserId: recipientUserId,
        amount: amount,
        narration: narration,
        transactionPin: transactionPin,
      );

      if (!mounted) return (response.success, response.message);

      if (response.success) {
        state = state.copyWith(
          isProcessing: false,
          response: response,
          isSuccess: true,
        );
        return (true, null);
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: response.message,
          isSuccess: false,
        );
        return (false, response.message);
      }
    } catch (e) {
      String errorMessage = 'Transfer failed';
      if (e.toString().contains('Invalid transaction PIN')) {
        errorMessage = 'Invalid transaction PIN';
      } else if (e.toString().contains('Insufficient funds')) {
        errorMessage = 'Insufficient funds';
      } else if (e.toString().contains('exceeds your daily limit')) {
        errorMessage = e.toString().split('Exception: ').last;
      }

      if (!mounted) return (false, errorMessage);

      state = state.copyWith(
        isProcessing: false,
        error: errorMessage,
      );
      return (false, errorMessage);
    }
  }

  /// Reset state
  void reset() {
    state = const InternalTransferState();
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }
}

/// Provider for recipient lookup
final recipientControllerProvider =
    StateNotifierProvider.autoDispose<RecipientController, RecipientState>((ref) {
  return RecipientController(ref.watch(walletRepositoryProvider));
});

/// Provider for internal transfer
final internalTransferControllerProvider =
    StateNotifierProvider.autoDispose<InternalTransferController, InternalTransferState>((ref) {
  return InternalTransferController(ref.watch(walletRepositoryProvider));
});
