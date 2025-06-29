import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditarNombrePage extends StatefulWidget {
  const EditarNombrePage({super.key});

  @override
  State<EditarNombrePage> createState() => _EditarNombrePageState();
}

class _EditarNombrePageState extends State<EditarNombrePage> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  Future<void> _loadCurrentName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentName = prefs.getString('username') ?? '';
      setState(() {
        _nameController.text = currentName;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar nombre: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _nameController.text.trim());

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre actualizado correctamente')),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Editar Nombre'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono y título
              Icon(Icons.person, size: 80, color: Colors.blue[600]),
              const SizedBox(height: 24),
              Text(
                'Editar Nombre de Usuario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Cambia tu nombre para personalizar la aplicación:',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de nombre
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tu nombre',
                  hintText: 'Ej: Juan Pérez',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
