import 'package:flutter/material.dart';
import '../viewmodels/paciente_viewmodel.dart';

class PacientesView extends StatefulWidget {
  const PacientesView({super.key});

  @override
  State<PacientesView> createState() => _PacientesViewState();
}

class _PacientesViewState extends State<PacientesView> {
  final PacienteViewModel viewModel = PacienteViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.cargarPacientes();
    viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void mostrarDialogoEditar(dynamic paciente) {
    final telefonoEditar = TextEditingController(text: paciente['telefono']);
    final edadEditar = TextEditingController(text: paciente['edad']?.toString() ?? '');
    final direccionEditar = TextEditingController(text: paciente['direccion']);
    final alergiaEditar = TextEditingController(text: paciente['alergia']);
    final contactoEditar = TextEditingController(text: paciente['contacto_emergencia']);
    
    String sexoEditar = paciente['sexo'] ?? 'Femenino';
    
    final nombrePaciente = paciente['usuario'] != null ? paciente['usuario']['nombre'] : 'Sin nombre';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Editar: $nombrePaciente',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: telefonoEditar,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextField(
                  controller: edadEditar,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Edad'),
                ),
                TextField(
                  controller: direccionEditar,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                TextField(
                  controller: alergiaEditar,
                  decoration: const InputDecoration(labelText: 'Alergia'),
                ),
                TextField(
                  controller: contactoEditar,
                  decoration: const InputDecoration(labelText: 'Contacto emergencia'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sexoEditar,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                    DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      sexoEditar = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await viewModel.editarPaciente(
                  idPaciente: paciente['id_paciente'],
                  telefono: telefonoEditar.text,
                  edad: int.tryParse(edadEditar.text) ?? 0,
                  sexo: sexoEditar,
                  direccion: direccionEditar.text,
                  alergia: alergiaEditar.text,
                  contactoEmergencia: contactoEditar.text,
                  estado: paciente['estado'] ?? 'Activo',
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Pacientes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo compartida
          Image.asset(
            'assets/inicio.jpg',
            fit: BoxFit.cover,
          ),

          // Capa translúcida para mejorar contraste y lectura
          Container(
            color: Colors.white.withOpacity(0.25),
          ),

          SafeArea(
            child: FutureBuilder(
              future: viewModel.cargarPacientes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && viewModel.pacientes.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }

                if (viewModel.pacientes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay pacientes registrados en el sistema.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.pacientes.length,
                  itemBuilder: (context, index) {
                    final paciente = viewModel.pacientes[index];
                    final nombre = paciente['usuario'] != null ? paciente['usuario']['nombre'] : 'Desconocido';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.withOpacity(0.15),
                          radius: 26,
                          child: const Icon(Icons.person, color: Colors.teal, size: 28),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Tel: ${paciente['telefono'] ?? 'N/A'}  |  Edad: ${paciente['edad'] ?? 'N/A'}\nAlergias: ${paciente['alergia'] ?? 'Ninguna'}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.teal),
                              onPressed: () => mostrarDialogoEditar(paciente),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Eliminar Paciente', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text('¿Estás seguro de eliminar a $nombre de la lista?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmar == true) {
                                  await viewModel.borrarPaciente(paciente['id_paciente']);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}