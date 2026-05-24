/// Typed LEGO theme payload.
class LegoTheme {
  /// Creates a typed LEGO theme model.
  const LegoTheme({
    required this.id,
    required this.parentId,
    required this.name,
  });

  /// Parses a theme model from a Rebrickable JSON object.
  factory LegoTheme.fromJson(Map<String, Object?> json) {
    final idRaw = json['id'];
    final parentIdRaw = json['parent_id'];
    final nameRaw = json['name'];

    if (idRaw is! num || nameRaw is! String) {
      throw const FormatException('Invalid LEGO theme payload.');
    }

    return LegoTheme(
      id: idRaw.toInt(),
      parentId: parentIdRaw is num ? parentIdRaw.toInt() : null,
      name: nameRaw,
    );
  }

  /// Rebrickable theme ID.
  final int id;

  /// Parent theme ID, or null for root themes.
  final int? parentId;

  /// Human-readable theme name.
  final String name;

  /// Serializes this model to JSON.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
    };
  }
}
