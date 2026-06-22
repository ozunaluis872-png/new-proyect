import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/recogida_provider.dart';
import '../providers/usuarios_provider.dart';
import '../themes/app_theme.dart';

/// Panel de administrador con reportes y gestión de usuarios.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsuariosProvider>(context, listen: false).cargarUsuarios();
      Provider.of<RecogidaProvider>(context, listen: false).cargarRecogidas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).usuario;

    // Solo Admin puede ver este dashboard
    if (currentUser?.rol.toLowerCase() != 'administrador') {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text('Solo administradores pueden acceder a este panel'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administrador'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'Reportes'),
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildReportesTab(context), _buildUsuariosTab(context)],
        ),
      ),
    );
  }

  /// Tab de Reportes y Estadísticas
  Widget _buildReportesTab(BuildContext context) {
    return Consumer2<RecogidaProvider, UsuariosProvider>(
      builder: (context, recogidaProvider, usuariosProvider, _) {
        final recogidas = recogidaProvider.recogidas;
        final usuarios = usuariosProvider.usuarios;

        final totalRecogidas = recogidas.length;
        final completadas = recogidas
            .where((r) => r.estado.toLowerCase() == 'recogida')
            .length;
        final enRuta = recogidas
            .where((r) => r.estado.toLowerCase() == 'en ruta')
            .length;
        final pendientes = recogidas
            .where((r) => r.estado.toLowerCase() == 'pendiente')
            .length;

        final operadores = usuarios
            .where((u) => u.rol.toLowerCase() == 'operador')
            .length;
        final admins = usuarios
            .where((u) => u.rol.toLowerCase() == 'administrador')
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Métricas de Recogidas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildMetricasGrid(
                context,
                totalRecogidas,
                completadas,
                enRuta,
                pendientes,
              ),
              const SizedBox(height: 32),
              Text(
                'Recursos del Sistema',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildRecursosCard(context, operadores, admins, usuarios.length),
              const SizedBox(height: 32),
              Text(
                'Actividad Reciente',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (recogidas.isEmpty)
                const Center(child: Text('Sin actividad reciente'))
              else
                ...recogidas
                    .take(5)
                    .map(
                      (r) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            _getIconoPorEstado(r.estado),
                            color: _getColorPorEstado(r.estado),
                          ),
                          title: Text('Recogida #${r.id}'),
                          subtitle: Text(
                            '${r.cantidadPaquetes} paquetes - ${r.estado}',
                          ),
                          trailing: Text(
                            'Cliente #${r.clienteId}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  /// Grilla de métricas de recogidas
  Widget _buildMetricasGrid(
    BuildContext context,
    int total,
    int completadas,
    int enRuta,
    int pendientes,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildMetricCard(
          context,
          'Total',
          total.toString(),
          Icons.local_shipping,
          LoginovaColors.primary,
        ),
        _buildMetricCard(
          context,
          'Completadas',
          completadas.toString(),
          Icons.check_circle,
          LoginovaColors.success,
        ),
        _buildMetricCard(
          context,
          'En Ruta',
          enRuta.toString(),
          Icons.directions_car,
          LoginovaColors.secondary,
        ),
        _buildMetricCard(
          context,
          'Pendientes',
          pendientes.toString(),
          Icons.hourglass_empty,
          LoginovaColors.warning,
        ),
      ],
    );
  }

  /// Tarjeta de métrica individual
  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de recursos
  Widget _buildRecursosCard(
    BuildContext context,
    int operadores,
    int admins,
    int totalUsuarios,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecursoRow('Total Usuarios', totalUsuarios.toString()),
            const SizedBox(height: 12),
            _buildRecursoRow('Administradores', admins.toString()),
            const SizedBox(height: 12),
            _buildRecursoRow('Operadores', operadores.toString()),
          ],
        ),
      ),
    );
  }

  /// Fila de recurso
  Widget _buildRecursoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: LoginovaColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: LoginovaColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Tab de Gestión de Usuarios
  Widget _buildUsuariosTab(BuildContext context) {
    return Consumer<UsuariosProvider>(
      builder: (context, provider, _) {
        final usuarios = provider.usuarios;

        return RefreshIndicator(
          onRefresh: provider.cargarUsuarios,
          child: usuarios.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('Sin usuarios registrados')),
                  ],
                )
              : ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorPorRol(usuario.rol),
                          child: Text(
                            usuario.nombre.isNotEmpty
                                ? usuario.nombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(usuario.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(usuario.correo),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorPorRol(
                                  usuario.rol,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                usuario.rol,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorPorRol(usuario.rol),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Ver Detalles'),
                              onTap: () =>
                                  _mostrarDetallesUsuario(context, usuario),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  /// Muestra detalles de usuario
  void _mostrarDetallesUsuario(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Usuario #${usuario.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nombre', usuario.nombre),
            const SizedBox(height: 8),
            _buildDetailRow('Correo', usuario.correo),
            const SizedBox(height: 8),
            _buildDetailRow('Rol', usuario.rol),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Construye fila de detalle
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  /// Obtiene color según rol
  Color _getColorPorRol(String rol) {
    if (rol.toLowerCase() == 'administrador') {
      return LoginovaColors.error;
    }
    return LoginovaColors.secondary;
  }

  /// Obtiene color según estado
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

  /// Obtiene ícono según estado
  IconData _getIconoPorEstado(String estado) {
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
}
