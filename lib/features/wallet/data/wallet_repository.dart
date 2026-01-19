import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/network/api_config.dart';

/// Wallet Repository Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

/// BVN Data Model
class BvnData {
  final String? bvn;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;

  BvnData({
    this.bvn,
    this.firstName,
    this.lastName,
    this.middleName,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
  });

  factory BvnData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return BvnData();
    return BvnData(
      bvn: json['bvn'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      middleName: json['middleName'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
    );
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(' ');
  }
}

/// Address Data Model
class AddressData {
  final String? address;
  final String? state;
  final String? lga;

  AddressData({
    this.address,
    this.state,
    this.lga,
  });

  factory AddressData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AddressData();
    return AddressData(
      address: json['address'],
      state: json['state'],
      lga: json['lga'],
    );
  }
}

/// Wallet Setup Progress Model
class WalletSetupProgress {
  final bool hasWallet;
  final String currentStep;
  final String? resumeRoute;
  final BvnData bvnData;
  final AddressData addressData;
  final String? occupation;
  final bool nameMatchesBvn;
  final String? userFirstName;
  final String? userLastName;

  WalletSetupProgress({
    required this.hasWallet,
    required this.currentStep,
    this.resumeRoute,
    required this.bvnData,
    required this.addressData,
    this.occupation,
    required this.nameMatchesBvn,
    this.userFirstName,
    this.userLastName,
  });

  factory WalletSetupProgress.fromJson(Map<String, dynamic> json) {
    return WalletSetupProgress(
      hasWallet: json['hasWallet'] ?? false,
      currentStep: json['currentStep'] ?? 'NOT_STARTED',
      resumeRoute: json['resumeRoute'],
      bvnData: BvnData.fromJson(json['bvnData']),
      addressData: AddressData.fromJson(json['addressData']),
      occupation: json['occupation'],
      nameMatchesBvn: json['nameMatchesBvn'] ?? true,
      userFirstName: json['user']?['firstName'],
      userLastName: json['user']?['lastName'],
    );
  }
}

/// Complete Step 2 Request Model
class CompleteStep2Request {
  final String address;
  final String state;
  final String lga;
  final String? occupation;
  final bool syncWithBvn;

  CompleteStep2Request({
    required this.address,
    required this.state,
    required this.lga,
    this.occupation,
    required this.syncWithBvn,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'state': state,
        'lga': lga,
        if (occupation != null) 'occupation': occupation,
        'syncWithBvn': syncWithBvn,
      };
}

/// Complete Step 3 Request Model
class CompleteStep3Request {
  final String photoUrl;

  CompleteStep3Request({required this.photoUrl});

  Map<String, dynamic> toJson() => {'photoUrl': photoUrl};
}

/// Complete Step 4 Request Model
class CompleteStep4Request {
  final String proofOfAddressUrl;

  CompleteStep4Request({required this.proofOfAddressUrl});

  Map<String, dynamic> toJson() => {'proofOfAddressUrl': proofOfAddressUrl};
}

/// Complete Step 5 Request Model (Transaction PIN + Wallet Creation)
class CompleteStep5Request {
  final String transactionPin;

  CompleteStep5Request({required this.transactionPin});

  Map<String, dynamic> toJson() => {'transactionPin': transactionPin};
}

/// Wallet Creation Response Model
class WalletCreationResponse {
  final bool success;
  final String message;
  final String? walletId;
  final String? accountNumber;
  final String? accountName;

  WalletCreationResponse({
    required this.success,
    required this.message,
    this.walletId,
    this.accountNumber,
    this.accountName,
  });

  factory WalletCreationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return WalletCreationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      walletId: data?['walletId'],
      accountNumber: data?['accountNumber'],
      accountName: data?['accountName'],
    );
  }
}

/// BVN Verification Method Model
class BvnVerificationMethod {
  final String method; // 'phone' or 'email'
  final String hint; // Masked value like '090******76' or 'da**z@gmail.com'

  BvnVerificationMethod({
    required this.method,
    required this.hint,
  });

  factory BvnVerificationMethod.fromJson(Map<String, dynamic> json) {
    return BvnVerificationMethod(
      method: json['method'] ?? '',
      hint: json['hint'] ?? '',
    );
  }

  bool get isEmail => method == 'email';
}

/// BVN Method Option Model (from Mono API)
class BvnMethodOption {
  final String method; // 'phone', 'email', or 'alternate_phone'
  final String hint; // e.g. 'Sms will be sent to 0903***8859'

