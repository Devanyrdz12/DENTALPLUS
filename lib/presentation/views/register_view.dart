import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _rolSeleccionado = 'paciente';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = res.user;

      if (user != null) {
        await supabase.from('usuario').insert({
          'id_usuario': user.id,
          'nombre': _nombreController.text.trim(),
          'rol': _rolSeleccionado,
        });

        if (_rolSeleccionado == 'paciente') {
          await supabase.from('paciente').insert({
            'id_usuario': user.id,
          });
        } else if (_rolSeleccionado == 'dentista') {
          await supabase.from('dentista').insert({
            'id_usuario': user.id,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro completado con éxito.')),
          );
          Navigator.pop(context);
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $error'),
            backgroundColor: Colors.red,
          ),
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
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

        // Sombra oscura
        Container(
          color: Colors.black.withOpacity(0.3),
        ),

        // Formulario
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10,
                  sigmaY: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_add_alt_1,
                          size: 70,
                          color: Colors.teal,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 30),

                        DropdownButtonFormField<String>(
                          value: _rolSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Cuenta',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon:
                                const Icon(Icons.person_outline),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'paciente',
                              child: Text('Paciente'),
                            ),
                            DropdownMenuItem(
                              value: 'dentista',
                              child: Text('Dentista'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _rolSeleccionado = newValue;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.badge),
                          ),
                          validator: (value) =>
                              value != null && value.isEmpty
                                  ? 'Campo requerido'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) =>
                              value != null && value.isEmpty
                                  ? 'Campo requerido'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) =>
                              value != null && value.length < 6
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                        ),

                        const SizedBox(height: 24),

                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _registrarUsuario,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize:
                                      const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Crear Cuenta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
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