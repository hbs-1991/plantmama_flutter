class Review {
  final int id;
  final int productId;
  final String title;
  final String comment;
  final int rating;
  final String userName;
  final String userEmail;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.productId,
    required this.title,
    required this.comment,
    required this.rating,
    required this.userName,
    required this.userEmail,
    required this.isVerifiedPurchase,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      productId: json['product'] ?? 0,
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      rating: json['rating'] ?? 1,
      userName: json['user_name'] ?? 'Anonymous',
      userEmail: json['user_email'] ?? '',
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'title': title,
      'comment': comment,
      'rating': rating,
      'user_name': userName,
      'user_email': userEmail,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return "${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}";
  }
}

class CreateReviewRequest {
  final String title;
  final String comment;
  final int rating;
  final String userName;
  final String userEmail;

  CreateReviewRequest({
    required this.title,
    required this.comment,
    required this.rating,
    required this.userName,
    required this.userEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'comment': comment,
      'rating': rating,
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}