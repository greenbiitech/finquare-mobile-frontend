import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/features/auth/data/auth_repository.dart';

/// Keys for SharedPreferences
class AppStorageKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String hasPasskey = 'has_passkey';
}

/// App startup state
enum AppStartupState {
  loading,
  showOnboarding,
  showLogin,
  showPasskeyLogin,
  showCreatePasskey,
  showPickMembership,
  showHome,
}

/// App startup data
class AppStartupData {
  final AppStartupState state;
  final String? userEmail;
  final String? userName;
  final UserData? user;

  const AppStartupData({
    required this.state,
    this.userEmail,
    this.userName,
    this.user,
  });
}

/// App Startup Service
class AppStartupService {
  final SharedPreferences _prefs;
  final ApiClient _apiClient;

  AppStartupService(this._prefs, this._apiClient);

  /// Check if onboarding has been completed
  bool get isOnboardingCompleted =>
      _prefs.getBool(AppStorageKeys.onboardingCompleted) ?? false;

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppStorageKeys.onboardingCompleted, true);
  }

  /// Save user info for welcome back screen
  Future<void> saveUserInfo(String email, String name) async {
    await _prefs.setString(AppStorageKeys.userEmail, email);
    await _prefs.setString(AppStorageKeys.userName, name);
  }

  /// Get saved user email
  String? get savedUserEmail => _prefs.getString(AppStorageKeys.userEmail);

  /// Get saved user name
  String? get savedUserName => _prefs.getString(AppStorageKeys.userName);

  /// Check if user has passkey set
  bool get hasPasskey => _prefs.getBool(AppStorageKeys.hasPasskey) ?? false;

  /// Set passkey status
  Future<void> setHasPasskey(bool value) async {
    await _prefs.setBool(AppStorageKeys.hasPasskey, value);
  }

  /// Clear user info on logout
  Future<void> clearUserInfo() async {
    await _prefs.remove(AppStorageKeys.userEmail);
    await _prefs.remove(AppStorageKeys.userName);
    await _prefs.remove(AppStorageKeys.hasPasskey);
  }

  /// Determine initial app state
  Future<AppStartupData> determineInitialState() async {
    // Check if onboarding completed
    if (!isOnboardingCompleted) {
      return const AppStartupData(state: AppStartupState.showOnboarding);
    }

    // Check if we have a saved token
    final token = await _apiClient.getToken();
    if (token == null) {
      // Check if we have saved user info AND user has passkey for passkey login
      final email = savedUserEmail;
      final name = savedUserName;
      if (email != null && name != null && hasPasskey) {
        return AppStartupData(
          state: AppStartupState.showPasskeyLogin,
          userEmail: email,
          userName: name,
        );
      }
      return const AppStartupData(state: AppStartupState.showLogin);
    }

    // We have a token, validate it by getting user profile
    try {
      final response = await _apiClient.get('/api/v1/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = UserData.fromJson(response.data['data']);

        // Save user info for future passkey logins
        await saveUserInfo(userData.email, userData.fullName);
        await setHasPasskey(userData.hasPasskey);

        if (!userData.hasPasskey) {
          return AppStartupData(
            state: AppStartupState.showCreatePasskey,
            user: userData,
          );
        } else if (!userData.hasPickedMembership) {
          return AppStartupData(
            state: AppStartupState.showPickMembership,
            user: userData,
          );
        } else {
          return AppStartupData(
            state: AppStartupState.showHome,
            user: userData,
          );
        }
      }
    } catch (e) {
      // Token invalid or expired, clear it
      await _apiClient.clearToken();
    }

    // Token was invalid, show passkey login if we have user info and passkey
    final email = savedUserEmail;
    final name = savedUserName;
    if (email != null && name != null && hasPasskey) {
      return AppStartupData(
        state: AppStartupState.showPasskeyLogin,
        userEmail: email,
        userName: name,
      );
    }

    return const AppStartupData(state: AppStartupState.showLogin);
  }
}

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

/// App Startup Service provider
final appStartupServiceProvider = Provider<AppStartupService>((ref) {
  return AppStartupService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(apiClientProvider),
  );
});

/// App startup state provider
final appStartupProvider = FutureProvider<AppStartupData>((ref) async {
  final service = ref.watch(appStartupServiceProvider);
  return service.determineInitialState();
});
