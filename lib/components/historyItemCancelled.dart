import 'package:flutter/material.dart';

class HistoryItemCancelledWidget extends StatefulWidget {
  const HistoryItemCancelledWidget({super.key});

  @override
  State<HistoryItemCancelledWidget> createState() => _HistoryItemCancelledWidgetState();
}

class _HistoryItemCancelledWidgetState extends State<HistoryItemCancelledWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white, // Белый цвет для всех секций
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Order #712',
                            style: TextStyle(
                              color: Color(0xFF2F3F24),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'May 25, 2025',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      width: 130,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0x99FF5C5F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x00000020)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.cancel,
                              color: Color(0xFF800200),
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Cancelled',
                              style: TextStyle(
                                color: Color(0xFF800200),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/plant.jpg',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      width: 197.9,
                      height: 100,
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Roses bucket',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'and 3 more items',
                            style: TextStyle(
                              color: Color(0xFF8C7070),
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '1400 TMT',
                            style: TextStyle(
                              color: Color(0xFF9A463C),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // TODO: обработка Details
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A463C),
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: обработка Reorder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A463C),
                      minimumSize: const Size(210, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reorder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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
