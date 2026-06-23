import 'package:json_annotation/json_annotation.dart';
import 'package:lego_catalog/src/json/catalog_json_converters.dart';

part 'lego_theme.g.dart';

/// Typed LEGO theme payload.
@JsonSerializable(fieldRename: FieldRename.snake)
class LegoTheme {
  /// Creates a typed LEGO theme model.
  const LegoTheme({
    required this.id,
    required this.parentId,
    required this.name,
  });

  /// Parses a theme model from a Rebrickable JSON object.
  factory LegoTheme.fromJson(Map<String, dynamic> json) =>
      _$LegoThemeFromJson(json);

  /// Rebrickable theme ID.
  @RequiredIntConverter()
  final int id;

  /// Parent theme ID, or null for root themes.
  @NullableIntConverter()
  final int? parentId;

  /// Human-readable theme name.
  final String name;

  /// Serializes this model to JSON.
  Map<String, dynamic> toJson() => _$LegoThemeToJson(this);
}
