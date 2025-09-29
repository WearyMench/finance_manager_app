import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/user_change_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

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
    _startResendCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60; // 60 segundos
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyEmail(_codeController.text.trim());

    if (success && mounted) {
      // Limpiar datos del usuario anterior usando el servicio centralizado
      await UserChangeService.clearPreviousUserData(context);

      // Mostrar mensaje de éxito y navegar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verificado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      // Navegación será manejada por el AppWrapper
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Código de verificación inválido',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationCode();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de verificación reenviado'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Error al reenviar código'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isResending = false;
      });
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
                      // Icon and title
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
                          Icons.mark_email_read,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Verifica tu Email',
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
                        'Hemos enviado un código de verificación a:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        widget.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Verification form
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
                              // Verification code field
                              TextFormField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Código de verificación',
                                  hintText: '123456',
                                  prefixIcon: const Icon(Icons.security),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa el código de verificación';
                                  }
                                  if (value.trim().length != 6) {
                                    return 'El código debe tener 6 dígitos';
                                  }
                                  if (!RegExp(
                                    r'^\d{6}$',
                                  ).hasMatch(value.trim())) {
                                    return 'El código debe contener solo números';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _verifyEmail(),
                              ),
                              const SizedBox(height: 24),

                              // Verify button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _verifyEmail,
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
                                            'Verificar Email',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Resend code button
                              TextButton(
                                onPressed: _resendCountdown > 0 || _isResending
                                    ? null
                                    : _resendCode,
                                child: _isResending
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _resendCountdown > 0
                                            ? 'Reenviar código en ${_resendCountdown}s'
                                            : 'Reenviar código',
                                        style: TextStyle(
                                          color: _resendCountdown > 0
                                              ? Colors.grey
                                              : Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // Back to login
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
                                            Icons.arrow_back,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Volver al Login',
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
