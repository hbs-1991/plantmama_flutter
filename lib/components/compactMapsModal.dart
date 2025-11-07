import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:geocoding/geocoding.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../utils/platform_utils.dart";

class CompactMapsModal extends StatefulWidget {
  const CompactMapsModal({super.key});

  @override
  State<CompactMapsModal> createState() => CompactMapsModalState();
}

class CompactMapsModalState extends State<CompactMapsModal> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(37.9601, 58.3261);
  LatLng _selectedLocation = const LatLng(37.9601, 58.3261);
  String _selectedAddress = "";
  bool _isLoading = true;
  Set<Marker> _markers = {};
  final TextEditingController _addressController = TextEditingController();

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
        _selectedLocation = _currentLocation;
        _isLoading = false;
      });
      
      _updateMarker();
      _getAddressFromLocation(_currentLocation);
    } catch (e) {
      print('Ошибка получения текущей локации: $e');
      setState(() {
        _isLoading = false;
        _currentLocation = const LatLng(37.9601, 58.3261);
        _selectedLocation = _currentLocation;
      });
      _updateMarker();
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
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
    setState(() {
      _selectedLocation = _currentLocation;
    });
    
    if (PlatformUtils.shouldUseGoogleMaps) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15),
      );
    }
    
    _getAddressFromLocation(_currentLocation);
  }

  void _confirmSelection() {
    Navigator.of(context).pop({
      'address': _selectedAddress,
      'location': _selectedLocation,
    });
  }

  Widget _buildMapContent() {
    if (PlatformUtils.shouldUseGoogleMaps) {
      return GoogleMap(
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
            _selectedLocation = location;
          });
          _getAddressFromLocation(location);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      );
    } else {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 24,
                color: const Color(0xFFE91E63),
              ),
              const SizedBox(height: 4),
              const Text(
                'Текущая локация',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B2E2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Координаты: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF8C7070),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _selectCurrentLocation,
                icon: const Icon(Icons.my_location, size: 14),
                label: const Text('Использовать', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE6F0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
                Expanded(
                  child: Text(
                    'Выберите адрес',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
          ),
          
          // Поле ввода адреса (только для мобильной версии)
          if (!PlatformUtils.shouldUseGoogleMaps)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Введите адрес:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B2E2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'ул. Молодежная, Ашхабад',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAddress = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Карта
          Container(
            height: 200,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      _buildMapContent(),
                      
                      // Кнопка текущей локации (только для веб)
                      if (PlatformUtils.shouldUseGoogleMaps)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FloatingActionButton.small(
                            onPressed: _selectCurrentLocation,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.my_location, color: Colors.black87, size: 16),
                          ),
                        ),
                    ],
                  ),
          ),
          
          // Выбранный адрес
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE6F0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выбранный адрес:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress.isNotEmpty 
                      ? _selectedAddress 
                      : PlatformUtils.shouldUseGoogleMaps 
                          ? 'Нажмите на карту'
                          : 'Введите адрес выше',
                  style: TextStyle(
                    fontSize: 11,
                    color: _selectedAddress.isNotEmpty 
                        ? Colors.black87 
                        : Colors.grey,
                  ),
                ),
                ...[
                  const SizedBox(height: 4),
                  Text(
                    'Координаты: ${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8C7070),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAddress.isNotEmpty ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Подтвердить',
                      style: TextStyle(
                        fontSize: 11,
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
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
} 