import 'package:flutter/material.dart';
import 'safe_image.dart';

class CartItemWidget extends StatefulWidget {
  final String name;
  final String subtitle;
  final String imageUrl;
  final String price;
  final int quantity;
  final VoidCallback? onRemove;
  final Function(int)? onQuantityChanged;

  const CartItemWidget({
    super.key,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.onRemove,
    this.onQuantityChanged,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
  }

  void _incrementQuantity() {
      setState(() {
      _quantity++;
    });
    widget.onQuantityChanged?.call(_quantity);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
      widget.onQuantityChanged?.call(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
          child: Row(
            children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
                child: SafeImage(
                  imageUrl: widget.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(
                    widget.name,
                                style: const TextStyle(
                      fontSize: 16,
                                  fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                  const SizedBox(height: 4),
                        Text(
                    widget.subtitle,
                          style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                        '${widget.price} TMT',
                        style: const TextStyle(
                          fontSize: 16,
                            fontWeight: FontWeight.bold,
                          color: Color(0xFF8B3A3A),
                          ),
                        ),
                        Row(
                          children: [
                          GestureDetector(
                            onTap: _decrementQuantity,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _quantity > 1 
                                  ? const Color(0xFF8B3A3A) 
                                  : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                                                  Text(
                            _quantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _incrementQuantity,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B3A3A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                ),
              ),
            ],
        ),
      ),
    );
  }
}
