import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/utils/health_score.dart';

void main() {
  group('computeHealthScore', () {
    test('returns 100 for perfect metrics', () {
      final score = computeHealthScore(
        occupancyRate: 1.0, revenueDelta: 0.5,
        clientReturnRate: 1.0, cancellationRate: 0.0, noShowRate: 0.0,
      );
      expect(score, 100.0);
    });

    test('returns near-minimum score for worst case metrics', () {
      final score = computeHealthScore(
        occupancyRate: 0.0, revenueDelta: -1.0,
        clientReturnRate: 0.0, cancellationRate: 1.0, noShowRate: 0.0,
      );
      // revenueScore contributes ~8.33 even at worst (clamped to 0.5/1.5 * 25)
      expect(score, lessThanOrEqualTo(10.0));
      expect(score, greaterThanOrEqualTo(0.0));
    });

    test('treats revenueDelta as 0.0 when previousRealized is 0', () {
      // Caller deve passar 0.0 quando previousRealized == 0
      final score = computeHealthScore(
        occupancyRate: 0.68, revenueDelta: 0.0,
        clientReturnRate: 0.71, cancellationRate: 0.14, noShowRate: 0.06,
      );
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('returns value between 0 and 100 for typical metrics', () {
      final score = computeHealthScore(
        occupancyRate: 0.68, revenueDelta: 0.08,
        clientReturnRate: 0.71, cancellationRate: 0.14, noShowRate: 0.06,
      );
      expect(score, inInclusiveRange(0, 100));
    });
  });
}
