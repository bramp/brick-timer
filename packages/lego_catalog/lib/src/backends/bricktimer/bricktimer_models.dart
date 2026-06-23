import 'package:json_annotation/json_annotation.dart';
import 'package:lego_catalog/src/json/catalog_json_converters.dart';
import 'package:lego_catalog/src/models/lego_set.dart';

part 'bricktimer_models.g.dart';

/// Wire model for the Brick Timer catalog search response.
@JsonSerializable(createToJson: false)
class BrickTimerLegoSetSummary {
  /// Creates a Brick Timer set summary DTO.
  const BrickTimerLegoSetSummary({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  /// Parses a set summary from the Brick Timer backend payload.
  factory BrickTimerLegoSetSummary.fromJson(Map<String, dynamic> json) =>
      _$BrickTimerLegoSetSummaryFromJson(json);

  /// Canonical set identifier (for example, `10316-1`).
  @NonEmptyStringOrEmptyFallbackConverter()
  final String setNumber;

  /// Human-readable set name.
  @NonEmptyStringOrUnknownSetFallbackConverter()
  final String name;

  /// Total number of pieces in the set.
  @FlexibleIntConverter()
  final int totalPieces;

  /// Optional image URL for the set.
  @NonEmptyStringOrNullConverter()
  final String? imageUrl;

  /// Converts the Brick Timer DTO into the shared catalog model.
  LegoSetSummary toDomain() {
    return LegoSetSummary(
      setNumber: setNumber,
      name: name,
      totalPieces: totalPieces,
      imageUrl: imageUrl,
    );
  }
}

/// Wire model for the Brick Timer catalog details response.
@JsonSerializable(createToJson: false)
class BrickTimerLegoSetDetails {
  /// Creates a Brick Timer set details DTO.
  const BrickTimerLegoSetDetails({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  /// Parses set details from the Brick Timer backend payload.
  factory BrickTimerLegoSetDetails.fromJson(Map<String, dynamic> json) =>
      _$BrickTimerLegoSetDetailsFromJson(json);

  /// Canonical set identifier (for example, `10316-1`).
  @NonEmptyStringOrEmptyFallbackConverter()
  final String setNumber;

  /// Human-readable set name.
  @NonEmptyStringOrUnknownSetFallbackConverter()
  final String name;

  /// Total number of pieces in the set.
  @FlexibleIntConverter()
  final int totalPieces;

  /// Optional image URL for the set.
  @NonEmptyStringOrNullConverter()
  final String? imageUrl;

  /// Converts the Brick Timer DTO into the shared catalog model.
  LegoSetDetails toDomain() {
    return LegoSetDetails(
      setNumber: setNumber,
      name: name,
      totalPieces: totalPieces,
      imageUrl: imageUrl,
    );
  }
}
