import 'package:flutter/material.dart';

class AddReviewWidget extends StatefulWidget {
  const AddReviewWidget({super.key});

  @override
  State<AddReviewWidget> createState() => _AddReviewWidgetState();
}

class _AddReviewWidgetState extends State<AddReviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      thickness: 2,
                      color: const Color(0xFF989898),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add review',
                    style: TextStyle(
                      color: Color(0xFF989898),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF638042),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.done,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
