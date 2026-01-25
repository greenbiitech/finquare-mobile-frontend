import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/providers/esusu_creation_provider.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

class ConfigureEsusuPage extends ConsumerStatefulWidget {
  const ConfigureEsusuPage({super.key});

  @override
  ConsumerState<ConfigureEsusuPage> createState() => _ConfigureEsusuPageState();
}

class _ConfigureEsusuPageState extends ConsumerState<ConfigureEsusuPage> {
  bool _isPayoutScheduleExpanded = false;

  final TextEditingController _contributionController = TextEditingController();

  final List<String> _frequencyOptions = ['Weekly', 'Monthly', 'Quarterly'];
  final List<int> _commissionOptions = List.generate(50, (i) => i + 1);

  final currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '\u20A6',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(esusuCreationProvider);
      if (state.contributionAmount != null) {
        _contributionController.text = state.contributionAmount!.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _contributionController.dispose();
    super.dispose();
  }

  List<int> _getParticipantOptions(int maxMembers) {
    final maxParticipants = maxMembers.clamp(3, 100);
    return List.generate(maxParticipants - 2, (i) => i + 3);
  }

  PaymentFrequency _frequencyFromString(String value) {
    switch (value) {
      case 'Weekly':
        return PaymentFrequency.weekly;
      case 'Monthly':
        return PaymentFrequency.monthly;
      case 'Quarterly':
        return PaymentFrequency.quarterly;
      default:
        return PaymentFrequency.monthly;
    }
  }

  String _frequencyToString(PaymentFrequency? frequency) {
    switch (frequency) {
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      default:
        return 'Monthly';
    }
  }

