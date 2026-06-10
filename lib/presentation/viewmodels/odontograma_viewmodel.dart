import 'package:flutter/material.dart';
import '../../data/repositories/odontograma_repository.dart';

class OdontogramaViewModel extends ChangeNotifier {
  final OdontogramaRepository _repository = OdontogramaRepository();
  List<dynamic> dientes = [];
  bool isLoading = false;
  String? error;

  Future<void> cargarOdontograma(String idPaciente) async {
    isLoading = true;
    notifyListeners();
    try {
      dientes = await _repository.obtenerOdontograma(idPaciente);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarDiente(String idPaciente, int diente, String diagnostico) async {
    isLoading = true;
    notifyListeners();
    try {
      await _repository.guardarDiente(
        idPaciente: idPaciente,
        diente: diente,
        diagnostico: diagnostico,
      );
      await cargarOdontograma(idPaciente);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String obtenerDiagnostico(int diente) {
    // Usamos un ciclo seguro para evitar que Dart se confunda con los tipos de datos nulos
    for (var d in dientes) {
      if (d['diente'] == diente) {
        return d['diagnostico']?.toString() ?? 'Sano';
      }
    }
    return 'Sano'; // Si termina de buscar y no hay datos, el diente está sano
  }
}