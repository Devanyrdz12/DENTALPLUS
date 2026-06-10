import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OdontogramaRepository {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> obtenerOdontograma(String idPaciente) async {
    try {
      return await supabase
          .from('odontograma')
          .select()
          .eq('id_paciente', idPaciente)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw Exception('Error al obtener odontograma: $e');
    }
  }

  Future<void> guardarDiente({
    required String idPaciente,
    required int diente,
    required String diagnostico,
  }) async {
    try {
      // 1. Hacemos un escaneo rápido para ver si el diente ya está en el inventario
      final existente = await supabase
          .from('odontograma')
          .select('id_odontograma')
          .eq('id_paciente', idPaciente)
          .eq('diente', diente)
          .maybeSingle();

      if (existente != null) {
        // 2. Si ya existe, aplicamos un update rápido usando su ID
        await supabase
            .from('odontograma')
            .update({'diagnostico': diagnostico})
            .eq('id_odontograma', existente['id_odontograma'])
            .timeout(const Duration(seconds: 5));
      } else {
        // 3. Si es la primera vez que tocamos este diente, lo insertamos
        await supabase.from('odontograma').insert({
          'id_paciente': idPaciente,
          'diente': diente,
          'diagnostico': diagnostico,
        }).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      throw Exception('Error al guardar diente: $e');
    }
  }
}