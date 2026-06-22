import 'package:flutter/material.dart';

import '../models/recogida.dart';
import '../themes/app_theme.dart';
import 'editar_recogida_screen.dart';
import 'evidencia_screen.dart';

/// Pantalla profesional que muestra los detalles completos de una recogida.
class DetalleRecogidaScreen extends StatefulWidget {
  final Recogida recogida;

  const DetalleRecogidaScreen({super.key, required this.recogida});

  @override
  State<DetalleRecogidaScreen> createState() => _DetalleRecogidaScreenState();
}

class _DetalleRecogidaScreenState extends State<DetalleRecogidaScreen> {
  late Recogida _recogida;
  late List<String> _evidencias;

  @override
  void initState() {
    super.initState();
    _recogida = widget.recogida;
    _evidencias = List<String>.from(_recogida.evidencias);
  }

  Future<void> _editarRecogida() async {
    final actualizada = await Navigator.push<Recogida>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarRecogidaScreen(recogida: _recogida),
      ),
    );

    if (actualizada != null && mounted) {
      setState(() {
        _recogida = actualizada;
        _evidencias = List<String>.from(actualizada.evidencias);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recogida actualizada correctamente')),
      );
    }
  }

  Future<void> _agregarEvidencia() async {
    final evidenciaPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenciaScreen(recogidaId: _recogida.id),
      ),
    );

    if (evidenciaPath != null && evidenciaPath.trim().isNotEmpty && mounted) {
      setState(() {
        _evidencias = [..._evidencias, evidenciaPath];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia agregada correctamente')),
      );
    }
  }

  /// Obtiene el color según el estado de la recogida
  Color _getEstadoColor(String estado) {
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

  /// Obtiene el ícono según el estado de la recogida
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.hourglass_empty;
      case 'asignada':
        return Icons.assignment;
      case 'en ruta':
        return Icons.local_shipping;
      case 'recogida':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEstadoColor(_recogida.estado);
    final icon = _getEstadoIcon(_recogida.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Recogida'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado actual
              _buildEstadoCard(color, icon),
              const SizedBox(height: 24),

              // Información general
              _buildSectionTitle('Información General'),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Información de cliente y operador
              _buildSectionTitle('Asignación'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.person,
                      label: 'Cliente ID',
                      value: '#${_recogida.clienteId}',
                      color: LoginovaColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.engineering,
                      label: 'Operador ID',
                      value: '#${_recogida.usuarioId}',
                      color: LoginovaColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Paquetes
              _buildSectionTitle('Paquetes'),
              const SizedBox(height: 12),
              _buildPackagesCard(),
              const SizedBox(height: 24),

              // Observaciones
              if (_recogida.observaciones.isNotEmpty) ...[
                _buildSectionTitle('Observaciones'),
                const SizedBox(height: 12),
                _buildObservacionesCard(),
                const SizedBox(height: 24),
              ],

              // Evidencias
              _buildSectionTitle('Evidencias'),
              const SizedBox(height: 12),
              _buildEvidenciasSection(),
              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta de estado
  Widget _buildEstadoCard(Color color, IconData icon) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado Actual',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recogida.estado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de información general
  Widget _buildInfoCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: LoginovaColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildInfoRow('ID de Recogida', '#${_recogida.id}'),
            const Divider(height: 16),
            _buildInfoRow(
              'Cantidad de Paquetes',
              '${_recogida.cantidadPaquetes} paquetes',
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de información
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LoginovaColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  /// Construye un elemento de detalle
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LoginovaColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de paquetes
  Widget _buildPackagesCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LoginovaColors.secondary.withValues(alpha: 0.1),
          border: Border.all(
            color: LoginovaColors.secondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LoginovaColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: LoginovaColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de Paquetes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LoginovaColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_recogida.cantidadPaquetes}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: LoginovaColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de observaciones
  Widget _buildObservacionesCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notas',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LoginovaColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _recogida.observaciones,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: LoginovaColors.primary,
          ),
    );
  }

  /// Construye la sección de evidencias
  Widget _buildEvidenciasSection() {
    if (_evidencias.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: LoginovaColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No hay evidencias',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LoginovaColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _evidencias.length,
      itemBuilder: (context, index) {
        return Card(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: LoginovaColors.background,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 48,
                  color: LoginovaColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Evidencia ${index + 1}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye los botones de acción
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Evidencia'),
                onPressed: _agregarEvidencia,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar Recogida'),
            onPressed: _editarRecogida,
          ),
        ),
      ],
    );
  }
}
