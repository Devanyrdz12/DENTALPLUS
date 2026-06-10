import 'package:supabase_flutter/supabase_flutter.dart';

class CitaRepository {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> obtenerCitas() async {
    final response = await supabase
        .from('cita')
        .select('*, paciente(usuario(nombre))')
        .order('fecha', ascending: true);

    return response;
  }

  Future<void> insertarCita({
    required String idPaciente,
    required String idDentista, // Nota: Este es el id_usuario que viene de la sesión
    required String fecha,
    required String hora,
    required String estado,
  }) async {
    // 1. Buscamos el id_dentista real vinculado a este usuario
    final dentistaRes = await supabase
        .from('dentista')
        .select('id_dentista')
        .eq('id_usuario', idDentista)
        .single();
        
    final idDentistaReal = dentistaRes['id_dentista'];

    // 2. Insertamos la cita usando el ID correcto
    await supabase.from('cita').insert({
      'id_paciente': idPaciente,
      'id_dentista': idDentistaReal,
      'fecha': fecha,
      'hora': hora,
      'estado': estado,
    });
  }

  Future<void> eliminarCita(String idCita) async {
    await supabase.from('cita').delete().eq('id_cita', idCita);
  }

  Future<void> actualizarCita({
    required String idCita,
    required String fecha,
    required String hora,
    required String estado,
  }) async {
    await supabase.from('cita').update({
      'fecha': fecha,
      'hora': hora,
      'estado': estado,
    }).eq('id_cita', idCita);
  }
}