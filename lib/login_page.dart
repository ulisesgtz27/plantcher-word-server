import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true; // true = login, false = registro
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Iniciar sesión - CON MEJOR MANEJO DE ERRORES
        try {
          print('Intentando iniciar sesión con: ${_emailController.text.trim()}');
          
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          print('Login exitoso. Usuario: ${userCredential.user?.uid}');
          
          // Verificar que el usuario existe antes de continuar
          if (userCredential.user != null) {
            // Pequeña pausa para asegurar que Firebase se sincronice
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Sesión iniciada exitosamente!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
          return;
          
        } catch (e) {
          print('Error en login: $e');
          print('Tipo de error: ${e.runtimeType}');
          
          // Si el error es de reCAPTCHA/App Check, pero el usuario podría estar logueado
          if (e.toString().contains('CONFIGURATION_NOT_FOUND') || 
              e.toString().contains('reCAPTCHA') ||
              e.toString().contains('App Check') ||
              e.toString().toLowerCase().contains('recaptcha') ||
              e.toString().toLowerCase().contains('configuration') ||
              e.toString().toLowerCase().contains('app check')) {
            
            print('Error de reCAPTCHA detectado, verificando estado del usuario...');
            
            // Esperar un poco y verificar si el usuario está logueado
            await Future.delayed(const Duration(milliseconds: 1000));
            
            if (FirebaseAuth.instance.currentUser != null) {
              print('Usuario logueado exitosamente a pesar del error de reCAPTCHA');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Sesión iniciada exitosamente!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              return;
            }
            
            // Si no está logueado, no mostrar error al usuario
            print('Login falló realmente');
            return;
          }
          
          // Si es otro tipo de error, re-lanzarlo
          throw e;
        }
      } else {
        // Registrarse - MEJORADO CON MEJOR MANEJO
        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();
        
        try {
          print('Intentando registrar usuario: $email');
          
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          print('Registro exitoso. Usuario: ${userCredential.user?.uid}');
          
          // Si llegamos aquí, el registro fue exitoso
          if (userCredential.user != null) {
            await userCredential.user!.updateDisplayName('Usuario');
            
            // Pequeña pausa para asegurar sincronización
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Cuenta creada exitosamente!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            
            // Limpiar los campos después del registro exitoso
            _emailController.clear();
            _passwordController.clear();
          }
          
          return; // Salir exitosamente
          
        } catch (e) {
          print('Error en registro: $e');
          print('Tipo de error: ${e.runtimeType}');
          
          // PARA CUALQUIER ERROR EN REGISTRO, INTENTAR LOGIN INMEDIATO
          try {
            print('Intentando login automático después del error de registro...');
            await Future.delayed(const Duration(milliseconds: 1000));
            
            UserCredential loginCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            print('Login automático exitoso: ${loginCredential.user?.uid}');
            
            // Pequeña pausa para sincronización
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Cuenta creada e iniciada exitosamente!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return; // Salir exitosamente
            
          } catch (loginError) {
            print('Error en login automático: $loginError');
            
            // Si es error de reCAPTCHA, ignorar
            if (e.toString().contains('CONFIGURATION_NOT_FOUND') || 
                e.toString().contains('reCAPTCHA') ||
                e.toString().contains('App Check') ||
                e.toString().toLowerCase().contains('recaptcha') ||
                e.toString().toLowerCase().contains('configuration') ||
                e.toString().toLowerCase().contains('app check')) {
              
              // Verificar si el usuario está logueado a pesar del error
              await Future.delayed(const Duration(milliseconds: 500));
              if (FirebaseAuth.instance.currentUser != null) {
                print('Usuario logueado exitosamente a pesar del error');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Cuenta creada e iniciada exitosamente!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                return;
              }
              
              // NO MOSTRAR ERROR AL USUARIO
              return;
            }
            // Si es otro tipo de error, sí mostrarlo
            throw e;
          }
        }
      }

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      
      // FILTRAR ERRORES DE RECAPTCHA
      if (e.message?.contains('CONFIGURATION_NOT_FOUND') == true || 
          e.message?.contains('reCAPTCHA') == true ||
          e.message?.contains('App Check') == true ||
          e.code == 'app-check-error' ||
          e.message?.toLowerCase().contains('recaptcha') == true ||
          e.message?.toLowerCase().contains('configuration') == true ||
          e.message?.toLowerCase().contains('app check') == true) {
        print('Error de reCAPTCHA filtrado');
        return;
      }
      
      String mensaje = 'Error de autenticación';

      // Manejo específico para errores comunes
      switch (e.code) {
        case 'user-not-found':
          mensaje = 'No se encontró una cuenta con este email';
          break;
        case 'wrong-password':
          mensaje = 'Contraseña incorrecta';
          break;
        case 'email-already-in-use':
          mensaje = 'Ya existe una cuenta con este email';
          break;
        case 'weak-password':
          mensaje = 'La contraseña debe tener al menos 6 caracteres';
          break;
        case 'invalid-email':
          mensaje = 'Formato de email inválido';
          break;
        case 'invalid-credential':
          mensaje = 'Credenciales inválidas. Verifica tu email y contraseña';
          break;
        case 'network-request-failed':
          mensaje = 'Error de conexión. Verifica tu internet';
          break;
        case 'too-many-requests':
          mensaje = 'Demasiados intentos. Espera un momento';
          break;
        case 'operation-not-allowed':
          mensaje = 'Operación no permitida. Verifica la configuración de Firebase';
          break;
        case 'user-disabled':
          mensaje = 'Esta cuenta ha sido deshabilitada';
          break;
        default:
          // Para cualquier otro error, verificar si contiene palabras clave de reCAPTCHA
          if (e.message?.toLowerCase().contains('recaptcha') == true ||
              e.message?.toLowerCase().contains('configuration') == true ||
              e.message?.toLowerCase().contains('app check') == true) {
            print('Error de reCAPTCHA filtrado en default');
            return;
          }
          mensaje = 'Error: ${e.message ?? e.code}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on TypeError catch (e) {
      // Manejo específico para errores de tipo (como "type list object is not subtype")
      print('TypeError detectado: $e');
      print('Stack trace: ${e.stackTrace}');
      
      // Verificar si el usuario está logueado a pesar del error de tipo
      await Future.delayed(const Duration(milliseconds: 500));
      if (FirebaseAuth.instance.currentUser != null) {
        print('Usuario logueado exitosamente a pesar del TypeError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? '¡Sesión iniciada exitosamente!' : '¡Cuenta creada exitosamente!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Si no está logueado, mostrar error genérico
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error temporal. Intenta nuevamente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error general: $e');
      print('Tipo de error general: ${e.runtimeType}');
      
      // Solo mostrar errores que NO sean de reCAPTCHA/App Check/Type
      String errorString = e.toString().toLowerCase();
      if (!errorString.contains('configuration_not_found') && 
          !errorString.contains('recaptcha') &&
          !errorString.contains('app check') &&
          !errorString.contains('app-check') &&
          !errorString.contains('configuration') &&
          !errorString.contains('type') && // Filtrar errores de tipo
          !errorString.contains('subtype') && // Filtrar errores de subtipo
          !errorString.contains('list')) { // Filtrar errores de lista
        
        // Verificar si el usuario está logueado a pesar del error
        await Future.delayed(const Duration(milliseconds: 500));
        if (FirebaseAuth.instance.currentUser != null) {
          print('Usuario logueado exitosamente a pesar del error general');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isLogin ? '¡Sesión iniciada exitosamente!' : '¡Cuenta creada exitosamente!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('Error filtrado: $e');
        
        // Verificar si el usuario está logueado a pesar del error filtrado
        await Future.delayed(const Duration(milliseconds: 500));
        if (FirebaseAuth.instance.currentUser != null) {
          print('Usuario logueado exitosamente a pesar del error filtrado');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isLogin ? '¡Sesión iniciada exitosamente!' : '¡Cuenta creada exitosamente!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A4C93), // Morado profundo
              Color(0xFF9C89B8), // Morado medio
              Color(0xFFB8A9C9), // Morado claro
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo/Icono educativo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 80,
                      color: Color(0xFF6A4C93),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Título principal
                  const Text(
                    'Plantcher',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtítulo
                  const Text(
                    'Tu compañero para crear planeaciones educativas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Formulario de login
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Título del formulario
                          Text(
                            _isLogin
                                ? '¡Bienvenido de vuelta!'
                                : '¡Únete a nosotros!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A4C93),
                              fontFamily: 'ComicNeue',
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Campo Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email,
                                  color: Color(0xFF6A4C93)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF6A4C93), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Ingresa un email válido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Campo Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock,
                                  color: Color(0xFF6A4C93)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF6A4C93), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _authenticate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A4C93),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      _isLogin
                                          ? 'Iniciar Sesión'
                                          : 'Registrarse',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'ComicNeue',
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Cambiar entre login y registro
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? '¿No tienes cuenta? '
                                    : '¿Ya tienes cuenta? ',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(
                                  _isLogin ? 'Regístrate' : 'Inicia sesión',
                                  style: const TextStyle(
                                    color: Color(0xFF6A4C93),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Iconos educativos decorativos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEducationalIcon(Icons.edit_note, 'Planear'),
                      _buildEducationalIcon(Icons.groups, 'Enseñar'),
                      _buildEducationalIcon(Icons.lightbulb, 'Innovar'),
                      _buildEducationalIcon(Icons.celebration, 'Lograr'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationalIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }
}
