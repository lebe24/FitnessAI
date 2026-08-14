import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// A failure, phrased for the person looking at the screen.
///
/// The technical detail does not belong in the UI — it goes to `error_logs`
/// (see ErrorLogService). What the user gets is a sentence describing what
/// happened and what they can do about it.
class FriendlyError {
  /// Short headline, e.g. "You're offline".
  final String title;

  /// One or two sentences: what happened, then the way out.
  final String message;

  /// Whether retrying the same action could plausibly work. False for things
  /// the user must change first, like an email that is already registered.
  final bool canRetry;

  /// Deliberate user choices that merely look like failures in code —
  /// backing out of the Google sign-in sheet, for instance. Nothing is shown;
  /// telling someone off for changing their mind is its own bug.
  final bool silent;

  const FriendlyError({
    required this.title,
    required this.message,
    this.canRetry = true,
    this.silent = false,
  });

  /// Single-line form for a SnackBar, which has no room for a title.
  String get short => message;

  // ── Catalogue ──────────────────────────────────────────────────────────────

  static const offline = FriendlyError(
    title: "You're offline",
    message:
        'We couldn\'t reach BeFit. Check your internet connection and try again.',
  );

  static const slow = FriendlyError(
    title: 'That took too long',
    message:
        'The connection timed out before we finished. Give it another go in a moment.',
  );

  static const serverDown = FriendlyError(
    title: 'Something went wrong on our side',
    message:
        'This one is on us, not you. Please try again shortly — we have been notified.',
  );

  static const planFailed = FriendlyError(
    title: "We couldn't build your plan",
    message:
        'Your answers are saved, so nothing is lost. Tap retry and we will pick up where we left off.',
  );

  static const signInFailed = FriendlyError(
    title: "That sign-in didn't go through",
    message: 'Please try signing in again.',
  );

  static const signInCancelled = FriendlyError(
    title: 'Sign-in cancelled',
    message: 'No problem — tap the button whenever you are ready.',
    canRetry: false,
    silent: true,
  );

  static const emailTaken = FriendlyError(
    title: 'That email is already registered',
    message: 'Try signing in instead, or use a different email address.',
    canRetry: false,
  );

  static const wrongCredentials = FriendlyError(
    title: "Those details didn't match",
    message: 'Double-check your email and password, then try again.',
  );

  static const emailNotConfirmed = FriendlyError(
    title: 'Confirm your email first',
    message:
        'We sent you a confirmation link. Open it, then come back and sign in.',
    canRetry: false,
  );

  static const tooManyAttempts = FriendlyError(
    title: 'Too many tries',
    message: 'Wait a minute or two before trying again.',
  );

  static const unknown = FriendlyError(
    title: 'Something went wrong',
    message: 'That didn\'t work as expected. Please try again.',
  );

  // ── Mapping ────────────────────────────────────────────────────────────────

  /// Translate [error] into something worth showing a user.
  ///
  /// Ordered from most specific to least. [fallback] lets a caller pick the
  /// wording for "we don't recognise this" — the plan builder wants
  /// [planFailed] rather than the generic [unknown], because it can promise
  /// the user's answers are safe.
  static FriendlyError from(Object error, {FriendlyError? fallback}) {
    // Connectivity — check before anything else, since almost any call can
    // fail this way and the advice ("check your connection") always applies.
    if (error is SocketException) return offline;
    if (error is TimeoutException) return slow;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
          return offline;
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return slow;
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          if (code == 429) return tooManyAttempts;
          if (code >= 500) return serverDown;
          return fallback ?? unknown;
        default:
          return fallback ?? unknown;
      }
    }

    if (error is AuthException) return _fromAuth(error);

    // Google Sign-In surfaces cancellation as a PlatformException rather than
    // a distinct type; treating it as a failure would scold the user for
    // changing their mind.
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('cancel') || code == 'sign_in_canceled') {
        return signInCancelled;
      }
      if (code.contains('network')) return offline;
      return fallback ?? signInFailed;
    }

    // A malformed payload is a backend problem, not something the user can fix
    // by trying differently — but a retry may still hit a healthy response.
    if (error is FormatException) return fallback ?? serverDown;

    return fallback ?? unknown;
  }

  static FriendlyError _fromAuth(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('already registered') || m.contains('already exists')) {
      return emailTaken;
    }
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return wrongCredentials;
    }
    if (m.contains('email not confirmed') || m.contains('not confirmed')) {
      return emailNotConfirmed;
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return tooManyAttempts;
    }
    if (m.contains('network') || m.contains('failed host lookup')) {
      return offline;
    }
    return signInFailed;
  }
}
