import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication_firebase.dart';
import '../providers/medication_provider_firebase.dart';
import '../widgets/inventory_adjustment_dialog.dart';

class QuickActionButton extends StatelessWidget {
  final MedicationFirebase medication;
  final VoidCallback? onActionCompleted;
  
  const QuickActionButton({
    Key? key,
    required this.medication,
    this.onActionCompleted,
  }) : super(key: key);

  Future<void> _showAdjustmentDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => InventoryAdjustmentDialog(
        medication: medication,
        currentStock: medication.stock,
        isDecrement: true,
      ),
    );
    
    if (result != null && result.containsKey('newStock') && onActionCompleted != null) {
      onActionCompleted!();
    }
  }

  Future<void> _quickDecrement(BuildContext context) async {
    if (medication.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay stock disponible para disminuir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      
      // Disminuir en 1 la cantidad
      final updatedMedication = medication.copyWith(
        stock: medication.stock - 1,
      );
      
      final success = await medicationProvider.updateMedication(updatedMedication);
      
      if (success && onActionCompleted != null) {
        onActionCompleted!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'quick_decrement':
            _quickDecrement(context);
            break;
          case 'adjust':
            _showAdjustmentDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'quick_decrement',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 20),
              SizedBox(width: 8),
              Text('Disminuir 1'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'adjust',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 8),
              Text('Ajustar inventario'),
            ],
          ),
        ),
      ],
    );
  }
}
