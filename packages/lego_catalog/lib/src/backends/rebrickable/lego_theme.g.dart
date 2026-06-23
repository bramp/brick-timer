// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lego_theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegoTheme _$LegoThemeFromJson(Map<String, dynamic> json) => LegoTheme(
  id: const RequiredIntConverter().fromJson(json['id']),
  parentId: const NullableIntConverter().fromJson(json['parent_id']),
  name: json['name'] as String,
);

Map<String, dynamic> _$LegoThemeToJson(LegoTheme instance) => <String, dynamic>{
  'id': const RequiredIntConverter().toJson(instance.id),
  'parent_id': const NullableIntConverter().toJson(instance.parentId),
  'name': instance.name,
};
