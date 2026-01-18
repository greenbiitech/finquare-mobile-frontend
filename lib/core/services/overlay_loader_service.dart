import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

/// State for loading overlay
class LoadingState {
  final bool isLoading;
  final String? message;

  const LoadingState({
    this.isLoading = false,
    this.message,
  });

  LoadingState copyWith({bool? isLoading, String? message}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

/// Loading state notifier
class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(const LoadingState());

  void show([String? message]) {
    state = LoadingState(isLoading: true, message: message);
  }

  void hide() {
    state = const LoadingState(isLoading: false);
  }

  void updateMessage(String message) {
    if (state.isLoading) {
      state = state.copyWith(message: message);
    }
  }
}

/// Provider for loading state
final loadingProvider = StateNotifierProvider<LoadingNotifier, LoadingState>(
  (ref) => LoadingNotifier(),
);

/// Overlay loader widget that wraps the app
class OverlayLoaderWrapper extends ConsumerWidget {
  final Widget child;

  const OverlayLoaderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingProvider);

    return Stack(
      children: [
        child,
        if (loadingState.isLoading) const _LoadingOverlay(),
      ],
    );
  }
}

/// The actual loading overlay
class _LoadingOverlay extends ConsumerWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                if (loadingState.message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    loadingState.message!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension for easy loading control
extension LoadingExtension on WidgetRef {
  void showLoading([String? message]) {
    read(loadingProvider.notifier).show(message);
  }

  void hideLoading() {
    read(loadingProvider.notifier).hide();
  }

  void updateLoadingMessage(String message) {
    read(loadingProvider.notifier).updateMessage(message);
  }
}

/// Utility class for showing loading in non-widget contexts
class OverlayLoader {
  static WidgetRef? _ref;

  static void init(WidgetRef ref) {
    _ref = ref;
  }

  static void show([String? message]) {
    _ref?.read(loadingProvider.notifier).show(message);
  }

  static void hide() {
    _ref?.read(loadingProvider.notifier).hide();
  }

  static void updateMessage(String message) {
    _ref?.read(loadingProvider.notifier).updateMessage(message);
  }

  /// Execute a future with loading overlay
  static Future<T> wrap<T>(
    Future<T> Function() future, {
    String? loadingMessage,
  }) async {
    show(loadingMessage);
    try {
      return await future();
    } finally {
      hide();
    }
  }
}
