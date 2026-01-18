import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/features/auth/data/auth_repository.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/services/app_startup_service.dart';
import 'package:finsquare_mobile_app/core/services/notification_service.dart';
import 'package:finsquare_mobile_app/core/services/notification_repository.dart';

/// Auth State
class AuthState {
  final bool isLoading;
  final String? error;
  final UserData? user;
  final String? tempEmail;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.tempEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserData? user,
    String? tempEmail,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      user: clearUser ? null : (user ?? this.user),
      tempEmail: tempEmail ?? this.tempEmail,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final AppStartupService _startupService;
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;

  AuthNotifier(
    this._repository,
    this._startupService,
    this._notificationService,
    this._notificationRepository,
  ) : super(const AuthState()) {
    // Set up token refresh callback to register with backend
    _notificationService.setTokenRefreshCallback(_registerDeviceToken);
  }

  /// Register FCM token with backend (called after login and on token refresh)
  Future<void> _registerDeviceToken(String token) async {
    await _notificationRepository.registerDeviceToken(token);
  }

  /// Register current FCM token with backend
  Future<void> _registerCurrentDeviceToken() async {
    final token = await _notificationService.getToken();
    if (token != null) {
      await _notificationRepository.registerDeviceToken(token);
    }
  }

  /// Signup
  Future<bool> signup({
    required String email,
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.signup(
        SignupRequest(
          email: email,
          phoneNumber: phoneNumber,
          password: password,
          firstName: firstName,
          lastName: lastName,
        ),
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          tempEmail: email,
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

  /// Verify OTP
  Future<bool> verifyOtp(String otp) async {
    if (state.tempEmail == null) {
      state = state.copyWith(error: 'Email not found. Please signup again.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.verifyOtp(
        VerifyOtpRequest(
          email: state.tempEmail!,
          otp: otp,
        ),
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          user: response.user,
        );

        // Register FCM token with backend after successful verification
        await _registerCurrentDeviceToken();

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

  /// Resend OTP
  Future<bool> resendOtp() async {
    if (state.tempEmail == null) {
      state = state.copyWith(error: 'Email not found. Please signup again.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.resendOtp(state.tempEmail!);

      state = state.copyWith(isLoading: false);
      return response.success;
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

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.login(
        LoginRequest(identifier: email, password: password),
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          user: response.user,
          tempEmail: response.user?.email ?? email,
        );

        // Save user info for next app launch (use actual email from response, not login identifier)
        if (response.user != null) {
          final fullName = '${response.user!.firstName} ${response.user!.lastName}';
          await _startupService.saveUserInfo(response.user!.email, fullName);
          await _startupService.setHasPasskey(response.user!.hasPasskey);
        }

        // Register FCM token with backend after successful login
        await _registerCurrentDeviceToken();

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

  /// Login with Passkey
  Future<bool> loginWithPasskey({
    required String email,
    required String passkey,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.loginWithPasskey(
        PasskeyLoginRequest(email: email, passkey: passkey),
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          user: response.user,
        );

        // Register FCM token with backend after successful passkey login
        await _registerCurrentDeviceToken();

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
      print('Passkey login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Create Passkey
  Future<bool> createPasskey(String passkey) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.createPasskey(
        CreatePasskeyRequest(passkey: passkey),
      );

      if (response.success) {
        final user = response.user ?? state.user;
        state = state.copyWith(
          isLoading: false,
          user: user,
        );

        // Save user info for next app launch (passkey created = user has passkey set)
        if (user != null && state.tempEmail != null) {
          final fullName = '${user.firstName} ${user.lastName}';
          await _startupService.saveUserInfo(state.tempEmail!, fullName);
          await _startupService.setHasPasskey(true);
        }

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

  /// Request Password Reset
  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, tempEmail: email);
    try {
      final response = await _repository.requestPasswordReset(email);

      state = state.copyWith(isLoading: false);
      if (!response.success) {
        state = state.copyWith(error: response.message);
      }
      return response.success;
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

  /// Verify Reset OTP
  Future<String?> verifyResetOtp(String otp) async {
    if (state.tempEmail == null) {
      state = state.copyWith(error: 'Email not found. Please try again.');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.verifyResetOtp(state.tempEmail!, otp);

      state = state.copyWith(isLoading: false);
      if (response.success && response.token != null) {
        return response.token;
      } else {
        state = state.copyWith(error: response.message);
        return null;
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return null;
    }
  }

  /// Reset Password
  Future<bool> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.resetPassword(token, newPassword);

      state = state.copyWith(isLoading: false);
      if (!response.success) {
        state = state.copyWith(error: response.message);
      }
      return response.success;
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

  /// Logout
  Future<void> logout() async {
    // Remove FCM token from backend before logging out
    await _notificationRepository.removeDeviceToken();
    await _repository.logout();
    state = const AuthState();
  }

  /// Set temp email (for navigation between screens)
  void setTempEmail(String email) {
    state = state.copyWith(tempEmail: email);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh user profile
  Future<bool> refreshUserProfile() async {
    try {
      final response = await _repository.getProfile();
      if (response.success && response.user != null) {
        state = state.copyWith(user: response.user);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(appStartupServiceProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(notificationRepositoryProvider),
  );
});
