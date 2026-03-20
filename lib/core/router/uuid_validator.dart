/// Pure UUID validation utility — safe to use in route guards.
///
/// Validates the standard 8-4-4-4-12 hex format (case-insensitive).
/// Returns `false` for empty strings, path-traversal attempts, and any
/// value that does not match the expected pattern.
bool isValidUuid(String id) {
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(id);
}
