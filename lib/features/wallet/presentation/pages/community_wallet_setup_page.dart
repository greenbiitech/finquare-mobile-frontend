import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/community_wallet_provider.dart';

/// Community Wallet Setup Steps
enum CommunityWalletSetupStep {
  checklist,
  signatories,
  approvalRules,
  createPin,
  confirmPin,
  success,
}

/// Approval Rule enum for UI
enum ApprovalRule {
  adminAndAnyOne,
  adminAndSignatoryB,
  allThree;

  String get displayName {
    switch (this) {
      case ApprovalRule.adminAndAnyOne:
        return 'Admin & (Any 1 other Signatory)';
      case ApprovalRule.adminAndSignatoryB:
        return 'Admin  & Signatory B only to approve';
      case ApprovalRule.allThree:
        return 'Admin, Signatory B & Signatory C';
    }
  }

  String get description {
    switch (this) {
      case ApprovalRule.adminAndAnyOne:
        return 'Requires Admin A plus any one of the other selected signatories to approve.';
      case ApprovalRule.adminAndSignatoryB:
        return 'Requires Admin A and specifically Signatory B to approve.';
      case ApprovalRule.allThree:
        return 'Requires all three selected signatories (Admin A, B, and C) to approve.';
    }
  }
}

/// Community Wallet Setup Page
/// Multi-step flow for creating a community wallet
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
  bool _isCreatingWallet = false;

  // Form data
  ApprovalRule _selectedApprovalRule = ApprovalRule.adminAndAnyOne;
  String _pin = '';
  String _confirmPin = '';

  // Checklist state - selected co-admins (exactly 2)
  List<CoAdmin> _selectedCoAdmins = [];

  // Signatories state
  CoAdmin? _signatoryB;
  CoAdmin? _signatoryC;

  // Confetti state
  bool _confettiLaunched = false;

  /// Convert approval rule enum to backend string format
  String _getApprovalRuleString() {
    switch (_selectedApprovalRule) {
      case ApprovalRule.adminAndAnyOne:
        return 'FIFTY_PERCENT'; // Admin + any 1 other = 2 of 3 = ~66%, closest to 50%
      case ApprovalRule.adminAndSignatoryB:
        return 'SEVENTY_FIVE_PERCENT'; // Admin + Signatory B specifically
      case ApprovalRule.allThree:
        return 'HUNDRED_PERCENT'; // All 3 must approve
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch co-admins when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityWalletProvider.notifier).fetchCoAdmins(widget.communityId);
    });
  }

  // Get admin info from provider
  String get _adminName => ref.read(communityWalletProvider.notifier).adminInfo['name'] ?? 'Admin';
  String get _adminEmail => ref.read(communityWalletProvider.notifier).adminInfo['email'] ?? '';

  // Get co-admins from provider
  List<CoAdmin> get _coAdmins => ref.watch(communityWalletProvider).coAdmins;

  void _nextStep() async {
    switch (_currentStep) {
      case CommunityWalletSetupStep.checklist:
        // From checklist, go directly to approval rules (signatories were set via the card)
        setState(() => _currentStep = CommunityWalletSetupStep.approvalRules);
        break;
      case CommunityWalletSetupStep.signatories:
        // After setting signatories, go back to checklist
        setState(() => _currentStep = CommunityWalletSetupStep.checklist);
        break;
      case CommunityWalletSetupStep.approvalRules:
        setState(() => _currentStep = CommunityWalletSetupStep.createPin);
        break;
      case CommunityWalletSetupStep.createPin:
        setState(() => _currentStep = CommunityWalletSetupStep.confirmPin);
        break;
      case CommunityWalletSetupStep.confirmPin:
        if (_pin != _confirmPin) {
          setState(() {
            _error = 'PINs do not match';
            _currentStep = CommunityWalletSetupStep.createPin;
            _pin = '';
            _confirmPin = '';
          });
          return;
        }

        // Call createWallet API
        await _createCommunityWallet();
        break;
      case CommunityWalletSetupStep.success:
        break;
    }
  }

  Future<void> _createCommunityWallet() async {
    setState(() => _isCreatingWallet = true);

    try {
      // Get signatory IDs (signatoryB and signatoryC odooIds)
      final signatoryIds = <String>[];
      if (_signatoryB != null) signatoryIds.add(_signatoryB!.odooId);
      if (_signatoryC != null) signatoryIds.add(_signatoryC!.odooId);

      final success = await ref.read(communityWalletProvider.notifier).createWallet(
        communityId: widget.communityId,
        signatoryIds: signatoryIds,
        approvalRule: _getApprovalRuleString(),
        transactionPin: _pin,
      );

      if (success) {
        setState(() {
          _isCreatingWallet = false;
          _currentStep = CommunityWalletSetupStep.success;
        });
      } else {
        final error = ref.read(communityWalletProvider).error;
        setState(() {
          _isCreatingWallet = false;
          _error = error ?? 'Failed to create community wallet';
        });
        showWarningSnackbar(_error ?? 'Failed to create community wallet');
      }
    } catch (e) {
      setState(() {
        _isCreatingWallet = false;
        _error = e.toString();
      });
      showWarningSnackbar('Failed to create community wallet');
    }
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
          _currentStep = CommunityWalletSetupStep.checklist;
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
    // These screens use circular back button instead of AppBar
    final showAppBar = _currentStep != CommunityWalletSetupStep.checklist &&
        _currentStep != CommunityWalletSetupStep.signatories &&
        _currentStep != CommunityWalletSetupStep.approvalRules &&
        _currentStep != CommunityWalletSetupStep.createPin &&
        _currentStep != CommunityWalletSetupStep.confirmPin &&
        _currentStep != CommunityWalletSetupStep.success;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
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
  Widget _buildChecklistStep() {
    // Must have exactly 2 co-admins selected
    final bool hasCoAdmins = _selectedCoAdmins.length == 2;
    // Signatories are set when both B and C are selected
    final bool hasSignatories = _signatoryB != null && _signatoryC != null;
    final bool canContinue = hasCoAdmins && hasSignatories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          AppBackButton(onTap: () => context.pop()),
          const SizedBox(height: 22),
          Text(
            'Wallet checklist',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Before you can create a community wallet we need you to do the following',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _showSelectCoAdminsModal,
            child: _buildChecklistItem(
              title: 'Add Co-admins',
              subtitle: 'Community admins must set up co-admins that can serve as signatories and approve fund releases',
              isCompleted: hasCoAdmins,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (!hasCoAdmins) {
                showWarningSnackbar('Please add Co-admins first');
              } else {
                // Navigate to set signatories step
                setState(() {
                  _currentStep = CommunityWalletSetupStep.signatories;
                });
              }
            },
            child: _buildChecklistItem(
              title: 'Set co admins as Signatories',
              subtitle: 'Community admins must set up co-admins that can serve as signatories and approve fund releases',
              isCompleted: hasSignatories,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? AppColors.primary : const Color(0xFFF5F5F5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: canContinue ? _nextStep : null,
              child: Text(
                'Continue',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: canContinue ? Colors.white : const Color(0xFFBDBDBD),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSelectCoAdminsModal() {
    final communityState = ref.read(communityWalletProvider);

    // Show warning if still loading or error
    if (communityState.isLoading) {
      showWarningSnackbar('Loading co-admins, please wait...');
      return;
    }

    if (communityState.error != null) {
      showWarningSnackbar(communityState.error!);
      // Retry fetching co-admins
      ref.read(communityWalletProvider.notifier).fetchCoAdmins(widget.communityId);
      return;
    }

    if (_coAdmins.isEmpty) {
      showWarningSnackbar('No co-admins available. Please add co-admins to your community first.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SelectCoAdminsModal(
        coAdmins: _coAdmins,
        selectedCoAdmins: _selectedCoAdmins,
        onSelectionChanged: (selected) {
          setState(() => _selectedCoAdmins = selected);
        },
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isCompleted ? 'Completed' : 'Not Done',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: Set up Signatories
  Widget _buildSignatoriesStep() {
    // When B is selected, C auto-fills with the other co-admin
    final bool canContinue = _signatoryB != null && _signatoryC != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          AppBackButton(onTap: _previousStep),
          const SizedBox(height: 22),
          Text(
            'Set up signatories',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Before you can create a community wallet we need you to do the following',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 24),

          // Signatory A (Admin - pre-filled)
          Text(
            'Signatory A',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 8),
          _buildSignatoryCard(
            name: _adminName,
            email: _adminEmail,
            isFixed: true,
          ),

          const SizedBox(height: 16),

          // Signatory B (Select from co-admins)
          Text(
            'Signatory B',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 8),
          _buildSignatoryDropdown(
            selectedCoAdmin: _signatoryB,
            onTap: () => _showSignatoryBSelector(),
          ),

          const SizedBox(height: 16),

          // Signatory C (Auto-fills when B is selected)
          Text(
            'Signatory C',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 8),
          _buildSignatoryDropdown(
            selectedCoAdmin: _signatoryC,
            onTap: _signatoryB != null ? () => _showSignatoryCSelector() : null,
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? AppColors.primary : const Color(0xFFF5F5F5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: canContinue ? _nextStep : null,
              child: Text(
                'Continue',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: canContinue ? Colors.white : const Color(0xFFBDBDBD),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSignatoryCard({
    required String name,
    required String email,
    bool isFixed = false,
    bool hasDropdown = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar placeholder
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE8E8E8),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF606060),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF282637),
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: const Color(0xFF8E8E8E),
                    ),
                  ),
                ],
              ),
            ),
            if (hasDropdown)
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF606060),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatoryDropdown({
    CoAdmin? selectedCoAdmin,
    VoidCallback? onTap,
  }) {
    if (selectedCoAdmin != null) {
      return _buildSignatoryCard(
        name: selectedCoAdmin.odooName,
        email: selectedCoAdmin.odooEmail,
        hasDropdown: true,
        onTap: onTap,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              'Select',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E8E),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF606060),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignatoryBSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SignatorySelectorModal(
        title: 'Select Signatory B',
        coAdmins: _selectedCoAdmins,
        excludeCoAdmin: _signatoryC,
        onSelected: (coAdmin) {
          setState(() {
            _signatoryB = coAdmin;
            // Auto-fill Signatory C with the other co-admin
            if (_selectedCoAdmins.length == 2) {
              _signatoryC = _selectedCoAdmins.firstWhere(
                (c) => c.odooId != coAdmin.odooId,
              );
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSignatoryCSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SignatorySelectorModal(
        title: 'Select Signatory C',
        coAdmins: _selectedCoAdmins,
        excludeCoAdmin: _signatoryB,
        onSelected: (coAdmin) {
          setState(() {
            _signatoryC = coAdmin;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Step 3: Set up Approval Rules
  Widget _buildApprovalRulesStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          AppBackButton(onTap: _previousStep),
          const SizedBox(height: 22),
          Text(
            'Set up Approval rules',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define the number of signatories required to approve transactions. This ensures that no single person can move funds without consensus.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 24),

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
                  color: isSelected ? const Color(0xFFE8E8E8) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF333333) : const Color(0xFFE8E8E8),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radio button
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF333333) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF333333) : const Color(0xFF333333),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
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
                            rule.displayName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
            );
          }),

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
  Widget _buildPinStep({required bool isConfirm}) {
    final currentPin = isConfirm ? _confirmPin : _pin;
    final isPinComplete = currentPin.length == 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          AppBackButton(onTap: _previousStep),
          const SizedBox(height: 20),
          Text(
            isConfirm ? 'Confirm your Transaction pin 🔐' : 'Create a Transaction pin 🔐',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Pick a 4-digit PIN that even a ninja couldn't guess. (But you can, obviously!)",
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF606060),
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

          const Spacer(),

          // PIN Display - dots in rounded container
          Center(
            child: Container(
              width: 190,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: currentPin.length > index
                          ? AppColors.primary
                          : const Color(0xFFE8E8E8),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),

          const Spacer(),

          // Keypad
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              String? buttonText;
              Icon? buttonIcon;
              VoidCallback? onPressed;
              Color? color;

              if (index < 9) {
                buttonText = (index + 1).toString();
                onPressed = () => _addDigit(buttonText!, isConfirm);
              } else if (index == 9) {
                buttonIcon = const Icon(Icons.backspace_outlined, color: Colors.black);
                onPressed = () => _removeDigit(isConfirm);
              } else if (index == 10) {
                buttonText = '0';
                onPressed = () => _addDigit(buttonText!, isConfirm);
              } else {
                // Show loading indicator when creating wallet
                if (_isCreatingWallet) {
                  return Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }
                buttonIcon = Icon(
                  Icons.check,
                  color: Color(isPinComplete ? 0xFFFFFFFF : 0xFFBBBBBB),
                );
                onPressed = isPinComplete && !_isCreatingWallet ? _nextStep : null;
                color = isPinComplete ? AppColors.primary : null;
              }

              return _buildPinKeypadButton(
                text: buttonText,
                icon: buttonIcon,
                onPressed: onPressed,
                color: color,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPinKeypadButton({
    String? text,
    Icon? icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        width: 58,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFF3F3F3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                )
              : icon,
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

  void _launchConfetti() {
    if (_confettiLaunched) return;
    _confettiLaunched = true;

    // Launch multiple confetti bursts over time
    final bursts = [
      {'delay': 0, 'x': 0.5, 'y': 0.3, 'particles': 100, 'spread': 70},
      {'delay': 200, 'x': 0.2, 'y': 0.4, 'particles': 50, 'spread': 100},
      {'delay': 400, 'x': 0.8, 'y': 0.4, 'particles': 50, 'spread': 100},
      {'delay': 700, 'x': 0.5, 'y': 0.5, 'particles': 80, 'spread': 80},
      {'delay': 1000, 'x': 0.3, 'y': 0.3, 'particles': 60, 'spread': 90},
      {'delay': 1300, 'x': 0.7, 'y': 0.3, 'particles': 60, 'spread': 90},
      {'delay': 1600, 'x': 0.5, 'y': 0.4, 'particles': 100, 'spread': 70},
      {'delay': 2000, 'x': 0.2, 'y': 0.5, 'particles': 50, 'spread': 100},
      {'delay': 2300, 'x': 0.8, 'y': 0.5, 'particles': 50, 'spread': 100},
      {'delay': 2600, 'x': 0.5, 'y': 0.3, 'particles': 80, 'spread': 80},
    ];

    for (final burst in bursts) {
      Future.delayed(Duration(milliseconds: burst['delay'] as int), () {
        if (mounted) {
          Confetti.launch(
            context,
            options: ConfettiOptions(
              particleCount: burst['particles'] as int,
              spread: (burst['spread'] as int).toDouble(),
              x: burst['x'] as double,
              y: burst['y'] as double,
            ),
          );
        }
      });
    }
  }

  /// Step 6: Success
  Widget _buildSuccessStep() {
    // Launch confetti when this step is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchConfetti();
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              const SizedBox(height: 150),
              SvgPicture.asset('assets/svgs/sucessful.svg'),
              const SizedBox(height: 20),
              Text(
                'Your Community Wallet has been created',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'You can now safely fund your wallet and carry out community finance activities',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
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
              'Alright',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal for selecting co-admins
class _SelectCoAdminsModal extends StatefulWidget {
  final List<CoAdmin> coAdmins;
  final List<CoAdmin> selectedCoAdmins;
  final Function(List<CoAdmin>) onSelectionChanged;

  const _SelectCoAdminsModal({
    required this.coAdmins,
    required this.selectedCoAdmins,
    required this.onSelectionChanged,
  });

  @override
  State<_SelectCoAdminsModal> createState() => _SelectCoAdminsModalState();
}

class _SelectCoAdminsModalState extends State<_SelectCoAdminsModal> {
  late List<CoAdmin> _selected;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedCoAdmins);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CoAdmin> get _filteredCoAdmins {
    if (_searchQuery.isEmpty) return widget.coAdmins;
    return widget.coAdmins.where((coAdmin) {
      return coAdmin.odooName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          coAdmin.odooEmail.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleSelection(CoAdmin coAdmin) {
    final isAlreadySelected = _selected.any((c) => c.odooId == coAdmin.odooId);

    if (!isAlreadySelected && _selected.length >= 2) {
      // Already have 2 selected, show message
      showWarningSnackbar('You can only select exactly 2 Co-admins');
      return;
    }

    setState(() {
      if (isAlreadySelected) {
        _selected.removeWhere((c) => c.odooId == coAdmin.odooId);
      } else {
        _selected.add(coAdmin);
      }
    });
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Co-Admins',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search members',
                hintStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: const Color(0xFF8E8E8E),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E8E)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Co-admins list
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCoAdmins.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final coAdmin = _filteredCoAdmins[index];
                final isSelected = _selected.any((c) => c.odooId == coAdmin.odooId);
                return _buildCoAdminListItem(coAdmin, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoAdminListItem(CoAdmin coAdmin, bool isSelected) {
    return InkWell(
      onTap: () => _toggleSelection(coAdmin),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8E8E8),
              backgroundImage: coAdmin.odooPhoto != null ? NetworkImage(coAdmin.odooPhoto!) : null,
              child: coAdmin.odooPhoto == null
                  ? Text(
                      coAdmin.odooName.isNotEmpty ? coAdmin.odooName[0].toUpperCase() : 'C',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF606060),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        coAdmin.odooName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF282637),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5A84B)),
                        ),
                        child: Text(
                          'co-admin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE5A84B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coAdmin.odooEmail,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: const Color(0xFF8E8E8E),
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Modal for selecting a signatory from co-admins
class _SignatorySelectorModal extends StatelessWidget {
  final String title;
  final List<CoAdmin> coAdmins;
  final CoAdmin? excludeCoAdmin;
  final Function(CoAdmin) onSelected;

  const _SignatorySelectorModal({
    required this.title,
    required this.coAdmins,
    this.excludeCoAdmin,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final availableCoAdmins = coAdmins.where((c) =>
      excludeCoAdmin == null || c.odooId != excludeCoAdmin!.odooId
    ).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          ...availableCoAdmins.map((coAdmin) => InkWell(
            onTap: () => onSelected(coAdmin),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE8E8E8),
                    child: Text(
                      coAdmin.odooName.isNotEmpty ? coAdmin.odooName[0].toUpperCase() : 'C',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF606060),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coAdmin.odooName,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF282637),
                          ),
                        ),
                        Text(
                          coAdmin.odooEmail,
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
            ),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
