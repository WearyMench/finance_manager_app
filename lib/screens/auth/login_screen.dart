import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final biometricAvailable = await authProvider.isBiometricAvailable();
      final biometricEnabled = await authProvider.isBiometricEnabled();

      if (mounted) {
        setState(() {
          _biometricAvailable = biometricAvailable;
          _biometricEnabled = biometricEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
          _biometricEnabled = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Limpiar errores previos
    authProvider.clearError();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Preguntar si quiere habilitar biometría después del login exitoso
      _askForBiometricSetup();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Bienvenido!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted && authProvider.error != null) {
      // Mostrar error específico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _askForBiometricSetup() async {
    if (!_biometricAvailable || _biometricEnabled) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Habilitar autenticación biométrica?'),
        content: const Text(
          'Puedes usar tu huella dactilar o Face ID para iniciar sesión más rápido y de forma segura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.enableBiometric(
                _emailController.text.trim(),
                _passwordController.text,
              );
            },
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithBiometric() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    try {
      final success = await authProvider.loginWithBiometric();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted && authProvider.error != null) {
        // Mostrar error específico de biometría
        String errorMessage = authProvider.error!;

        // Personalizar mensajes de error comunes
        if (errorMessage.contains('fallida') ||
            errorMessage.contains('cancelada')) {
          errorMessage = 'Autenticación biométrica cancelada o fallida';
        } else if (errorMessage.contains('No hay credenciales') ||
            errorMessage.contains('no está configurada')) {
          errorMessage =
              'Primero debes configurar la biometría en Configuración';
        } else if (errorMessage.contains('no está disponible')) {
          errorMessage =
              'La autenticación biométrica no está disponible en este dispositivo';
        } else if (errorMessage.contains('Windows')) {
          errorMessage =
              'La autenticación biométrica no está disponible en Windows. Usa un dispositivo móvil.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Configurar',
              textColor: Colors.white,
              onPressed: () {
                // Navegar a configuración
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and title
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Gestor de Gastos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Login form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Correo electrónico',
                                  hintText: 'tu@email.com',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value.trim())) {
                                    return 'Por favor ingresa un email válido';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                                onChanged: (value) {
                                  // Limpiar errores cuando el usuario empiece a escribir
                                  if (value.isNotEmpty) {
                                    Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).clearError();
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  hintText: 'Tu contraseña',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                onChanged: (value) {
                                  // Limpiar errores cuando el usuario empiece a escribir
                                  if (value.isNotEmpty) {
                                    Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).clearError();
                                  }
                                },
                              ),
                              const SizedBox(height: 24),

                              // Login button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Iniciar Sesión',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Forgot password link
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ForgotPasswordScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      // Botón de autenticación biométrica
                                      if (_biometricEnabled) ...[
                                        const SizedBox(height: 16),
                                        const Text(
                                          'O usa',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),

                                        // Botón de biometría
                                        if (_biometricEnabled)
                                          OutlinedButton.icon(
                                            onPressed: authProvider.isLoading
                                                ? null
                                                : _loginWithBiometric,
                                            icon: Icon(
                                              Icons.fingerprint,
                                              color: _biometricAvailable
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            label: Text(
                                              _biometricAvailable
                                                  ? 'Huella dactilar'
                                                  : 'Biometría no disponible',
                                              style: TextStyle(
                                                color: _biometricAvailable
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              side: BorderSide(
                                                color: _biometricAvailable
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                      ],

                                      // Mostrar error si existe
                                      if (authProvider.error != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  authProvider.error!,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Register link
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_add,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color ??
                                                    Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: '¿No tienes cuenta? ',
                                                ),
                                                TextSpan(
                                                  text: 'Regístrate',
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}
