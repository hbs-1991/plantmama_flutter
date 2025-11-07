class Section {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String? image;
  final String color;
  final int order;

  Section({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    this.image,
    required this.color,
    required this.order,
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
      order: json['order'] ?? 0,
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
      'order': order,
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
        return 'assets/images/flower.jpg';
      case 'plants':
        return 'assets/images/plant.png';
      case 'cafe':
        return 'assets/images/coffee.jpg';
      default:
        return 'assets/images/plant.png';
    }
  }
}