import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/network/api_config.dart';

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

/// Signup Request Model
class SignupRequest {
  final String email;
  final String phoneNumber;
  final String password;
  final String firstName;
  final String lastName;

  SignupRequest({
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      };
}

/// Verify OTP Request Model
class VerifyOtpRequest {
  final String email;
  final String otp;

  VerifyOtpRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
      };
}

/// Login Request Model
class LoginRequest {
  final String identifier;
  final String password;

  LoginRequest({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
      };
}

/// Passkey Login Request Model
class PasskeyLoginRequest {
  final String email;
  final String passkey;

  PasskeyLoginRequest({
    required this.email,
    required this.passkey,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'passkey': passkey,
      };
}

/// Create Passkey Request Model
class CreatePasskeyRequest {
  final String passkey;

  CreatePasskeyRequest({required this.passkey});

  Map<String, dynamic> toJson() => {
        'passkey': passkey,
      };
}

/// Auth Response Model
class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final UserData? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // API returns data nested inside 'data' object
    final data = json['data'] as Map<String, dynamic>?;
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: data?['token'],
      user: data?['user'] != null ? UserData.fromJson(data!['user']) : null,
    );
  }
}

/// User Data Model
class MainWallet {
  final String id;
  final String balance;
  final String walletType;

  MainWallet({
    required this.id,
    required this.balance,
    required this.walletType,
  });

  factory MainWallet.fromJson(Map<String, dynamic> json) {
    return MainWallet(
      id: json['id'] ?? '',
      balance: json['balance'] ?? '0.00',
      walletType: json['walletType'] ?? 'MAIN',
    );
  }
}

class UserData {
  final String id;
  final String email;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String fullName;
  final bool hasPasskey;
  final bool hasPickedMembership;
  final bool hasWallet;
  final MainWallet? mainWallet;

  UserData({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.hasPasskey,
    required this.hasPickedMembership,
    required this.hasWallet,
    this.mainWallet,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      hasPasskey: json['hasPasskey'] ?? false,
      hasPickedMembership: json['hasPickedMembership'] ?? false,
      hasWallet: json['hasWallet'] ?? false,
      mainWallet: json['mainWallet'] != null
          ? MainWallet.fromJson(json['mainWallet'])
          : null,
    );
  }
}

/// Auth Repository
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Signup
  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.signup,
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Verify OTP
  Future<AuthResponse> verifyOtp(VerifyOtpRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: request.toJson(),
    );

    // Save token if login successful
    final authResponse = AuthResponse.fromJson(response.data);
    if (authResponse.token != null) {
      await _apiClient.saveToken(authResponse.token!);
    }

    return authResponse;
  }

  /// Resend OTP
  Future<AuthResponse> resendOtp(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.resendOtp,
      data: {'email': email},
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Login
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);
    if (authResponse.token != null) {
      await _apiClient.saveToken(authResponse.token!);
    }

    return authResponse;
  }

  /// Login with Passkey
  Future<AuthResponse> loginWithPasskey(PasskeyLoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.loginPasskey,
      data: request.toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);
    if (authResponse.token != null) {
      await _apiClient.saveToken(authResponse.token!);
    }

    return authResponse;
  }

  /// Create Passkey
  Future<AuthResponse> createPasskey(CreatePasskeyRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.createPasskey,
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Request Password Reset
  Future<AuthResponse> requestPasswordReset(String identifier) async {
    final response = await _apiClient.post(
      ApiEndpoints.requestReset,
      data: {'identifier': identifier},
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Verify Reset OTP
  Future<AuthResponse> verifyResetOtp(String token, String otp) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyResetOtp,
      data: {'token': token, 'otp': otp},
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Reset Password
  Future<AuthResponse> resetPassword(String token, String newPassword) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'password': newPassword},
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Logout
  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  /// Get current user profile
  Future<AuthResponse> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    return AuthResponse.fromJson(response.data);
  }
}
