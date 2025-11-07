class Category {
  final int id;
  final String name;
  final String slug;
  final String sectionName;
  final String sectionSlug;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.sectionName,
    required this.sectionSlug,
    required this.order,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      sectionName: json['section_name'] ?? '',
      sectionSlug: json['section_slug'] ?? '',
      order: json['order'] ?? 0,
    );
  }
} 