import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MisTarjetasView extends StatefulWidget {
  const MisTarjetasView({super.key});

  @override
  State<MisTarjetasView> createState() => _MisTarjetasViewState();
}

class _MisTarjetasViewState extends State<MisTarjetasView> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _tarjetas = [];
  bool _isLoading = true;

  final TextEditingController _titularController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _mesController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarTarjetas();
  }

  Future<void> _cargarTarjetas() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final res = await _supabase.from('tarjeta_paciente').select().eq('id_usuario', user.id);
        setState(() { _tarjetas = res; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _agregarTarjeta() async {
    if (_numeroController.text.length < 16 || _titularController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una tarjeta válida de 16 dígitos.')));
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Algoritmo de enmascaramiento de seguridad nativo xd
    final ultimosDigitos = _numeroController.text.substring(_numeroController.text.length - 4);
    final numeroSeguro = "**** **** **** $ultimosDigitos";

    await _supabase.from('tarjeta_paciente').insert({
      'id_usuario': user.id,
      'titular': _titularController.text,
      'numero_enmascarado': numeroSeguro,
      'mes_expira': _mesController.text.padLeft(2, '0'),
      'anio_expira': _anioController.text,
    });

    _titularController.clear();
    _numeroController.clear();
    _mesController.clear();
    _anioController.clear();
    
    Navigator.pop(context);
    setState(() => _isLoading = true);
    _cargarTarjetas();
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Añadir Método de Pago Seguro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
            const SizedBox(height: 16),
            TextField(controller: _titularController, decoration: const InputDecoration(labelText: 'Nombre del Titular', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _numeroController, keyboardType: TextInputType.number, maxLength: 16, decoration: const InputDecoration(labelText: 'Número de Tarjeta', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _mesController, keyboardType: TextInputType.number, maxLength: 2, decoration: const InputDecoration(labelText: 'Mes (MM)', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _anioController, keyboardType: TextInputType.number, maxLength: 2, decoration: const InputDecoration(labelText: 'Año (AA)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _agregarTarjeta,
              child: const Text('Guardar Tarjeta'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Métodos de Pago'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tarjetas.isEmpty
              ? const Center(child: Text('No tienes tarjetas vinculadas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tarjetas.length,
                  itemBuilder: (context, index) {
                    final t = _tarjetas[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.indigo, Colors.blue.shade900]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(alignment: Alignment.topRight, child: Icon(Icons.credit_card, color: Colors.white, size: 32)),
                          const SizedBox(height: 10),
                          Text(t['numero_enmascarado'], style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontFamily: 'monospace')),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TITULAR', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  Text(t['titular'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('EXPIRA', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  Text('${t['mes_expira']}/${t['anio_expira']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add),
      ),
    );
  }
}