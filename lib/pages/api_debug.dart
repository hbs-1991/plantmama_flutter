import 'package:flutter/material.dart';
import '../utils/api_status.dart';

class ApiDebugPage extends StatefulWidget {
  const ApiDebugPage({super.key});

  @override
  State<ApiDebugPage> createState() => _ApiDebugPageState();
}

class _ApiDebugPageState extends State<ApiDebugPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _diagnostics;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final diagnostics = await ApiStatus.getDiagnostics();
      setState(() {
        _diagnostics = diagnostics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('API Диагностика', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Состояние API',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ошибка: $_errorMessage',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            else if (_diagnostics != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildEndpointsCard(),
                      const SizedBox(height: 20),
                      _buildCorsCard(),
                      const SizedBox(height: 20),
                      _buildRecommendationsCard(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final overallAvailable = _diagnostics!['overall_available'] ?? false;
    
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  overallAvailable ? Icons.check_circle : Icons.error,
                  color: overallAvailable ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Общий статус API',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              overallAvailable ? 'API доступен' : 'API недоступен',
              style: TextStyle(
                color: overallAvailable ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Время проверки: ${_diagnostics!['timestamp'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointsCard() {
    final endpoints = _diagnostics!['endpoints'] ?? {};
    
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус эндпоинтов',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...endpoints.entries.map((entry) {
              final endpoint = entry.key;
              final status = entry.value;
              final isAvailable = status['available'] ?? false;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.error,
                      color: isAvailable ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        endpoint,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    if (isAvailable)
                      Text(
                        '${status['statusCode']}',
                        style: const TextStyle(color: Colors.green, fontSize: 14),
                      )
                    else
                      Text(
                        'Ошибка',
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCorsCard() {
    final corsSupport = _diagnostics!['cors_support'] ?? false;
    
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  corsSupport ? Icons.check_circle : Icons.warning,
                  color: corsSupport ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'CORS поддержка',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              corsSupport ? 'CORS настроен правильно' : 'Проблемы с CORS',
              style: TextStyle(
                color: corsSupport ? Colors.green : Colors.orange,
                fontSize: 16,
              ),
            ),
            if (!corsSupport) ...[
              const SizedBox(height: 8),
              const Text(
                'Это может вызывать ошибки в веб-версии приложения',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final overallAvailable = _diagnostics!['overall_available'] ?? false;
    final corsSupport = _diagnostics!['cors_support'] ?? false;
    
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Рекомендации',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!overallAvailable) ...[
              _buildRecommendation(
                Icons.wifi_off,
                'API недоступен',
                'Проверьте:\n• Интернет-соединение\n• Статус ngrok туннеля\n• Доступность сервера',
                Colors.red,
              ),
            ],
            if (!corsSupport) ...[
              const SizedBox(height: 16),
              _buildRecommendation(
                Icons.security,
                'Проблемы с CORS',
                'На сервере нужно настроить заголовки:\n• Access-Control-Allow-Origin\n• Access-Control-Allow-Methods\n• Access-Control-Allow-Headers',
                Colors.orange,
              ),
            ],
            if (overallAvailable && corsSupport) ...[
              _buildRecommendation(
                Icons.check_circle,
                'API работает корректно',
                'Все системы функционируют нормально',
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
