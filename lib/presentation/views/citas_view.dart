import 'package:flutter/material.dart';
import '../viewmodels/cita_viewmodel.dart';
import '../widgets/gemini_bot_widget.dart';

class CitasView extends StatefulWidget {
  const CitasView({super.key});

  @override
  State<CitasView> createState() => _CitasViewState();
}

class _CitasViewState extends State<CitasView> {
  final CitaViewModel _viewModel = CitaViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.cargarCitas();
    _viewModel.addListener(() { if (mounted) setState(() {}); });
  }

  void _moderar(dynamic cita, String nuevoEstado, String msg) async {
    final exito = await _viewModel.cambiarEstadoCita(cita, nuevoEstado);
    if (!exito && _viewModel.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_viewModel.error!), backgroundColor: Colors.red));
    } else if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.teal));
    }
  }

  void _abrirDialogoEditar(dynamic cita) {
    final TextEditingController fCtrl = TextEditingController(text: cita['fecha']);
    final TextEditingController hCtrl = TextEditingController(text: cita['hora']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Modificar Cita (Admin)', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10), // Espacio para que la etiqueta flotante no se pegue al título
            TextField(
              controller: fCtrl,
              decoration: InputDecoration(
                labelText: 'Nueva Fecha (YYYY-MM-DD)', 
                labelStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                floatingLabelBehavior: FloatingLabelBehavior.always, // Mantiene la etiqueta ordenada arriba
                prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24), // Espacio amplio entre inputs
            TextField(
              controller: hCtrl,
              decoration: InputDecoration(
                labelText: 'Nueva Hora (HH:MM)', 
                labelStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                floatingLabelBehavior: FloatingLabelBehavior.always, // Mantiene la etiqueta ordenada arriba
                prefixIcon: const Icon(Icons.access_time, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54, fontSize: 16))
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _viewModel.editarHorarioDentista(cita['id_cita'].toString(), fCtrl.text, hCtrl.text);
            },
            child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Control de Citas',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.teal,
          elevation: 4,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'Pendientes'),
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Programadas'),
              Tab(icon: Icon(Icons.cancel_outlined), text: 'Canceladas'),
            ],
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/inicio.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withOpacity(0.4),
            ),
            _viewModel.isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : TabBarView(
                    children: [
                      _buildListaFiltrada('Pendiente'),
                      _buildListaFiltrada('Programada'),
                      _buildListaFiltrada('Cancelada'),
                    ],
                  ),
          ],
        ),
        floatingActionButton: const GeminiBotWidget(isDentist: true),
      ),
    );
  }

  Widget _buildListaFiltrada(String estadoFiltrar) {
    final citasFiltradas = _viewModel.citas.where((c) => c['estado'] == estadoFiltrar).toList();

    if (citasFiltradas.isEmpty) {
      return Center(
        child: Text(
          'No hay citas en este estado.', 
          style: const TextStyle(color: Colors.white70, fontSize: 16)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: citasFiltradas.length,
      itemBuilder: (context, index) {
        final cita = citasFiltradas[index];
        final nombre = (cita['paciente'] != null && cita['paciente']['usuario'] != null)
            ? cita['paciente']['usuario']['nombre'] : 'Anónimo';

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
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              nombre, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '📅 ${cita['fecha']}  |  ⏰ ${cita['hora']}\n🩺 Motivo: ${cita['motivo']}',
                style: const TextStyle(color: Colors.black54, height: 1.3),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (estadoFiltrar == 'Pendiente') ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 28), 
                    onPressed: () => _moderar(cita, 'Programada', 'Cita autorizada')
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 28), 
                    onPressed: () => _moderar(cita, 'Cancelada', 'Cita rechazada')
                  ),
                ],
                if (estadoFiltrar != 'Pendiente') 
                  IconButton(
                    icon: const Icon(Icons.replay_circle_filled_rounded, color: Colors.orange, size: 28),
                    tooltip: 'Regresar a Pendiente',
                    onPressed: () => _moderar(cita, 'Pendiente', 'Cita enviada de vuelta a revisión'),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.teal, size: 26), 
                  onPressed: () => _abrirDialogoEditar(cita),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}