import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cita_viewmodel.dart';
import '../../services/auth_service.dart';

class HistorialCitasView extends StatefulWidget {
  const HistorialCitasView({super.key});

  @override
  State<HistorialCitasView> createState() => _HistorialCitasViewState();
}

class _HistorialCitasViewState extends State<HistorialCitasView> {
  final CitaViewModel _viewModel = CitaViewModel();
  List<dynamic> _misCitas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final idUsuario = context.read<AuthService>().currentUser?.id;
    if (idUsuario != null) {
      final res = await _viewModel.obtenerCitasPaciente(idUsuario);
      if (mounted) setState(() { _misCitas = res; _loading = false; });
    }
  }

  void _abrirDialogoReagendar(dynamic cita) {
    final TextEditingController fCtrl = TextEditingController(text: cita['fecha']);
    final TextEditingController hCtrl = TextEditingController(text: cita['hora']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Cambio de Horario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- CAMPO FECHA CON PICKER ---
            TextField(
              controller: fCtrl,
              readOnly: true, // Bloquea el teclado manual
              decoration: const InputDecoration(labelText: 'Nueva Fecha', prefixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context, 
                  initialDate: DateTime.now(), 
                  firstDate: DateTime.now(), 
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  fCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                }
              },
            ),
            const SizedBox(height: 12),
            
            // --- CAMPO HORA CON PICKER ---
            TextField(
              controller: hCtrl,
              readOnly: true, // Bloquea el teclado manual
              decoration: const InputDecoration(labelText: 'Nueva Hora', prefixIcon: Icon(Icons.access_time)),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null && context.mounted) {
                  hCtrl.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loading = true);
              await _viewModel.reagendarDesdePaciente(citaOriginal: cita, nuevaFecha: fCtrl.text, nuevaHora: hCtrl.text);
              await _cargarHistorial();
            },
            child: const Text('Enviar Solicitud'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas'), backgroundColor: Colors.blue),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _misCitas.isEmpty
              ? const Center(child: Text('No tienes registros de citas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _misCitas.length,
                  itemBuilder: (context, index) {
                    final cita = _misCitas[index];
                    final estado = cita['estado'];
                    final dr = cita['dentista'] != null ? cita['dentista']['usuario']['nombre'] : 'Dentista';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('Dr(a). $dr', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('📅 ${cita['fecha']} | ⏰ ${cita['hora']}\nEstado: $estado\n🩺 ${cita['motivo']}'),
                        trailing: (estado == 'Pendiente' || estado == 'Programada')
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Solicitar Reagendar',
                                    onPressed: () => _abrirDialogoReagendar(cita),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Auto-Cancelar Cita',
                                    onPressed: () async {
                                      setState(() => _loading = true);
                                      await _viewModel.cambiarEstadoCita(cita, 'Cancelada');
                                      await _cargarHistorial();
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}