import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SolicitarCitaViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  List<dynamic> dentistas = [];
  List<dynamic> tratamientos = [];
  bool isLoading = false;
  String? error;

  Future<void> cargarDatosIniciales() async {
    isLoading = true;
    notifyListeners();
    try {
      final resDentistas = await supabase.from('dentista').select('id_dentista, usuario(nombre)');
      dentistas = resDentistas;

      final resTrat = await supabase.from('tratamiento').select('nombre, precio').order('nombre');
      tratamientos = resTrat;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agendarCita({
    required String idUsuarioPaciente,
    required String idDentista,
    required String fecha,
    required String hora,
    required List<String> tratamientosSeleccionados,
    String? motivoPersonalizado, // <-- Nuevo slot para el texto del paciente
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final resPac = await supabase
          .from('paciente')
          .select('id_paciente')
          .eq('id_usuario', idUsuarioPaciente)
          .maybeSingle();
          
      if (resPac == null) throw Exception("No se encontró el perfil del paciente.");
      final idPaciente = resPac['id_paciente'];

      // Fusionamos los chips seleccionados con el texto escrito a mano
      String motivoFinal = tratamientosSeleccionados.join(', ');
      
      if (motivoPersonalizado != null && motivoPersonalizado.trim().isNotEmpty) {
        if (motivoFinal.isEmpty) {
          motivoFinal = "Consulta / Otros: $motivoPersonalizado";
        } else {
          motivoFinal = "$motivoFinal | Síntomas/Detalles: $motivoPersonalizado";
        }
      }

      if (motivoFinal.isEmpty) motivoFinal = 'Revisión General';

      await supabase.from('cita').insert({
        'id_paciente': idPaciente,
        'id_dentista': idDentista,
        'fecha': fecha,
        'hora': hora,
        'estado': 'Pendiente',
        'motivo': motivoFinal, 
      });

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}