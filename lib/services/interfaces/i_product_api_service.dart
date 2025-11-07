import 'dart:async';
import '../../models/product.dart';
import '../../models/section.dart';
import '../../models/category.dart';

abstract class IProductApiService {
  Future<List<Product>> getProducts();
  Future<Product?> getProductById(int id);
  Future<List<Section>> getSections();
  Future<List<Category>> getCategories();
}


