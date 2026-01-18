import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

/// Community Wallet Setup Steps
enum CommunityWalletSetupStep {
  checklist,
  signatories,
  approvalRules,
  createPin,
  confirmPin,
  success,
}

/// Mock Co-Admin model for UI development
class MockCoAdmin {
  final String userId;
  final String fullName;
  final String? photo;

  MockCoAdmin({required this.userId, required this.fullName, this.photo});
}

/// Approval Rule enum for UI
enum ApprovalRule {
  thirtyPercent,
  fiftyPercent,
  seventyFivePercent,
  hundredPercent;

  String get displayName {
    switch (this) {
      case ApprovalRule.thirtyPercent:
        return '30%';
      case ApprovalRule.fiftyPercent:
        return '50%';
      case ApprovalRule.seventyFivePercent:
        return '75%';
      case ApprovalRule.hundredPercent:
        return '100%';
    }
  }

  String get description {
    switch (this) {
      case ApprovalRule.thirtyPercent:
        return 'At least 30% of signatories must approve';
      case ApprovalRule.fiftyPercent:
        return 'At least 50% of signatories must approve';
      case ApprovalRule.seventyFivePercent:
        return 'At least 75% of signatories must approve';
      case ApprovalRule.hundredPercent:
        return 'All signatories must approve';
    }
  }
}

/// Community Wallet Setup Page
/// Multi-step flow for creating a community wallet
///
/// TODO: Connect to backend when UI is finalized
/// - Replace mock data with actual API calls
/// - Use repository.getCoAdmins(communityId) for co-admins list
/// - Use repository.createCommunityWallet() for wallet creation
class CommunityWalletSetupPage extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityWalletSetupPage({super.key, required this.communityId});

  @override
  ConsumerState<CommunityWalletSetupPage> createState() =>
      _CommunityWalletSetupPageState();
}

