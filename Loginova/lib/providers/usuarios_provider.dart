import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuario_service.dart';

/// Provider que gestiona la lista de usuarios del sistema.
class UsuariosProvider extends ChangeNotifier {
  final UsuarioService _service = UsuarioService();
  List<Usuario> _usuarios = [];
  bool _cargando = false;
  String? _error;

  List<Usuario> get usuarios => _usuarios;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Carga la lista de usuarios desde la API
  Future<void> cargarUsuarios() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuarios = await _service.obtenerUsuarios();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Elimina un usuario por ID
  Future<void> eliminarUsuario(int id) async {
    try {
      await _service.eliminarUsuario(id);
      _usuarios.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
