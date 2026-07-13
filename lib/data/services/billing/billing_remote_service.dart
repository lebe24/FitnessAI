import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The user's subscription row from the backend `user_subscriptions` table
/// (written by the RevenueCat webhook — see GET /api/v1/billing/subscription).
class UserSubscription {
  final String plan;
  final String status; // active | cancelled | expired
  final String? store;
  final double? amountPaid;
  final String? currency;
  final DateTime? subscribedAt;
  final DateTime? expiresAt;

  const UserSubscription({
    required this.plan,
    required this.status,
    this.store,
    this.amountPaid,
    this.currency,
    this.subscribedAt,
    this.expiresAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      plan: json['plan'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'active',
      store: json['store'] as String?,
      amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      subscribedAt: DateTime.tryParse(json['subscribed_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    );
  }

  bool get isYearly => plan.contains('yearly') || plan.contains('annual');

  String get planLabel => isYearly ? 'Premium · Yearly' : 'Premium · Monthly';

  String get amountLabel {
    if (amountPaid == null) return '';
    final cur = currency ?? '';
    return '$cur ${amountPaid!.toStringAsFixed(2)}'.trim();
  }
}

/// Reads billing data from the backend (the webhook-fed source of truth).
class BillingRemoteService {
  late final Dio _dio;

  BillingRemoteService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
  }

  /// Latest subscription row, or null when the user never subscribed
  /// (or the request fails — billing UI treats both as "no details").
  Future<UserSubscription?> getSubscription() async {
    try {
      final res = await _dio.get('api/v1/billing/subscription');
      final data = res.data;
      if (data == null || data is! Map<String, dynamic>) return null;
      return UserSubscription.fromJson(data);
    } catch (e) {
      debugPrint('BillingRemoteService.getSubscription failed: $e');
      return null;
    }
  }
}
