import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/network/api_client.dart';

class BillingRepository {
  final ApiClient _client;

  BillingRepository(this._client);

  /// POST /b/:slug/billing/checkout
  /// Returns the Stripe Checkout URL.
  Future<Result<String>> createCheckout({
    required String slug,
    required String planName,
  }) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/b/$slug/billing/checkout',
      fromJson: (json) => json,
      body: {'planName': planName},
    );
    return switch (result) {
      Success(:final data) => Success(data['url'] as String),
      HttpFailure(:final failure) => HttpFailure(failure),
    };
  }

  /// DELETE /b/:slug/billing/subscription
  Future<Result<void>> cancelSubscription({required String slug}) =>
      _client.delete('/b/$slug/billing/subscription');
}
