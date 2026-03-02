// lib/admin/admin_hidden_entry.dart
import 'package:flutter/material.dart';

/// A tiny wrapper used in the UI to optionally enable a hidden admin entry.
///
/// In your project, some screens wrap a widget with [AdminHiddenEntry].
/// If you want to add real admin access later (long-press, PIN, etc.),
/// you can extend this file without touching the rest of the UI.
class AdminHiddenEntry extends StatelessWidget {
  final Widget child;

  /// Optional callback if you want to handle a hidden admin action.
  final VoidCallback? onActivate;

  /// If true, enables a long-press gesture to trigger [onActivate].
  final bool enableLongPress;

  /// Duration for long-press activation (defaults to 2 seconds).
  final Duration activationDelay;

  const AdminHiddenEntry({
    super.key,
    required this.child,
    this.onActivate,
    this.enableLongPress = false,
    this.activationDelay = const Duration(seconds: 2),
  });

  @override
  Widget build(BuildContext context) {
    if (!enableLongPress || onActivate == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) async {
        // Wait for [activationDelay], and if still mounted, activate.
        // (This is a simple implementation; refine if you need cancel logic.)
        await Future.delayed(activationDelay);
        onActivate?.call();
      },
      child: child,
    );
  }
}
