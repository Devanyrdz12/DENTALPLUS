import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cita_viewmodel.dart';
import '../viewmodels/solicitar_cita_viewmodel.dart';
import '../../services/auth_service.dart';
import '../widgets/gemini_bot_widget.dart';

class CitasPacienteView extends StatefulWidget {
  const CitasPacienteView({super.key});

  @override
  State<CitasPacienteView> createState() => _CitasPacienteViewState();
}

class _CitasPacienteViewState extends State<CitasPacienteView> {
  final CitaViewModel _citaVM = CitaViewModel();
  final SolicitarCitaViewModel _solicitarVM = SolicitarCitaViewModel();

  List<dynamic> _misCitas = [];
  bool _loadingCitas = true;

  String? _idDentistaSeleccionado;
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final List<String> _tratamientosSeleccionados = [];

  bool _mostrarCampoPersonalizado = false;
  final TextEditingController _motivoCustomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
    _solicitarVM.cargarDatosIniciales().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _horaController.dispose();
    _motivoCustomController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    final idUsuario = context.read<AuthService>().currentUser?.id;
    if (idUsuario != null) {
      final res = await _citaVM.obtenerCitasPaciente(idUsuario);
      if (mounted) {
        setState(() {
          _misCitas = res;
          _loadingCitas = false;
        });
      }
    }
  }

  void _abrirDialogoReagendar(dynamic cita) {
    final fCtrl = TextEditingController(text: cita['fecha']);
    final hCtrl = TextEditingController(text: cita['hora']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reagendar cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Fecha'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                  initialDate: DateTime.now(),
                );
                if (picked != null) {
                  fCtrl.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                }
              },
            ),
            TextField(
              controller: hCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Hora'),
              onTap: () async {
                final picked =
                    await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) {
                  hCtrl.text =
                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loadingCitas = true);
              await _citaVM.reagendarDesdePaciente(
                citaOriginal: cita,
                nuevaFecha: fCtrl.text,
                nuevaHora: hCtrl.text,
              );
              await _cargarHistorial();
            },
            child: const Text('Enviar'),
          )
        ],
      ),
    );
  }

  Future<void> _enviarSolicitudNueva(TabController tabController) async {
    final idUsuario = context.read<AuthService>().currentUser?.id;

    if (_idDentistaSeleccionado == null ||
        _fechaController.text.isEmpty ||
        _horaController.text.isEmpty ||
        idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final ok = await _solicitarVM.agendarCita(
      idUsuarioPaciente: idUsuario,
      idDentista: _idDentistaSeleccionado!,
      fecha: _fechaController.text,
      hora: _horaController.text,
      tratamientosSeleccionados: _tratamientosSeleccionados,
      motivoPersonalizado:
          _mostrarCampoPersonalizado ? _motivoCustomController.text : null,
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita enviada'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _fechaController.clear();
        _horaController.clear();
        _motivoCustomController.clear();
        _tratamientosSeleccionados.clear();
        _idDentistaSeleccionado = null;
        _mostrarCampoPersonalizado = false;
      });

      await _cargarHistorial();
      tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi Agenda Dental'),
              backgroundColor:  Colors.teal,
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.calendar_month), text: 'Mis Citas'),
                  Tab(icon: Icon(Icons.add), text: 'Agendar'),
                ],
              ),
            ),

            // 🔥 FONDO IGUAL QUE CATÁLOGO
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/inicio.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: TabBarView(
                children: [
                  _buildMisCitas(),
                  _buildAgendar(tabController),
                ],
              ),
            ),

            floatingActionButton:
                const GeminiBotWidget(isDentist: false),
          );
        },
      ),
    );
  }

  // ================= MIS CITAS =================
  Widget _buildMisCitas() {
    if (_loadingCitas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_misCitas.isEmpty) {
      return const Center(child: Text('No tienes citas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _misCitas.length,
      itemBuilder: (context, i) {
        final c = _misCitas[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            title: Text('Dr(a). ${c['dentista']['usuario']['nombre']}'),
            subtitle: Text('${c['fecha']} - ${c['hora']}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _abrirDialogoReagendar(c),
            ),
          ),
        );
      },
    );
  }

  // ================= AGENDAR =================
  Widget _buildAgendar(TabController tabController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agendar Cita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _idDentistaSeleccionado,
              items: _solicitarVM.dentistas.map((d) {
                return DropdownMenuItem(
                  value: d['id_dentista'].toString(),
                  child: Text(d['usuario']['nombre']),
                );
              }).toList(),
              onChanged: (v) =>
                  setState(() => _idDentistaSeleccionado = v),
              decoration: const InputDecoration(
                labelText: 'Dentista',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _fechaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                  initialDate: DateTime.now(),
                );
                if (p != null) {
                  _fechaController.text =
                      "${p.year}-${p.month}-${p.day}";
                }
              },
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _horaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Hora',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final p = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now());
                if (p != null) {
                  _horaController.text =
                      "${p.hour}:${p.minute}";
                }
              },
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              children: _solicitarVM.tratamientos
                  .map((t) => FilterChip(
                        label: Text(t['nombre']),
                        selected: _tratamientosSeleccionados
                            .contains(t['nombre']),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _tratamientosSeleccionados
                                  .add(t['nombre']);
                            } else {
                              _tratamientosSeleccionados
                                  .remove(t['nombre']);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () =>
                  _enviarSolicitudNueva(tabController),
              child: const Text('Confirmar Cita'),
            )
          ],
        ),
      ),
    );
  }
}