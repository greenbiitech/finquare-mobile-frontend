import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

/// Select Verification Method Page
///
/// Second step in wallet setup flow.
/// User selects how they want to receive the OTP verification code.
/// No API call here - just navigation to Verify BVN Credentials.
class SelectVerificationMethodPage extends ConsumerStatefulWidget {
  const SelectVerificationMethodPage({
    super.key,
    required this.sessionId,
    required this.methods,
  });

  final String sessionId;
  final List<BvnMethodOption> methods;

  @override
  ConsumerState<SelectVerificationMethodPage> createState() =>
      _SelectVerificationMethodPageState();
}

class _SelectVerificationMethodPageState
    extends ConsumerState<SelectVerificationMethodPage> {
  int _selectedIndex = 0;

  void _onContinue() {
    if (widget.methods.isEmpty) return;

    final selectedMethod = widget.methods[_selectedIndex];

    // Navigate to Verify BVN Credentials with session data
    // Pass only the method string (e.g. 'phone' or 'email'), not the whole object
    context.push(
      AppRoutes.verifyBvnCredentials,
      extra: {
        'sessionId': widget.sessionId,
        'method': selectedMethod.method,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const AppBackButton(),
                const SizedBox(height: 22),
                SvgPicture.asset('assets/svgs/pagination_dots.svg'),
                const SizedBox(height: 15),
                Text(
                  'Select Verification Method',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose the destination for sending the verification code.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF606060),
                  ),
                ),
                const SizedBox(height: 30),

                // Radio Options
                if (widget.methods.isEmpty)
                  Text(
                    'No verification methods available.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  )
                else
                  ...List.generate(widget.methods.length, (index) {
                    final method = widget.methods[index];
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 1.11,
                                child: Radio<int>(
                                  value: index,
                                  groupValue: _selectedIndex,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedIndex = value!;
                                    });
                                  },
                                  fillColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                          (states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary;
                                    }
                                    return const Color(0xFF49454F);
                                  }),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  method.hint,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _mainTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.methods.isNotEmpty
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: widget.methods.isNotEmpty ? _onContinue : null,
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.methods.isNotEmpty
                    ? Colors.white
                    : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
