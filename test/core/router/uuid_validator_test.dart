import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/router/uuid_validator.dart';

void main() {
  group('isValidUuid', () {
    test('returns true for a valid lowercase UUID v4', () {
      expect(isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
    });

    test('returns false for a plain invalid string', () {
      expect(isValidUuid('invalid-id'), isFalse);
    });

    test('returns false for a path-traversal attack string', () {
      expect(isValidUuid('../../admin'), isFalse);
    });

    test('returns false for an empty string', () {
      expect(isValidUuid(''), isFalse);
    });

    test('returns true for a valid uppercase UUID (case insensitive)', () {
      expect(isValidUuid('550E8400-E29B-41D4-A716-446655440000'), isTrue);
    });
  });
}
