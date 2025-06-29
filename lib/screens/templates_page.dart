import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_template.dart';
import '../db/database_helper.dart';
import 'add_template_page.dart';
import 'edit_template_page.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ExpenseTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final templates = await _dbHelper.getAllExpenseTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar plantillas: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(ExpenseTemplate template) async {
    try {
      await _dbHelper.deleteExpenseTemplate(template.id!);
      await _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla eliminada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _toggleFavorite(ExpenseTemplate template) async {
    try {
      await _dbHelper.toggleFavoriteTemplate(template.id!, !template.favorito);
      await _loadTemplates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar favorito: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(ExpenseTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plantilla'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${template.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTemplate(template);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Plantillas de Gastos'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTemplates,
              child: _templates.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          color: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getCategoryColor(
                                template.categoria,
                              ),
                              child: Icon(
                                _getCategoryIcon(template.categoria),
                                color: Colors.white,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    template.nombre,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (template.favorito)
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        template.categoria,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (template.recurrente != null &&
                                        template.recurrente != 'ninguna')
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.repeat,
                                            size: 14,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            template.recurrenciaText,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (template.nota != null &&
                                    template.nota!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.note_alt,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          template.nota!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[700],
                                                fontStyle: FontStyle.italic,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: SizedBox(
                              width: 120,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'es_MX',
                                      symbol: '\$',
                                    ).format(template.monto),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          template.favorito
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: template.favorito
                                              ? Colors.amber
                                              : Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _toggleFavorite(template),
                                        tooltip: template.favorito
                                            ? 'Quitar de favoritos'
                                            : 'Agregar a favoritos',
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16),
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditTemplatePage(
                                                    template: template,
                                                  ),
                                            ),
                                          );
                                          _loadTemplates();
                                        },
                                        tooltip: 'Editar',
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 16,
                                        ),
                                        onPressed: () =>
                                            _showDeleteDialog(template),
                                        tooltip: 'Eliminar',
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTemplatePage()),
          );
          _loadTemplates();
        },
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        tooltip: 'Agregar plantilla',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay plantillas guardadas',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para crear tu primera plantilla',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'comida':
        return Colors.orange;
      case 'transporte':
        return Colors.blue;
      case 'ocio':
        return Colors.purple;
      case 'servicios':
        return Colors.green;
      case 'ropa':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'comida':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'ocio':
        return Icons.movie;
      case 'servicios':
        return Icons.home;
      case 'ropa':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }
}
