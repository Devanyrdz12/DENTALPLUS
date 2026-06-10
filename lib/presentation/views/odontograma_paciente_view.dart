import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../viewmodels/odontograma_viewmodel.dart';

class OdontogramaPacienteView extends StatefulWidget {
  const OdontogramaPacienteView({super.key});

  @override
  State<OdontogramaPacienteView> createState() => _OdontogramaPacienteViewState();
}

class _OdontogramaPacienteViewState extends State<OdontogramaPacienteView> {
  final OdontogramaViewModel _viewModel = OdontogramaViewModel();
  bool _isLoading = true;
  String? _error;

  final List<int> _dientesSuperiores = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
  ];

  final List<int> _dientesInferiores = [
    32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _cargarDatos() async {
    try {
      final idUsuario = context.read<AuthService>().currentUser?.id;

      if (idUsuario == null) {
        throw Exception("Sesión no encontrada.");
      }

      final res = await Supabase.instance.client
          .from('paciente')
          .select('id_paciente')
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (res == null) {
        throw Exception("No se encontró un perfil de paciente activo.");
      }

      final idPaciente = res['id_paciente'];
      await _viewModel.cargarOdontograma(idPaciente);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Color _obtenerColorDiente(String diagnostico) {
    switch (diagnostico) {
      case 'Caries':
        return Colors.red;
      case 'Obturado':
        return Colors.blue;
      case 'Ausente':
        return Colors.grey;
      case 'Corona':
        return Colors.orange;
      case 'Sano':
      default:
        return Colors.white;
    }
  }

  Widget _mensajeInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: const Text(
        "📌 El odontograma 3D es únicamente para visualización del estado dental del paciente. "
        "La información mostrada está basada en los registros clínicos realizados por el dentista.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _leyenda(String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black87, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildArcoDental(List<int> dientes, bool esSuperior) {
    // Matriz de coordenadas corregida para evitar colapsos visuales
    final List<Map<String, double>> posiciones = [
      {'x': 20, 'y': 240, 'angle': -1.45},
      {'x': 25, 'y': 190, 'angle': -1.25},
      {'x': 35, 'y': 140, 'angle': -1.00},
      {'x': 55, 'y': 95, 'angle': -0.75},
      {'x': 80, 'y': 60, 'angle': -0.50},
      {'x': 110, 'y': 32, 'angle': -0.30},
      {'x': 145, 'y': 15, 'angle': -0.15},
      {'x': 182, 'y': 8, 'angle': -0.05},
      {'x': 218, 'y': 8, 'angle': 0.05},
      {'x': 255, 'y': 15, 'angle': 0.15},
      {'x': 290, 'y': 32, 'angle': 0.30},
      {'x': 320, 'y': 60, 'angle': 0.50},
      {'x': 345, 'y': 95, 'angle': 0.75},
      {'x': 365, 'y': 140, 'angle': 1.00},
      {'x': 375, 'y': 190, 'angle': 1.25},
      {'x': 380, 'y': 240, 'angle': 1.45},
    ];

    return SizedBox(
      width: 430,
      height: 300,
      child: Stack(
        children: List.generate(dientes.length, (index) {
          final diente = dientes[index];
          final diagnostico = _viewModel.obtenerDiagnostico(diente);
          final color = _obtenerColorDiente(diagnostico);

          final pos = posiciones[index];
          final double posX = pos['x']!;
          
          // Ecuación matemática corregida para reflejar el arco de forma simétrica
          final double posY = esSuperior ? pos['y']! : 255 - pos['y']!;
          final double angulo = esSuperior ? pos['angle']! : -pos['angle']!;

          return Positioned(
            left: posX,
            top: posY,
            child: Transform.rotate(
              angle: angulo,
              child: Container(
                width: 34,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.black87, width: 1.2),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(esSuperior ? 6 : 14),
                    bottom: Radius.circular(esSuperior ? 14 : 6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$diente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color == Colors.white ? Colors.black87 : Colors.white,
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
        title: const Text('Mi Odontograma 3D'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/inicio.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.25), // Capa translúcida para mejorar contraste
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)))
                  : SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Bloque de advertencia
                            _mensajeInfo(),

                            // 2. Sección de Leyendas (Flexibles con Wrap)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Wrap(
                                spacing: 14,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _leyenda('Sano', Colors.white),
                                  _leyenda('Caries', Colors.red),
                                  _leyenda('Obturado', Colors.blue),
                                  _leyenda('Ausente', Colors.grey),
                                  _leyenda('Corona', Colors.orange),
                                ],
                              ),
                            ),

                            const Divider(height: 35, indent: 30, endIndent: 30),

                            // 3. Canvas Interactivo Unificado (Scroll + Zoom)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: InteractiveViewer(
                                boundaryMargin: const EdgeInsets.all(20),
                                minScale: 0.8,
                                maxScale: 2.5,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'MAXILAR SUPERIOR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.teal,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildArcoDental(_dientesSuperiores, true),
                                    
                                    // Separador inter-maxilar controlado
                                    const SizedBox(height: 35),

                                    const Text(
                                      'MANDÍBULA INFERIOR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.teal,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildArcoDental(_dientesInferiores, false),
                                    const SizedBox(height: 25),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}