import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fitness/domain/models/friendly_error.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

DioException _dio(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response(requestOptions: RequestOptions(path: '/x'),
              statusCode: status),
    );

void main() {
  group('connectivity', () {
    test('a socket failure reads as being offline', () {
      expect(FriendlyError.from(const SocketException('failed host lookup')),
          FriendlyError.offline);
    });

    test('dio connection errors read as being offline', () {
      expect(FriendlyError.from(_dio(DioExceptionType.connectionError)),
          FriendlyError.offline);
    });

    test('every timeout flavour reads as slow, not broken', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(FriendlyError.from(_dio(t)), FriendlyError.slow, reason: '$t');
      }
      expect(FriendlyError.from(TimeoutException('x')), FriendlyError.slow);
    });
  });

  group('http status', () {
    test('5xx blames us, not the user', () {
      expect(
          FriendlyError.from(_dio(DioExceptionType.badResponse, status: 500)),
          FriendlyError.serverDown);
      expect(
          FriendlyError.from(_dio(DioExceptionType.badResponse, status: 503)),
          FriendlyError.serverDown);
    });

    test('429 asks the user to wait rather than retry immediately', () {
      expect(
          FriendlyError.from(_dio(DioExceptionType.badResponse, status: 429)),
          FriendlyError.tooManyAttempts);
    });

    test('a 4xx falls back to the caller-supplied wording', () {
      expect(
        FriendlyError.from(_dio(DioExceptionType.badResponse, status: 404),
            fallback: FriendlyError.planFailed),
        FriendlyError.planFailed,
      );
    });
  });

  group('auth', () {
    test('a duplicate email points at signing in instead', () {
      final e = FriendlyError.from(
          AuthException('User already registered'));
      expect(e, FriendlyError.emailTaken);
      // Retrying the same thing cannot help, so the UI must not offer it.
      expect(e.canRetry, isFalse);
    });

    test('bad credentials do not leak which field was wrong', () {
      final e = FriendlyError.from(AuthException('Invalid login credentials'));
      expect(e, FriendlyError.wrongCredentials);
      expect(e.message.toLowerCase(), isNot(contains('password is')));
    });

    test('an unconfirmed email explains the next step', () {
      expect(FriendlyError.from(AuthException('Email not confirmed')),
          FriendlyError.emailNotConfirmed);
    });

    test('an unrecognised auth failure still lands somewhere sensible', () {
      expect(FriendlyError.from(AuthException('some new supabase wording')),
          FriendlyError.signInFailed);
    });
  });

  group('cancellation', () {
    test('backing out of the sign-in sheet is silent, not an error', () {
      final e = FriendlyError.from(
          PlatformException(code: 'sign_in_canceled'));
      expect(e, FriendlyError.signInCancelled);
      expect(e.silent, isTrue,
          reason: 'showing a red banner would scold the user for '
              'changing their mind');
    });
  });

  group('no technical detail escapes', () {
    test('the raw exception never appears in what the user reads', () {
      const raw =
          'DioException [connection timeout]: Failed host lookup: api.internal '
          'at package:dio/src/dio_mixin.dart:548';
      final e = FriendlyError.from(_dio(DioExceptionType.connectionTimeout));

      expect(e.message, isNot(contains('DioException')));
      expect(e.message, isNot(contains('package:')));
      expect(e.message, isNot(contains(raw)));
      expect(e.title, isNotEmpty);
      expect(e.message, isNotEmpty);
    });

    test('an unknown object is absorbed rather than stringified', () {
      final e = FriendlyError.from(Object());
      expect(e, FriendlyError.unknown);
      expect(e.message, isNot(contains('Instance of')));
    });

    test('a fallback overrides the generic wording for unknown errors', () {
      expect(FriendlyError.from(Object(), fallback: FriendlyError.planFailed),
          FriendlyError.planFailed);
    });
  });
}
