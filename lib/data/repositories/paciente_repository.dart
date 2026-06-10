import 'package:supabase_flutter/supabase_flutter.dart';

class PacienteRepository {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> obtenerPacientes() async {
    final response = await supabase
        .from('paciente')
        .select('*, usuario(nombre)');

    return response;
  }

  Future<void> insertarPaciente({
    required String idUsuario,
    required String telefono,
    required int edad,
    required String sexo,
    required String direccion,
    required String alergia,
    required String contactoEmergencia,
    required String estado,
  }) async {
    await supabase.from('paciente').update({
      'telefono': telefono,
      'edad': edad,
      'sexo': sexo,
      'direccion': direccion,
      'alergia': alergia,
      'contacto_emergencia': contactoEmergencia,
      'estado': estado,
    }).eq('id_usuario', idUsuario);
  }

  Future<void> eliminarPaciente(String idPaciente) async {
    await supabase
        .from('paciente')
        .delete()
        .eq('id_paciente', idPaciente);
  }

  Future<void> actualizarPaciente({
    required String idPaciente,
    required String telefono,
    required int edad,
    required String sexo,
    required String direccion,
    required String alergia,
    required String contactoEmergencia,
    required String estado,
  }) async {
    await supabase.from('paciente').update({
      'telefono': telefono,
      'edad': edad,
      'sexo': sexo,
      'direccion': direccion,
      'alergia': alergia,
      'contacto_emergencia': contactoEmergencia,
      'estado': estado,
    }).eq('id_paciente', idPaciente);
  }
}