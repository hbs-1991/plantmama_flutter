import 'package:flutter/material.dart';

class CommentWidget extends StatefulWidget {
  const CommentWidget({super.key});

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: List.generate(5, (index) => const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star, color: Color(0xFF8B3A3A), size: 14),
                      )),
                    ),
                  ),
                  const Text(
                    'May 25, 2025',
                    style: TextStyle(
                      color: Color(0xFF8C7070),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Best on the market',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'I love this product because the support is great. I reallhy like it I love this product because the support is great. I reallhy like it I love this product because the support is great. I reallhy like it I love this product because the support is great. I reallhy like it I love this product because the support is great. I reallhy like it ',
                      style: TextStyle(
                        color: Color(0xFF8C7070),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFC4C4C4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(
                    Icons.person,
                    color: Color(0xFF8B3A3A),
                    size: 35,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Maksat Amanow',
                    style: TextStyle(
                      color: Color(0xFF8B3A3A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
