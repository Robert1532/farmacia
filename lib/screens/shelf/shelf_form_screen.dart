import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shelf_firebase.dart';
import '../../providers/shelf_provider_firebase.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class ShelfFormScreen extends StatefulWidget {
  final ShelfFirebase? shelf; // Recibe el estante completo (o null si es creación)

  const ShelfFormScreen({
    Key? key,
    this.shelf,
  }) : super(key: key);

  @override
  _ShelfFormScreenState createState() => _ShelfFormScreenState();
}

class _ShelfFormScreenState extends State<ShelfFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false; // true si estamos editando

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.shelf != null; // Modo edición si hay un estante

    if (_isEditing) {
      // Llena los campos con los datos del estante
      _nameController.text = widget.shelf!.name;
      _descriptionController.text = widget.shelf!.description ?? '';
      _locationController.text = widget.shelf!.location;
      _capacityController.text = widget.shelf!.capacity.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveShelf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final location = _locationController.text.trim();
      final capacity = int.parse(_capacityController.text.trim());

      if (_isEditing && widget.shelf != null) {
        // Actualizar estante existente
        final updatedShelf = widget.shelf!.copyWith(
          name: name,
          description: description.isNotEmpty ? description : null,
          location: location,
          capacity: capacity,
          updatedAt: DateTime.now(),
        );

        await shelfProvider.updateShelf(updatedShelf);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estante actualizado correctamente')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Crear nuevo estante
        await shelfProvider.addShelf(
          name: name,
          description: description.isNotEmpty ? description : null,
          location: location,
          capacity: capacity,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estante creado correctamente')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el estante: $e')),
        );
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Estante' : 'Nuevo Estante'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nombre',
                      hintText: 'Ingrese el nombre del estante',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Descripción (opcional)',
                      hintText: 'Ingrese una descripción',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Ubicación',
                      hintText: 'Ingrese la ubicación del estante',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una ubicación';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _capacityController,
                      label: 'Capacidad',
                      hintText: 'Ingrese la capacidad del estante',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la capacidad';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        if (int.parse(value) <= 0) {
                          return 'La capacidad debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveShelf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_isEditing ? 'Actualizar Estante' : 'Crear Estante'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}