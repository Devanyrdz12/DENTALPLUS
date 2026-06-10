import 'package:flutter/material.dart';
import '../../data/repositories/paciente_repository.dart';

class PacienteViewModel extends ChangeNotifier {
  final PacienteRepository repository = PacienteRepository();
  List<dynamic> pacientes = [];

  Future<void> cargarPacientes() async {
    pacientes = await repository.obtenerPacientes();
    notifyListeners();
  }

  Future<void> agregarPaciente({
    required String idUsuario,
    required String telefono,
    required int edad,
    required String sexo,
    required String direccion,
    required String alergia,
    required String contactoEmergencia,
    required String estado,
  }) async {
    await repository.insertarPaciente(
      idUsuario: idUsuario,
      telefono: telefono,
      edad: edad,
      sexo: sexo,
      direccion: direccion,
      alergia: alergia,
      contactoEmergencia: contactoEmergencia,
      estado: estado,
    );
    await cargarPacientes();
  }

  Future<void> borrarPaciente(String idPaciente) async {
    await repository.eliminarPaciente(idPaciente);
    await cargarPacientes();
  }

  Future<void> editarPaciente({
    required String idPaciente,
    required String telefono,
    required int edad,
    required String sexo,
    required String direccion,
    required String alergia,
    required String contactoEmergencia,
    required String estado,
  }) async {
    await repository.actualizarPaciente(
      idPaciente: idPaciente,
      telefono: telefono,
      edad: edad,
      sexo: sexo,
      direccion: direccion,
      alergia: alergia,
      contactoEmergencia: contactoEmergencia,
      estado: estado,
    );
    await cargarPacientes();
  }
}