import 'package:json_annotation/json_annotation.dart';

/// Parses required ints from flexible JSON representations.
class RequiredIntConverter implements JsonConverter<int, Object?> {
  /// Creates a converter for required integer fields.
  const RequiredIntConverter();

  @override
  int fromJson(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw const FormatException('Invalid integer payload.');
  }

  @override
  Object? toJson(int value) => value;
}

/// Parses nullable ints from flexible JSON representations.
class NullableIntConverter implements JsonConverter<int?, Object?> {
  /// Creates a converter for optional integer fields.
  const NullableIntConverter();

  @override
  int? fromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  Object? toJson(int? value) => value;
}

/// Parses non-empty strings, defaulting to "Unknown Set" when missing.
class NonEmptyStringOrUnknownSetFallbackConverter
    implements JsonConverter<String, Object?> {
  /// Creates a converter with an "Unknown Set" fallback.
  const NonEmptyStringOrUnknownSetFallbackConverter();

  @override
  String fromJson(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return 'Unknown Set';
  }

  @override
  Object? toJson(String value) => value;
}

/// Parses non-empty strings, defaulting to an empty string when missing.
class NonEmptyStringOrEmptyFallbackConverter
    implements JsonConverter<String, Object?> {
  /// Creates a converter with an empty-string fallback.
  const NonEmptyStringOrEmptyFallbackConverter();

  @override
  String fromJson(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return '';
  }

  @override
  Object? toJson(String value) => value;
}

/// Parses optional non-empty strings, defaulting to null when missing.
class NonEmptyStringOrNullConverter implements JsonConverter<String?, Object?> {
  /// Creates a converter with a null fallback.
  const NonEmptyStringOrNullConverter();

  @override
  String? fromJson(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  @override
  Object? toJson(String? value) => value;
}

/// Parses ints from number/string values and defaults to zero when invalid.
class FlexibleIntConverter implements JsonConverter<int, Object?> {
  /// Creates a converter with a zero fallback.
  const FlexibleIntConverter();

  @override
  int fromJson(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  Object? toJson(int value) => value;
}
