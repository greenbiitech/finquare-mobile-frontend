import 'dart:async';

import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

class CodeResendWidget extends StatefulWidget {
  final VoidCallback? onResend;

  const CodeResendWidget({
    super.key,
    this.onResend,
  });

  @override
  State<CodeResendWidget> createState() => _CodeResendWidgetState();
}

class _CodeResendWidgetState extends State<CodeResendWidget> {
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    _canResend = false;
    _start = 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void handleResend() {
    widget.onResend?.call();
    startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get timerText {
    final minutes = (_start ~/ 60).toString();
    final seconds = (_start % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Didn't get a code?",
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: Color(0xFF595959),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: _canResend ? handleResend : null,
          child: Text.rich(
            TextSpan(
              text: 'Resend Code ',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: _canResend ? FontWeight.w700 : FontWeight.w600,
                color: _canResend ? AppColors.primary : Color(0xFFC0BFC4),
              ),
              children: _canResend
                  ? null
                  : [
                      TextSpan(
                        text: '($timerText)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}
