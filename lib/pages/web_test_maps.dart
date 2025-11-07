import 'package:flutter/material.dart';
// Импортируем веб-реализацию модалки карт
import '../components/webMapsModal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WebTestMapsPage extends StatefulWidget {
  const WebTestMapsPage({super.key});

  @override
  State<WebTestMapsPage> createState() => _WebTestMapsPageState();
}

class _WebTestMapsPageState extends State<WebTestMapsPage> {
  String _selectedAddress = '';
  LatLng? _selectedLocation;

  void _openAddressPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const WebMapsModal(),
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
        title: const Text('Тест универсальных карт'),
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
              
              // Информация о веб-версии
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Веб-версия',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Эта версия оптимизирована для работы в браузере Edge и других веб-браузерах. '
                      'Некоторые функции геолокации могут работать ограниченно.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
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
                  color: Colors.white,
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
              
              // Инструкции для веб
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
                      'Инструкции для веб-версии:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B2E2E),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Разрешите доступ к геолокации в браузере\n'
                      '• Используйте поиск для быстрого поиска адреса\n'
                      '• Нажмите на карту для выбора точной локации\n'
                      '• В веб-версии некоторые функции могут работать медленнее',
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