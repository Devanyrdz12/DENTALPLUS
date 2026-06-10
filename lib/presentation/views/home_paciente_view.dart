import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class HomePacienteView extends StatelessWidget {
  const HomePacienteView({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/inicio.jpg',
            fit: BoxFit.cover,
          ),

          // Capa oscura
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DentalPlus',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black54,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mi Portal Dental',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                          tooltip: 'Cerrar Sesión',
                          onPressed: () =>
                              context.read<AuthService>().logout(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Tarjeta de bienvenida
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          color: Colors.teal,
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Bienvenido a tu expediente',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Gestiona tus citas, tratamientos y pagos desde un solo lugar.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 1,
                      children: [
                        _buildCard(
                          context,
                          Icons.medical_information,
                          'Tratamientos',
                          '/catalogo',
                        ),
                        _buildCard(
                          context,
                          Icons.calendar_month,
                          'Mis Citas',
                          '/mis_citas',
                        ),
                        _buildCard(
                          context,
                          Icons.monitor_heart,
                          'Mi Odontograma',
                          '/mi_odontograma',
                        ),
                        _buildCard(
                          context,
                          Icons.account_balance_wallet,
                          'Mi Billetera',
                          '/mis_facturas',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (route.isNotEmpty) {
            context.push(route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cargando $title... (Módulo en construcción)',
                ),
              ),
            );
          }
        },
        child: Container(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 42,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}