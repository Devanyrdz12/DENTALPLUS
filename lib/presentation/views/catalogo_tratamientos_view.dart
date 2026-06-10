import 'package:flutter/material.dart';
import '../viewmodels/finanzas_viewmodel.dart';

class CatalogoTratamientosView extends StatefulWidget {
  const CatalogoTratamientosView({super.key});

  @override
  State<CatalogoTratamientosView> createState() => _CatalogoTratamientosViewState();
}

class _CatalogoTratamientosViewState extends State<CatalogoTratamientosView> {
  final FinanzasViewModel _viewModel = FinanzasViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.cargarTratamientos().then((_) {
      if (mounted) setState(() {});
    });
  }

  // Función optimizada para limpiar acentos y evitar fallos de coincidencia
  String _removerAcentos(String texto) {
    var conAcentos = 'áéíóúüñÁÉÍÓÚÜÑ';
    var sinAcentos = 'aeiouunAEIOUUN';
    for (int i = 0; i < conAcentos.length; i++) {
      texto = texto.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return texto;
  }

  String _obtenerImagenTratamiento(String nombre) {
    // Convertimos a minúsculas, quitamos espacios y removemos acentos
    final nombreLimpio = _removerAcentos(nombre.toLowerCase().trim());

    switch (nombreLimpio) {
      case 'resina (caries)':
      case 'resina':
        return 'assets/tratamientos/resinacaries.png';

      case 'limpieza dental basica':
      case 'limpieza dental':
      case 'limpieza':
        return 'assets/tratamientos/limpieza.jpg';

      case 'extraccion simple':
      case 'extraccion':
        return 'assets/tratamientos/extraccion.jpg';

      case 'blanqueamiento':
      case 'blanqueamiento dental':
        return 'assets/tratamientos/blanqueamiento.png';

      default:
        // Imagen comodín por si se agrega un tratamiento nuevo en la base de datos
        return 'assets/tratamientos/placeholder_dental.png'; 
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Tratamientos'),
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
        child: _construirCuerpo(),
      ),
    );
  }

  Widget _construirCuerpo() {
    if (_viewModel.error != null) {
      return Center(
        child: Text(
          'Error de conexión: ${_viewModel.error}',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_viewModel.tratamientos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.tratamientos.length,
      itemBuilder: (context, index) {
        final tratamiento = _viewModel.tratamientos[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con control de errores integrado
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: Image.asset(
                  _obtenerImagenTratamiento(tratamiento['nombre'] ?? ''),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Si no encuentra el archivo físico en assets, muestra un fondo elegante
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 190,
                      color: Colors.teal.shade50,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: Colors.teal.shade300,
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.teal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tratamiento['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tratamiento Dental Profesional',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${tratamiento['precio'] ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}