/// Model representing a delivery/service region
///
/// Regions allow the app to show region-specific products, pricing,
/// delivery options, and availability. Users can select their region
/// to see relevant content.
class Region {
  final int id;
  final String code;
  final String name;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Region({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a default/fallback region
  factory Region.defaultRegion() => Region(
        id: 0,
        code: 'default',
        name: 'Default Region',
        timezone: 'UTC',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      timezone: json['timezone'] ?? 'UTC',
      isActive: json['is_active'] ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'timezone': timezone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Region && other.id == id && other.code == code;
  }

  @override
  int get hashCode => id.hashCode ^ code.hashCode;

  @override
  String toString() => 'Region(id: $id, code: $code, name: $name)';
}
