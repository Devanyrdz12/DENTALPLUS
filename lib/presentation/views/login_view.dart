import 'package:flutter/material.dart';
import 'dart:ui'; // Requerido para el efecto de cristal (BackdropFilter)
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _hacerLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AuthService>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso.'), backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un Stack para poner la imagen de fondo y el formulario encima
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CAPA BASE: La imagen de inicio que subiste
          Image.asset(
            'assets/inicio.jpg', // Asegúrate de que la ruta coincida con tu pubspec.yaml
            fit: BoxFit.cover,
          ),
          
          // 2. CAPA DE SOMBRA: Un pequeño oscurecimiento para que la tarjeta resalte
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          // 3. CAPA INTERACTIVA: El formulario centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  // Efecto de cristal difuminado
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85), // Tarjeta blanca casi opaca
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          size: 70,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'DentalPlus',
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        const SizedBox(height: 24),
                        
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _hacerLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: () {
                            context.push('/register');
                          },
                          child: const Text(
                            '¿No tienes cuenta? Regístrate aquí',
                            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}   