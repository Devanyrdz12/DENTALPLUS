import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../viewmodels/facturas_paciente_viewmodel.dart';
import '../../services/auth_service.dart';

class FacturasPacienteView extends StatefulWidget {
  const FacturasPacienteView({super.key});

  @override
  State<FacturasPacienteView> createState() => _FacturasPacienteViewState();
}

class _FacturasPacienteViewState extends State<FacturasPacienteView> {
  final FacturasPacienteViewModel _viewModel = FacturasPacienteViewModel();
  bool _isGeneratingPdf = false;

  final _supabase = Supabase.instance.client;
  List<dynamic> _tarjetas = [];
  bool _isLoadingTarjetas = true;

  final TextEditingController _titularController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _mesController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final idUsuario = context.read<AuthService>().currentUser?.id;

    if (idUsuario != null) {
      _viewModel.cargarFacturas(idUsuario).then((_) {
        if (mounted) {
          setState(() {
            // Fuerza el redibujado de la interfaz con los datos cargados del ViewModel
          });
        }
      });
    }

    _cargarTarjetas();
  }

  @override
  void dispose() {
    // Quitamos _viewModel.dispose() ya que ChangeNotifier se maneja de forma automática
    _titularController.dispose();
    _numeroController.dispose();
    _mesController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  // =========================
  // TARJETAS
  // =========================
  Future<void> _cargarTarjetas() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final res = await _supabase
            .from('tarjeta_paciente')
            .select()
            .eq('id_usuario', user.id);

        if (mounted) {
          setState(() {
            _tarjetas = res;
            _isLoadingTarjetas = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTarjetas = false);
      }
    }
  }

  Future<void> _agregarTarjeta() async {
    if (_numeroController.text.length < 16 ||
        _titularController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarjeta inválida')),
      );
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final ultimos = _numeroController.text.substring(
      _numeroController.text.length - 4,
    );

    await _supabase.from('tarjeta_paciente').insert({
      'id_usuario': user.id,
      'titular': _titularController.text,
      'numero_enmascarado': "**** **** **** $ultimos",
      'mes_expira': _mesController.text.padLeft(2, '0'),
      'anio_expira': _anioController.text,
    });

    _titularController.clear();
    _numeroController.clear();
    _mesController.clear();
    _anioController.clear();

    Navigator.pop(context);
    _cargarTarjetas();
  }

  void _abrirFormularioTarjeta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Añadir Tarjeta',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titularController,
              decoration: const InputDecoration(labelText: 'Titular de la Tarjeta'),
            ),
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Número de Tarjeta', counterText: ""),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mesController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: const InputDecoration(labelText: 'Mes (MM)', counterText: ""),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _anioController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: const InputDecoration(labelText: 'Año (AA)', counterText: ""),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _agregarTarjeta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Guardar Tarjeta", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI TARJETAS
  // =========================
  Widget _buildTabTarjetas() {
    return Stack(
      children: [
        // FONDO INSTITUCIONAL
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/inicio.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // CAPA TRANSLÚCIDA
        Container(
          color: Colors.white.withOpacity(0.25),
          child: _isLoadingTarjetas
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _tarjetas.isEmpty
                  ? const Center(
                      child: Text(
                        "No tienes tarjetas registradas",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tarjetas.length,
                      itemBuilder: (context, i) {
                        final t = _tarjetas[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade600,
                                Colors.teal.shade800,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.credit_card, color: Colors.white, size: 30),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                                    onPressed: () async {
                                      await _supabase
                                          .from('tarjeta_paciente')
                                          .delete()
                                          .eq('id_tarjeta', t['id_tarjeta']);

                                      _cargarTarjetas();
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                t['numero_enmascarado'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('TITULAR', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                                        Text(
                                          t['titular'].toString().toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('EXPIRA', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                                      Text(
                                        "${t['mes_expira']}/${t['anio_expira']}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // BOTÓN AGREGAR
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            onPressed: _abrirFormularioTarjeta,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }

  // ===================================
  // LOGICA DE IMPRESIÓN/PDF
  // ===================================
  Future<void> _imprimirFactura(Map<String, dynamic> factura) async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      final numero = factura['id_pago'] ?? factura['numero_factura'] ?? 'S/N';
      final total = factura['monto'] ?? factura['total'] ?? '0.00';
      final fecha = factura['fecha'] ?? 'Sin fecha';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("COMPROBANTE DE FACTURACIÓN", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2, color: PdfColors.teal),
                  pw.SizedBox(height: 20),
                  pw.Text("Detalles del Servicio:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text("Folio / Pago: #$numero"),
                  pw.Text("Fecha de Emisión: $fecha"),
                  pw.Text("Moneda: MXN"),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("TOTAL A PAGAR:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text("\$$total", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  pw.Center(child: pw.Text("¡Gracias por su confianza!", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey))),
                ],
              ),
            );
          },
        ),
      );

     await Printing.sharePdf(
     bytes: await pdf.save(),
     filename: 'Factura_$numero.pdf',
);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ===============================
  // UI FACTURAS
  // ===============================
  Widget _buildTabFacturas() {
    final facturas = _viewModel.pagos;

    return Stack(
      children: [
        // FONDO INSTITUCIONAL
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/inicio.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // CAPA TRANSLÚCIDA
        Container(
          color: Colors.white.withOpacity(0.25),
          child: facturas.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes facturas registradas",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: facturas.length,
                  itemBuilder: (context, i) {
                    final f = facturas[i];

                    final numero = f['id_pago'] ?? f['numero_factura'] ?? 'S/N';
                    final total = f['monto'] ?? f['total'] ?? '0.00';
                    final fecha = f['fecha'] ?? 'Sin fecha';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.receipt_long, color: Colors.white),
                        ),
                        title: Text(
                          'Factura #$numero',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Fecha: $fecha\nTotal: \$$total'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                          onPressed: () => _imprimirFactura(f),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================
  // UI GENERAL
  // =========================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Billetera'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Facturas"),
              Tab(text: "Tarjetas"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabFacturas(),
            _buildTabTarjetas(),
          ],
        ),
      ),
    );
  }
}