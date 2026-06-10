class PacienteModel {

  final String idPaciente;
  final String telefono;
  final int edad;
  final String sexo;
  final String direccion;
  final String alergia;
  final String contactoEmergencia;
  final String estado;

  PacienteModel({
    required this.idPaciente,
    required this.telefono,
    required this.edad,
    required this.sexo,
    required this.direccion,
    required this.alergia,
    required this.contactoEmergencia,
    required this.estado,
  });

  factory PacienteModel.fromJson(Map<String, dynamic> json) {

    return PacienteModel(
      idPaciente: json['id_paciente'] ?? '',
      telefono: json['telefono'] ?? '',
      edad: json['edad'] ?? 0,
      sexo: json['sexo'] ?? '',
      direccion: json['direccion'] ?? '',
      alergia: json['alergia'] ?? '',
      contactoEmergencia: json['contacto_emergencia'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {

    return {
      'telefono': telefono,
      'edad': edad,
      'sexo': sexo,
      'direccion': direccion,
      'alergia': alergia,
      'contacto_emergencia': contactoEmergencia,
      'estado': estado,
    };
  }
}