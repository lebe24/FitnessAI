import 'package:fitness/domain/models/friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One way to show a failure, so every screen reports problems identically.
///
/// Takes a [FriendlyError] rather than a String — the type is the guard rail.
/// A raw `e.toString()` cannot be passed here without first being translated,
/// which is what used to leak stack traces into the UI.
void showFriendlyError(BuildContext context, FriendlyError error) {
  // Cancellations are user choices, not failures.
  if (error.silent) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF1A1A2E),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  error.message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
