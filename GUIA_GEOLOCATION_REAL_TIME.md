# Guía de Geolocalización en Tiempo Real - Loginova

## 🗺️ Overview

Se ha implementado un sistema completo de **geolocalización en tiempo real** que permite:

✅ Rastrear la ubicación actual del operador en tiempo real
✅ Mostrar la ubicación de las recogidas en un mapa interactivo
✅ Calcular distancias automáticas entre el operador y cada recogida
✅ Indicar si el operador está cerca o lejos de una recogida
✅ Mostrar ETA (Tiempo Estimado de Llegada)
✅ Seleccionar ubicaciones en el mapa al crear nuevas recogidas

---

## 📋 Cambios Realizados

### 1. **Modelo de Datos (`Recogida`)**
Se agregaron campos para almacenar coordenadas:
```dart
double? latitud;    // Latitud de la recogida
double? longitud;   // Longitud de la recogida
DateTime? fechaCreacion; // Fecha de creación
```

### 2. **Servicios Nuevos y Mejorados**

#### `LocationService` (Mejorado)
- Emite cambios de ubicación mediante **Stream**
- Rastreo continuo cada 15 segundos
- Envía ubicación al backend automáticamente
- Geocodificación bidireccional (dirección ↔ coordenadas)

```dart
// Escuchar cambios en tiempo real
locationService.locationStream.listen((location) {
  print('Nueva ubicación: ${location.latitude}, ${location.longitude}');
});
```

#### `ProximityService` (Nuevo)
Calcula distancia y proximidad entre operador y recogida:
```dart
final proximityInfo = ProximityService.calculateProximity(
  operatorLat: 6.2442,
  operatorLng: -75.5812,
  pickupLat: 6.2500,
  pickupLng: -75.5700,
);

print('Distancia: ${proximityInfo.distanceFormatted}');
print('ETA: ${ProximityService.getETA(proximityInfo.distanceMeters)}');
print('¿Cerca? ${proximityInfo.isClosed}');
```

Estados de proximidad:
- **veryNear**: < 500m (✅ Verde)
- **near**: 500m - 1km (ℹ️ Azul)
- **far**: 1km - 5km (⚠️ Amarillo)
- **veryFar**: > 5km (❌ Rojo)

### 3. **Providers Nuevos y Mejorados**

#### `LocationProvider` (Mejorado)
Emite cambios de ubicación en tiempo real:
```dart
Provider.of<LocationProvider>(context).locationStream.listen(...);
```

#### `ProximityProvider` (Nuevo)
Gestiona proximidades en tiempo real:
```dart
final proximityProvider = Provider.of<ProximityProvider>(context);

// Iniciar rastreo
await proximityProvider.startProximityTracking(recogidas);

// Obtener proximidad de una recogida específica
final info = proximityProvider.getProximityForPickup(recogidaId);

// Obtener recogidas cercanas
final cercanasIds = proximityProvider.getClosePickups();

// Ordenar por proximidad
final ordenadas = proximityProvider.getPickupsSortedByProximity();
```

### 4. **Widgets Nuevos**

#### `ProximityIndicator` 
Muestra información de proximidad de forma visual:
```dart
ProximityIndicator(
  proximityInfo: proximityInfo,
  isCompact: false, // Modo expandido
)
```

#### `DistanceDisplay`
Muestra solo la distancia:
```dart
DistanceDisplay(
  distanceMeters: 1500,
  showLabel: true,
)
```

#### `ProximityBadge`
Badge compacto con información:
```dart
ProximityBadge(proximityInfo: proximityInfo)
```

### 5. **Pantallas Mejoradas**

#### `MapaScreen` (Completamente rediseñada)
- ✨ Muestra ubicación del operador en tiempo real (marcador azul)
- 📍 Muestra todas las recogidas con sus coordenadas
- 🎯 Indicador visual cuando el operador está cerca (checkmark)
- 📊 Resumen de recogidas cercanas vs total
- 🔄 Botón para centrar en ubicación actual
- 📱 Panel con detalles y información de proximidad

**Uso:**
```dart
// La pantalla se inicializa automáticamente con:
- Ubicación actual del operador
- Rastreo de proximidad para todas las recogidas
- Stream de ubicación en tiempo real
```

#### `CrearRecogidaScreen` (Mejorada)
- 🗺️ Selector de ubicación interactivo en el mapa
- 📍 Tap en el mapa para seleccionar ubicación
- 📝 Auto-rellena dirección desde coordenadas
- ✅ Valida que se haya seleccionado ubicación
- 📌 Muestra coordenadas seleccionadas

**Uso:**
```
1. Abre "Nueva Recogida"
2. Toca "Selecciona la ubicación en el mapa"
3. Tap en la ubicación deseada (verás el marcador)
4. Toca "Confirmar ubicación"
5. La dirección se auto-llena
6. Completa el resto del formulario
7. Guarda
```

---

## 🔧 Backend - Cambios en .NET

### DTOs Actualizados
```csharp
public record RecogidaRequest(
    [Required] int ClienteId,
    int? UsuarioId,
    [Required] string Estado,
    [Range(0, int.MaxValue)] int CantidadPaquetes,
    string? Observaciones,
    decimal? Latitud,      // ✨ Nuevo
    decimal? Longitud);    // ✨ Nuevo

public record RecogidaResponse(
    int Id,
    int ClienteId,
    int? UsuarioId,
    string Estado,
    int CantidadPaquetes,
    string? Observaciones,
    List<string> Evidencias,
    decimal? Latitud,           // ✨ Nuevo
    decimal? Longitud,          // ✨ Nuevo
    DateTime? FechaCreacion);   // ✨ Nuevo
```

