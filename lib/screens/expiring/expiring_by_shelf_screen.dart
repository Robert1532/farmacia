import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/models/shelf_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/widgets/shelf_expiration_card.dart';

class ExpiringByShelfScreen extends StatefulWidget {
  const ExpiringByShelfScreen({Key? key}) : super(key: key);

  @override
  _ExpiringByShelfScreenState createState() => _ExpiringByShelfScreenState();
}

class _ExpiringByShelfScreenState extends State<ExpiringByShelfScreen> {
  bool _isLoading = true;
  List<ShelfFirebase> _shelves = [];
  Map<String, List<MedicationFirebase>> _medicationsByShelf = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      
      await medicationProvider.fetchMedications();
      await shelfProvider.fetchShelves();
      
      _shelves = shelfProvider.shelves;
      
      // Agrupar medicamentos por estante
      final Map<String, List<MedicationFirebase>> medicationsByShelf = {};
      
      // Solo considerar medicamentos con stock > 0
      final medicationsWithStock = medicationProvider.medications
          .where((med) => med.stock > 0)
          .toList();
      
      // Agrupar por estante
      for (final shelf in _shelves) {
        final shelfMedications = medicationsWithStock
            .where((med) => med.shelfId == shelf.id)
            .toList();
        
        // Solo incluir estantes con medicamentos
        if (shelfMedications.isNotEmpty) {
          medicationsByShelf[shelf.id] = shelfMedications;
        }
      }
      
      // Medicamentos sin estante asignado
      final unassignedMedications = medicationsWithStock
          .where((med) => med.shelfId == null || med.shelfId!.isEmpty)
          .toList();
      
      if (unassignedMedications.isNotEmpty) {
        medicationsByShelf['unassigned'] = unassignedMedications;
      }
      
      setState(() {
        _medicationsByShelf = medicationsByShelf;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos por Estante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicationsByShelf.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Estantes con medicamentos
                      ..._buildShelfSections(),
                      
                      // Medicamentos sin estante
                      if (_medicationsByShelf.containsKey('unassigned'))
                        _buildUnassignedSection(),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay medicamentos por expirar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Todos los medicamentos están en buen estado',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildShelfSections() {
    final List<Widget> sections = [];
    
    for (final shelfId in _medicationsByShelf.keys) {
      if (shelfId == 'unassigned') continue;
      
      final shelf = _shelves.firstWhere(
        (s) => s.id == shelfId,
        orElse: () => ShelfFirebase(
          id: shelfId,
          name: 'Estante Desconocido',
          location: 'Ubicación Desconocida',
          capacity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final medications = _medicationsByShelf[shelfId]!;
      
      // Contar medicamentos por categoría
      final expired = medications.where((med) => med.expirationDate != null && med.isExpired).length;
      final expiringSoon = medications.where((med) => med.expirationDate != null && !med.isExpired && med.isExpiringSoon).length;
      final expiringInMonth = medications.where((med) => med.expirationDate != null && !med.isExpired && !med.isExpiringSoon && med.isExpiringInMonth).length;
      final lowStock = medications.where((med) => med.stock < 10).length;
      
      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shelf header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shelves,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shelf.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            shelf.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/expiring/shelf-detail',
                          arguments: {'shelfId': shelf.id},
                        );
                      },
                      tooltip: 'Ver detalle',
                    ),
                  ],
                ),
              ),
              
              // Shelf stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Expirados',
                            expired.toString(),
                            Colors.red,
                            Icons.event_busy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'En 7 días',
                            expiringSoon.toString(),
                            Colors.orange,
                            Icons.timer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'En 30 días',
                            expiringInMonth.toString(),
                            Colors.amber,
                            Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Stock Bajo',
                            lowStock.toString(),
                            Colors.blue,
                            Icons.inventory,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return sections;
  }
  
  Widget _buildUnassignedSection() {
    final medications = _medicationsByShelf['unassigned']!;
    
    // Contar medicamentos por categoría
    final expired = medications.where((med) => med.expirationDate != null && med.isExpired).length;
    final expiringSoon = medications.where((med) => med.expirationDate != null && !med.isExpired && med.isExpiringSoon).length;
    final expiringInMonth = medications.where((med) => med.expirationDate != null && !med.isExpired && !med.isExpiringSoon && med.isExpiringInMonth).length;
    final lowStock = medications.where((med) => med.stock < 10).length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sin Estante Asignado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Medicamentos sin ubicación',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/expiring/unassigned',
                    );
                  },
                  tooltip: 'Ver detalle',
                ),
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Expirados',
                        expired.toString(),
                        Colors.red,
                        Icons.event_busy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'En 7 días',
                        expiringSoon.toString(),
                        Colors.orange,
                        Icons.timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'En 30 días',
                        expiringInMonth.toString(),
                        Colors.amber,
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Stock Bajo',
                        lowStock.toString(),
                        Colors.blue,
                        Icons.inventory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
