import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

/// Types of snackbar notifications
enum SnackbarType {
  success,
  error,
  warning,
  info,
}

/// Configuration for each snackbar type
class _SnackbarConfig {
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;

  const _SnackbarConfig({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
  });
}

/// Snackbar service for showing top notifications
class SnackbarService {
  SnackbarService._();
  static final SnackbarService instance = SnackbarService._();

  static const _configs = {
    SnackbarType.success: _SnackbarConfig(
      backgroundColor: Color(0xFF4CAF50),
      iconColor: Colors.white,
      icon: Icons.check_circle_outline,
    ),
    SnackbarType.error: _SnackbarConfig(
      backgroundColor: Color(0xFFE53935),
      iconColor: Colors.white,
      icon: Icons.error_outline,
    ),
    SnackbarType.warning: _SnackbarConfig(
      backgroundColor: Color(0xFFFFA726),
      iconColor: Colors.white,
      icon: Icons.warning_amber_outlined,
    ),
    SnackbarType.info: _SnackbarConfig(
      backgroundColor: Color(0xFF2196F3),
      iconColor: Colors.white,
      icon: Icons.info_outline,
    ),
  };

  /// Show a snackbar notification from top
  void show({
    required String message,
    String? title,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final config = _configs[type]!;

    showOverlayNotification(
      (context) => _TopSnackbar(
        message: message,
        title: title,
        config: config,
        onTap: onTap,
        onDismiss: () => OverlaySupportEntry.of(context)?.dismiss(),
      ),
      duration: duration,
      position: NotificationPosition.top,
    );
  }

  /// Show success notification
  void showSuccess(String message, {String? title, VoidCallback? onTap}) {
    show(
      message: message,
      title: title,
      type: SnackbarType.success,
      onTap: onTap,
    );
  }

  /// Show error notification
  void showError(String message, {String? title, VoidCallback? onTap}) {
    show(
      message: message,
      title: title,
      type: SnackbarType.error,
      onTap: onTap,
    );
  }

  /// Show warning notification
  void showWarning(String message, {String? title, VoidCallback? onTap}) {
    show(
      message: message,
      title: title,
      type: SnackbarType.warning,
      onTap: onTap,
    );
  }

  /// Show info notification
  void showInfo(String message, {String? title, VoidCallback? onTap}) {
    show(
      message: message,
      title: title,
      type: SnackbarType.info,
      onTap: onTap,
    );
  }
}

/// The actual snackbar widget
class _TopSnackbar extends StatelessWidget {
  final String message;
  final String? title;
  final _SnackbarConfig config;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _TopSnackbar({
    required this.message,
    this.title,
    required this.config,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            onTap?.call();
            onDismiss?.call();
          },
          onHorizontalDragEnd: (_) => onDismiss?.call(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: config.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: config.backgroundColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null) ...[
                          Text(
                            title!,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          message,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: title != null ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: title != null ? 0.9 : 1.0),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Global snackbar functions for easy access
void showSuccessSnackbar(String message, {String? title}) {
  SnackbarService.instance.showSuccess(message, title: title);
}

void showErrorSnackbar(String message, {String? title}) {
  SnackbarService.instance.showError(message, title: title);
}

void showWarningSnackbar(String message, {String? title}) {
  SnackbarService.instance.showWarning(message, title: title);
}

void showInfoSnackbar(String message, {String? title}) {
  SnackbarService.instance.showInfo(message, title: title);
}
