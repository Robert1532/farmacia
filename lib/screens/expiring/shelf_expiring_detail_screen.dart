import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/models/shelf_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/currency_formatter.dart';

class ShelfExpiringDetailScreen extends StatefulWidget {
  final String shelfId;
  
  const ShelfExpiringDetailScreen({
    Key? key,
    required this.shelfId,
  }) : super(key: key);

  @override
  _ShelfExpiringDetailScreenState createState() => _ShelfExpiringDetailScreenState();
}

class _ShelfExpiringDetailScreenState extends State<ShelfExpiringDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  ShelfFirebase? _shelf;
  List<MedicationFirebase> _medications = [];
  Map<String, List<MedicationFirebase>> _categorizedMedications = {};
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      
      await medicationProvider.fetchMedications();
      await shelfProvider.fetchShelfById(widget.shelfId);
      
      _shelf = shelfProvider.getShelfById(widget.shelfId);
      
      // Obtener medicamentos del estante con stock > 0
      _medications = medicationProvider.medications
          .where((med) => med.shelfId == widget.shelfId && med.stock > 0)
          .toList();
      
      // Categorizar medicamentos
      final Map<String, List<MedicationFirebase>> categorized = {
        'expired': [],
        'sevenDays': [],
        'thirtyDays': [],
        'sixtyDays': [],
        'lowStock': [],
      };
      
      for (final medication in _medications) {
        // Categorizar por expiración
        if (medication.expirationDate != null) {
          if (medication.isExpired) {
            categorized['expired']!.add(medication);
          } else if (medication.isExpiringSoon) {
            categorized['sevenDays']!.add(medication);
          } else if (medication.isExpiringInMonth) {
            categorized['thirtyDays']!.add(medication);
          } else if (medication.isExpiringInTwoMonths) {
            categorized['sixtyDays']!.add(medication);
          }
        }
        
        // Categorizar por stock bajo
        if (medication.stock < 10) {
          categorized['lowStock']!.add(medication);
        }
      }
      
      // Ordenar por fecha de expiración
      for (final key in categorized.keys) {
        categorized[key]!.sort((a, b) {
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
          return a.expirationDate!.compareTo(b.expirationDate!);
        });
      }
      
      setState(() {
        _categorizedMedications = categorized;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shelf data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_shelf?.name ?? 'Detalle de Estante'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Expirados'),
            Tab(text: '7 Días'),
            Tab(text: '30 Días'),
            Tab(text: '60 Días'),
            Tab(text: 'Stock Bajo'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
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
          : _shelf == null
              ? const Center(child: Text('Estante no encontrado'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMedicationList(_categorizedMedications['expired'] ?? [], Colors.red),
                    _buildMedicationList(_categorizedMedications['sevenDays'] ?? [], Colors.orange),
                    _buildMedicationList(_categorizedMedications['thirtyDays'] ?? [], Colors.amber),
                    _buildMedicationList(_categorizedMedications['sixtyDays'] ?? [], Colors.blue),
                    _buildMedicationList(_categorizedMedications['lowStock'] ?? [], Colors.purple),
                  ],
                ),
    );
  }
  
  Widget _buildMedicationList(List<MedicationFirebase> medications, Color color) {
    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay medicamentos en esta categoría',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medications.length,
        itemBuilder: (context, index) {
          final medication = medications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: color,
                ),
              ),
              title: Text(
                medication.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (medication.expirationDate != null)
                    Text(
                      'Expira: ${DateFormat('dd/MM/yyyy').format(medication.expirationDate!)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text('Stock: ${medication.stock}'),
                  Text('Precio: ${CurrencyFormatter.format(medication.sellingPrice)}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/medication-detail',
                  arguments: {'medicationId': medication.id},
                ).then((_) => _loadData());
              },
            ),
          );
        },
      ),
    );
  }
}
