import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacturasPacienteViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  List<dynamic> pagos = [];
  String nombrePaciente = 'Paciente';
  bool isLoading = false;
  String? error;

  Future<void> cargarFacturas(String idUsuario) async {
    isLoading = true;
    notifyListeners();
    try {
      // 1. Buscamos el ID del personaje y su nombre
      final resPac = await supabase
          .from('paciente')
          .select('id_paciente, usuario(nombre)')
          .eq('id_usuario', idUsuario)
          .maybeSingle();
          
      if (resPac == null) throw Exception("Perfil no encontrado.");
      final idPaciente = resPac['id_paciente'];
      nombrePaciente = resPac['usuario']['nombre'] ?? 'Paciente';

      // 2. Buscamos su historial de loot/pagos
      final resPagos = await supabase
          .from('pago')
          .select('*')
          .eq('id_paciente', idPaciente)
          .order('fecha', ascending: false);
          
      pagos = resPagos;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}