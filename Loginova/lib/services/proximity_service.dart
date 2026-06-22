import 'location_service.dart';

/// Información sobre la proximidad entre el operador y una recogida.
class ProximityInfo {
  final double distanceMeters;
  final double distanceKm;
  final String distanceFormatted;
  final bool isClosed; // Está dentro del rango de proximidad
  final ProximityStatus status;
  final String message;

  ProximityInfo({
    required this.distanceMeters,
    required this.status,
    required this.message,
  }) : distanceKm = distanceMeters / 1000,
       distanceFormatted = _formatDistanceHelper(distanceMeters),
       isClosed =
           distanceMeters <= 500; // Considera "cerca" si está a 500m o menos

  /// Helper privado para formatear distancia
  static String _formatDistanceHelper(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Estado de proximidad del operador respecto a la recogida
enum ProximityStatus {
  /// Operador está muy lejos (> 5 km)
  veryFar,

  /// Operador está lejos (1 - 5 km)
  far,

  /// Operador está cerca (500m - 1 km)
  near,

  /// Operador está muy cerca (< 500m)
  veryNear,

  /// Sin datos de ubicación
  unknown,
}

/// Servicio para calcular proximidad entre operador y recogidas.
/// Proporciona información de distancia y estado de proximidad.
class ProximityService {
  // Umbrales de distancia en metros
  static const int _veryNearThresholdMeters = 500;
  static const int _nearThresholdMeters = 1000;
  static const int _farThresholdMeters = 5000;

  /// Calcula la información de proximidad entre dos puntos.
  static ProximityInfo calculateProximity({
    required double operatorLat,
    required double operatorLng,
    required double pickupLat,
    required double pickupLng,
  }) {
    final distanceMeters = LocationService.calculateDistance(
      operatorLat,
      operatorLng,
      pickupLat,
      pickupLng,
    );

    return ProximityInfo(
      distanceMeters: distanceMeters,
      status: _getStatus(distanceMeters),
      message: _getMessageForStatus(_getStatus(distanceMeters)),
    );
  }

  /// Obtiene el estado de proximidad basado en la distancia.
  static ProximityStatus _getStatus(double distanceMeters) {
    if (distanceMeters < _veryNearThresholdMeters) {
      return ProximityStatus.veryNear;
    } else if (distanceMeters < _nearThresholdMeters) {
      return ProximityStatus.near;
    } else if (distanceMeters < _farThresholdMeters) {
      return ProximityStatus.far;
    } else {
      return ProximityStatus.veryFar;
    }
  }

  /// Obtiene el mensaje descriptivo del estado.
  static String _getMessageForStatus(ProximityStatus status) {
    switch (status) {
      case ProximityStatus.veryNear:
        return '✅ Operador muy cerca de la recogida';
      case ProximityStatus.near:
        return '⚠️ Operador cerca de la recogida';
      case ProximityStatus.far:
        return '📍 Operador lejos de la recogida';
      case ProximityStatus.veryFar:
        return '🚗 Operador muy lejos de la recogida';
      case ProximityStatus.unknown:
        return '❓ Sin información de ubicación';
    }
  }

  /// Obtiene el color para visualizar el estado
  static String getColorForStatus(ProximityStatus status) {
    switch (status) {
      case ProximityStatus.veryNear:
        return '#4CAF50'; // Verde oscuro - Muy cerca
      case ProximityStatus.near:
        return '#8BC34A'; // Verde claro - Cerca
      case ProximityStatus.far:
        return '#FFC107'; // Amarillo - Lejos
      case ProximityStatus.veryFar:
        return '#FF5722'; // Rojo - Muy lejos
      case ProximityStatus.unknown:
        return '#9E9E9E'; // Gris - Desconocido
    }
  }

  /// Obtiene el ícono para visualizar el estado
  static String getIconForStatus(ProximityStatus status) {
    switch (status) {
      case ProximityStatus.veryNear:
        return '✓'; // Check
      case ProximityStatus.near:
        return '⚠'; // Warning
      case ProximityStatus.far:
        return '→'; // Arrow
      case ProximityStatus.veryFar:
        return '✗'; // X
      case ProximityStatus.unknown:
        return '?'; // Question mark
    }
  }

  /// Comprueba si el operador está suficientemente cerca para la recogida
  static bool isCloseEnough(double distanceMeters) {
    return distanceMeters <= _nearThresholdMeters;
  }

  /// Obtiene el tiempo estimado de llegada (estimación simple)
  /// Suponiendo velocidad promedio de 40 km/h en ciudad
  static String getETA(double distanceMeters) {
    const avgSpeedKmh = 40;
    final distanceKm = distanceMeters / 1000;
    final timeMinutes = ((distanceKm / avgSpeedKmh) * 60).toInt();

    if (timeMinutes < 1) {
      return '< 1 min';
    } else if (timeMinutes < 60) {
      return '$timeMinutes min';
    } else {
      final hours = timeMinutes ~/ 60;
      final remainingMinutes = timeMinutes % 60;
      return '$hours h $remainingMinutes min';
    }
  }

  /// Formatea la distancia de forma legible
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}
