import 'package:flutter/material.dart';

class ItemInfoCompoundWidget extends StatefulWidget {
  const ItemInfoCompoundWidget({super.key});

  @override
  State<ItemInfoCompoundWidget> createState() => _ItemInfoCompoundWidgetState();
}

class _ItemInfoCompoundWidgetState extends State<ItemInfoCompoundWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Container(
        width: 100,
        height: 247.9,
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          maxHeight: 320,
        ),
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoRow('Compound:', '11 roses'),
              const Divider(thickness: 2, color: Color(0xFF8B3A3A)),
              _buildInfoRow('Bucket:', 'Monobucket (M)'),
              const Divider(thickness: 2, color: Color(0xFF8B3A3A)),
              _buildInfoRow('Package:', 'Neutral'),
              const Divider(thickness: 2, color: Color(0xFF8B3A3A)),
              _buildInfoRow('Postcard:', 'Default'),
              const Divider(thickness: 2, color: Color(0xFF8B3A3A)),
              _buildInfoRow('Composition:', 'Box'),
              const Divider(thickness: 2, color: Color(0xFF8B3A3A)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.arrow_back, color: Color(0xFF8B3A3A), size: 24),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B3A3A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF8B3A3A),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
