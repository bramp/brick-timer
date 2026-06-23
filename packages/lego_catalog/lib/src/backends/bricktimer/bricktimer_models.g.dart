// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bricktimer_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickTimerLegoSetSummary _$BrickTimerLegoSetSummaryFromJson(
  Map<String, dynamic> json,
) => BrickTimerLegoSetSummary(
  setNumber: const NonEmptyStringOrEmptyFallbackConverter().fromJson(
    json['setNumber'],
  ),
  name: const NonEmptyStringOrUnknownSetFallbackConverter().fromJson(
    json['name'],
  ),
  totalPieces: const FlexibleIntConverter().fromJson(json['totalPieces']),
  imageUrl: const NonEmptyStringOrNullConverter().fromJson(json['imageUrl']),
);

BrickTimerLegoSetDetails _$BrickTimerLegoSetDetailsFromJson(
  Map<String, dynamic> json,
) => BrickTimerLegoSetDetails(
  setNumber: const NonEmptyStringOrEmptyFallbackConverter().fromJson(
    json['setNumber'],
  ),
  name: const NonEmptyStringOrUnknownSetFallbackConverter().fromJson(
    json['name'],
  ),
  totalPieces: const FlexibleIntConverter().fromJson(json['totalPieces']),
  imageUrl: const NonEmptyStringOrNullConverter().fromJson(json['imageUrl']),
);
