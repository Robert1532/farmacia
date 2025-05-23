import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/widgets/inventory_adjustment_dialog.dart' as inventory_dialog;
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/widgets/confirm_dialog.dart';
import 'package:farmacia/utils/currency_formatter.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String medicationId;

  const MedicationDetailScreen({
    Key? key,
    required this.medicationId,
  }) : super(key: key);

  @override
  _MedicationDetailScreenState createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  bool _isLoading = true;
  MedicationFirebase? _medication;
  String? _shelfName;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  Future<void> _loadMedication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      
      // Fetch the medication from Firebase
      final medication = await medicationProvider.fetchMedicationById(widget.medicationId);
      _medication = medication;
      
      if (_medication != null && _medication!.shelfId != null) {
        // Fetch the shelf from Firebase
        await shelfProvider.fetchShelfById(_medication!.shelfId!);
        final shelf = shelfProvider.getShelfById(_medication!.shelfId!);
        _shelfName = shelf?.name;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medication: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Eliminar Medicamento',
        content: '¿Estás seguro de que deseas eliminar este medicamento? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        cancelText: 'Cancelar',
        isDestructive: true,
      ),
    );

    if (confirmed == true && _medication != null) {
      try {
        final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
        await medicationProvider.deleteMedication(_medication!.id);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el medicamento: $e')),
          );
        }
      }
    }
  }

  Future<void> _adjustInventory() async {
    if (_medication == null) return;

   final result = await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (context) => inventory_dialog.InventoryAdjustmentDialog(
    currentStock: _medication!.stock,
  ),
);


    if (result != null && mounted) {
      try {
        final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
        final newStock = result['newStock'] as int;
        final reason = result['reason'] as String;
        
        // Update the medication in Firebase
        await medicationProvider.updateMedicationStock(
          _medication!.id,
          newStock,
          reason,
        );
        
        // Refresh the medication data
        await _loadMedication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inventario actualizado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el inventario: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Medicamento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _medication == null
                ? null
                : () async {
                    final updated = await Navigator.pushNamed(
                      context,
                      '/medication-form',
                      arguments: {'medicationId': _medication!.id},
                    );
                    if (updated == true) {
                      _loadMedication();
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _medication == null ? null : _deleteMedication,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medication == null
              ? const Center(child: Text('Medicamento no encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with name and stock
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _medication!.name,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                if (_medication!.genericName != null && _medication!.genericName!.isNotEmpty)
                                  Text(
                                    _medication!.genericName!,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _medication!.stock > 0
                                  ? _medication!.stock < 10
                                      ? AppColors.warning
                                      : AppColors.success
                                  : AppColors.danger,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Stock: ${_medication!.stock}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Price information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Información de Precio',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Precio de Compra:'),
                                  Text(
                                    CurrencyFormatter.format(_medication!.purchasePrice),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Precio de Venta:'),
                                  Text(
                                    CurrencyFormatter.format(_medication!.sellingPrice),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Margen de Ganancia:'),
                                  Text(
                                    '${((_medication!.sellingPrice - _medication!.purchasePrice) / _medication!.purchasePrice * 100).toStringAsFixed(2)}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Valor Total en Inventario:'),
                                  Text(
                                    CurrencyFormatter.format(_medication!.sellingPrice * _medication!.stock),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalles',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              if (_medication!.description != null && _medication!.description!.isNotEmpty) ...[
                                const Text(
                                  'Descripción:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(_medication!.description!),
                                const SizedBox(height: 8),
                              ],
                              if (_medication!.dosage != null && _medication!.dosage!.isNotEmpty)
                                _buildDetailRow('Dosificación:', _medication!.dosage!),
                              if (_medication!.presentation != null && _medication!.presentation!.isNotEmpty)
                                _buildDetailRow('Presentación:', _medication!.presentation!),
                              if (_medication!.laboratory != null && _medication!.laboratory!.isNotEmpty)
                                _buildDetailRow('Laboratorio:', _medication!.laboratory!),
                              if (_shelfName != null)
                                _buildDetailRow('Estante:', _shelfName!),
                          
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fechas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              if (_medication!.expirationDate != null)
                                _buildDetailRow(
                                  'Fecha de Expiración:',
                                  DateFormat('dd/MM/yyyy').format(_medication!.expirationDate!),
                                  _isExpiringSoon(_medication!.expirationDate!)
                                      ? AppColors.danger
                                      : null,
                                ),
                              if (_medication!.entryDate != null)
                                _buildDetailRow(
                                  'Fecha de Entrada:',
                                  DateFormat('dd/MM/yyyy').format(_medication!.entryDate!),
                                ),
                              _buildDetailRow(
                                'Última Actualización:',
                                DateFormat('dd/MM/yyyy HH:mm').format(_medication!.updatedAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _medication == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _adjustInventory,
              icon: const Icon(Icons.edit),
              label: const Text('Ajustar Inventario'),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  bool _isExpiringSoon(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }
}
