import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'services/auth_service.dart';
import 'presentation/views/login_view.dart';
import 'presentation/views/register_view.dart';
import 'presentation/views/home_paciente_view.dart';
import 'presentation/views/home_dentista_view.dart';
import 'presentation/views/pacientes_view.dart';
import 'presentation/views/citas_view.dart';
import 'presentation/views/odontograma_view.dart';
import 'presentation/views/finanzas_view.dart';
import 'presentation/views/catalogo_tratamientos_view.dart';
import 'presentation/views/odontograma_paciente_view.dart';
import 'presentation/views/solicitar_cita_view.dart';
import 'presentation/views/facturas_paciente_view.dart';
import 'presentation/views/citas_paciente_view.dart';
import 'presentation/views/mis_tarjetas_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gvujyrgeyvbfmatclizr.supabase.co',
    anonKey: 'sb_publishable_5U2U_rD-XcSnrb_eI3k1Lw_5a43VuKI',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);

    final GoRouter router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authService,
      redirect: (context, state) {
        final isAuthenticated = authService.isAuthenticated;
        final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!isAuthenticated) {
          return isGoingToAuth ? null : '/login';
        }

        if (isAuthenticated && isGoingToAuth) {
          return authService.userRole == 'dentista' ? '/dentista' : '/paciente';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginView()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterView()),
        GoRoute(path: '/paciente', builder: (context, state) => const HomePacienteView()),
        GoRoute(path: '/dentista', builder: (context, state) => const HomeDentistaView()),
        GoRoute(path: '/pacientes', builder: (context, state) => const PacientesView()),
        GoRoute(path: '/citas', builder: (context, state) => const CitasView()),
        
        // 🛠️ CORREGIDO: Sin 'const' y sin parámetros extras para que use el Dropdown interno
        GoRoute(path: '/odontograma', builder: (context, state) => OdontogramaView()),
        
        GoRoute(path: '/finanzas', builder: (context, state) => const FinanzasView()),
        GoRoute(path: '/catalogo', builder: (context, state) => const CatalogoTratamientosView()),
        GoRoute(path: '/mi_odontograma', builder: (context, state) => const OdontogramaPacienteView()),
        GoRoute(path: '/solicitar_cita', builder: (context, state) => const SolicitarCitaView()),
        GoRoute(path: '/mis_facturas', builder: (context, state) => const FacturasPacienteView()),
        GoRoute(path: '/mis_citas', builder: (context, state) => const CitasPacienteView()),
        GoRoute(path: '/tarjetas', builder: (context, state) => const MisTarjetasView()),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DentalPlus',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF87DAD8),
          primary: const Color(0xFF87DAD8),
          secondary: const Color(0xFF1E293B),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF87DAD8),
            foregroundColor: const Color(0xFF1A1A2E),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF87DAD8), width: 2),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}