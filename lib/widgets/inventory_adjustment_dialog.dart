import 'package:flutter/material.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/widgets/custom_button.dart';
import 'package:farmacia/widgets/custom_text_field.dart';
import 'package:farmacia/models/medication_firebase.dart';

class InventoryAdjustmentDialog extends StatefulWidget {
  final int currentStock;
  final MedicationFirebase? medication;
  final bool isDecrement;

  const InventoryAdjustmentDialog({
    Key? key,
    required this.currentStock,
    this.medication,
    this.isDecrement = false,
  }) : super(key: key);

  @override
  State<InventoryAdjustmentDialog> createState() => _InventoryAdjustmentDialogState();
}

class _InventoryAdjustmentDialogState extends State<InventoryAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _stockController = TextEditingController();
  final _reasonController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _stockController.text = widget.currentStock.toString();
  }
  
  @override
  void dispose() {
    _stockController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isDecrement ? 'Disminuir Inventario' : 'Ajustar Inventario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current stock
            Row(
              children: [
                const Text('Stock Actual: '),
                Text(
                  '${widget.currentStock}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // New stock
            CustomTextField(
              controller: _stockController,
              label: 'Nuevo Stock',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un valor';
                }
                final stock = int.tryParse(value);
                if (stock == null) {
                  return 'Por favor ingresa un número válido';
                }
                if (stock < 0) {
                  return 'El stock no puede ser negativo';
                }
                if (widget.isDecrement && stock >= widget.currentStock) {
                  return 'El nuevo stock debe ser menor que el actual';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Reason
            CustomTextField(
              controller: _reasonController,
              label: 'Motivo del Ajuste',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un motivo';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        CustomButton(
          text: 'Guardar',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newStock = int.parse(_stockController.text);
              final reason = _reasonController.text;
              
              Navigator.pop(context, {
                'newStock': newStock,
                'reason': reason,
              });
            }
          },
          color: AppColors.primary,
        ),
      ],
    );
  }
}
