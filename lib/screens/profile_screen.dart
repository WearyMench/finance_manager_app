import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isEditing = false;
  bool _isChangingPassword = false;

  final Map<String, String> _currencies = {
    'DOP': 'Peso Dominicano (RD\$)',
    'MXN': 'Peso Mexicano (\$)',
    'USD': 'Dólar Estadounidense (\$)',
    'EUR': 'Euro (€)',
    'COP': 'Peso Colombiano (\$)',
    'ARS': 'Peso Argentino (\$)',
  };

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedCurrency = user?.currency ?? 'USD';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('El nombre es requerido');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('El email es requerido');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        currency: _selectedCurrency,
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
          _successMessage = 'Perfil actualizado correctamente';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = authProvider.error ?? 'Error al actualizar el perfil';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al actualizar el perfil: $e';
      });
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.trim().isEmpty) {
      _showError('La contraseña actual es requerida');
      return;
    }

    if (_newPasswordController.text.trim().isEmpty) {
      _showError('La nueva contraseña es requerida');
      return;
    }

    if (_newPasswordController.text.trim().length < 6) {
      _showError('La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.updatePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isChangingPassword = false;
          _successMessage = 'Contraseña actualizada correctamente';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              authProvider.error ?? 'Error al cambiar la contraseña';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cambiar la contraseña: $e';
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _isChangingPassword = false;
      _clearMessages();
    });
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi Perfil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'Gestiona tu información personal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _isLoading ? null : _cancelEditing,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _clearMessages();
                  });
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.getPrimaryColor(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Actualizando perfil...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Success message
              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.getSuccessColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.getSuccessColor(context).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.getSuccessColor(context),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: AppTheme.getSuccessColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearMessages,
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.getSuccessColor(context),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.getErrorColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.getErrorColor(context).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: AppTheme.getErrorColor(context),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.getErrorColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearMessages,
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.getErrorColor(context),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.getPrimaryColor(context),
                      AppTheme.getPrimaryColor(context).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'Usuario',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _emailController.text.isNotEmpty
                                ? _emailController.text
                                : 'usuario@ejemplo.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currencies[_selectedCurrency] ?? 'USD',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(
                              context,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.getPrimaryColor(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Información Personal',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorderColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getPrimaryColor(context),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _isEditing
                            ? AppTheme.getBackgroundColor(context)
                            : AppTheme.getDividerColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorderColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getPrimaryColor(context),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _isEditing
                            ? AppTheme.getBackgroundColor(context)
                            : AppTheme.getDividerColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency Field
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Moneda',
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorderColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getPrimaryColor(context),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _isEditing
                            ? AppTheme.getBackgroundColor(context)
                            : AppTheme.getDividerColor(context),
                      ),
                      items: _currencies.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isEditing
                          ? (value) {
                              setState(() {
                                _selectedCurrency = value ?? 'USD';
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.getPrimaryColor(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Guardar Cambios'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Password Change Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getWarningColor(
                              context,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock,
                            color: AppTheme.getWarningColor(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cambiar Contraseña',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!_isChangingPassword)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isChangingPassword = true;
                              _clearMessages();
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Cambiar Contraseña'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.getWarningColor(context),
                            side: BorderSide(
                              color: AppTheme.getWarningColor(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      )
                    else ...[
                      // Current Password
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getBackgroundColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getBackgroundColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getBackgroundColor(context),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isChangingPassword = false;
                                        _currentPasswordController.clear();
                                        _newPasswordController.clear();
                                        _confirmPasswordController.clear();
                                        _clearMessages();
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.getTextSecondaryColor(
                                  context,
                                ),
                                side: BorderSide(
                                  color: AppTheme.getBorderColor(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.getWarningColor(
                                  context,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
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
                                  : const Text('Cambiar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
