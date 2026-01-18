import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/dues/data/models/due_creation_data.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _mainTextColor = Color(0xFF333333);

class ConfigureDuesPage extends StatefulWidget {
  final DueCreationData? dueData;

  const ConfigureDuesPage({super.key, this.dueData});

  @override
  State<ConfigureDuesPage> createState() => _ConfigureDuesPageState();
}

class _ConfigureDuesPageState extends State<ConfigureDuesPage> {
  final TextEditingController _amountController = TextEditingController();
  String _frequency = 'Every week';
  String _deduction = 'Disabled';
  String _reminder = 'Enabled';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _amountError;

  late DueCreationData _dueData;

  // Frequency options
  static const List<String> _frequencyOptions = [
    'Only once',
    'Every week',
    'Every month',
    'Quarterly',
    'Bi-Annually',
    'Yearly',
  ];

  // Amount validation constants
  static const int minAmount = 100;
  static const int maxAmount = 100000000;

  @override
  void initState() {
    super.initState();
    _dueData = widget.dueData ?? DueCreationData();
    _amountController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validateForm() {
    if (mounted) {
      setState(() {
        _validateAmount();
      });
    }
  }

  void _validateAmount() {
    final text = _amountController.text.trim();

    if (text.isEmpty) {
      _amountError = null;
      return;
    }

    final amount = int.tryParse(text);

    if (amount == null) {
      _amountError = 'Please enter a valid number';
    } else if (amount < minAmount) {
      _amountError =
          'Minimum amount is NGN ${minAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else if (amount > maxAmount) {
      _amountError =
          'Maximum amount is NGN ${maxAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else {
      _amountError = null;
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _validateForm();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _validateForm();
    }
  }

  bool _isFormValid() {
    return _amountController.text.trim().isNotEmpty &&
        _amountError == null &&
        _startDate != null;
  }

  int _calculatePaymentPeriods() {
    if (_startDate == null) return 0;
    if (_frequency == 'Only once') return 1;
    if (_endDate == null) return -1;

    final start = _startDate!;
    final end = _endDate!;

    switch (_frequency) {
      case 'Every week':
        return ((end.difference(start).inDays) / 7).ceil() + 1;
      case 'Every month':
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        return months + 1;
      case 'Quarterly':
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        return (months / 3).ceil() + 1;
      case 'Bi-Annually':
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        return (months / 6).ceil() + 1;
      case 'Yearly':
        return (end.year - start.year) + 1;
      default:
        return 0;
    }
  }

  List<DateTime> _generateDueDates() {
    if (_startDate == null) return [];

    List<DateTime> dates = [_startDate!];

    if (_frequency == 'Only once' || _endDate == null) {
      return dates;
    }

    DateTime currentDate = _startDate!;
    final endDate = _endDate!;

    while (currentDate.isBefore(endDate)) {
      DateTime? nextDate;

      switch (_frequency) {
        case 'Every week':
          nextDate =
              DateTime(currentDate.year, currentDate.month, currentDate.day + 7);
          break;
        case 'Every month':
          nextDate =
              DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case 'Quarterly':
          nextDate =
              DateTime(currentDate.year, currentDate.month + 3, currentDate.day);
          break;
        case 'Bi-Annually':
          nextDate =
              DateTime(currentDate.year, currentDate.month + 6, currentDate.day);
          break;
        case 'Yearly':
          nextDate =
              DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
          break;
        default:
          break;
      }

      if (nextDate == null || nextDate.isAfter(endDate)) break;

      dates.add(nextDate);
      currentDate = nextDate;
    }

    return dates;
  }

  double _calculateTotalAmount() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final periods = _calculatePaymentPeriods();

    if (periods == -1) {
      return 0;
    }

    return amount * periods;
  }

  Future<void> _showBottomSheet(
      String title, List<String> options, Function(String) onSelect) async {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(
                option,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),
              onTap: () {
                onSelect(option);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'e.g 5000',
                        labelText: 'Due Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    if (_amountError != null)
                      Padding(
                        padding: EdgeInsets.only(left: 15, top: 4),
                        child: Text(
                          _amountError!,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: 15, top: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Total due each member has to pay (Min: NGN 100, Max: NGN 100,000,000)",
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF424940),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// Frequency Dropdown
                _buildDropdown(
                  title: "Frequency",
                  value: _frequency,
                  options: _frequencyOptions,
                  onSelected: (val) => setState(() {
                    _frequency = val;
                    if (val == 'Only once') {
                      _endDate = null;
                    }
                  }),
                ),

                /// Start Date Picker
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    height: 56,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF717970)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _startDate == null
                                ? "Start date"
                                : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.calendar_month_outlined),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15, top: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Subsequent due dates will be calculated automatically.",
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF424940),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// End Date Picker (Optional) - Hidden for "Only once" frequency
                if (_frequency != 'Only once') ...[
                  GestureDetector(
                    onTap: _selectEndDate,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF717970)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _endDate == null
                                  ? "End date (Optional)"
                                  : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(Icons.calendar_month_outlined),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15, top: 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Leave empty for indefinite dues.",
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF424940),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                /// Automatic Deductions Dropdown
                _buildDropdown(
                  title: "Automatic deductions",
                  value: _deduction,
                  options: ['Enabled', 'Disabled'],
                  onSelected: (val) => setState(() => _deduction = val),
                ),

                /// Automatic Reminders Dropdown
                _buildDropdown(
                  title: "Automatic reminders",
                  value: _reminder,
                  options: ['Enabled', 'Disabled'],
                  onSelected: (val) => setState(() => _reminder = val),
                ),

                /// Payment Summary Preview
                if (_startDate != null &&
                    _amountController.text.trim().isNotEmpty &&
                    _amountError == null) ...[
                  const SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Color(0xFF21A8FB).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Payment Periods:',
                          _calculatePaymentPeriods() == -1
                              ? 'Indefinite'
                              : '${_calculatePaymentPeriods()} ${_calculatePaymentPeriods() == 1 ? 'payment' : 'payments'}',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Amount per payment:',
                          'NGN ${int.parse(_amountController.text.trim()).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        ),
                        if (_calculatePaymentPeriods() > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Total per member:',
                            'NGN ${_calculateTotalAmount().toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            isHighlighted: true,
                          ),
                        ],
                        if (_generateDueDates().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Due Dates:',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424940),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_generateDueDates().take(5).map((date) => Padding(
                                padding: EdgeInsets.only(bottom: 4, left: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Color(0xFF21A8FB)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
                                        color: Color(0xFF424940),
                                      ),
                                    ),
                                  ],
                                ),
                              ))),
                          if (_generateDueDates().length > 5)
                            Padding(
                              padding: EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                '... and ${_generateDueDates().length - 5} more',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF717970),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: DefaultButton(
          isButtonEnabled: _isFormValid(),
          onPressed: _isFormValid()
              ? () {
                  // Create complete due data
                  final completeDueData = _dueData.copyWith(
                    amount: double.parse(_amountController.text.trim()),
                    frequency: _frequency,
                    startDate: _startDate,
                    endDate: _endDate,
                    automaticDeduction: _deduction == 'Enabled',
                    automaticReminder: _reminder == 'Enabled',
                  );

                  // Navigate to success screen
                  context.push(AppRoutes.duesSuccess, extra: completeDueData);
                }
              : null,
          title: 'Create Due',
          height: 54,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          buttonColor: Color(0xFF21A8FB),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            color: Color(0xFF595959),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showBottomSheet(title, options, onSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _greyBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF595959),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF424940),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? Color(0xFF21A8FB) : Colors.black,
          ),
        ),
      ],
    );
  }
}
