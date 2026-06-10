import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stats actuales de la sesión
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  // Aquí guardamos si es 'dentista' o 'paciente'
  String? userRole; 

  // Misión: Loguear al usuario
  Future<void> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Si el login es un hit crítico, buscamos su rol
        await fetchUserRole(response.user!.id);
      }
    } catch (e) {
      // Manejo del lag mental / errores de credenciales
      throw Exception('Error de login: $e');
    }
  }

// Misión: Descubrir la clase del jugador (Dentista o Paciente)
  Future<void> fetchUserRole(String userId) async {
    try {
      // Ahora apuntamos a la tabla 'usuario' buscando por 'id_usuario'
      final data = await _supabase
          .from('usuario') 
          .select('rol')
          .eq('id_usuario', userId)
          .single();
          
      userRole = data['rol'];
      notifyListeners(); // Avisamos a la UI que ya cargó el rol
      
    } catch (e) {
      print('Fallo al obtener el rol del usuario: $e');
    }
  }

  // Misión: Desconectar (Rage Quit)
  Future<void> logout() async {
    await _supabase.auth.signOut();
    userRole = null;
    notifyListeners();
  }
}