import 'package:farmacia/models/medication_firebase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shelf_firebase.dart';
import '../../providers/shelf_provider_firebase.dart';
import '../../providers/medication_provider_firebase.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../utils/app_colors.dart';

class ShelfDetailScreen extends StatefulWidget {
  final String shelfId;

  const ShelfDetailScreen({
    Key? key,
    required this.shelfId,
  }) : super(key: key);

  @override
  State<ShelfDetailScreen> createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  bool _isLoading = true;
  ShelfFirebase? _shelf;
  List<MedicationFirebase> _medications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      
      // Cargar el estante
      final shelf = await shelfProvider.fetchShelfById(widget.shelfId);
      
      if (shelf == null) {
        setState(() {
          _errorMessage = 'No se encontró el estante';
          _isLoading = false;
        });
        return;
      }
      
      // Cargar los medicamentos de este estante
      await medicationProvider.fetchMedications();
      final medications = medicationProvider.medications
          .where((med) => med.shelfId == widget.shelfId)
          .toList();
      
      if (mounted) {
        setState(() {
          _shelf = shelf;
          _medications = medications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteShelf() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Eliminar Estante',
        content: 'Esta acción eliminará el estante. ¿Estás seguro?',
        confirmText: 'Eliminar',
        cancelText: 'Cancelar',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
        final success = await shelfProvider.deleteShelf(widget.shelfId);
        
        if (success && mounted) {
          Navigator.of(context).pop(true); // Volver a la pantalla anterior
        } else if (mounted) {
          setState(() {
            _errorMessage = shelfProvider.errorMessage;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_shelf?.name ?? 'Detalle de Estante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _shelf == null
                ? null
                : () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/shelf-form',
                      arguments: {'shelf': _shelf}, // Pasa el estante completo
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _medications.isNotEmpty || _shelf == null
                ? null
                : _deleteShelf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Reintentar',
                        onPressed: _loadData,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_shelf == null) {
      return const Center(child: Text('No se encontró el estante'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del estante
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shelf!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_shelf!.description != null && _shelf!.description!.isNotEmpty) ...[
                    const Text(
                      'Descripción:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_shelf!.description!),
                    const SizedBox(height: 8),
                  ],
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text('Ubicación: ${_shelf!.location}'),
                    ],
                  ),
                  
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16),
                      const SizedBox(width: 4),
                      Text('Capacidad: ${_shelf!.capacity}'),
                    ],
                  ),
                  
                  Row(
                    children: [
                      const Icon(Icons.medication, size: 16),
                      const SizedBox(width: 4),
                      Text('Medicamentos: ${_medications.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de medicamentos
          if (_medications.isEmpty) ...[
            const Center(
              child: Text(
                'No hay medicamentos en este estante',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Medicamentos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final medication = _medications[index];
                return Card(
                  child: ListTile(
                    title: Text(medication.name),
                    subtitle: Text('Stock: ${medication.stock}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/medication-detail',
                        arguments: {'medicationId': medication.id},
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}