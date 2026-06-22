import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recogidas_screen.dart';
import '../screens/crear_recogida_screen.dart';
import '../screens/mapa_screen.dart';
import '../screens/admin_dashboard_screen.dart';

/// Definición de todas las rutas nombradas de la aplicación.
class AppRoutes {
  /// Mapa de rutas disponibles en la aplicación.
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot': (context) => const ForgotPasswordScreen(),
    '/home': (context) => const HomeScreen(),
    '/recogidas': (context) => const RecogidasScreen(),
    '/crear-recogida': (context) => const CrearRecogidaScreen(),
    '/mapa': (context) => const MapaScreen(),
    '/admin': (context) => const AdminDashboardScreen(),
  };
}
