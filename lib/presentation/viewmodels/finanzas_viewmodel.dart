import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanzasViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  List<dynamic> tratamientos = [];
  List<dynamic> historialPagos = [];
  bool isLoading = false;
  String? error;

  Future<void> cargarTratamientos() async {
    try {
      final response = await supabase.from('tratamiento').select().order('nombre');
      tratamientos = response;
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cargarHistorialPagos() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await supabase
          .from('pago')
          .select('*, paciente(usuario(nombre))')
          .order('fecha', ascending: false);
      historialPagos = response;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> procesarCobro({
    required String idPaciente,
    required String concepto,
    required double monto,
    required String estado,
    required String metodoPago,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await supabase.from('pago').insert({
        'id_paciente': idPaciente,
        'monto': monto,
        'concepto': concepto,
        'fecha': DateTime.now().toIso8601String(),
        'metodo_pago': metodoPago,
        'estado': estado, 
      });

      await cargarHistorialPagos();
      return true; 
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false; 
    }
  }

  Future<bool> actualizarEstadoPago(String idPago, String nuevoEstado) async {
    try {
      await supabase.from('pago').update({'estado': nuevoEstado}).eq('id_pago', idPago);
      await cargarHistorialPagos();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // METRICAS DE GANANCIAS RE-BALANCEADAS
  // ==========================================

  // 1. Ganancias en billetes físicos (Efectivo purito)
  double get totalGananciasEfectivo {
    return historialPagos
        .where((p) => p['estado'] == 'Pagado' && p['metodo_pago'] == 'Efectivo')
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['monto'].toString()) ?? 0.0));
  }

  // 2. Ganancias digitales (Pagado con Tarjeta al contado)
  double get totalGananciasTarjeta {
    return historialPagos
        .where((p) => p['estado'] == 'Pagado' && p['metodo_pago'] == 'Tarjeta')
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['monto'].toString()) ?? 0.0));
  }

  // 3. El total de oro 100% asegurado
  double get totalGananciasNetas => totalGananciasEfectivo + totalGananciasTarjeta;

  // 💰 NUEVO: El "Corte" de la App (2.5% de comisión por monetización)
  double get totalComisionesApp => totalGananciasNetas * 0.025;

  // 🧑‍⚕️ NUEVO: Lo que le queda al Dentista tras pagar el impuesto de la plataforma
  double get gananciasDentistaLimpias => totalGananciasNetas - totalComisionesApp;

  // 4. Oro en cooldown (Créditos a meses que aún no caen por completo)
  double get totalAMeses {
    return historialPagos
        .where((p) => p['estado'] == 'Pagado a meses')
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['monto'].toString()) ?? 0.0));
  }

  // 5. Oro en riesgo (Pacientes morosos)
  double get totalCuentasPorCobrar {
    return historialPagos
        .where((p) => p['estado'] == 'Sin pagar')
        .fold(0.0, (sum, p) => sum + (double.tryParse(p['monto'].toString()) ?? 0.0));
  }
}