import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/providers/contribution_creation_provider.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/create_contribution_page.dart'
    as create_page;

// Contribution brand colors
const Color _contributionPrimary = Color(0xFFF83181);

class ConfigureContributionPage extends ConsumerStatefulWidget {
  final create_page.ContributionType? contributionType;
  final String? contributionName;
  final String? contributionDescription;
  final String? imagePath;

  const ConfigureContributionPage({
    super.key,
    this.contributionType,
    this.contributionName,
    this.contributionDescription,
    this.imagePath,
  });

  @override
  ConsumerState<ConfigureContributionPage> createState() =>
      _ConfigureContributionPageState();
}

class _ConfigureContributionPageState
    extends ConsumerState<ConfigureContributionPage> {
  final TextEditingController _amountController = TextEditingController();
  DateTime? _startDate;
  DateTime? _deadline;

  // Recipient selection
  bool _isCommunityWalletSelected = true;
  ContributionCommunityMember? _selectedMember;

  ParticipantVisibility _visibility = ParticipantVisibility.viewAll;
  bool _notifyRecipient = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setTypeInProvider();
      _setBasicInfoInProvider();
      _loadMembers();
    });
  }

  void _setTypeInProvider() {
    final notifier = ref.read(contributionCreationProvider.notifier);
    switch (widget.contributionType) {
      case create_page.ContributionType.fixedAmount:
        notifier.setType(ContributionType.fixed);
        break;
      case create_page.ContributionType.targetContribution:
        notifier.setType(ContributionType.target);
        break;
      case create_page.ContributionType.flexible:
        notifier.setType(ContributionType.flexible);
        break;
      case null:
        break;
    }
  }

  void _setBasicInfoInProvider() {
    final notifier = ref.read(contributionCreationProvider.notifier);
    if (widget.contributionName != null) {
      notifier.setContributionName(widget.contributionName!);
    }
    if (widget.contributionDescription != null) {
      notifier.setDescription(widget.contributionDescription);
    }
    if (widget.imagePath != null) {
      notifier.setIconPath(widget.imagePath);
    }
  }

  Future<void> _loadMembers() async {
    await ref.read(contributionCreationProvider.notifier).loadCommunityMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (widget.contributionType == create_page.ContributionType.flexible) {
      return _startDate != null && (_isCommunityWalletSelected || _selectedMember != null);
    }
    return _amountController.text.trim().isNotEmpty &&
        _startDate != null &&
        (_isCommunityWalletSelected || _selectedMember != null);
  }

  String get _amountFieldLabel {
    switch (widget.contributionType) {
      case create_page.ContributionType.fixedAmount:
        return 'Contribution amount';
      case create_page.ContributionType.targetContribution:
        return 'Target amount';
      case create_page.ContributionType.flexible:
      case null:
        return 'Amount';
    }
  }

  String get _amountFieldDescription {
    switch (widget.contributionType) {
      case create_page.ContributionType.fixedAmount:
        return 'Amount each participant must contribute';
      case create_page.ContributionType.targetContribution:
        return 'Total target amount to be achieved collectively';
      case create_page.ContributionType.flexible:
      case null:
        return '';
    }
  }

  bool get _showAmountField {
    return widget.contributionType != create_page.ContributionType.flexible;
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _contributionPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _deadline = picked;
        }
      });
    }
  }

  void _showRecipientModal() {
    final state = ref.read(contributionCreationProvider);
    final eligibleMembers = state.eligibleMembers;

    final TextEditingController searchController = TextEditingController();
    List<ContributionCommunityMember> filteredMembers = List.from(eligibleMembers);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Recipient',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Search field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search members',
                          hintStyle: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            color: const Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filteredMembers = eligibleMembers
                                .where((m) => m.fullName
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Community Wallet option (always first)
              _buildCommunityWalletItem(setModalState),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Member list
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _contributionPrimary,
                        ),
                      )
                    : filteredMembers.isEmpty
                        ? Center(
                            child: Text(
                              'No eligible members found',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                color: const Color(0xFF606060),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredMembers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = filteredMembers[index];
                              return _buildMemberItem(member);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityWalletItem(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Wallet',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Default recipient',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isCommunityWalletSelected = true;
                _selectedMember = null;
              });
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: _isCommunityWalletSelected ? _contributionPrimary : null,
              side: const BorderSide(color: _contributionPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: Text(
              _isCommunityWalletSelected ? 'Selected' : 'Select',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isCommunityWalletSelected ? Colors.white : _contributionPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(ContributionCommunityMember member) {
    final isSelected = !_isCommunityWalletSelected && _selectedMember?.id == member.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getAvatarColor(member.fullName),
            backgroundImage: member.photo != null ? NetworkImage(member.photo!) : null,
            child: member.photo == null
                ? Text(
                    _getInitials(member.fullName),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.isCurrentUser ? '${member.fullName} (You)' : member.fullName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _contributionPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _contributionPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isCommunityWalletSelected = false;
                _selectedMember = member;
              });
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? _contributionPrimary : null,
              side: const BorderSide(color: _contributionPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: Text(
              isSelected ? 'Selected' : 'Select',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : _contributionPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
      const Color(0xFF03A9F4),
      const Color(0xFF009688),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF795548),
    ];
    return colors[name.hashCode % colors.length];
  }

  void _showVisibilityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Participants can',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ...ParticipantVisibility.values.map((visibility) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  visibility.displayName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                trailing: _visibility == visibility
                    ? const Icon(Icons.check, color: _contributionPrimary)
                    : null,
                onTap: () {
                  setState(() {
                    _visibility = visibility;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleNext() {
    if (!_isFormValid) return;

    final notifier = ref.read(contributionCreationProvider.notifier);

    // Save amount
    if (_showAmountField && _amountController.text.trim().isNotEmpty) {
      final amount = double.tryParse(
          _amountController.text.trim().replaceAll(',', '').replaceAll('₦', ''));
      if (amount != null) {
        notifier.setAmount(amount);
      }
    }

    // Save start date
    if (_startDate != null) {
      notifier.setStartDate(_startDate!);
    }

    // Save deadline
    if (_deadline != null) {
      notifier.setDeadline(_deadline);
    }

    // Save recipient
    if (_isCommunityWalletSelected) {
      notifier.setRecipientType(RecipientType.communityWallet);
    } else if (_selectedMember != null) {
      notifier.setRecipientType(RecipientType.member);
      notifier.setRecipient(_selectedMember!.id, _selectedMember!.fullName);
    }

    // Save visibility
    notifier.setVisibility(_visibility);

    // Save notify recipient
    notifier.setNotifyRecipient(_notifyRecipient);

    // Navigate to add participants page
    context.push(AppRoutes.contributionAddParticipants);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contributionCreationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Configure',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contribution/Target amount (not shown for Flexible type)
                      if (_showAmountField) ...[
                        CustomTextField(
                          controller: _amountController,
                          labelText: _amountFieldLabel,
                          hintText: '₦',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _amountFieldDescription,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF606060),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Start date
                      _buildDateField(
                        label: 'Start date',
                        value: _startDate,
                        onTap: () => _selectDate(isStartDate: true),
                      ),
                      const SizedBox(height: 16),

                      // Deadline
                      _buildDateField(
                        label: 'Deadline (optional)',
                        value: _deadline,
                        onTap: () => _selectDate(isStartDate: false),
                      ),
                      const SizedBox(height: 24),

                      // Add a recipient
                      Text(
                        'Add a recipient',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRecipientDropdown(state),
                      const SizedBox(height: 24),

                      // Participants can
                      Text(
                        'Participants can',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildVisibilityDropdown(),

                      // Notify recipient checkbox (only show if recipient is a member)
                      if (!_isCommunityWalletSelected && _selectedMember != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _notifyRecipient = !_notifyRecipient;
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _notifyRecipient
                                        ? _contributionPrimary
                                        : const Color(0xFF9E9E9E),
                                    width: 2,
                                  ),
                                  color: _notifyRecipient
                                      ? _contributionPrimary
                                      : Colors.transparent,
                                ),
                                child: _notifyRecipient
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Notify Recipient',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
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
              backgroundColor:
                  _isFormValid ? _contributionPrimary : Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: _isFormValid ? _handleNext : null,
            child: Text(
              'Next',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null
                  ? DateFormat('MMM dd, yyyy').format(value)
                  : label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: value != null ? Colors.black : const Color(0xFF9E9E9E),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientDropdown(ContributionCreationState state) {
    return GestureDetector(
      onTap: _showRecipientModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (_isCommunityWalletSelected) ...[
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.grey, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Community Wallet',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedMember != null) ...[
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(_selectedMember!.fullName),
                backgroundImage: _selectedMember!.photo != null
                    ? NetworkImage(_selectedMember!.photo!)
                    : null,
                child: _selectedMember!.photo == null
                    ? Text(
                        _getInitials(_selectedMember!.fullName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                      _selectedMember!.fullName,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _selectedMember!.email,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select recipient',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ],
            if (state.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _contributionPrimary,
                ),
              )
            else
              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityDropdown() {
    return GestureDetector(
      onTap: _showVisibilityModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _visibility.displayName,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
