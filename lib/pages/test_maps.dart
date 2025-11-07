import 'package:flutter/material.dart';
import '../components/compactMapsModal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestMapsPage extends StatefulWidget {
  const TestMapsPage({super.key});

  @override
  State<TestMapsPage> createState() => _TestMapsPageState();
}

class _TestMapsPageState extends State<TestMapsPage> {
  String _selectedAddress = '';
  LatLng? _selectedLocation;

  void _openAddressPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 350,
          height: 450,
          child: const CompactMapsModal(),
        ),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _selectedAddress = result['address'] as String;
          _selectedLocation = result['location'] as LatLng;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Тест выбора адреса'),
        backgroundColor: const Color(0xFFFDECEC),
        foregroundColor: const Color(0xFF4B2E2E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/images/pinkbg.png'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Кнопка открытия модального окна
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openAddressPicker,
                  icon: const Icon(Icons.map),
                  label: const Text('Выбрать адрес на карте'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Отображение выбранного адреса
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Белый цвет для всех секций
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выбранный адрес:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B2E2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedAddress.isNotEmpty 
                          ? _selectedAddress 
                          : 'Адрес не выбран',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedAddress.isNotEmpty 
                            ? const Color(0xFF4B2E2E) 
                            : Colors.grey,
                      ),
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Координаты: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8C7070),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Инструкции
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Инструкции:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B2E2E),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Нажмите кнопку "Выбрать адрес на карте"\n'
                      '• Используйте поиск для быстрого поиска адреса\n'
                      '• Нажмите на карту для выбора точной локации\n'
                      '• Нажмите кнопку "Подтвердить адрес" для сохранения',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8C7070),
                      ),
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