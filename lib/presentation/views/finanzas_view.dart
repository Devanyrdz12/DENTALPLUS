import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../viewmodels/finanzas_viewmodel.dart';
import '../viewmodels/paciente_viewmodel.dart';

class FinanzasView extends StatefulWidget {
  const FinanzasView({super.key});

  @override
  State<FinanzasView> createState() => _FinanzasViewState();
}

class _FinanzasViewState extends State<FinanzasView> {
  final PacienteViewModel _pacienteVM = PacienteViewModel();
  final FinanzasViewModel _finanzasVM = FinanzasViewModel();

  String? _idPacienteSeleccionado;
  String _metodoPagoSeleccionado = 'Efectivo';
  String _estadoPagoSeleccionado = 'Pagado';
  
  final List<Map<String, dynamic>> _carrito = [];
  final TextEditingController _nombreCustomController = TextEditingController();
  final TextEditingController _precioCustomController = TextEditingController();

  // Color Azul Agua Global para consistencia
  final Color _azulAgua = const Color.fromARGB(255, 0, 134, 120); 

  double get _montoTotal {
    return _carrito.fold(0.0, (sum, item) => sum + (item['precio'] ?? 0.0));
  }

  void _onFinanzasVMChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _pacienteVM.cargarPacientes().then((_) { if (mounted) setState(() {}); });
    _finanzasVM.cargarTratamientos().then((_) { if (mounted) setState(() {}); });
    _finanzasVM.cargarHistorialPagos();
    _finanzasVM.addListener(_onFinanzasVMChanged);
  }

  @override
  void dispose() {
    _finanzasVM.removeListener(_onFinanzasVMChanged);
    _nombreCustomController.dispose();
    _precioCustomController.dispose();
    super.dispose();
  }

  void _agregarPersonalizadoAlCarrito() {
    if (_nombreCustomController.text.isEmpty || _precioCustomController.text.isEmpty) return;
    final double precio = double.tryParse(_precioCustomController.text) ?? 0.0;
    setState(() {
      _carrito.add({'nombre': _nombreCustomController.text, 'precio': precio});
      _nombreCustomController.clear();
      _precioCustomController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _ejecutarCobro() async {
    if (_idPacienteSeleccionado == null || _carrito.isEmpty) return;

    if (_metodoPagoSeleccionado == 'Tarjeta') {
      try {
        final listaPacientes = _pacienteVM.pacientes.where(
          (p) => p['id_paciente'].toString() == _idPacienteSeleccionado,
        ).toList();

        if (listaPacientes.isEmpty) return;

        final pacienteData = listaPacientes.first;

        final idUsuarioPaciente = pacienteData['id_usuario'] ?? 
                                 (pacienteData['usuario'] != null ? pacienteData['usuario']['id'] : null);

        if (idUsuarioPaciente == null) {
          if (!mounted) return; 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error Crítico: No se detectó credencial de usuario vinculada a este expediente.'), backgroundColor: Colors.red),
          );
          return;
        }

        final List<dynamic> responseTarjetas = await Supabase.instance.client
            .from('tarjeta_paciente')
            .select()
            .eq('id_usuario', idUsuarioPaciente);

        if (!mounted) return;

        if (responseTarjetas.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(Icons.credit_card_off, color: _azulAgua, size: 48),
              title: const Text('Sin Método de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('Este usuario no cuenta con una tarjeta registrada en su billetera digital. Por favor, pida al paciente que agregue una tarjeta desde su aplicación antes de cobrar por este medio.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text('Entendido', style: TextStyle(color: _azulAgua, fontWeight: FontWeight.bold))
                ),
              ],
            ),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el Firewall de pagos: $e'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final String conceptoUnido = jsonEncode(_carrito);

    final exito = await _finanzasVM.procesarCobro(
      idPaciente: _idPacienteSeleccionado!,
      concepto: conceptoUnido,
      monto: _montoTotal,
      estado: _estadoPagoSeleccionado,
      metodoPago: _metodoPagoSeleccionado,
    );

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Cobro registrado con $_metodoPagoSeleccionado!'), backgroundColor: Colors.teal),
      );
      setState(() {
        _carrito.clear();
        _estadoPagoSeleccionado = 'Pagado';
        _metodoPagoSeleccionado = 'Efectivo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas y Cobros', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _azulAgua,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'Nuevo Cobro'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Registro de Pagos'),
              Tab(icon: Icon(Icons.analytics), text: 'Ganancias'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/inicio.jpg'), fit: BoxFit.cover),
          ),
          child: Container(
            color: Colors.black.withOpacity(0.4), 
            child: TabBarView(
              children: [
                _buildTabNuevoCobro(),
                _buildTabHistorial(),
                _buildTabGanancias(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNuevoCobro() {
    final opcionesEstado = _metodoPagoSeleccionado == 'Efectivo'
        ? ['Pagado', 'Sin pagar']
        : ['Pagado', 'Sin pagar', 'Pagado a meses'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // UNIFICADO: Un solo contenedor blanco estilizado para todo el formulario
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selección de Paciente
                Text('1. Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _azulAgua.withOpacity(0.9))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.person, color: _azulAgua)
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  value: _idPacienteSeleccionado,
                  hint: const Text('Selecciona un paciente'),
                  items: _pacienteVM.pacientes.map((paciente) {
                    final nombre = (paciente['usuario'] != null) ? paciente['usuario']['nombre'] : 'Desconocido';
                    return DropdownMenuItem<String>(value: paciente['id_paciente'].toString(), child: Text(nombre));
                  }).toList(),
                  onChanged: (val) => setState(() => _idPacienteSeleccionado = val),
                ),
                const Divider(height: 32, thickness: 1),

                // 2. Catálogo de Tratamientos
                Text('2. Catálogo Base o Personalizado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _azulAgua.withOpacity(0.9))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: _finanzasVM.tratamientos.map((t) {
                    final isSelected = _carrito.any((item) => item['nombre'] == t['nombre']);
                    return FilterChip(
                      label: Text('${t['nombre']} (\$${t['precio']})', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                      selected: isSelected,
                      selectedColor: _azulAgua.withOpacity(0.25),
                      checkmarkColor: _azulAgua,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _carrito.add({'nombre': t['nombre'], 'precio': (t['precio'] as num).toDouble()});
                          } else {
                            _carrito.removeWhere((item) => item['nombre'] == t['nombre']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                
                // Campos personalizados embebidos dentro de la sección
                Row(
                  children: [
                    Expanded(flex: 2, child: TextField(controller: _nombreCustomController, decoration: InputDecoration(labelText: 'Otro Tratamiento', isDense: true, labelStyle: TextStyle(color: Colors.grey.shade600), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _azulAgua.withOpacity(0.5)))))),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: TextField(controller: _precioCustomController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Precio \$', isDense: true, labelStyle: TextStyle(color: Colors.grey.shade600), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _azulAgua.withOpacity(0.5)))))),
                    IconButton(icon: Icon(Icons.add_circle, color: _azulAgua, size: 36), onPressed: _agregarPersonalizadoAlCarrito),
                  ],
                ),
                
                // Chips de conceptos seleccionados en el carrito actual
                if (_carrito.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _carrito.map((item) => InputChip(
                        backgroundColor: Colors.white,
                        deleteIconColor: Colors.red.shade400,
                        label: Text(item['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), 
                        onDeleted: () => setState(() => _carrito.remove(item))
                      )).toList(),
                    ),
                  ),
                ],
                const Divider(height: 32, thickness: 1),

                // 3. Método de Pago
                Text('3. Método de Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _azulAgua.withOpacity(0.9))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.credit_card, color: _azulAgua)
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  value: _metodoPagoSeleccionado,
                  items: ['Efectivo', 'Tarjeta'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _metodoPagoSeleccionado = val!;
                      if (_metodoPagoSeleccionado == 'Efectivo' && _estadoPagoSeleccionado == 'Pagado a meses') {
                        _estadoPagoSeleccionado = 'Pagado';
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 4. Estado de Cobro
                Text('4. Estado del Cobro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _azulAgua.withOpacity(0.9))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.rule, color: _azulAgua)
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  value: _estadoPagoSeleccionado,
                  items: opcionesEstado.map((estado) => DropdownMenuItem(value: estado, child: Text(estado))).toList(),
                  onChanged: (val) => setState(() => _estadoPagoSeleccionado = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón de Cobrar Principal (Afuera de la tarjeta unificada)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16), 
              backgroundColor: _azulAgua, 
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            ),
            onPressed: _finanzasVM.isLoading ? null : _ejecutarCobro,
            icon: const Icon(Icons.point_of_sale, size: 24),
            label: Text('Cobrar TOTAL: \$${_montoTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHistorial() {
    if (_finanzasVM.isLoading && _finanzasVM.historialPagos.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }
    if (_finanzasVM.historialPagos.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
          child: const Text('No hay registros de pagos aún.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _finanzasVM.historialPagos.length,
      itemBuilder: (context, index) {
        final pago = _finanzasVM.historialPagos[index];
        final id = pago['id_pago'].toString();
        
        final nombrePaciente = (pago['paciente'] != null && pago['paciente']['usuario'] != null) 
            ? pago['paciente']['usuario']['nombre'] 
            : 'Paciente Anónimo';
            
        final estado = pago['estado'];
        final metodo = pago['metodo_pago'] ?? 'No esp.';
        
        return Card(
          color: Colors.white.withOpacity(0.95),
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(nombrePaciente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text(
              'Concepto: ${pago['concepto'].toString().startsWith('[') ? "Combo de Tratamientos 🛒" : (pago['concepto'] ?? 'N/A')}\nVia: $metodo | Estado: $estado',
              style: const TextStyle(color: Colors.black54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\$${pago['monto']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: estado == 'Pagado' ? Colors.teal : Colors.orange.shade800)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  color: Colors.white,
                  onSelected: (nuevoEstado) async {
                    await _finanzasVM.actualizarEstadoPago(id, nuevoEstado);
                    if (mounted) setState(() {});
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Pagado', child: Text('Marcar como Pagado')),
                    const PopupMenuItem(value: 'Pagado a meses', child: Text('Marcar como Pagado a meses')),
                    const PopupMenuItem(value: 'Sin pagar', child: Text('Marcar como Sin pagar')),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabGanancias() {
    if (_finanzasVM.isLoading && _finanzasVM.historialPagos.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }

    final totalNeto = _finanzasVM.totalGananciasNetas;
    final totalEfectivo = _finanzasVM.totalGananciasEfectivo;
    final totalTarjeta = _finanzasVM.totalGananciasTarjeta;
    final totalMeses = _finanzasVM.totalAMeses;
    final totalDeuda = _finanzasVM.totalCuentasPorCobrar;
    
    final comisionesApp = _finanzasVM.totalComisionesApp;
    final gananciasLimpiasDentista = _finanzasVM.gananciasDentistaLimpias;
    
    final totalFacturado = totalNeto + totalMeses + totalDeuda;
    final ratioCobro = totalFacturado > 0 ? (totalNeto / totalFacturado) : 1.0;

    final ingresosRecientes = _finanzasVM.historialPagos
        .where((p) => p['estado'] == 'Pagado')
        .take(3)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumen Financiero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),

          Card(
            color: _azulAgua.withOpacity(0.95),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white24, radius: 24, child: Icon(Icons.attach_money, color: Colors.white, size: 30)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Facturación Bruta (Caja + Banco)', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                          Text('\$${totalNeto.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      )
                    ],
                  ),
                  const Divider(color: Colors.white30, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(children: [const Icon(Icons.money, color: Colors.white70, size: 16), const SizedBox(width: 4), Text('Efectivo: \$${totalEfectivo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                      Row(children: [const Icon(Icons.credit_card, color: Colors.white70, size: 16), const SizedBox(width: 4), Text('Tarjeta: \$${totalTarjeta.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            color: Colors.amber.shade800.withOpacity(0.95), 
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white24, radius: 22, child: Icon(Icons.storefront, color: Colors.white, size: 24)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comisiones de la App (2.5%)', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                          Text('\$${comisionesApp.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      )
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ganancia Limpia Dental:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('\$${gananciasLimpiasDentista.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            color: Colors.indigo.shade600.withOpacity(0.95),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.white24, radius: 22, child: Icon(Icons.hourglass_bottom, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dinero en Plazos (A Meses)', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                      Text('\$${totalMeses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            color: Colors.orange.shade800.withOpacity(0.95),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.white24, radius: 22, child: Icon(Icons.money_off, color: Colors.white, size: 24)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cuentas por Cobrar (Deuda)', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                      Text('\$${totalDeuda.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Efectividad de Recaudación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Liquidez actual:', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                    Text('${(ratioCobro * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: ratioCobro.isNaN ? 0.0 : ratioCobro,
                  backgroundColor: Colors.grey.shade300,
                  color: _azulAgua,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Text('Proporción del monto cobrado por completo vs el retenido a meses o en deuda.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic), textAlign: TextAlign.center)
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Últimos Cobros Liquidados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 10),
          if (ingresosRecientes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No hay ingresos en este periodo.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500))),
            )
          else
            ...ingresosRecientes.map((p) {
              final paciente = (p['paciente'] != null && p['paciente']['usuario'] != null)
                  ? p['paciente']['usuario']['nombre'] : 'Anónimo';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.arrow_upward, color: Colors.teal),
                  title: Text(paciente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  subtitle: Text("${p['fecha'] != null ? p['fecha'].toString().split('T')[0] : ''} - Vía: ${p['metodo_pago'] ?? ''}", style: const TextStyle(color: Colors.black54)),
                  trailing: Text('+\$${p['monto']}', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}