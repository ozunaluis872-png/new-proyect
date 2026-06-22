import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/recogida.dart';
import '../providers/recogida_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla interactiva que muestra recogidas en un mapa de Google Maps.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  // Ubicación por defecto: Centro de Medellín, Colombia
  static const LatLng _ubicacionPorDefecto = LatLng(6.2442, -75.5812);

  final CameraPosition _posicionInicial = const CameraPosition(
    target: _ubicacionPorDefecto,
    zoom: 13,
  );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Genera coordenadas pseudoaleatorias basadas en el ID de recogida
  /// para simular ubicaciones diferentes en un área realista
  LatLng _generarCoordenadas(int recogidaId) {
    // Usar el ID como seed para generar coordenadas en un área
    // alrededor de Medellín (radio de ~5km)
    final seed = recogidaId * 12345;
    final latOffset = ((seed % 1000) - 500) / 100000;
    final lngOffset = ((seed ~/ 1000 % 1000) - 500) / 100000;

    return LatLng(
      _ubicacionPorDefecto.latitude + latOffset,
      _ubicacionPorDefecto.longitude + lngOffset,
    );
  }

  /// Actualiza los marcadores del mapa basado en recogidas
  void _actualizarMarcadores(List<Recogida> recogidas) {
    _markers.clear();

    for (final recogida in recogidas) {
      final coords = _generarCoordenadas(recogida.id);
      final color = _getColorPorEstado(recogida.estado);

      _markers.add(
        Marker(
          markerId: MarkerId('recogida_${recogida.id}'),
          position: coords,
          infoWindow: InfoWindow(
            title: 'Recogida #${recogida.id}',
            snippet:
                '${recogida.cantidadPaquetes} paquetes - ${recogida.estado}',
            onTap: () => _mostrarDetalles(recogida),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarcadorHue(color)),
        ),
      );
    }

    setState(() {});
  }

  /// Obtiene el color según el estado de la recogida
  Color _getColorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return LoginovaColors.warning;
      case 'asignada':
        return LoginovaColors.info;
      case 'en ruta':
        return LoginovaColors.secondary;
      case 'recogida':
        return LoginovaColors.success;
      case 'cancelada':
        return LoginovaColors.error;
      default:
        return LoginovaColors.textSecondary;
    }
  }

  /// Convierte Color a Hue para BitmapDescriptor
  double _getMarcadorHue(Color color) {
    // Simplificación: mapear colores a valores de hue
    if (color == LoginovaColors.warning) return BitmapDescriptor.hueYellow;
    if (color == LoginovaColors.success) return BitmapDescriptor.hueGreen;
    if (color == LoginovaColors.error) return BitmapDescriptor.hueRed;
    if (color == LoginovaColors.info) return BitmapDescriptor.hueBlue;
    return BitmapDescriptor.hueOrange;
  }

  /// Muestra detalles de recogida al hacer clic en marcador
  void _mostrarDetalles(Recogida recogida) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recogida #${recogida.id}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Cliente ID', '#${recogida.clienteId}'),
            _buildDetailRow('Operador ID', '#${recogida.usuarioId}'),
            _buildDetailRow('Paquetes', '${recogida.cantidadPaquetes}'),
            _buildDetailRow('Estado', recogida.estado),
            if (recogida.observaciones.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Observaciones', recogida.observaciones),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de detalle
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Recogidas'), elevation: 0),
      body: Consumer<RecogidaProvider>(
        builder: (context, provider, _) {
          // Actualizar marcadores cuando cambian recogidas
          if (provider.recogidas.isNotEmpty && _markers.isEmpty) {
            _actualizarMarcadores(provider.recogidas);
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _actualizarMarcadores(provider.recogidas);
                },
                initialCameraPosition: _posicionInicial,
                markers: _markers,
                myLocationEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
              ),
              if (provider.cargando)
                const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    await provider.cargarRecogidas();
                    _actualizarMarcadores(provider.recogidas);
                  },
                  tooltip: 'Recargar mapa',
                  child: const Icon(Icons.refresh),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
