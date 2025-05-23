import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmacia/models/shelf_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/widgets/empty_state.dart';
import 'package:farmacia/widgets/custom_search_bar.dart';

class ShelfListScreen extends StatefulWidget {
  const ShelfListScreen({Key? key}) : super(key: key);

  @override
  _ShelfListScreenState createState() => _ShelfListScreenState();
}

class _ShelfListScreenState extends State<ShelfListScreen> {
  bool _isLoading = true;
  List<ShelfFirebase> _shelves = [];
  List<ShelfFirebase> _filteredShelves = [];
  Map<String, int> _medicationCounts = {};
  String _searchQuery = '';

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
      // Get providers
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);

      // Fetch shelves from Firebase
      await shelfProvider.fetchShelves();
      _shelves = shelfProvider.shelves;

      // Sort shelves by name
      _shelves.sort((a, b) => a.name.compareTo(b.name));
      _filteredShelves = List.from(_shelves);

      // Fetch medications to count items per shelf
      await medicationProvider.fetchMedications();
      final medications = medicationProvider.medications;

      // Count medications per shelf
      _medicationCounts = {};
      for (final medication in medications) {
        if (medication.shelfId != null) {
          _medicationCounts[medication.shelfId!] = (_medicationCounts[medication.shelfId!] ?? 0) + 1;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shelves: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterShelves(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredShelves = List.from(_shelves);
      } else {
        _filteredShelves = _shelves
            .where((shelf) =>
                shelf.name.toLowerCase().contains(query.toLowerCase()) ||
                (shelf.description != null &&
                    shelf.description!.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              hintText: 'Buscar estantes...',
              onChanged: _filterShelves,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredShelves.isEmpty
                    ? EmptyState(
                        icon: Icons.shelves,
                        title: 'No hay estantes',
                        message: _searchQuery.isNotEmpty
                            ? 'No se encontraron estantes que coincidan con "$_searchQuery"'
                            : 'Agrega estantes para organizar tus medicamentos',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredShelves.length,
                          itemBuilder: (context, index) {
                            final shelf = _filteredShelves[index];
                            final medicationCount = _medicationCounts[shelf.id] ?? 0;
                            return _buildShelfCard(shelf, medicationCount);
                          },
                        ),
                      ),
          ),
        ],
      ),
 // shelf_list_screen.dart (parte modificada)
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    final result = await Navigator.pushNamed(
      context,
      '/shelf-form',
    );
    if (result == true) {
      _loadData();
    }
  },
  child: const Icon(Icons.add),
),
    );
  }

  Widget _buildShelfCard(ShelfFirebase shelf, int medicationCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/shelf-detail',
            arguments: {'shelfId': shelf.id},
          );
          if (result == true) {
            _loadData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shelves,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelf.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (shelf.description != null && shelf.description!.isNotEmpty)
                      Text(
                        shelf.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '$medicationCount medicamentos',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