  BvnMethodOption({
    required this.method,
    required this.hint,
  });

  factory BvnMethodOption.fromJson(Map<String, dynamic> json) {
    return BvnMethodOption(
      method: json['method'] ?? '',
      hint: json['hint'] ?? '',
    );
  }

  bool get isEmail => method.toLowerCase() == 'email';
  bool get isPhone => method.toLowerCase() == 'phone';
  bool get isAlternatePhone => method.toLowerCase() == 'alternate_phone';
}

/// BVN Initiate Response Model
class BvnInitiateResponse {
  final bool success;
  final String message;
  final String sessionId;
  final List<BvnMethodOption> methods; // Available methods with hints

  BvnInitiateResponse({
    required this.success,
    required this.message,
    required this.sessionId,
    required this.methods,
  });

  factory BvnInitiateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return BvnInitiateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      sessionId: data?['sessionId'] ?? '',
      methods: (data?['methods'] as List<dynamic>?)
              ?.map((e) => BvnMethodOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// BVN Verify Response Model (after selecting method, OTP is sent)
class BvnVerifyResponse {
  final bool success;
  final String message;

  BvnVerifyResponse({
    required this.success,
    required this.message,
  });

  factory BvnVerifyResponse.fromJson(Map<String, dynamic> json) {
    return BvnVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// BVN Details Response Model (after OTP verification)
class BvnDetailsResponse {
  final bool success;
  final String message;
  final BvnData bvnData;

  BvnDetailsResponse({
    required this.success,
    required this.message,
    required this.bvnData,
  });

  factory BvnDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return BvnDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      bvnData: BvnData(
        firstName: data?['firstName'],
        lastName: data?['lastName'],
        middleName: data?['middleName'],
        phoneNumber: data?['phoneNumber'],
        dateOfBirth: data?['dateOfBirth'],
        gender: data?['gender'],
      ),
    );
  }
}

/// Wallet API Response Model
class WalletResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  WalletResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

/// Transaction Model
class WalletTransaction {
  final String? id;
  final double amount;
  final String type; // CREDIT or DEBIT
  final String? narration;
  final String? reference;
  final String? status;
  final DateTime? date;
  final String? senderName;
  final String? senderAccount;
  final String? receiverName;
  final String? receiverAccount;

  WalletTransaction({
    this.id,
    required this.amount,
    required this.type,
    this.narration,
    this.reference,
    this.status,
    this.date,
    this.senderName,
    this.senderAccount,
    this.receiverName,
    this.receiverAccount,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    // Parse amount - handle both string and number
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Parse date - handle various formats
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // Determine transaction type from various possible fields
    String determineType(Map<String, dynamic> json) {
      final type = json['type'] ?? json['transactionType'] ?? json['txnType'] ?? '';
      if (type.toString().toUpperCase().contains('CREDIT')) return 'CREDIT';
      if (type.toString().toUpperCase().contains('DEBIT')) return 'DEBIT';
      return type.toString().toUpperCase();
    }

    return WalletTransaction(
      id: json['id']?.toString() ?? json['transactionId']?.toString(),
      amount: parseAmount(json['amount'] ?? json['transactionAmount']),
      type: determineType(json),
      narration: json['narration'] ?? json['reason'] ?? json['description'],
      reference: json['reference'] ?? json['transactionRef'] ?? json['transactionref'],
      status: json['status'] ?? json['transactionStatus'] ?? 'SUCCESS',
      date: parseDate(json['date'] ?? json['createdAt'] ?? json['transactionDate']),
      senderName: json['senderName'] ?? json['sendername'],
      senderAccount: json['senderAccount'] ?? json['sourceaccount'],
      receiverName: json['receiverName'] ?? json['beneficiaryName'],
      receiverAccount: json['receiverAccount'] ?? json['accountnumber'],
    );
  }

  bool get isCredit => type.toUpperCase() == 'CREDIT';
  bool get isDebit => type.toUpperCase() == 'DEBIT';

  String get formattedAmount {
    final prefix = isCredit ? '+' : '-';
    return '$prefix₦${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    if (date == null) return '';
    return '${date!.day}/${date!.month}/${date!.year}';
  }
}

/// Transaction History Response Model
class TransactionHistoryResponse {
  final bool success;
  final String? message;
  final List<WalletTransaction> transactions;
  final String? fromDate;
  final String? toDate;
  final String? source; // '9psb' or 'local'

  TransactionHistoryResponse({
    required this.success,
    this.message,
    required this.transactions,
    this.fromDate,
    this.toDate,
    this.source,
  });

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final txList = data?['transactions'] as List<dynamic>? ?? [];

    return TransactionHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'],
      transactions: txList
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      fromDate: data?['fromDate'],
      toDate: data?['toDate'],
      source: data?['source'],
    );
  }
}

/// Wallet Balance Response Model
class WalletBalanceResponse {
  final bool success;
  final String message;
  final String balance;
  final String accountNumber;
  final String accountName;
  final String walletId;
  final bool syncedFromPsb;

