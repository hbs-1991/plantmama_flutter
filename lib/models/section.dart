/// Section model matching API schema (ProductSection)
class Section {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String? image;
  final String color;
  final int order;        // Maps to display_order from API
  final bool isActive;    // New: from API

  Section({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    this.image,
    required this.color,
    required this.order,
    this.isActive = true,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      image: json['image'],
      color: json['color'] ?? '#000000',
      // API uses display_order, fallback to order for backward compatibility
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
      'image': image,
      'color': color,
      'display_order': order,
      'is_active': isActive,
    };
  }

  String get safeImageUrl {
    if (image == null || image!.isEmpty) {
      return defaultImageUrl;
    }

    // Если это ngrok URL, добавляем специальные заголовки
    if (image!.contains('ngrok')) {
      // Возвращаем URL как есть, но в UI будем использовать специальные заголовки
      return image!;
    }

    return image!;
  }

  String get defaultImageUrl {
    switch (slug.toLowerCase()) {
      case 'flowers':
      case 'tsvety':
        return 'assets/images/flower.jpg';
      case 'plants':
        return 'assets/images/plant.png';
      case 'cafe':
      case 'kafe':
        return 'assets/images/coffee.jpg';
      default:
        return 'assets/images/plant.png';
    }
  }
}