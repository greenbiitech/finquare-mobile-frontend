import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,
    required this.isButtonEnabled,
    required this.onPressed,
    this.buttonColor,
    this.height,
    this.width,
    required this.title,
    this.margin,
    this.titleColor,
    this.titleIsWidget = false,
    this.titleWidget,
    this.fontSize = 18,
    this.border,
    this.fontWeight,
    this.loading = false,
    this.loadingIndicatorColor,
  });

  final bool isButtonEnabled;
  final bool loading;
  final double? height;
  final double? width;
  final Color? buttonColor;
  final void Function()? onPressed;
  final String title;
  final EdgeInsetsGeometry? margin;
  final Color? titleColor;
  final bool? titleIsWidget;
  final Widget? titleWidget;
  final BorderSide? border;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? loadingIndicatorColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height ?? 48,
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled
              ? (buttonColor ?? AppColors.primary)
              : Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: border ?? const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(43),
          ),
        ),
        onPressed: isButtonEnabled ? onPressed : null,
        child: loading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loadingIndicatorColor ?? titleColor ?? Colors.white,
                  ),
                ),
              )
            : titleIsWidget != null && titleIsWidget == true
                ? titleWidget
                : Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: fontSize,
                      color: titleColor ?? Colors.white,
                      fontWeight: fontWeight ?? FontWeight.w600,
                    ),
                  ),
      ),
    );
  }
}
