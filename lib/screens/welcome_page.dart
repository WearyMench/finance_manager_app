import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../utils/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _nameController.text.trim());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.getPrimaryGradient(context),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),

                // Logo y título animados
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Icono principal
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.getWhiteWithOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.getWhiteWithOpacity(0.3),
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

                            // Título
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

                            // Subtítulo
                            Text(
                              'Controla tus finanzas personales de manera inteligente',
                              style: TextStyle(
                                color: AppColors.getWhiteWithOpacity(0.9),
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Formulario
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getBlackWithOpacity(0.1),
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
                          // Campo de nombre
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: '¿Cómo te llamas?',
                              hintText: 'Ingresa tu nombre',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.getSurfaceColor(context),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _saveUsername(),
                          ),
                          const SizedBox(height: 24),

                          // Botón de continuar
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveUsername,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getPrimaryColor(
                                context,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Comenzar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