class _CommunityWalletSetupPageState
    extends ConsumerState<CommunityWalletSetupPage> {
  CommunityWalletSetupStep _currentStep = CommunityWalletSetupStep.checklist;
  String? _error;

  // Form data
  MockCoAdmin? _selectedSignatory;
  ApprovalRule _selectedApprovalRule = ApprovalRule.fiftyPercent;
  String _pin = '';
  String _confirmPin = '';

  // Mock data - replace with actual API data later
  final String _adminName = 'John Doe';
  final List<MockCoAdmin> _coAdmins = [
    MockCoAdmin(userId: '1', fullName: 'Jane Smith'),
    MockCoAdmin(userId: '2', fullName: 'Bob Wilson'),
    MockCoAdmin(userId: '3', fullName: 'Alice Johnson'),
  ];

  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case CommunityWalletSetupStep.checklist:
          _currentStep = CommunityWalletSetupStep.signatories;
          break;
        case CommunityWalletSetupStep.signatories:
          _currentStep = CommunityWalletSetupStep.approvalRules;
          break;
        case CommunityWalletSetupStep.approvalRules:
          _currentStep = CommunityWalletSetupStep.createPin;
          break;
        case CommunityWalletSetupStep.createPin:
          _currentStep = CommunityWalletSetupStep.confirmPin;
          break;
        case CommunityWalletSetupStep.confirmPin:
          // TODO: Call createWallet API here
          if (_pin == _confirmPin) {
            _currentStep = CommunityWalletSetupStep.success;
          } else {
            _error = 'PINs do not match';
            _currentStep = CommunityWalletSetupStep.createPin;
            _pin = '';
            _confirmPin = '';
          }
          break;
        case CommunityWalletSetupStep.success:
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case CommunityWalletSetupStep.checklist:
          context.pop();
          break;
        case CommunityWalletSetupStep.signatories:
          _currentStep = CommunityWalletSetupStep.checklist;
          break;
        case CommunityWalletSetupStep.approvalRules:
          _currentStep = CommunityWalletSetupStep.signatories;
          break;
        case CommunityWalletSetupStep.createPin:
          _currentStep = CommunityWalletSetupStep.approvalRules;
          _pin = '';
          break;
        case CommunityWalletSetupStep.confirmPin:
          _currentStep = CommunityWalletSetupStep.createPin;
          _confirmPin = '';
          break;
        case CommunityWalletSetupStep.success:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentStep != CommunityWalletSetupStep.success
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStep,
              ),
              title: Text(
                _getAppBarTitle(),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: _buildCurrentStep(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case CommunityWalletSetupStep.checklist:
        return 'Wallet Checklist';
      case CommunityWalletSetupStep.signatories:
        return 'Set up Signatories';
      case CommunityWalletSetupStep.approvalRules:
        return 'Set up Approval Rules';
      case CommunityWalletSetupStep.createPin:
        return 'Create Transaction PIN';
      case CommunityWalletSetupStep.confirmPin:
        return 'Confirm Transaction PIN';
      case CommunityWalletSetupStep.success:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case CommunityWalletSetupStep.checklist:
        return _buildChecklistStep();
      case CommunityWalletSetupStep.signatories:
        return _buildSignatoriesStep();
      case CommunityWalletSetupStep.approvalRules:
        return _buildApprovalRulesStep();
      case CommunityWalletSetupStep.createPin:
        return _buildPinStep(isConfirm: false);
      case CommunityWalletSetupStep.confirmPin:
        return _buildPinStep(isConfirm: true);
      case CommunityWalletSetupStep.success:
        return _buildSuccessStep();
    }
  }

  /// Step 1: Wallet Checklist
  /// TODO: Match to Figma design
  Widget _buildChecklistStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete these steps to activate your community wallet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 32),
          _buildChecklistItem(
            icon: Icons.people_outline,
            title: 'Set up Signatories',
            subtitle: 'Select who can approve withdrawals',
            isCompleted: false,
          ),
          const SizedBox(height: 16),
          _buildChecklistItem(
            icon: Icons.rule,
            title: 'Set up Approval Rules',
            subtitle: 'Configure approval percentage',
            isCompleted: false,
          ),
          const SizedBox(height: 16),
          _buildChecklistItem(
            icon: Icons.lock_outline,
            title: 'Create Transaction PIN',
            subtitle: 'Secure your community wallet',
            isCompleted: false,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: _nextStep,
              child: Text(
                'Start Setup',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted ? Colors.white : const Color(0xFF606060),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF282637),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: const Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: Set up Signatories
  /// TODO: Match to Figma design
  Widget _buildSignatoriesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select signatories who will approve fund releases',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 32),

          // Signatory A (Admin - pre-filled)
          Text(
            'Signatory A (Admin)',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF282637),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_adminName (You)',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF282637),
                        ),
                      ),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: const Color(0xFF8E8E8E),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: const Color(0xFF8E8E8E),
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Signatory B (Select Co-Admin)
          Text(
            'Signatory B',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF282637),
            ),
          ),
          const SizedBox(height: 8),

          if (_coAdmins.isEmpty)
            _buildNoCoAdminsMessage()
          else
            _buildCoAdminSelector(),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],

          const Spacer(),

          if (_coAdmins.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _selectedSignatory != null ? AppColors.primary : Colors.grey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(43),
                  ),
                ),
                onPressed: _selectedSignatory != null ? _nextStep : null,
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNoCoAdminsMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFFFFA000),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Co-Admins Available',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF282637),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need at least 2 Co-Admins to create a community wallet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(
              'Manage Co-Admins',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoAdminSelector() {
    return Column(
      children: _coAdmins.map((coAdmin) {
        final isSelected = _selectedSignatory?.userId == coAdmin.userId;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSignatory = coAdmin;
              _error = null;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE8E8E8),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage:
                      coAdmin.photo != null ? NetworkImage(coAdmin.photo!) : null,
                  child: coAdmin.photo == null
                      ? Text(
                          coAdmin.fullName.isNotEmpty
                              ? coAdmin.fullName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF606060),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coAdmin.fullName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF282637),
                        ),
                      ),
                      Text(
                        'Co-Admin',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: const Color(0xFF8E8E8E),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: const Color(0xFFE8E8E8),
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Step 3: Set up Approval Rules
  /// TODO: Match to Figma design
  Widget _buildApprovalRulesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select approval percentage for fund release',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 32),

          // Approval rule options
          ...ApprovalRule.values.map((rule) {
            final isSelected = _selectedApprovalRule == rule;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedApprovalRule = rule);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : const Color(0xFFE8E8E8),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.displayName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF282637),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rule.description,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: const Color(0xFF8E8E8E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 24,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: const Color(0xFFE8E8E8),
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF1976D2),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'With 2 signatories: ${_selectedApprovalRule == ApprovalRule.thirtyPercent || _selectedApprovalRule == ApprovalRule.fiftyPercent ? "1 approval needed" : "Both signatories must approve"}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: _nextStep,
              child: Text(
                'Continue',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Step 4 & 5: Create/Confirm PIN
  /// TODO: Match to Figma design - use existing PIN keypad component if available
  Widget _buildPinStep({required bool isConfirm}) {
    final currentPin = isConfirm ? _confirmPin : _pin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isConfirm
                ? 'Re-enter your PIN to confirm'
                : 'Create a 4-digit PIN to secure your community wallet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 32),

          // PIN Display
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentPin.length;
                return Container(
                  margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        isFilled ? const Color(0xFFE8E8E8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE8E8E8),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: isFilled
                        ? Text(
                            '*',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5B5966),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                _error!,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          ],

          const SizedBox(height: 48),

          // Keypad
          _buildKeypad(isConfirm: isConfirm),
        ],
      ),
    );
  }

  Widget _buildKeypad({required bool isConfirm}) {
    return Center(
      child: SizedBox(
        width: 310,
        child: Wrap(
          spacing: 68,
          runSpacing: 20,
          children: [
            // Numbers 1-9
            for (int i = 1; i <= 9; i++)
              _buildKeypadButton(
                text: i.toString(),
                onTap: () => _addDigit(i.toString(), isConfirm),
              ),

            // Delete button
            _buildKeypadButton(
              icon: Icons.backspace_outlined,
              onTap: () => _removeDigit(isConfirm),
            ),

            // 0
            _buildKeypadButton(
              text: '0',
              onTap: () => _addDigit('0', isConfirm),
            ),

            // Confirm button
            _buildKeypadButton(
              icon: Icons.check,
              backgroundColor:
                  (isConfirm ? _confirmPin : _pin).length == 4
                      ? AppColors.primary
                      : Colors.grey,
              iconColor: Colors.white,
              onTap: (isConfirm ? _confirmPin : _pin).length == 4
                  ? _nextStep
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    Color backgroundColor = const Color(0xFFF3F3F3),
    Color textColor = const Color(0xFF333333),
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(37.5),
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                )
              : Icon(icon, size: 24, color: iconColor ?? textColor),
        ),
      ),
    );
  }

  void _addDigit(String digit, bool isConfirm) {
    if (isConfirm) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _error = null;
        });
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
          _error = null;
        });
      }
    }
  }

  void _removeDigit(bool isConfirm) {
    if (isConfirm) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _error = null;
        });
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _error = null;
        });
      }
    }
  }

  /// Step 6: Success
  /// TODO: Match to Figma design
  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Community Wallet Created!',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF282637),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your community wallet is now active and ready to receive funds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: () {
                context.pop();
              },
              child: Text(
                'Go to Wallet',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
