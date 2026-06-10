import 'package:flutter/material.dart';
import 'dart:math'; // <-- LIBRERÍA CRÍTICA PARA LA FÍSICA DEL ARCO
import '../viewmodels/odontograma_viewmodel.dart';
import '../viewmodels/paciente_viewmodel.dart';

class OdontogramaView extends StatefulWidget {
  const OdontogramaView({super.key});

  @override
  State<OdontogramaView> createState() => _OdontogramaViewState();
}

class _OdontogramaViewState extends State<OdontogramaView> {
  final PacienteViewModel _pacienteViewModel = PacienteViewModel();
  final OdontogramaViewModel _odontogramaViewModel = OdontogramaViewModel();

  String? _idPacienteSeleccionado;
  bool _isLoading = true;

  // Orden estandar universal para los dientes
  final List<int> _dientesSuperiores = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  final List<int> _dientesInferiores = [32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17];

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
    _odontogramaViewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _cargarPacientes() async {
    await _pacienteViewModel.cargarPacientes();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pacienteViewModel.dispose();
    _odontogramaViewModel.dispose();
    super.dispose();
  }

  void _seleccionarPaciente(String? idPaciente) {
    if (idPaciente == null) return;
    setState(() {
      _idPacienteSeleccionado = idPaciente;
    });
    _odontogramaViewModel.cargarOdontograma(idPaciente);
  }

  void _mostrarDialogoDiagnostico(int diente) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pieza Dental #$diente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _botonDiagnostico(diente, 'Sano', Colors.green),
              _botonDiagnostico(diente, 'Caries', Colors.red),
              _botonDiagnostico(diente, 'Obturado', Colors.blue),
              _botonDiagnostico(diente, 'Ausente', Colors.grey),
              _botonDiagnostico(diente, 'Corona', Colors.orange),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _botonDiagnostico(int diente, String diagnostico, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 12),
      title: Text(diagnostico),
      onTap: () async {
        if (_idPacienteSeleccionado != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardando diagnóstico...'), duration: Duration(milliseconds: 500)),
          );

          await _odontogramaViewModel.actualizarDiente(
            _idPacienteSeleccionado!,
            diente,
            diagnostico,
          );

          if (mounted && _odontogramaViewModel.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error del Servidor: ${_odontogramaViewModel.error}'), 
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
    );
  }

  Color _obtenerColorDiente(String diagnostico) {
    switch (diagnostico) {
      case 'Caries': return Colors.red;
      case 'Obturado': return Colors.blue;
      case 'Ausente': return Colors.grey;
      case 'Corona': return Colors.orange;
      case 'Sano':
      default: return Colors.white;
    }
  }

  // Widget auxiliar para pintar la barra de leyendas de colores
  Widget _leyenda(String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black87, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  // ==========================================
  // 🦷 MOTOR DE RENDERIZADO DEL ARCO DENTAL (FORMA DE "U" PERFECTA)
  // ==========================================
  Widget _buildArcoDental(List<int> dientes, bool esSuperior) {
    final List<Map<String, double>> posiciones = [
      {'x': 25,  'y': 250, 'angle': -1.57}, // Molar 3 (Acostado horizontal)
      {'x': 25,  'y': 200, 'angle': -1.40}, // Molar 2
      {'x': 30,  'y': 150, 'angle': -1.20}, // Molar 1
      {'x': 45,  'y': 105, 'angle': -0.90}, // Premolar 2
      {'x': 65,  'y': 65,  'angle': -0.60}, // Premolar 1
      {'x': 95,  'y': 35,  'angle': -0.40}, // Canino
      {'x': 130, 'y': 15,  'angle': -0.15}, // Incisivo Lateral
      {'x': 170, 'y': 5,   'angle': -0.05}, // Incisivo Central Izq
      {'x': 210, 'y': 5,   'angle': 0.05},  // Incisivo Central Der
      {'x': 250, 'y': 15,  'angle': 0.15},  // Incisivo Lateral
      {'x': 285, 'y': 35,  'angle': 0.40},  // Canino
      {'x': 315, 'y': 65,  'angle': 0.60},  // Premolar 1
      {'x': 335, 'y': 105, 'angle': 0.90},  // Premolar 2
      {'x': 350, 'y': 150, 'angle': 1.20},  // Molar 1
      {'x': 355, 'y': 200, 'angle': 1.40},  // Molar 2
      {'x': 355, 'y': 250, 'angle': 1.57},  // Molar 3 (Acostado horizontal)
    ];

    return SizedBox(
      width: 420, // Ancho total del lienzo para que no choque con los bordes
      height: 310, // Alto del arco
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(dientes.length, (index) {
          final diente = dientes[index];
          final diagnostico = _odontogramaViewModel.obtenerDiagnostico(diente);
          final color = _obtenerColorDiente(diagnostico);

          final pos = posiciones[index];
          final double posX = pos['x']!;
          final double posY = esSuperior ? pos['y']! : 250 - pos['y']!;
          final double angulo = esSuperior ? pos['angle']! : -pos['angle']!;

          return Positioned(
            left: posX,
            top: posY,
            child: Transform.rotate(
              angle: angulo,
              child: GestureDetector(
                onTap: () => _mostrarDialogoDiagnostico(diente),
                child: Container(
                  width: 36, // Grosor del diente
                  height: 52, // Largo del diente
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Colors.black87, width: 1.5),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(esSuperior ? 8 : 16),
                      bottom: Radius.circular(esSuperior ? 16 : 8),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(2, 2))
                    ]
                  ),
                  child: Center(
                    child: Text(
                      '$diente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color == Colors.white ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odontograma Clínico', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/inicio.jpg'), fit: BoxFit.cover),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Paciente',
                            prefixIcon: Icon(Icons.person, color: Colors.teal),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                          value: _idPacienteSeleccionado,
                          items: _pacienteViewModel.pacientes.map((paciente) {
                            final nombre = paciente['usuario'] != null ? paciente['usuario']['nombre'] : 'Desconocido';
                            return DropdownMenuItem<String>(value: paciente['id_paciente'].toString(), child: Text(nombre));
                          }).toList(),
                          onChanged: _seleccionarPaciente,
                        ),
                      ),
                    ),
                    
                    if (_odontogramaViewModel.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Fallo de conexión: ${_odontogramaViewModel.error}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),

                    if (_odontogramaViewModel.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)),
                      ),

                    if (_idPacienteSeleccionado != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
                          child: Wrap(
                            spacing: 12, runSpacing: 6, alignment: WrapAlignment.center,
                            children: [
                              _leyenda('Sano', Colors.white),
                              _leyenda('Caries', Colors.red),
                              _leyenda('Obturado', Colors.blue),
                              _leyenda('Ausente', Colors.grey),
                              _leyenda('Corona', Colors.orange),
                            ],
                          ),
                        ),
                      ),

                    Expanded(
                      child: _idPacienteSeleccionado == null
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                                child: const Text(
                                  'Selecciona un paciente para cargar la mandíbula interactiva.', 
                                  style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : InteractiveViewer(
                              boundaryMargin: const EdgeInsets.all(80.0),
                              minScale: 0.5,
                              maxScale: 2.5,
                              child: Center(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('MAXILAR SUPERIOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 2, fontSize: 14)),
                                      const SizedBox(height: 10),
                                      _buildArcoDental(_dientesSuperiores, true), 
                                      const SizedBox(height: 50), 
                                      _buildArcoDental(_dientesInferiores, false), 
                                      const SizedBox(height: 10),
                                      const Text('MANDÍBULA INFERIOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 2, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}