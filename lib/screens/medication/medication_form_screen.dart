import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/models/shelf_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/widgets/custom_text_field.dart';
import 'package:farmacia/widgets/custom_dropdown.dart';
import 'package:farmacia/widgets/custom_date_picker.dart';
import 'package:farmacia/widgets/custom_button.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/currency_formatter.dart';

class MedicationFormScreen extends StatefulWidget {
  final String? medicationId;

  const MedicationFormScreen({
    Key? key,
    this.medicationId,
  }) : super(key: key);

  @override
  _MedicationFormScreenState createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitialized = false;
  List<ShelfFirebase> _shelves = [];

  // Form fields
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _presentationController = TextEditingController();
  final _laboratoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedShelfId;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 365));
  DateTime _entryDate = DateTime.now();
  bool _useSuggestedPrice = false;
  List<Map<String, dynamic>> _priceSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _presentationController.dispose();
    _laboratoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load shelves
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      await shelfProvider.fetchShelves();
      _shelves = shelfProvider.shelves;

      // If editing, load medication data
      if (widget.medicationId != null) {
        final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
        final medication = await medicationProvider.fetchMedicationById(widget.medicationId!);
        
        if (medication != null) {
          _nameController.text = medication.name;
          _genericNameController.text = medication.genericName ?? '';
          _descriptionController.text = medication.description ?? '';
          _dosageController.text = medication.dosage ?? '';
          _presentationController.text = medication.presentation ?? '';
          _laboratoryController.text = medication.laboratory ?? '';
          _purchasePriceController.text = medication.purchasePrice.toString();
          _sellingPriceController.text = medication.sellingPrice.toString();
          _stockController.text = medication.stock.toString();
          _selectedShelfId = medication.shelfId;
          if (medication.expirationDate != null) {
            _expirationDate = medication.expirationDate!;
          }
          if (medication.entryDate != null) {
            _entryDate = medication.entryDate!;
          }
          
          // Get price suggestions
          _priceSuggestions = medication.getPriceSuggestions();
        }
      } else {
        // Default values for new medication
        _purchasePriceController.text = '0.0';
        _sellingPriceController.text = '0.0';
        _stockController.text = '0';
      }

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }
  
  void _updatePriceSuggestions() {
    if (_purchasePriceController.text.isEmpty) return;
    
    try {
      final purchasePrice = double.parse(_purchasePriceController.text);
      
      // Create a temporary medication object to get suggestions
      final tempMedication = MedicationFirebase(
        id: widget.medicationId ?? '',
        name: _nameController.text,
        purchasePrice: purchasePrice,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        expirationDate: _expirationDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _priceSuggestions = tempMedication.getPriceSuggestions();
      });
    } catch (e) {
      print('Error calculating price suggestions: $e');
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      
      final medication = MedicationFirebase(
        id: widget.medicationId ?? '',
        name: _nameController.text,
        genericName: _genericNameController.text.isEmpty ? null : _genericNameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        dosage: _dosageController.text.isEmpty ? null : _dosageController.text,
        presentation: _presentationController.text.isEmpty ? null : _presentationController.text,
        laboratory: _laboratoryController.text.isEmpty ? null : _laboratoryController.text,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stock: int.parse(_stockController.text),
        shelfId: _selectedShelfId,
        expirationDate: _expirationDate,
        entryDate: _entryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.medicationId == null) {
        // Create new medication
        await medicationProvider.addMedication(medication);
      } else {
        // Update existing medication
        await medicationProvider.updateMedication(medication);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el medicamento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicationId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Medicamento' : 'Nuevo Medicamento'),
      ),
      body: _isLoading && !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic information
                    const Text(
                      'Información Básica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nombre',
                      hintText: 'Ingrese el nombre del medicamento',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _genericNameController,
                      label: 'Nombre Genérico',
                      hintText: 'Ingrese el nombre genérico (opcional)',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Descripción',
                      hintText: 'Ingrese una descripción (opcional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _dosageController,
                      label: 'Dosificación',
                      hintText: 'Ej: 500mg, 10ml, etc. (opcional)',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _presentationController,
                      label: 'Presentación',
                      hintText: 'Ej: Tabletas, Jarabe, etc. (opcional)',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _laboratoryController,
                      label: 'Laboratorio',
                      hintText: 'Ingrese el nombre del laboratorio (opcional)',
                    ),
                  

                    // Inventory information
                    const Text(
                      'Información de Inventario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _purchasePriceController,
                            label: 'Precio de Compra',
                            hintText: 'Ingrese el precio de compra',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixText: 'Bs. ',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el precio';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Ingrese un número válido';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _updatePriceSuggestions();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _sellingPriceController,
                            label: 'Precio de Venta',
                            hintText: 'Ingrese el precio de venta',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixText: 'Bs. ',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el precio';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Ingrese un número válido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    // Price suggestions
                    if (_priceSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Sugerencias de Precio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _priceSuggestions.map((suggestion) {
                          return ListTile(
                            title: Text(suggestion['label']),
                            subtitle: Text(suggestion['description']),
                            trailing: Text(
                              CurrencyFormatter.format(suggestion['price']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _sellingPriceController.text = suggestion['price'].toString();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _stockController,
                      label: 'Stock',
                      hintText: 'Ingrese la cantidad en stock',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el stock';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomDropdown<String>(
                      label: 'Estante',
                      hint: 'Seleccione un estante (opcional)',
                      value: _selectedShelfId,
                      items: _shelves.map((shelf) {
                        return DropdownMenuItem<String>(
                          value: shelf.id,
                          child: Text(shelf.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedShelfId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Dates
                    const Text(
                      'Fechas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomDatePicker(
                      label: 'Fecha de Expiración',
                      selectedDate: _expirationDate,
                      onDateSelected: (date) {
                        setState(() {
                          _expirationDate = date;
                        });
                      },
                      firstDate: DateTime.now(),
                      allowFutureDates: true,
                    ),
                    const SizedBox(height: 12),
                    CustomDatePicker(
                      label: 'Fecha de Entrada',
                      selectedDate: _entryDate,
                      onDateSelected: (date) {
                        setState(() {
                          _entryDate = date;
                        });
                      },
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      allowFutureDates: false,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    CustomButton(
                      text: isEditing ? 'Actualizar Medicamento' : 'Guardar Medicamento',
                      isLoading: _isLoading,
                      onPressed: _saveMedication,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