  WalletBalanceResponse({
    required this.success,
    required this.message,
    required this.balance,
    required this.accountNumber,
    required this.accountName,
    required this.walletId,
    required this.syncedFromPsb,
  });

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return WalletBalanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      balance: data?['balance']?.toString() ?? '0.00',
      accountNumber: data?['accountNumber'] ?? '',
      accountName: data?['accountName'] ?? '',
      walletId: data?['walletId'] ?? '',
      syncedFromPsb: data?['syncedFromPsb'] ?? false,
    );
  }

  double get balanceAsDouble => double.tryParse(balance) ?? 0.0;
}

/// Wallet Repository
class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository(this._apiClient);

  /// Get wallet setup progress
  Future<WalletSetupProgress> getSetupProgress() async {
    final response = await _apiClient.get(ApiEndpoints.walletSetupProgress);
    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response from server');
    }
    return WalletSetupProgress.fromJson(data);
  }

  /// Complete Step 2 (Personal Info + Address)
  Future<WalletResponse> completeStep2(CompleteStep2Request request) async {
    final response = await _apiClient.post(
      ApiEndpoints.walletStep2Complete,
      data: request.toJson(),
    );
    return WalletResponse.fromJson(response.data);
  }

  /// Complete Step 3 (Face Verification)
  Future<WalletResponse> completeStep3(CompleteStep3Request request) async {
    final response = await _apiClient.post(
      ApiEndpoints.walletStep3Complete,
      data: request.toJson(),
    );
    return WalletResponse.fromJson(response.data);
  }

  /// Complete Step 4 (Proof of Address)
  Future<WalletResponse> completeStep4(CompleteStep4Request request) async {
    final response = await _apiClient.post(
      ApiEndpoints.walletStep4Complete,
      data: request.toJson(),
    );
    return WalletResponse.fromJson(response.data);
  }

  /// Skip Step 4 (Proof of Address)
  Future<WalletResponse> skipStep4() async {
    final response = await _apiClient.post(ApiEndpoints.walletStep4Skip);
    return WalletResponse.fromJson(response.data);
  }

  /// Complete Step 5 (Transaction PIN + Wallet Creation)
  /// This creates the 9PSB wallet and saves the transaction PIN
  Future<WalletCreationResponse> completeStep5(CompleteStep5Request request) async {
    final response = await _apiClient.post(
      ApiEndpoints.walletStep5Complete,
      data: request.toJson(),
    );
    return WalletCreationResponse.fromJson(response.data);
  }

  // ============================================
  // BVN VALIDATION METHODS
  // ============================================

  /// Step 1: Initiate BVN lookup
  /// Returns session_id and available verification methods
  Future<BvnInitiateResponse> initiateBvn(String bvn) async {
    final response = await _apiClient.post(
      ApiEndpoints.bvnInitiate,
      data: {'bvn': bvn},
    );
    return BvnInitiateResponse.fromJson(response.data);
  }

  /// Step 2: Select verification method and send OTP
  /// Called after user enters full credential on Verify BVN Credentials page
  /// For alternate_phone method, phoneNumber is required
  Future<BvnVerifyResponse> verifyBvnMethod({
    required String sessionId,
    required String method,
    String? phoneNumber,
  }) async {
    final data = <String, dynamic>{
      'sessionId': sessionId,
      'method': method,
    };
    // Include phone number for alternate_phone method
    if (method == 'alternate_phone' && phoneNumber != null) {
      data['phoneNumber'] = phoneNumber;
    }
    final response = await _apiClient.post(
      ApiEndpoints.bvnVerify,
      data: data,
    );
    return BvnVerifyResponse.fromJson(response.data);
  }

  /// Step 3: Verify OTP and get BVN details
  Future<BvnDetailsResponse> verifyBvnOtp({
    required String sessionId,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bvnDetails,
      data: {
        'sessionId': sessionId,
        'otp': otp,
      },
    );
    return BvnDetailsResponse.fromJson(response.data);
  }

  // ============================================
  // WALLET BALANCE
  // ============================================

  /// Get wallet balance from 9PSB
  /// This fetches the real-time balance from 9PSB WAAS
  Future<WalletBalanceResponse> getBalance() async {
    final response = await _apiClient.get(ApiEndpoints.walletBalance);
    return WalletBalanceResponse.fromJson(response.data);
  }

  // ============================================
  // TRANSACTION HISTORY
  // ============================================

  /// Get wallet transaction history
  /// @param fromDate - Start date (format: "dd/MM/yyyy")
  /// @param toDate - End date (format: "dd/MM/yyyy")
  /// @param limit - Number of transactions to fetch
  Future<TransactionHistoryResponse> getTransactionHistory({
    String? fromDate,
    String? toDate,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;
    queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      ApiEndpoints.walletTransactions,
      queryParameters: queryParams,
    );
    return TransactionHistoryResponse.fromJson(response.data);
  }

  // ============================================
  // WITHDRAWAL AND TRANSFER
  // ============================================

  /// Get list of banks
  Future<List<Bank>> getBanks() async {
    final response = await _apiClient.get(ApiEndpoints.walletBanks);
    // Response structure: { status: "SUCCESS", message: "SUCCESS", data: { bankList: [...] } }
    final psbData = response.data['data'];
    if (psbData == null) return [];
    
    // Handle case where bankList is inside data
    final bankList = psbData is Map ? psbData['bankList'] : psbData;
    
    if (bankList is! List) return [];
    
    return bankList.map((e) => Bank.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Resolve account details
  Future<ResolveAccountResponse> resolveAccount(
    String accountNumber,
    String bankCode,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.walletResolveAccount,
      data: {
        'accountNumber': accountNumber,
        'bankCode': bankCode,
      },
    );
    return ResolveAccountResponse.fromJson(response.data);
  }

  /// Withdraw funds
  Future<WalletResponse> withdraw({
    required double amount,
    required String destinationAccountNumber,
    required String destinationBankCode,
    required String destinationAccountName,
    required String narration,
    required String transactionPin,
    bool saveBeneficiary = false,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.walletWithdraw,
      data: {
        'amount': amount,
        'destinationAccountNumber': destinationAccountNumber,
        'destinationBankCode': destinationBankCode,
        'destinationAccountName': destinationAccountName,
        'narration': narration,
        'transactionPin': transactionPin,
        'saveBeneficiary': saveBeneficiary,
      },
    );
    return WalletResponse.fromJson(response.data);
  }

  // ============================================
  // WITHDRAWAL ACCOUNT MANAGEMENT
  // ============================================

  /// Get saved withdrawal account
  Future<WithdrawalAccount?> getWithdrawalAccount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.withdrawalAccountMe);
      final data = response.data['data'];
      if (data == null) return null;
      return WithdrawalAccount.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      // Return null if not found (404) or any other error
      return null;
    }
  }

  /// Save withdrawal account
  Future<WithdrawalAccount> saveWithdrawalAccount(
    CreateWithdrawalAccountRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.withdrawalAccount,
      data: request.toJson(),
    );
    final data = response.data['data'] ?? response.data;
    return WithdrawalAccount.fromJson(data as Map<String, dynamic>);
  }

  /// Delete withdrawal account
  Future<void> deleteWithdrawalAccount() async {
    await _apiClient.delete(ApiEndpoints.withdrawalAccount);
  }

  // ============================================
  // COMMUNITY WALLET
  // ============================================

  /// Get co-admins for signatory selection
  Future<List<CoAdmin>> getCoAdmins(String communityId) async {
    final response = await _apiClient.get(ApiEndpoints.getCoAdmins(communityId));
    final data = response.data['data'];
    if (data == null) return [];

    if (data is List) {
      return data.map((e) => CoAdmin.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Check community wallet eligibility
  Future<CommunityWalletEligibility> checkWalletEligibility(String communityId) async {
    final response = await _apiClient.get(ApiEndpoints.getWalletEligibility(communityId));
    return CommunityWalletEligibility.fromJson(response.data);
  }

  /// Create community wallet
  Future<CommunityWalletResponse> createCommunityWallet(
    String communityId,
    CreateCommunityWalletRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.createCommunityWallet(communityId),
      data: request.toJson(),
    );
    return CommunityWalletResponse.fromJson(response.data);
  }
}

/// Bank Model
class Bank {
  final String code;
  final String name;

  Bank({required this.code, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['bankCode'] ?? json['code'] ?? '',
      name: json['bankName'] ?? json['name'] ?? '',
    );
  }
}

/// Withdrawal Account Model
class WithdrawalAccount {
  final String? id;
  final String userId;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  const WithdrawalAccount({
    this.id,
    required this.userId,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.dateCreated,
    this.dateUpdated,
  });

  factory WithdrawalAccount.fromJson(Map<String, dynamic> json) {
    return WithdrawalAccount(
      id: json['id'],
      userId: json['userId'] ?? '',
      bankCode: json['bankCode'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      dateCreated: json['dateCreated'] != null
          ? DateTime.tryParse(json['dateCreated'])
          : null,
      dateUpdated: json['dateUpdated'] != null
          ? DateTime.tryParse(json['dateUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'bankCode': bankCode,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountName': accountName,
  };
}

/// Create Withdrawal Account Request
class CreateWithdrawalAccountRequest {
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;

  const CreateWithdrawalAccountRequest({
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  Map<String, dynamic> toJson() => {
    'bankCode': bankCode,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountName': accountName,
  };
}

// ============================================
// COMMUNITY WALLET MODELS
// ============================================

/// Co-Admin Model for community wallet signatories
class CoAdmin {
  final String odooId;
  final String odooName;
  final String odooEmail;
  final String? odooPhoto;

  CoAdmin({
    required this.odooId,
    required this.odooName,
    required this.odooEmail,
    this.odooPhoto,
  });

  factory CoAdmin.fromJson(Map<String, dynamic> json) {
    return CoAdmin(
      odooId: json['odooId']?.toString() ?? json['id']?.toString() ?? '',
      odooName: json['odooName'] ?? json['fullName'] ?? json['name'] ?? '',
      odooEmail: json['odooEmail'] ?? json['email'] ?? '',
      odooPhoto: json['odooPhoto'] ?? json['photo'],
    );
  }
}

/// Community Wallet Eligibility Response
class CommunityWalletEligibility {
  final bool eligible;
  final bool hasPersonalWallet;
  final int coAdminCount;
  final String? reason;

  CommunityWalletEligibility({
    required this.eligible,
    required this.hasPersonalWallet,
    required this.coAdminCount,
    this.reason,
  });

  factory CommunityWalletEligibility.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CommunityWalletEligibility(
      eligible: data['eligible'] ?? false,
      hasPersonalWallet: data['hasPersonalWallet'] ?? false,
      coAdminCount: data['coAdminCount'] ?? 0,
      reason: data['reason'],
    );
  }
}

/// Create Community Wallet Request
class CreateCommunityWalletRequest {
  final List<String> signatoryIds;
  final String approvalRule;
  final String transactionPin;

  CreateCommunityWalletRequest({
    required this.signatoryIds,
    required this.approvalRule,
    required this.transactionPin,
  });

  Map<String, dynamic> toJson() => {
    'signatoryIds': signatoryIds,
    'approvalRule': approvalRule,
    'transactionPin': transactionPin,
  };
}

/// Community Wallet Response
class CommunityWalletResponse {
  final bool success;
  final String message;
  final String? walletId;
  final String? accountNumber;

  CommunityWalletResponse({
    required this.success,
    required this.message,
    this.walletId,
    this.accountNumber,
  });

  factory CommunityWalletResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return CommunityWalletResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      walletId: data?['walletId'] ?? data?['id'],
      accountNumber: data?['accountNumber'],
    );
  }
}

/// Resolve Account Response Model
class ResolveAccountResponse {
  final bool success;
  final String message;
  final String accountName;
  final String accountNumber;

  ResolveAccountResponse({
    required this.success,
    required this.message,
    required this.accountName,
    required this.accountNumber,
  });

  factory ResolveAccountResponse.fromJson(Map<String, dynamic> json) {
    // Check for success code "00" or nested structure
    final code = json['code'] as String?;
    final message = json['message'] as String? ?? '';
    final isSuccess = code == '00' || message.toLowerCase().contains('success') || (json['success'] == true);

    // Handle nested format: { customer: { account: { ... } } }
    final customer = json['customer'] as Map<String, dynamic>?;
    final account = customer?['account'] as Map<String, dynamic>?;
    
    // Fallback to data field if present (for standard API wrapper)
    final data = json['data'] as Map<String, dynamic>?;

    return ResolveAccountResponse(
      success: isSuccess,
      message: message,
      accountName: account?['name'] ?? data?['accountName'] ?? '',
      accountNumber: account?['number'] ?? data?['accountNumber'] ?? '',
    );
  }
}
