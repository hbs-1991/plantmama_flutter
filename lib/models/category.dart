/// Category model matching API schema (ProductCategory)
class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;  // From API
  final String? icon;         // From API - category icon
  final int? sectionId;       // API uses section_id
  final int? parentId;        // API uses parent_id for hierarchical categories
  final String sectionName;   // Keep for display purposes
  final String sectionSlug;   // Derived from section or direct
  final int order;            // Maps to display_order
  final bool isActive;        // From API

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.sectionId,
    this.parentId,
    required this.sectionName,
    required this.sectionSlug,
    required this.order,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle nested section object if present
    String sectionName = '';
    String sectionSlug = '';
    int? sectionId;

    if (json['section'] is Map) {
      final section = json['section'] as Map<String, dynamic>;
      sectionName = section['name'] ?? '';
      sectionSlug = section['slug'] ?? '';
      sectionId = section['id'];
    } else {
      sectionName = json['section_name'] ?? '';
      sectionSlug = json['section_slug'] ?? (json['section_id']?.toString() ?? '');
      sectionId = json['section_id'];
    }

    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      sectionId: sectionId,
      parentId: json['parent_id'],
      sectionName: sectionName,
      sectionSlug: sectionSlug,
      // API uses display_order, fallback to order
      order: json['display_order'] ?? json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'section_id': sectionId,
      'parent_id': parentId,
      'section_name': sectionName,
      'section_slug': sectionSlug,
      'display_order': order,
      'is_active': isActive,
    };
  }
} 