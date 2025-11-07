import 'dart:async';
import '../../models/review.dart';

abstract class IReviewService {
  Future<List<Review>> getProductReviews(int productId, {
    int? rating,
    bool? isVerifiedPurchase,
    String? search,
    String ordering = '-created_at',
    bool forceRefresh = false,
  });
  Future<Review?> addReview(int productId, CreateReviewRequest reviewRequest);
  Future<List<Review>> getAllReviews({
    int? rating,
    bool? isVerifiedPurchase,
    String? search,
    String ordering = '-created_at',
  });
  Future<Review?> getReview(int reviewId);
}


