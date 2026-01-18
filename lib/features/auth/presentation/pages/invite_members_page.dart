import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_creation_provider.dart';

class InviteMembersPage extends ConsumerStatefulWidget {
  /// Optional communityId - if provided, we're inviting to an existing community
  /// If null, we're in the community creation flow
  final String? communityId;

  const InviteMembersPage({super.key, this.communityId});

  @override
  ConsumerState<InviteMembersPage> createState() => _InviteMembersPageState();
}

class _InviteMembersPageState extends ConsumerState<InviteMembersPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // For existing community flow
  String? _existingCommunityInviteLink;
  bool _isLoadingInviteLink = false;
  final List<MemberToInvite> _localMembersToInvite = [];
  bool _isSendingInvites = false;

  /// Check if we're inviting to an existing community (not creation flow)
  bool get _isExistingCommunityFlow => widget.communityId != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));

    // If existing community flow, load invite link
    if (_isExistingCommunityFlow) {
      _loadInviteLinkForExistingCommunity();
    }
  }

  Future<void> _loadInviteLinkForExistingCommunity() async {
    if (widget.communityId == null) return;

    setState(() {
      _isLoadingInviteLink = true;
    });

    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.getInviteLink(widget.communityId!);

      if (mounted && response.success) {
        setState(() {
          _existingCommunityInviteLink = response.inviteLink;
          _isLoadingInviteLink = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInviteLink = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canAddMember {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    return name.isNotEmpty && (email.isNotEmpty || phone.isNotEmpty);
  }

  void _addMember() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      showErrorSnackbar('Name is required');
      return;
    }

    if (email.isEmpty && phone.isEmpty) {
      showErrorSnackbar('Either email or phone number is required');
      return;
    }

    final member = MemberToInvite(
      name: name,
      email: email.isNotEmpty ? email : null,
      phone: phone.isNotEmpty ? phone : null,
    );

    if (_isExistingCommunityFlow) {
      setState(() {
        _localMembersToInvite.add(member);
      });
    } else {
      ref.read(communityCreationProvider.notifier).addMember(member);
    }

    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();

    showSuccessSnackbar('Member added successfully!');
  }

  void _removeMember(int index) {
    if (_isExistingCommunityFlow) {
      setState(() {
        _localMembersToInvite.removeAt(index);
      });
    } else {
      ref.read(communityCreationProvider.notifier).removeMember(index);
    }
  }

  Future<void> _copyInviteLink() async {
    final inviteLink = _isExistingCommunityFlow
        ? _existingCommunityInviteLink
        : ref.read(communityCreationProvider).inviteLink;

    if (inviteLink == null || inviteLink.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: inviteLink));
    if (mounted) {
      showSuccessSnackbar('Invite link copied to clipboard!');
    }
  }

  String _buildMemberSubtitle(MemberToInvite member) {
    final email = member.email?.isNotEmpty == true ? member.email : null;
    final phone = member.phone?.isNotEmpty == true ? member.phone : null;

    if (email != null && phone != null) {
      return '$email\n$phone';
    } else if (email != null) {
      return email;
    } else if (phone != null) {
      return phone;
    }
    return 'No contact info';
  }

  Future<void> _sendInvites() async {
    if (_isExistingCommunityFlow) {
      // Existing community flow - send invites directly via repository
      await _sendInvitesForExistingCommunity();
    } else {
      // Creation flow - use provider
      final notifier = ref.read(communityCreationProvider.notifier);
      final response = await notifier.sendInvites();

      if (response != null && mounted) {
        if (response.totalSent > 0) {
          showSuccessSnackbar('Sent ${response.totalSent} invite(s) successfully!');
        }
        if (response.totalFailed > 0) {
          showErrorSnackbar('${response.totalFailed} invite(s) failed to send');
        }
        context.push(AppRoutes.welcomeCommunity);
      }
    }
  }

  Future<void> _sendInvitesForExistingCommunity() async {
    if (widget.communityId == null || _localMembersToInvite.isEmpty) return;

    // Convert MemberToInvite to EmailInvite
    final emailInvites = _localMembersToInvite
        .where((m) => m.email != null && m.email!.isNotEmpty)
        .map((m) => EmailInvite(
              email: m.email!,
              name: m.name,
              phone: m.phone,
            ))
        .toList();

    if (emailInvites.isEmpty) {
      showErrorSnackbar('No valid email addresses to send invites');
      return;
    }

    setState(() {
      _isSendingInvites = true;
    });

    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.sendEmailInvites(
        widget.communityId!,
        emailInvites,
      );

      if (mounted) {
        if (response.success) {
          if (response.totalSent > 0) {
            showSuccessSnackbar('Sent ${response.totalSent} invite(s) successfully!');
          }
          if (response.totalFailed > 0) {
            showErrorSnackbar('${response.totalFailed} invite(s) failed to send');
          }
          // Clear local members and go back
          setState(() {
            _localMembersToInvite.clear();
            _isSendingInvites = false;
          });
          // Go back to members page
          context.pop();
        } else {
          showErrorSnackbar(response.message);
          setState(() {
            _isSendingInvites = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar('Failed to send invites: $e');
        setState(() {
          _isSendingInvites = false;
        });
      }
    }
  }

  void _showSkipInviteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip Invite',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'You can do this later from your account page',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.push(AppRoutes.welcomeCommunity);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBulkUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return _BulkUploadBottomSheet(
          onMembersUploaded: (List<MemberToInvite> members) {
            if (_isExistingCommunityFlow) {
              setState(() {
                _localMembersToInvite.addAll(members);
              });
            } else {
              ref.read(communityCreationProvider.notifier).addMembersFromCsv(members);
            }
            showSuccessSnackbar('${members.length} members added from CSV!');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityCreationProvider);

    // Use appropriate data source based on flow
    final inviteLink = _isExistingCommunityFlow
        ? (_isLoadingInviteLink ? 'Loading...' : (_existingCommunityInviteLink ?? 'No invite link'))
        : (state.inviteLink ?? 'Loading...');
    final membersToInvite = _isExistingCommunityFlow
        ? _localMembersToInvite
        : state.membersToInvite;
    final isLoading = _isExistingCommunityFlow ? _isSendingInvites : state.isLoading;

    return Stack(
      children: [
        Scaffold(
        backgroundColor: AppColors.surface,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              Row(
                children: [
                  AppBackButton(),
                  SizedBox(width: 15),
                  Text(
                    'Invite Members',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  // Only show Skip for creation flow
                  if (!_isExistingCommunityFlow)
                    InkWell(
                      onTap: _showSkipInviteDialog,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite your members',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Include the details of all the members you'd like to invite, or simply copy the link and share it with your Members.",
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Invite Link Section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invite link',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    inviteLink,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            InkWell(
                              onTap: (_isExistingCommunityFlow
                                  ? _existingCommunityInviteLink != null
                                  : state.inviteLink != null)
                                  ? _copyInviteLink
                                  : null,
                              child: Icon(
                                Icons.copy_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      // Added Members Section
                      if (membersToInvite.isNotEmpty) ...[
                        Text(
                          'Added Members (${membersToInvite.length})',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: membersToInvite.reversed
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final originalIndex = membersToInvite.length - 1 - entry.key;
                              final member = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: _buildAddedMemberCard(
                                  title: member.name,
                                  subtitle: _buildMemberSubtitle(member),
                                  onRemove: () => _removeMember(originalIndex),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    // Add New Member Section
                    Text(
                      'Invite New Member',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Name',
                      labelText: 'Name',
                    ),
                    SizedBox(height: 12),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email address',
                      labelText: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'Phone number',
                      labelText: 'Phone number',
                      keyboardType: TextInputType.phone,
                      suffixIcon: InkWell(
                        onTap: () {
                          // TODO: Implement contacts picker
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset('assets/svgs/phonebook.svg'),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canAddMember
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(43),
                          ),
                        ),
                        onPressed: _canAddMember ? _addMember : null,
                        child: Text(
                          'Add',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _canAddMember
                                ? AppColors.textOnPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    // Bulk Upload Section
                    Text(
                      'Get through this faster',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showBulkUploadBottomSheet(),
                      child: Text(
                        'Try Bulk Upload',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: membersToInvite.isNotEmpty
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: membersToInvite.isNotEmpty ? _sendInvites : null,
              child: Text(
                'Invite Members',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: membersToInvite.isNotEmpty
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddedMemberCard({
    required String title,
    required String subtitle,
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          InkWell(
            onTap: onRemove,
            child: SvgPicture.asset('assets/svgs/fi_x-circle.svg'),
          ),
        ],
      ),
    );
  }
}

class _BulkUploadBottomSheet extends StatefulWidget {
  final Function(List<MemberToInvite>) onMembersUploaded;

  const _BulkUploadBottomSheet({required this.onMembersUploaded});

  @override
  State<_BulkUploadBottomSheet> createState() => _BulkUploadBottomSheetState();
}

class _BulkUploadBottomSheetState extends State<_BulkUploadBottomSheet> {
  String? _selectedFileName;
  final List<MemberToInvite> _parsedMembers = [];
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickCSVFile() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final contents = await file.readAsString();
        final rows = const CsvToListConverter().convert(contents);

        if (rows.isEmpty) {
          setState(() {
            _errorMessage = 'CSV file is empty';
            _isProcessing = false;
          });
          return;
        }

        // Parse header to find column indices
        final header = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
        final nameIndex = header.indexWhere((h) => h == 'name' || h == 'fullname' || h == 'full name');
        final emailIndex = header.indexWhere((h) => h == 'email' || h == 'email address');
        final phoneIndex = header.indexWhere((h) => h == 'phone' || h == 'phone number' || h == 'phonenumber');

        if (nameIndex == -1) {
          setState(() {
            _errorMessage = 'CSV must have a "name" column';
            _isProcessing = false;
          });
          return;
        }

        if (emailIndex == -1 && phoneIndex == -1) {
          setState(() {
            _errorMessage = 'CSV must have "email" or "phone" column';
            _isProcessing = false;
          });
          return;
        }

        // Parse data rows (skip header)
        _parsedMembers.clear();
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          final name = nameIndex < row.length ? row[nameIndex]?.toString().trim() ?? '' : '';
          final email = emailIndex != -1 && emailIndex < row.length
              ? row[emailIndex]?.toString().trim() ?? ''
              : '';
          final phone = phoneIndex != -1 && phoneIndex < row.length
              ? row[phoneIndex]?.toString().trim() ?? ''
              : '';

          if (name.isNotEmpty && (email.isNotEmpty || phone.isNotEmpty)) {
            _parsedMembers.add(MemberToInvite(
              name: name,
              email: email.isNotEmpty ? email : null,
              phone: phone.isNotEmpty ? phone : null,
            ));
          }
        }

        setState(() {
          _selectedFileName = result.files.first.name;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error reading CSV file: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV should have columns: name, email, phone'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Draggable handle
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.background),
                ),
              ),
              child: Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Container(
                    height: 5,
                    width: 51,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload CSV file',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // File upload area
            InkWell(
              onTap: _isProcessing ? null : _pickCSVFile,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _selectedFileName != null
                      ? AppColors.primaryLight
                      : AppColors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedFileName != null
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _isProcessing
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : Column(
                        children: [
                          if (_selectedFileName != null)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 32,
                            )
                          else
                            SvgPicture.asset('assets/svgs/upload.svg'),
                          SizedBox(height: 10),
                          Text(
                            _selectedFileName ?? 'select File to upload',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: _selectedFileName != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_parsedMembers.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              '${_parsedMembers.length} members found',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            SizedBox(height: 16),
            // Error message
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) SizedBox(height: 16),
            // CSV info
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only CSV files are accepted (max 2MB)',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            // Download template link
            GestureDetector(
              onTap: _downloadTemplate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Download CSV template',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            // Upload button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _parsedMembers.isNotEmpty && !_isProcessing
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(43),
                    ),
                  ),
                  onPressed: _parsedMembers.isNotEmpty && !_isProcessing
                      ? () {
                          widget.onMembersUploaded(_parsedMembers);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    _isProcessing
                        ? 'Processing...'
                        : _parsedMembers.isNotEmpty
                            ? 'Upload ${_parsedMembers.length} Members'
                            : 'Upload',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _parsedMembers.isNotEmpty && !_isProcessing
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
