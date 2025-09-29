import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'new_home_screen.dart';
import 'transactions_screen.dart';
import 'accounts_screen_improved.dart';
import 'account_reports_screen.dart';
import 'settings_screen.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/auth_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Timer? _tokenCheckTimer;

  final List<Widget> _screens = [
    const NewHomeScreen(),
    const TransactionsScreen(),
    const AccountsScreenImproved(),
    const AccountReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Verificar la validez del token periódicamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenValidity();
      _startTokenCheckTimer();
    });
  }

  @override
  void dispose() {
    _tokenCheckTimer?.cancel();
    super.dispose();
  }

  void _checkTokenValidity() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.checkTokenValidity();
  }

  void _startTokenCheckTimer() {
    // Verificar la validez del token cada 5 minutos
    _tokenCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkTokenValidity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar mensaje de error de sesión si existe
        if (authProvider.error != null &&
            (authProvider.error!.contains('sesión') ||
                authProvider.error!.contains('expirado'))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.error!),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Cerrar',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    authProvider.clearError();
                  },
                ),
              ),
            );
          });
        }

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: Container(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
