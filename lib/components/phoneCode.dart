import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneCodeWidget extends StatefulWidget {
  const PhoneCodeWidget({super.key});

  @override
  State<PhoneCodeWidget> createState() => _PhoneCodeWidgetState();
}

class _PhoneCodeWidgetState extends State<PhoneCodeWidget> {
  final TextEditingController _pinCodeController = TextEditingController();
  final FocusNode _pinCodeFocusNode = FocusNode();

  @override
  void dispose() {
    _pinCodeController.dispose();
    _pinCodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: IntrinsicHeight(
          child: Container(
            width: 300,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white, // Белый цвет для всех секций
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.phone,
                        color: Color(0xFF8B3A3A),
                        size: 200,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white, // Белый цвет для всех секций
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'Phone number',
                                  style: TextStyle(
                                    color: Color(0xFF8C7070),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              PinCodeTextField(
                                appContext: context,
                                length: 6,
                                textStyle: const TextStyle(fontSize: 20),
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                enableActiveFill: false,
                                autoFocus: true,
                                focusNode: _pinCodeFocusNode,
                                enablePinAutofill: false,
                                errorTextSpace: 16,
                                showCursor: true,
                                cursorColor: const Color(0xFF8B3A3A),
                                obscureText: false,
                                hintCharacter: '•',
                                keyboardType: TextInputType.number,
                                pinTheme: PinTheme(
                                  fieldHeight: 44,
                                  fieldWidth: 44,
                                  borderWidth: 2,
                                  borderRadius: BorderRadius.circular(12),
                                  shape: PinCodeFieldShape.box,
                                  activeColor: const Color(0xFF8B3A3A),
                                  inactiveColor: const Color(0xFF8C7070),
                                  selectedColor: const Color(0xFF8B3A3A),
                                ),
                                controller: _pinCodeController,
                                onChanged: (_) {},
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: const Color(0xFF8B3A3A),
                          minimumSize: const Size(60, 60),
                        ),
                        onPressed: () async {
                          final code = _pinCodeController.text.trim();
                          if (code.length != 6) return;
                          Navigator.pop(context, code);
                        },
                        child: const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
