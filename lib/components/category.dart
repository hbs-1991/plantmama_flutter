import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryWidget extends StatefulWidget {
  final Category? category;
  final String? page;
  final VoidCallback? onTap;
  
  const CategoryWidget({
    super.key, 
    this.category,
    this.page,
    this.onTap,
  });

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  @override
  Widget build(BuildContext context) {
    final categoryName = widget.category?.name ?? 'Все';
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 150,
        ),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white, // Белый фон для всех категорий
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            categoryName,
            style: const TextStyle(
              color: Color(0xFF333333), // Темно-серый текст для всех категорий
              fontWeight: FontWeight.w500,
              fontSize: 14,
              letterSpacing: 0.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
