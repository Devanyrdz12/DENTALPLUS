import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CitaViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  List<dynamic> citas = [];
  bool isLoading = false;
  String? error;

  Future<void> cargarCitas() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await supabase
          .from('cita')
          .select('*, paciente(usuario(nombre))')
          .order('fecha', ascending: true);
      citas = response;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Carga las citas de un paciente específico (para el portal del usuario)
  Future<List<dynamic>> obtenerCitasPaciente(String idUsuario) async {
    try {
      final resPac = await supabase.from('paciente').select('id_paciente').eq('id_usuario', idUsuario).maybeSingle();
      if (resPac == null) return [];
      
      return await supabase
          .from('cita')
          .select('*, dentista(usuario(nombre))')
          .eq('id_paciente', resPac['id_paciente'])
          .order('fecha', ascending: false);
    } catch (e) {
      return [];
    }
  }

  // El núcleo del control de estados del Dentista (Aceptar/Rechazar/Reactivar)
  Future<bool> cambiarEstadoCita(Map<String, dynamic> cita, String nuevoEstado) async {
    try {
      final String idCita = cita['id_cita'].toString();

      // Validación de tiempo: Si intenta reactivar, validamos que la cita sea futura
      if (nuevoEstado == 'Pendiente') {
        DateTime fechaCita = DateTime.parse("${cita['fecha']} ${cita['hora']}");
        if (fechaCita.isBefore(DateTime.now())) {
          error = "No puedes reactivar una cita cuya fecha ya expiró en el tiempo real.";
          notifyListeners();
          return false;
        }
      }

      await supabase.from('cita').update({'estado': nuevoEstado}).eq('id_cita', idCita);
      await cargarCitas(); // Auto-recarga instantánea para evitar lag visual
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Lógica del Dentista para editar parámetros directos (Fecha y Hora)
  Future<bool> editarHorarioDentista(String idCita, String nuevaFecha, String nuevaHora) async {
    try {
      await supabase.from('cita').update({
        'fecha': nuevaFecha,
        'hora': nuevaHora,
      }).eq('id_cita', idCita);
      await cargarCitas();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Lógica de Reagendación del Paciente (Crea una nueva y marca la anterior)
  Future<bool> reagendarDesdePaciente({
    required Map<String, dynamic> citaOriginal,
    required String nuevaFecha,
    required String nuevaHora,
  }) async {
    try {
      // 1. Marcamos la cita vieja como Reagendada
      await supabase.from('cita').update({'estado': 'Reagendada'}).eq('id_cita', citaOriginal['id_cita']);

      // 2. Insertamos la nueva rama/cita en estado Pendiente con el Tag especial
      final motivoOriginal = citaOriginal['motivo'] ?? 'Revisión General';
      await supabase.from('cita').insert({
        'id_paciente': citaOriginal['id_paciente'],
        'id_dentista': citaOriginal['id_dentista'],
        'fecha': nuevaFecha,
        'hora': nuevaHora,
        'estado': 'Pendiente',
        'motivo': 'El paciente busca cambiar el horario de cita. Tratamientos: $motivoOriginal',
      });

      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}