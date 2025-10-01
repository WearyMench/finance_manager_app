import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/session_status_widget.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'transfer_categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: SessionStatusWidget(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSection(
            context,
            title: 'Perfil',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.person,
                title: 'Mi Perfil',
                subtitle: 'Editar información personal',
                onTap: () => _navigateToProfile(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSection(
            context,
            title: 'Seguridad',
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return FutureBuilder<bool>(
                    future: authProvider.isBiometricAvailable(),
                    builder: (context, snapshot) {
                      final bool biometricAvailable = snapshot.data ?? false;
                      return _buildSettingsItem(
                        context,
                        icon: Icons.fingerprint,
                        title: 'Autenticación biométrica',
                        subtitle: biometricAvailable
                            ? 'Usa tu huella dactilar o Face ID'
                            : 'No disponible en este dispositivo',
                        onTap: biometricAvailable
                            ? () => _navigateToBiometricSettings(context)
                            : () {},
                        trailing: Switch(
                          value: authProvider.biometricEnabled,
                          onChanged: biometricAvailable
                              ? (value) => _toggleBiometric(context, value)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Management Section
          _buildSection(
            context,
            title: 'Gestión de Datos',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.category,
                title: 'Categorías',
                subtitle: 'Gestionar categorías de transacciones',
                onTap: () => _navigateToCategories(context),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.swap_horiz,
                title: 'Categorías de Transferencias',
                subtitle: 'Gestionar categorías de transferencias',
                onTap: () => _navigateToTransferCategories(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSection(
            context,
            title: 'Configuración de la App',
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return _buildSettingsItem(
                    context,
                    icon: Icons.brightness_6,
                    title: 'Tema',
                    subtitle: themeProvider.themeName,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                title: 'Notificaciones',
                subtitle: 'Configurar alertas',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNotificationsDialog(context),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.security,
                title: 'Privacidad',
                subtitle: 'Configuración de privacidad',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildSection(
            context,
            title: 'Soporte',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.help,
                title: 'Ayuda',
                subtitle: 'Preguntas frecuentes y soporte',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHelpDialog(context),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.info,
                title: 'Acerca de',
                subtitle: 'Versión 1.0.0',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logout Section
          _buildSection(
            context,
            title: 'Sesión',
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.logout,
                title: 'Cerrar Sesión',
                subtitle: 'Salir de la aplicación',
                textColor: Colors.red,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: textColor ?? Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color:
              Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ??
              Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  // Navigation methods
  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
    );
  }

  void _navigateToTransferCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferCategoriesScreen()),
    );
  }

  // Dialog methods
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<ThemeProvider>(
              builder: (context, theme, child) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Claro'),
                      subtitle: const Text('Tema claro siempre'),
                      value: ThemeMode.light,
                      groupValue: theme.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          theme.setThemeMode(value);
                        }
                      },
                      secondary: const Icon(Icons.light_mode),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Oscuro'),
                      subtitle: const Text('Tema oscuro siempre'),
                      value: ThemeMode.dark,
                      groupValue: theme.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          theme.setThemeMode(value);
                        }
                      },
                      secondary: const Icon(Icons.dark_mode),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Sistema'),
                      subtitle: const Text('Seguir configuración del sistema'),
                      value: ThemeMode.system,
                      groupValue: theme.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          theme.setThemeMode(value);
                        }
                      },
                      secondary: const Icon(Icons.settings),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: const Text('Configuración de notificaciones próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidad'),
        content: const Text('Configuración de privacidad próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Text('Centro de ayuda próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mi Finanzas',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const Text('Una aplicación para gestionar tus finanzas personales.'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // Security methods
  void _navigateToBiometricSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración Biométrica'),
        content: const Text(
          'La autenticación biométrica está configurada. '
          'Puedes deshabilitarla desde el switch en la configuración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _toggleBiometric(BuildContext context, bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (value) {
      // Habilitar biometría - verificar disponibilidad primero
      final isAvailable = await authProvider.isBiometricAvailable();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La autenticación biométrica no está disponible en este dispositivo',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Verificar si ya hay credenciales guardadas
      final credentials = await authProvider.getBiometricCredentials();
      if (credentials == null) {
        // Mostrar diálogo explicativo en lugar de solo un SnackBar
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Configuración Requerida'),
            content: const Text(
              'Para habilitar la autenticación biométrica, primero debes iniciar sesión normalmente. '
              'Las credenciales se guardarán de forma segura para uso biométrico.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        return;
      }

      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Habilitar Biometría'),
          content: const Text(
            '¿Quieres habilitar la autenticación biométrica para un acceso más rápido y seguro?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Habilitar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await authProvider.enableBiometric(
          credentials['email']!,
          credentials['password']!,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometría habilitada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // Deshabilitar biometría - mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deshabilitar Biometría'),
          content: const Text(
            '¿Estás seguro de que quieres deshabilitar la autenticación biométrica?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deshabilitar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await authProvider.disableBiometric();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometría deshabilitada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}
