import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/currency_formatter.dart';
import 'package:farmacia/screens/medication/medication_form_screen.dart';
import 'package:farmacia/screens/medication/medication_detail_screen.dart';

class MedicationListScreen extends StatefulWidget {
  final String? filter;
  
  const MedicationListScreen({Key? key, this.filter}) : super(key: key);

  @override
  _MedicationListScreenState createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  bool _isLoading = true;
  List<MedicationFirebase> _medications = [];
  List<MedicationFirebase> _filteredMedications = [];
  String _searchQuery = '';
  String _currentFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter ?? 'all';
    _loadMedications();
  }
  
  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      
      await medicationProvider.fetchMedications();
      await shelfProvider.fetchShelves();
      
      setState(() {
        _medications = medicationProvider.medications;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _applyFilters() {
    List<MedicationFirebase> filtered = _medications;
    
    /// Apply search filter
if (_searchQuery.isNotEmpty) {
  filtered = filtered.where((med) {
    return med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
           (med.genericName != null && med.genericName!.toLowerCase().contains(_searchQuery.toLowerCase()));
  }).toList();
}

    
    // Apply category filter
    switch (_currentFilter) {
      case 'lowStock':
        filtered = filtered.where((med) => med.stock > 0 && med.stock < 10).toList();
        break;
      case 'outOfStock':
        filtered = filtered.where((med) => med.stock == 0).toList();
        break;
      case 'expiringSoon':
        filtered = filtered.where((med) => 
          med.stock > 0 && 
          med.expirationDate != null && 
          med.expirationDate!.difference(DateTime.now()).inDays < 30 && 
          med.expirationDate!.isAfter(DateTime.now())
        ).toList();
        break;
      case 'expired':
        filtered = filtered.where((med) => 
          med.stock > 0 && 
          med.expirationDate != null && 
          med.expirationDate!.isBefore(DateTime.now())
        ).toList();
        break;
      case 'all':
      default:
        // No additional filtering
        break;
    }
    
    setState(() {
      _filteredMedications = filtered;
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }
  
  void _onFilterChanged(String? filter) {
    if (filter != null) {
      setState(() {
        _currentFilter = filter;
      });
      _applyFilters();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedications,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar medicamentos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Stock Bajo', 'lowStock'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sin Stock', 'outOfStock'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Por Expirar', 'expiringSoon'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expirados', 'expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Medications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMedications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron medicamentos',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMedications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredMedications.length,
                          itemBuilder: (context, index) {
                            final medication = _filteredMedications[index];
                            return _buildMedicationCard(medication);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MedicationFormScreen(),
            ),
          ).then((_) => _loadMedications());
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar Medicamento',
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onFilterChanged(selected ? value : 'all');
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }
  
  Widget _buildMedicationCard(MedicationFirebase medication) {
    final shelfProvider = Provider.of<ShelfProviderFirebase>(context);
    final shelf = medication.shelfId != null
        ? shelfProvider.getShelfById(medication.shelfId!)
        : null;
    
    // Determine stock status color
    Color stockColor;
    if (medication.stock == 0) {
      stockColor = Colors.red;
    } else if (medication.stock < 10) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }
    
    // Determine expiration status
    Widget? expirationWidget;
    if (medication.expirationDate != null) {
      final now = DateTime.now();
      final difference = medication.expirationDate!.difference(now).inDays;
      
      if (medication.expirationDate!.isBefore(now)) {
        // Expired
        expirationWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Exp: ${DateFormat('dd/MM/yyyy').format(medication.expirationDate!)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (difference <= 30) {
        // Expiring soon
        expirationWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Exp: ${DateFormat('dd/MM/yyyy').format(medication.expirationDate!)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        // Normal
        expirationWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Exp: ${DateFormat('dd/MM/yyyy').format(medication.expirationDate!)}',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
            ),
          ),
        );
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationDetailScreen(
                medicationId: medication.id,
              ),
            ),
          ).then((_) => _loadMedications());
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication name and generic name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (medication.genericName != null && medication.genericName!.isNotEmpty)
                          Text(
                            medication.genericName!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Stock indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stock: ${medication.stock}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Price and shelf
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio: ${CurrencyFormatter.format(medication.sellingPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shelf != null)
                          Text(
                            'Estante: ${shelf.name}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Expiration date
                  if (expirationWidget != null) expirationWidget,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
