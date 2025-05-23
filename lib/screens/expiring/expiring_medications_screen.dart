import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';

class ExpiringMedicationsScreen extends StatefulWidget {
  const ExpiringMedicationsScreen({Key? key}) : super(key: key);

  @override
  _ExpiringMedicationsScreenState createState() => _ExpiringMedicationsScreenState();
}

class _ExpiringMedicationsScreenState extends State<ExpiringMedicationsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, List<MedicationFirebase>> _expiringMedications = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMedications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      await medicationProvider.fetchMedications();
      
      setState(() {
        _expiringMedications = medicationProvider.getExpiringMedications();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos por Expirar'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Expirados'),
            Tab(text: '7 Días'),
            Tab(text: '30 Días'),
            Tab(text: '60 Días'),
            Tab(text: '90 Días'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMedicationList(_expiringMedications['expired'] ?? [], Colors.red),
                _buildMedicationList(_expiringMedications['sevenDays'] ?? [], Colors.orange),
                _buildMedicationList(_expiringMedications['thirtyDays'] ?? [], Colors.amber),
                _buildMedicationList(_expiringMedications['sixtyDays'] ?? [], Colors.blue),
                _buildMedicationList(_expiringMedications['ninetyDays'] ?? [], Colors.green),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/expiring/by-shelf');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.shelves),
        tooltip: 'Ver por Estantes',
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
      onRefresh: _loadMedications,
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
                  if (medication.shelfId != null && medication.shelfId!.isNotEmpty)
                    FutureBuilder(
                      future: Provider.of<ShelfProviderFirebase>(context, listen: false)
                          .fetchShelfById(medication.shelfId!),
                      builder: (context, snapshot) {
                        final shelf = Provider.of<ShelfProviderFirebase>(context)
                            .getShelfById(medication.shelfId!);
                        return Text(
                          'Estante: ${shelf?.name ?? 'Desconocido'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                ],
              ),
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
    );
  }
}
