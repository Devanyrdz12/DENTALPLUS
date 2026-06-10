import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/solicitar_cita_viewmodel.dart';
import '../../services/auth_service.dart';

class SolicitarCitaView extends StatefulWidget {
  const SolicitarCitaView({super.key});

  @override
  State<SolicitarCitaView> createState() => _SolicitarCitaViewState();
}

class _SolicitarCitaViewState extends State<SolicitarCitaView> {
  final SolicitarCitaViewModel _viewModel = SolicitarCitaViewModel();
  
  String? _idDentistaSeleccionado;
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  
  // Aquí guardaremos el "loadout" de tratamientos que elija el usuario
  final List<String> _tratamientosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _viewModel.cargarDatosIniciales().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _horaController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (_idDentistaSeleccionado == null || _fechaController.text.isEmpty || _horaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena la fecha, hora y elige a tu dentista.')),
      );
      return;
    }

    final idUsuario = context.read<AuthService>().currentUser?.id;
    if (idUsuario == null) return;

    final exito = await _viewModel.agendarCita(
      idUsuarioPaciente: idUsuario,
      idDentista: _idDentistaSeleccionado!,
      fecha: _fechaController.text,
      hora: _horaController.text,
      tratamientosSeleccionados: _tratamientosSeleccionados,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cita solicitada con éxito!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Lo devolvemos al lobby tras agendar
    } else if (mounted && _viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_viewModel.error}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Nueva Cita'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _viewModel.isLoading && _viewModel.dentistas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('1. ¿Quién te atenderá?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                    hint: const Text('Selecciona a tu Dentista'),
                    value: _idDentistaSeleccionado,
                    items: _viewModel.dentistas.map((d) {
                      final nombre = d['usuario'] != null ? d['usuario']['nombre'] : 'Dentista';
                      return DropdownMenuItem<String>(
                        value: d['id_dentista'].toString(),
                        child: Text('Dr(a). $nombre'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _idDentistaSeleccionado = val),
                  ),
                  const SizedBox(height: 24),

                  const Text('2. Elige Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fechaController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              _fechaController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _horaController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked != null && context.mounted) {
                              _horaController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('3. ¿Qué tratamientos necesitas?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Puedes seleccionar más de uno.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  
                  // Wrap con FilterChips: el paciente puede marcar y desmarcar opciones
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _viewModel.tratamientos.map((t) {
                      final nombre = t['nombre'] as String;
                      final isSelected = _tratamientosSeleccionados.contains(nombre);
                      return FilterChip(
                        label: Text(nombre),
                        selected: isSelected,
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _tratamientosSeleccionados.add(nombre);
                            } else {
                              _tratamientosSeleccionados.remove(nombre);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _viewModel.isLoading ? null : _enviarSolicitud,
                    child: _viewModel.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Confirmar Cita', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}