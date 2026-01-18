import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

/// Animated balance text widget that smoothly transitions between values
///
/// Features:
/// - Animates from old value to new value
/// - Supports first load animation (0.00 → actual balance)
/// - Configurable animation duration
/// - Supports subscript decimals styling
class AnimatedBalanceText extends StatefulWidget {
  const AnimatedBalanceText({
    super.key,
    required this.balance,
    this.isFirstLoad = false,
    this.duration,
    this.style,
    this.prefix = '\u20A6',
    this.showSubscriptDecimals = true,
    this.subscriptFontSizeRatio = 0.6,
  });

  /// The balance value to display (e.g., "1234.56")
  final String balance;

  /// Whether this is the first load (triggers slower animation)
  final bool isFirstLoad;

  /// Animation duration (defaults based on isFirstLoad)
  final Duration? duration;

  /// Text style for the main balance
  final TextStyle? style;

  /// Currency prefix (default: ₦)
  final String prefix;

  /// Whether to show decimals as subscript
  final bool showSubscriptDecimals;

  /// Ratio for subscript font size (default: 0.6)
  final double subscriptFontSizeRatio;

  @override
  State<AnimatedBalanceText> createState() => _AnimatedBalanceTextState();
}

class _AnimatedBalanceTextState extends State<AnimatedBalanceText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _previousValue = 0.0;
  double _currentValue = 0.0;

  /// Tracks whether we've ever shown a real (non-zero) balance
  /// This is used to determine animation duration independently of widget.isFirstLoad
  bool _hasAnimatedFirstValue = false;

  @override
  void initState() {
    super.initState();

    _currentValue = _parseBalance(widget.balance);

    // If we're starting with a real balance and it's marked as first load,
    // we should animate from 0
    if (widget.isFirstLoad && _currentValue > 0) {
      _previousValue = 0.0;
    } else {
      _previousValue = _currentValue;
      // If we're starting with a real balance (not first load), we've already "shown" it
      if (_currentValue > 0) {
        _hasAnimatedFirstValue = true;
      }
    }

    _controller = AnimationController(
      vsync: this,
      duration: _getAnimationDuration(isFirstAnimation: widget.isFirstLoad),
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: _currentValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation if first load and we have a real value
    if (widget.isFirstLoad && _currentValue > 0) {
      _controller.forward();
      _hasAnimatedFirstValue = true;
    }
  }

  /// Get animation duration
  /// Uses longer duration for first-time animation (0 → real value)
  Duration _getAnimationDuration({required bool isFirstAnimation}) {
    if (widget.duration != null) return widget.duration!;
    return isFirstAnimation
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 400);
  }

  double _parseBalance(String balance) {
    try {
      // Remove any formatting (commas, spaces)
      final cleaned = balance.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedBalanceText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = _parseBalance(widget.balance);

    if (newValue != _currentValue) {
      _previousValue = _currentValue;
      _currentValue = newValue;

      // Determine if this is the first time showing a real balance
      // This happens when going from 0 to a real value and we haven't animated before
      final isFirstRealBalance = !_hasAnimatedFirstValue &&
                                  _previousValue < 0.01 &&
                                  _currentValue > 0;

      _animation = Tween<double>(
        begin: _previousValue,
        end: _currentValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.duration = _getAnimationDuration(isFirstAnimation: isFirstRealBalance);
      _controller.forward(from: 0);

      // Mark that we've animated to a real value
      if (_currentValue > 0) {
        _hasAnimatedFirstValue = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    // Format with commas and 2 decimal places
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$whole.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontWeight: FontWeight.w800,
      fontSize: 28,
      color: Colors.black,
    );

    final effectiveStyle = widget.style ?? defaultStyle;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final formatted = _formatNumber(_animation.value);

        if (!widget.showSubscriptDecimals) {
          return Text(
            '${widget.prefix}$formatted',
            style: effectiveStyle,
          );
        }

        // Split into whole and decimal parts
        final parts = formatted.split('.');
        final whole = parts[0];
        final decimal = parts.length > 1 ? '.${parts[1]}' : '';

        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.prefix}$whole',
                style: effectiveStyle,
              ),
              if (decimal.isNotEmpty)
                WidgetSpan(
                  alignment: PlaceholderAlignment.bottom,
                  child: Transform.translate(
                    offset: const Offset(0, 2),
                    child: Text(
                      decimal,
                      style: effectiveStyle.copyWith(
                        fontSize: effectiveStyle.fontSize! * widget.subscriptFontSizeRatio,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Simple balance text without animation (for static displays)
class BalanceText extends StatelessWidget {
  const BalanceText({
    super.key,
    required this.balance,
    this.style,
    this.prefix = '\u20A6',
    this.showSubscriptDecimals = true,
    this.subscriptFontSizeRatio = 0.6,
  });

  final String balance;
  final TextStyle? style;
  final String prefix;
  final bool showSubscriptDecimals;
  final double subscriptFontSizeRatio;

  String _formatBalance(String balance) {
    try {
      final cleaned = balance.replaceAll(RegExp(r'[^\d.]'), '');
      final value = double.tryParse(cleaned) ?? 0.0;
      final parts = value.toStringAsFixed(2).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '$whole.${parts[1]}';
    } catch (e) {
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontWeight: FontWeight.w800,
      fontSize: 28,
      color: Colors.black,
    );

    final effectiveStyle = style ?? defaultStyle;
    final formatted = _formatBalance(balance);

    if (!showSubscriptDecimals) {
      return Text(
        '$prefix$formatted',
        style: effectiveStyle,
      );
    }

    final parts = formatted.split('.');
    final whole = parts[0];
    final decimal = parts.length > 1 ? '.${parts[1]}' : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$prefix$whole',
            style: effectiveStyle,
          ),
          if (decimal.isNotEmpty)
            WidgetSpan(
              alignment: PlaceholderAlignment.bottom,
              child: Transform.translate(
                offset: const Offset(0, 2),
                child: Text(
                  decimal,
                  style: effectiveStyle.copyWith(
                    fontSize: effectiveStyle.fontSize! * subscriptFontSizeRatio,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
