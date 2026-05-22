import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Obtiene la ubicación actual si los permisos son concedidos.
  /// Lanza un error detallado si no se puede obtener la ubicación,
  /// lo cual es útil para que la UI muestre la opción de dirección manual.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      throw Exception('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        throw Exception('Los permisos de ubicación fueron denegados.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      throw Exception(
          'Los permisos de ubicación fueron denegados permanentemente. Por favor ingresa tu dirección manualmente.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception(
        'No se pudo obtener la ubicación a tiempo. Se usará una ubicación por defecto.',
      ),
    );
  }
}
