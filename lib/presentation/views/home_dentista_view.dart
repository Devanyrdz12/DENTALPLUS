import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class HomeDentistaView extends StatelessWidget {
  const HomeDentistaView({super.key});

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

          // Capa oscura integrada
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
                            'Panel de Control Médico',
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

                  // Tarjeta de bienvenida institucional
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
                          'Bienvenido de vuelta, Doctor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Gestiona tus pacientes, agenda de citas, odontogramas y contabilidad clínica.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Grid de módulos funcionales del dentista
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 1,
                      children: [
                        _buildCard(
                          context,
                          Icons.people_alt_rounded,
                          'Pacientes',
                          '/pacientes',
                        ),
                        _buildCard(
                          context,
                          Icons.edit_calendar_rounded,
                          'Citas',
                          '/citas',
                        ),
                        _buildCard(
                          context,
                          Icons.monitor_heart_rounded,
                          'Odontograma',
                          '/odontograma',
                        ),
                        _buildCard(
                          context,
                          Icons.account_balance_wallet_rounded,
                          'Finanzas',
                          '/finanzas',
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