  Future<void> _selectParticipationDeadline(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _esusuPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(esusuCreationProvider.notifier).setParticipationDeadline(picked);
    }
  }

  Future<void> _selectCollectionDate(BuildContext context) async {
    final state = ref.read(esusuCreationProvider);
    final minDate = state.minimumCollectionDate ?? DateTime.now().add(const Duration(days: 4));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _esusuPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(esusuCreationProvider.notifier).setCollectionDate(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date);
  }

  void _handleNext() {
    final state = ref.read(esusuCreationProvider);
    if (state.isConfigureComplete) {
      context.push(AppRoutes.addParticipants);
    }
  }

  List<Map<String, String>> _generatePayoutSchedule(EsusuCreationState state) {
    if (state.numberOfParticipants == null ||
        state.collectionDate == null ||
        state.frequency == null) {
      return [];
    }

    final schedule = <Map<String, String>>[];
    var currentDate = state.collectionDate!;
    final dateFormat = DateFormat('MMM yyyy');

    for (int i = 1; i <= state.numberOfParticipants!; i++) {
      schedule.add({
        'cycle': 'Cycle $i',
        'date': dateFormat.format(currentDate),
      });

      // Move to next cycle date based on frequency
      switch (state.frequency!) {
        case PaymentFrequency.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case PaymentFrequency.monthly:
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case PaymentFrequency.quarterly:
          currentDate = DateTime(currentDate.year, currentDate.month + 3, currentDate.day);
          break;
      }
    }

    return schedule;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esusuCreationProvider);
    final participantOptions = _getParticipantOptions(state.maxParticipants);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 20),
                  Text(
                    'Configure',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number of participants
                    Text(
                      'Number of participants',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown<int>(
                      value: state.numberOfParticipants,
                      items: participantOptions,
                      hint: 'Select participants',
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(esusuCreationProvider.notifier).setNumberOfParticipants(value);
                        }
                      },
                      itemLabel: (item) => item.toString(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max ${state.maxParticipants} based on community members',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contribution amount per member
                    _buildOutlinedTextField(
                      controller: _contributionController,
                      label: 'Contribution amount per member',
                      hint: 'e.g. 5000',
                      prefix: '\u20A6 ',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount != null) {
                          ref.read(esusuCreationProvider.notifier).setContributionAmount(amount);
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Minimum \u20A6100',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment frequency
                    Text(
                      'Payment frequency',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _frequencyToString(state.frequency),
                      items: _frequencyOptions,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(esusuCreationProvider.notifier).setFrequency(_frequencyFromString(value));
                        }
                      },
                      itemLabel: (item) => item,
                    ),
                    const SizedBox(height: 20),

                    // Participation Deadline
                    _buildDateField(
                      label: 'Participation Deadline',
                      value: state.participationDeadline,
                      onTap: () => _selectParticipationDeadline(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deadline for participants to accept invite',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Collection Date
                    _buildDateField(
                      label: 'Collection Date',
                      value: state.collectionDate,
                      onTap: state.participationDeadline != null
                          ? () => _selectCollectionDate(context)
                          : null,
                      enabled: state.participationDeadline != null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.participationDeadline != null
                          ? 'Must be at least 3 days after deadline'
                          : 'Select participation deadline first',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Take Commission checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: state.takeCommission,
                            onChanged: (value) {
                              ref.read(esusuCreationProvider.notifier).setTakeCommission(value ?? false);
                            },
                            activeColor: _esusuPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Take Commission',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Commission'),
                                content: const Text(
                                  'As the creator, you can take a percentage of each payout as commission. This amount is deducted before the receiver gets their payout.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF606060),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Commission percentage (visible when checkbox is checked)
                    if (state.takeCommission) ...[
                      Text(
                        'Commission percentage',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<int>(
                        value: state.commissionPercentage,
                        items: _commissionOptions,
                        hint: 'Select percentage',
                        onChanged: (value) {
                          ref.read(esusuCreationProvider.notifier).setCommissionPercentage(value);
                        },
                        itemLabel: (item) => '$item%',
                      ),
                      const SizedBox(height: 4),
                      if (state.commissionPercentage != null && state.totalPool > 0)
                        Text(
                          'You will earn ${currencyFormat.format(state.commission)} per cycle',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _esusuPrimaryColor,
                          ),
                        )
                      else
                        Text(
                          'Select participants and amount to see commission',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF606060),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],

                    // Summary Card
                    if (state.numberOfParticipants != null && state.contributionAmount != null)
                      _buildSummaryCard(state),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: state.isConfigureComplete,
                onPressed: _handleNext,
                title: 'Invite Members',
                buttonColor: state.isConfigureComplete
                    ? _esusuPrimaryColor
                    : Colors.grey.shade400,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(
                  hint,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9E9E9E),
                  ),
                )
              : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOutlinedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        labelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF606060),
        ),
        hintStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9E9E9E),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _esusuPrimaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0),
          ),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : const Color(0xFFFAFAFA),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? _formatDate(value) : label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: enabled
                    ? (value != null ? Colors.black : const Color(0xFF606060))
                    : const Color(0xFF9E9E9E),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: enabled ? const Color(0xFF606060) : const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(EsusuCreationState state) {
    final schedule = _generatePayoutSchedule(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: _esusuPrimaryColor, width: 3),
        ),
      ),
      child: Column(
        children: [
          // Total Amount per cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount per cycle:',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                currencyFormat.format(state.totalPool),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _esusuPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Commission
          if (state.takeCommission && state.commissionPercentage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commission (${state.commissionPercentage}%)',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF606060),
                  ),
                ),
                Text(
                  currencyFormat.format(state.commission),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Platform fees
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform fees (1.5%)',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF606060),
                ),
              ),
              Text(
                currencyFormat.format(state.platformFee),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Payout',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                currencyFormat.format(state.netPayout),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _esusuPrimaryColor,
                ),
              ),
            ],
          ),

          // Payout Schedule (only if we have all data)
          if (schedule.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Payout Schedule header
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPayoutScheduleExpanded = !_isPayoutScheduleExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payout Schedule (${_frequencyToString(state.frequency)})',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    _isPayoutScheduleExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black,
                  ),
                ],
              ),
            ),

            // Payout Schedule list
            if (_isPayoutScheduleExpanded) ...[
              const SizedBox(height: 12),
              ...schedule.take(5).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['cycle']!,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF606060),
                          ),
                        ),
                        Text(
                          item['date']!,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (schedule.length > 5)
                Text(
                  '+ ${schedule.length - 5} more cycles',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF606060),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
