import 'package:flutter/material.dart';
import 'safe_image.dart';

class GalleryWidget extends StatelessWidget {
  final String? imageUrl;
  const GalleryWidget({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? SafeImage(
                  imageUrl: imageUrl!,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/us9ec5.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
