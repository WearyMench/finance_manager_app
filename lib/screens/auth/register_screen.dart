import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedCurrency = 'USD';

  final Map<String, String> _currencies = {
    'USD': 'Dólar Americano (\$)',
    'EUR': 'Euro (€)',
    'MXN': 'Peso Mexicano (\$)',
    'COP': 'Peso Colombiano (\$)',
    'DOP': 'Peso Dominicano (RD\$)',
  };

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar los términos y condiciones para continuar',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      currency: _selectedCurrency,
    );

    if (success && mounted) {
      // Navegar a la pantalla de verificación de email
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              EmailVerificationScreen(email: _emailController.text.trim()),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Error al registrarse'),
          backgroundColor: Colors.red,
        ),
      );
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
                          Icons.person_add,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Crear Cuenta',
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
                        'Únete a nuestra plataforma de gestión financiera',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Register form
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
                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre completo',
                                  hintText: 'Tu nombre',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu nombre';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'El nombre debe tener al menos 2 caracteres';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),

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
                                  ).hasMatch(value)) {
                                    return 'Por favor ingresa un email válido';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),

                              // Currency field
                              DropdownButtonFormField<String>(
                                value: _selectedCurrency,
                                decoration: InputDecoration(
                                  labelText: 'Moneda',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                items: _currencies.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCurrency = value;
                                    });
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
                                  hintText:
                                      'Mínimo 8 caracteres con mayúsculas, números y símbolos',
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
                                    return 'Por favor ingresa una contraseña';
                                  }
                                  if (value.length < 8) {
                                    return 'La contraseña debe tener al menos 8 caracteres';
                                  }
                                  if (!RegExp(
                                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                                  ).hasMatch(value)) {
                                    return 'Debe contener mayúsculas, minúsculas y números';
                                  }
                                  if (!RegExp(
                                    r'^(?=.*[!@#$%^&*(),.?":{}|<>])',
                                  ).hasMatch(value)) {
                                    return 'Debe contener al menos un símbolo especial';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),

                              // Confirm password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar contraseña',
                                  hintText: 'Repite tu contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
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
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                              ),
                              const SizedBox(height: 16),

                              // Terms and conditions
                              CheckboxListTile(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                title: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Acepto los '),
                                      TextSpan(
                                        text: 'Términos y Condiciones',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(text: ' y la '),
                                      TextSpan(
                                        text: 'Política de Privacidad',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                              const SizedBox(height: 8),

                              // Register button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Crear Cuenta',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Login link
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
                                      Navigator.of(context).pop();
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
                                            Icons.login,
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
                                                  text: '¿Ya tienes cuenta? ',
                                                ),
                                                TextSpan(
                                                  text: 'Inicia sesión',
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
