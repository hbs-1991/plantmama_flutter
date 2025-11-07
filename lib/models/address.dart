import 'package:flutter/material.dart';

class Address {
  final int id;
  final String label;
  final String streetAddress;
  final String apartment;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.label,
    required this.streetAddress,
    required this.apartment,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    print('Address.fromJson: Получены данные: $json');
    try {
      return Address(
        id: json['id'] ?? 0,
        label: json['label'] ?? '',
        streetAddress: json['street_address'] ?? '',
        apartment: json['apartment'] ?? '',
        city: json['city'] ?? '',
        postalCode: json['postal_code'] ?? '',
        country: json['country'] ?? '',
        isDefault: json['is_default'] ?? false,
        isActive: json['is_active'] ?? true,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      print('Address.fromJson: Ошибка создания объекта: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'street_address': streetAddress,
      'apartment': apartment,
      'city': city,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      print('Address._parseDateTime: Ошибка парсинга даты "$dateString": $e');
      return DateTime.now();
    }
  }

  String get fullAddress {
    final parts = <String>[];
    if (streetAddress.isNotEmpty) parts.add(streetAddress);
    if (apartment.isNotEmpty) parts.add(apartment);
    if (city.isNotEmpty) parts.add(city);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.isEmpty ? 'Адрес не указан' : parts.join(', ');
  }

  String get displayLabel {
    if (label.isEmpty) return 'Адрес';
    switch (label.toLowerCase()) {
      case 'home':
        return 'Дом';
      case 'work':
        return 'Работа';
      case 'other':
        return 'Другой';
      default:
        return label;
    }
  }

  IconData get icon {
    if (label.isEmpty) return Icons.location_on;
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'other':
        return Icons.location_on;
      default:
        return Icons.location_on;
    }
  }
} 