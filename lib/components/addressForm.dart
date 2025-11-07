import 'package:flutter/material.dart';
import '../models/address.dart';

class AddressForm extends StatefulWidget {
  final Address? address;
  final Function(Address) onSave;

  const AddressForm({
    Key? key,
    this.address,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isDefault = false;
  String _selectedLabel = 'home';
  bool _isCustomLabel = false;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _labelController.text = widget.address!.label;
      _streetController.text = widget.address!.streetAddress;
      _apartmentController.text = widget.address!.apartment;
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode;
      _countryController.text = widget.address!.country;
      _isDefault = widget.address!.isDefault;
      
             // Определяем, является ли адрес кастомным
       if (widget.address!.label != 'home' && widget.address!.label != 'work') {
         _selectedLabel = 'other';
         _isCustomLabel = true;
         _showCustomInput = true;
         _labelController.text = widget.address!.label;
       } else {
         _selectedLabel = widget.address!.label;
         _isCustomLabel = false;
         _showCustomInput = false;
       }
    } else {
      _countryController.text = 'Turkmenistan';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final finalLabel = _isCustomLabel ? _labelController.text.trim() : _selectedLabel;
      
      print('AddressForm: _isCustomLabel: $_isCustomLabel');
      print('AddressForm: _selectedLabel: $_selectedLabel');
      print('AddressForm: _labelController.text: ${_labelController.text.trim()}');
      print('AddressForm: finalLabel: $finalLabel');
      
      final address = Address(
        id: widget.address?.id ?? 0,
        label: finalLabel,
        streetAddress: _streetController.text.trim(),
        apartment: _apartmentController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        isDefault: _isDefault,
        isActive: true,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onSave(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.address == null ? 'Добавить адрес' : 'Редактировать адрес',
        style: const TextStyle(
          color: Color(0xFF8B4513),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                   value: _selectedLabel,
                   decoration: const InputDecoration(
                     labelText: 'Тип адреса',
                     border: OutlineInputBorder(),
                   ),
                                       items: const [
                      DropdownMenuItem(value: 'home', child: Text('Дом')),
                      DropdownMenuItem(value: 'work', child: Text('Работа')),
                      DropdownMenuItem(value: 'other', child: Text('Другой')),
                    ],
                                       onChanged: (value) {
                      setState(() {
                        _selectedLabel = value!;
                        _isCustomLabel = value == 'other';
                        _showCustomInput = value == 'other';
                        if (_isCustomLabel && _labelController.text.isEmpty) {
                          _labelController.text = '';
                        }
                      });
                    },
                   validator: (value) {
                     if (value == null || value.isEmpty) {
                       return 'Выберите тип адреса';
                     }
                     return null;
                   },
                                   ),
 
               if (_showCustomInput)
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Expanded(
                           child: TextFormField(
                             controller: _labelController,
                             decoration: const InputDecoration(
                               labelText: 'Название адреса*',
                               border: OutlineInputBorder(),
                               hintText: 'Например: Дача, Магазин, Родители',
                             ),
                             validator: (value) {
                               if (value == null || value.trim().isEmpty) {
                                 return 'Введите название адреса';
                               }
                               return null;
                             },
                           ),
                         ),
                         const SizedBox(width: 8),
                         IconButton(
                           onPressed: () {
                             setState(() {
                               _showCustomInput = false;
                               _selectedLabel = 'home';
                               _isCustomLabel = false;
                               _labelController.clear();
                             });
                           },
                           icon: const Icon(Icons.close),
                           tooltip: 'Отменить',
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                   ],
                 ),
 
               TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Улица и номер дома*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите адрес';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apartmentController,
                decoration: const InputDecoration(
                  labelText: 'Квартира/Офис',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите город';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Почтовый индекс',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Страна*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите страну';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Адрес по умолчанию'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.address == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }
} 