### Controlador Actualizado
- Create: Guarda `Latitud` y `Longitud`
- Update: Actualiza `Latitud` y `Longitud`
- ToResponse: Retorna `Latitud`, `Longitud` y `FechaCreacion`

---

## 🎯 Flujo de Uso Completo

### 1️⃣ **Crear una Recogida con Ubicación**
```
Home → Crear Recogida → Seleccionar ubicación en mapa 
→ Rellenar datos → Guardar
```

### 2️⃣ **Ver Mapa con Ubicación en Tiempo Real**
```
Home → Mapa → Ver mi ubicación (marcador azul)
→ Ver recogidas con coordenadas
→ Tap en recogida para ver distancia y proximidad
```

### 3️⃣ **Monitorear Proximidad**
La app calcula automáticamente:
- Distancia del operador a cada recogida
- Si está cerca (< 1km) o lejos
- ETA estimado
- Todos se actualizan cada 15 segundos

---

## 📊 Ejemplos de Código

### Obtener Ubicación Actual
```dart
final locationProvider = Provider.of<LocationProvider>(context);
await locationProvider.getCurrentLocation();

if (locationProvider.currentLocation != null) {
  final lat = locationProvider.currentLocation!.latitude;
  final lng = locationProvider.currentLocation!.longitude;
  print('Estoy en: $lat, $lng');
}
```

### Iniciar Rastreo
```dart
final locationProvider = Provider.of<LocationProvider>(context);
final success = await locationProvider.startTracking();

if (success) {
  // Escuchar cambios
  locationProvider.locationStream.listen((location) {
    print('Nueva ubicación: ${location.latitude}');
  });
}
```

### Calcular Distancia a Recogida
```dart
if (recogida.latitud != null && recogida.longitud != null 
    && operatorLocation != null) {
  final proximityInfo = ProximityService.calculateProximity(
    operatorLat: operatorLocation.latitude,
    operatorLng: operatorLocation.longitude,
    pickupLat: recogida.latitud!,
    pickupLng: recogida.longitud!,
  );
  
  print('Distancia: ${proximityInfo.distanceFormatted}');
  print('Estado: ${proximityInfo.status}');
  print('ETA: ${ProximityService.getETA(proximityInfo.distanceMeters)}');
}
```

### Mostrar ProximityIndicator
```dart
ProximityIndicator(
  proximityInfo: proximityInfo,
  isCompact: false,
)
```

---

## ⚙️ Configuración Requerida

### Permisos Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### Permisos iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para rastrear recogidas en tiempo real</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos acceso a tu ubicación para funcionalidades en tiempo real</string>
```

---

## 🚀 Características Principales

| Característica | Estado | Descripción |
|---|---|---|
| Ubicación en tiempo real | ✅ | Se actualiza cada 15 segundos |
| Mapa interactivo | ✅ | Flutter Map con OpenStreetMap |
| Selector de ubicación | ✅ | Tap en mapa para seleccionar |
| Cálculo de distancia | ✅ | Fórmula de Haversine |
| Indicador de proximidad | ✅ | 4 estados: muy cerca, cerca, lejos, muy lejos |
| ETA estimado | ✅ | Basado en 40 km/h en ciudad |
| Geocodificación | ✅ | Convertir dirección ↔ coordenadas |
| Sincronización backend | ✅ | Guarda ubicación en BD |
| Rastreo continuo | ✅ | Background location tracking |

---

## 🐛 Troubleshooting

### La ubicación no se actualiza
1. Verifica que los permisos estén otorgados
2. Asegúrate de que el GPS está habilitado
3. Llama a `locationProvider.startTracking()`
4. Espera 15 segundos para la actualización

### El mapa no muestra ubicaciones
1. Verifica que las recogidas tienen `latitud` y `longitud`
2. Las coordenadas deben estar en formato correcto (ej: 6.2442, -75.5812)
3. Comprueba que el backend retorna estos campos en el response

### La distancia no es correcta
1. Verifica el formato de las coordenadas (LatLng espera double)
2. Asegúrate de usar el mismo sistema de coordenadas (WGS84/GPS)
3. La precisión depende de la precisión del GPS (±5-10m típico)

---

## 📚 Archivos Modificados/Creados

### Nuevos
- `lib/services/proximity_service.dart`
- `lib/providers/proximity_provider.dart`
- `lib/widgets/proximity_indicator.dart`

### Modificados
- `lib/models/recogida.dart` - Agregó latitud, longitud, fechaCreacion
- `lib/services/location_service.dart` - Agregó Stream, mejoró tracking
- `lib/providers/location_provider.dart` - Mejoró para suscribirse a stream
- `lib/screens/mapa_screen.dart` - Rediseño completo
- `lib/screens/crear_recogida_screen.dart` - Agregó selector de ubicación
- Backend: `DTOs/RecogidaDtos.cs`, `Controllers/RecogidasController.cs`

---

## 📞 Soporte

Para preguntas o problemas:
1. Revisa los logs de Flutter: `flutter logs`
2. Habilita el modo debug: `flutter run -v`
3. Verifica que el backend está enviando coordenadas correctas
4. Prueba con ubicación simulada en el emulador si es necesario

---

**Última actualización:** 2026-06-22
**Versión:** 2.0 (Con geolocalización en tiempo real)
