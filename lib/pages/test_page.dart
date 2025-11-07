import 'package:flutter/material.dart';
import '../test_address_api.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _testResult = '';

  Future<void> _runTest() async {
    setState(() {
      _testResult = 'Запуск теста...';
    });

    try {
      final test = AddressApiTest();
      await test.testAddressApi();
      setState(() {
        _testResult = 'Тест завершен. Проверьте консоль для деталей.';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Ошибка теста: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест API'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _runTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: const Text('Запустить тест API адресов'),
            ),
            const SizedBox(height: 20),
            Text(
              _testResult,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 