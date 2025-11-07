import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:geolocator/geolocator.dart";
import "package:geocoding/geocoding.dart";

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MapsModal extends StatefulWidget {
  const MapsModal({super.key, this.page});
  final String? page;

  @override
  State<MapsModal> createState() => _MapsModalState();
}

class _MapsModalState extends State<MapsModal> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(55.7558, 37.6176); // Москва по умолчанию
  String _selectedAddress = '';
  bool _isLoading = true;
  bool _isSaving = false;
  Set<Marker> _markers = {};


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      _updateMarker();
      _getAddressFromLocation(_currentLocation);
    } catch (e) {
      print('Ошибка получения текущей локации: $e');
      // В случае ошибки используем координаты по умолчанию
      setState(() {
        _isLoading = false;
        _currentLocation = const LatLng(55.7558, 37.6176); // Москва
      });
      _updateMarker();
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _currentLocation,
          infoWindow: InfoWindow(
            title: 'Выбранная локация',
            snippet: _selectedAddress.isNotEmpty ? _selectedAddress : 'Нажмите для выбора адреса',
          ),
        ),
      };
    });
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        
        setState(() {
          _selectedAddress = address.isNotEmpty ? address : 'Координаты: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
        _updateMarker();
      } else {
        setState(() {
          _selectedAddress = 'Координаты: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
        _updateMarker();
      }
    } catch (e) {
      print('Ошибка получения адреса: $e');
      setState(() {
        _selectedAddress = 'Координаты: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
      _updateMarker();
    }
  }



  void _selectCurrentLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15),
    );
    
    _getAddressFromLocation(_currentLocation);
  }

  Future<void> _confirmSelection() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Используем addAddress вместо updateProfile для добавления адреса
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.addAddress(
        label: 'home', // Используем допустимый label
        streetAddress: _selectedAddress,
        city: 'Неизвестно', // Можно добавить геокодирование для получения города
        postalCode: '000000',
        country: 'Неизвестно',
        isDefault: true,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Адрес доставки успешно добавлен'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Возвращаем true для обновления родительского виджета
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка добавления адреса'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                 color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.page == 'plants' ? const Color(0xFFE8F5E8) : const Color(0xFFFFE6F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                  const Expanded(
                    child: Text(
                      'Выберите адрес доставки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            

            
            // Карта
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation,
                            zoom: 15,
                          ),
                          markers: _markers,
                          onTap: (LatLng location) {
                            setState(() {
                              _currentLocation = location;
                            });
                            _getAddressFromLocation(location);
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                        
                        // Кнопка текущей локации
                        Positioned(
                          top: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed: _selectCurrentLocation,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.my_location, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
            ),
            
            // Выбранный адрес
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.page == 'plants' ? const Color(0xFFE8F5E8) : const Color(0xFFFFE6F0),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выбранный адрес:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddress.isNotEmpty 
                        ? _selectedAddress 
                        : 'Нажмите на карту для выбора адреса',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedAddress.isNotEmpty 
                          ? Colors.black87 
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedAddress.isNotEmpty && !_isSaving) ? _confirmSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.page == 'plants' ? const Color(0xFF4CAF50) : const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving 
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Сохранение...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Подтвердить адрес',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  @override
  void dispose() {
    super.dispose();
  }
}