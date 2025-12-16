/// Address model aligned with FastAPI backend schema.
///
/// API Schema (from api-docs/_common/schemas.yaml):
/// - full_name: string (required) - Recipient's full name
/// - phone: string (required) - Contact phone for delivery
/// - address_line1: string (required) - Primary address line
/// - address_line2: string (nullable) - Secondary address line
/// - city: string (required) - City name
/// - postal_code: string - Postal/ZIP code
/// - country: string (default: "Russia")
/// - is_default: boolean
class Address {
  final int id;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.postalCode = '',
    this.country = 'Russia',
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates Address from FastAPI JSON response.
  ///
  /// FastAPI response format:
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "id": 1,
  ///     "full_name": "John Doe",
  ///     "phone": "+1234567890",
  ///     "address_line1": "123 Main St",
  ///     "address_line2": "Apt 4",
  ///     "city": "Moscow",
  ///     "postal_code": "123456",
  ///     "country": "Russia",
  ///     "is_default": true,
  ///     "created_at": "2024-01-01T00:00:00Z",
  ///     "updated_at": "2024-01-01T00:00:00Z"
  ///   }
  /// }
  /// ```
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? 'Russia',
      isDefault: json['is_default'] ?? false,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts to JSON for FastAPI requests.
  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'address_line2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
    };
  }

  static DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  /// Formatted single-line address for display.
  String get formattedAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add(city);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }

  /// Full display with recipient info.
  String get fullDisplay {
    return '$fullName\n$phone\n$formattedAddress';
  }

  Address copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Address(id: $id, fullName: $fullName, city: $city)';
}
