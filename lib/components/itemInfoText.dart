import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/product.dart';
import '../services/interfaces/i_cart_service.dart';
import '../di/locator.dart';

class ItemInfoTextWidget extends StatefulWidget {
  final Product product;
  
  const ItemInfoTextWidget({super.key, required this.product});

  @override
  State<ItemInfoTextWidget> createState() => _ItemInfoTextWidgetState();
}

class _ItemInfoTextWidgetState extends State<ItemInfoTextWidget> {
  int _count = 1;
  bool _isAddingToCart = false;
  bool _isFavorite = false;
  final ICartService _cartService = locator.get<ICartService>();

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final isFavorite = await _cartService.isInFavorites(widget.product.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _cartService.addToCart(widget.product, _count);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} добавлен в корзину'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _cartService.removeFromFavorites(widget.product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name} удален из избранного'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await _cartService.addToFavorites(widget.product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name} добавлен в избранное'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      }
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Container(
        width: 100,
        height: 100,
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 320,
        ),
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Roses bucket',
                          style: TextStyle(
                            color: Color(0xFF4B2E2E),
                            fontSize: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border, size: 24),
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Large bucket of roses',
                        style: TextStyle(
                          color: Color(0xFF4B2E2E),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Text(
                    'The fiddle leaf fig is famous for its large, violin- shaped leaves and is a popular choice for modern interior spaces.',
                    style: TextStyle(
                      color: Color(0xFF8C7070),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '490TMT',
                                style: TextStyle(
                                  color: Color(0xFF9A463C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '700TMT',
                                style: TextStyle(
                                  color: Color(0xFF9A463C),
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 100,
                                height: 35,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF9A463C),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_count > 1) _count--;
                                        });
                                      },
                                      icon: const FaIcon(
                                        FontAwesomeIcons.minus,
                                        size: 15,
                                        color: Color(0xFF8B3A3A),
                                      ),
                                    ),
                                    Text(
                                      '$_count',
                                      style: const TextStyle(
                                        color: Color(0xFF8B3A3A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _count++;
                                        });
                                      },
                                      icon: const FaIcon(
                                        FontAwesomeIcons.plus,
                                        size: 15,
                                        color: Color(0xFF8B3A3A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isAddingToCart ? null : _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B3A3A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: _isAddingToCart 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _toggleFavorite,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFavorite ? Colors.red : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.white : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
