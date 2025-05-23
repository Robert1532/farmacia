import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/models/shelf_firebase.dart';
import 'package:farmacia/models/sale_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/shelf_provider_firebase.dart';
import 'package:farmacia/providers/sale_provider_firebase.dart';
import 'package:farmacia/providers/auth_provider_firebase.dart';
import 'package:farmacia/providers/theme_provider.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/constants.dart';
import 'package:farmacia/utils/currency_formatter.dart';
import 'package:farmacia/screens/admin/admin_screen.dart';
import 'package:farmacia/screens/expiring/expiring_medications_screen.dart';
import 'package:farmacia/screens/medication/medication_list_screen.dart';
import 'package:farmacia/screens/shelf/shelf_list_screen.dart';
import 'package:farmacia/screens/sales/sales_screen.dart';
import 'package:farmacia/screens/profile/profile_screen.dart';
import 'package:farmacia/widgets/expiration_notification_card.dart';
import 'package:farmacia/screens/admin/reports/sales_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<MedicationFirebase> _expiringMedications = [];
  Map<String, List<MedicationFirebase>> _expiringByPeriod = {};
  List<ShelfFirebase> _shelves = [];
  List<SaleFirebase> _recentSales = [];
  double _totalInventoryValue = 0;
  double _totalSalesValue = 0;
  int _lowStockCount = 0;
  int _expiringCount = 0;
  
  // Para auto-refresh
  late DateTime _lastRefreshTime;
  static const refreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastRefreshTime = DateTime.now();
    _loadData();
    
    // Configurar un timer para actualizar los datos cada 5 minutos
    _setupRefreshTimer();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Verificar si han pasado más de 5 minutos desde la última actualización
      final now = DateTime.now();
      if (now.difference(_lastRefreshTime) > refreshInterval) {
        _loadData();
      }
    }
  }
  
  void _setupRefreshTimer() {
    Future.delayed(refreshInterval, () {
      if (mounted) {
        _loadData();
        _setupRefreshTimer(); // Configurar el próximo timer
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      final shelfProvider = Provider.of<ShelfProviderFirebase>(context, listen: false);
      final saleProvider = Provider.of<SaleProviderFirebase>(context, listen: false);

      await medicationProvider.fetchMedications();
      await shelfProvider.fetchShelves();
      await saleProvider.fetchSales();

      // Get expiring medications by period (only with stock > 0)
      final allMedications = medicationProvider.medications;
      final medicationsWithStock = allMedications.where((med) => med.stock > 0).toList();
      
      // Get expiring medications by period
      final expiringByPeriod = <String, List<MedicationFirebase>>{};
      
      // Expired
      expiringByPeriod['expired'] = medicationsWithStock
          .where((med) => med.expirationDate != null && med.isExpired)
          .toList();
      
      // 7 days
      expiringByPeriod['sevenDays'] = medicationsWithStock
          .where((med) => med.expirationDate != null && !med.isExpired && med.isExpiringSoon)
          .toList();
      
      // 30 days
      expiringByPeriod['thirtyDays'] = medicationsWithStock
          .where((med) => med.expirationDate != null && !med.isExpired && !med.isExpiringSoon && med.isExpiringInMonth)
          .toList();
      
      // 60 days
      expiringByPeriod['sixtyDays'] = medicationsWithStock
          .where((med) => med.expirationDate != null && !med.isExpired && !med.isExpiringSoon && !med.isExpiringInMonth && med.isExpiringInTwoMonths)
          .toList();
      
      // 90 days
      expiringByPeriod['ninetyDays'] = medicationsWithStock
          .where((med) => med.expirationDate != null && !med.isExpired && !med.isExpiringSoon && !med.isExpiringInMonth && !med.isExpiringInTwoMonths && med.isExpiringInThreeMonths)
          .toList();
      
      // Combine all expiring medications for display
      final List<MedicationFirebase> expiringMedications = [
        ...expiringByPeriod['sevenDays'] ?? [],
        ...expiringByPeriod['thirtyDays'] ?? [],
        ...expiringByPeriod['sixtyDays'] ?? [],
        ...expiringByPeriod['ninetyDays'] ?? []
      ];
      
      expiringMedications.sort((a, b) {
        if (a.expirationDate == null) return 1;
        if (b.expirationDate == null) return -1;
        return a.expirationDate!.compareTo(b.expirationDate!);
      });

      _shelves = shelfProvider.shelves;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      // Get recent sales
      _recentSales = saleProvider.sales
          .where((sale) => sale.date.isAfter(thirtyDaysAgo))
          .toList();
      
      _recentSales.sort((a, b) => b.date.compareTo(a.date));

      // Calculate total inventory value
      _totalInventoryValue = medicationProvider.medications
          .fold(0, (sum, med) => sum + (med.sellingPrice * med.stock));

      // Calculate total sales value for last 30 days
      _totalSalesValue = saleProvider.sales
          .where((sale) => sale.date.isAfter(thirtyDaysAgo))
          .fold(0, (sum, sale) => sum + sale.total);

      // Count low stock items
      _lowStockCount = medicationProvider.medications
          .where((med) => med.stock < Constants.lowStockThreshold && med.stock > 0)
          .length;

      // Count all expiring medications
      _expiringCount = expiringMedications.length;

      setState(() {
        _expiringMedications = expiringMedications;
        _expiringByPeriod = expiringByPeriod;
        _isLoading = false;
        _lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProviderFirebase>(context);
    final user = authProvider.currentUser;
    final isDarkMode = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmacia App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      // Modificar el drawer para ocultar la opción de configuración
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Medicamentos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MedicationListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shelves),
              title: const Text('Estantes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShelfListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text('Medicamentos por Expirar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpiringMedicationsScreen()),
                );
              },
            ),
            if (user?.isAdmin == true) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'ADMINISTRACIÓN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Panel de Administración'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Gestión de Usuarios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/users');
                },
              ),
            
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            // Eliminamos la opción de configuración
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Shelves with expiring medications
                    _buildShelvesWithExpiringMedications(),
                    const SizedBox(height: 24),

                    // Expiring medications
                    _buildExpiringMedications(),
                    const SizedBox(height: 24),

                    // Shelves
                    _buildShelves(),
                    const SizedBox(height: 24),

                    // Recent sales
                    _buildRecentSales(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-sale');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add_shopping_cart),
        tooltip: 'Nueva Venta',
      ),
    );
  }

  // Modificar el método _buildSummaryCards para mejorar la responsividad
  Widget _buildSummaryCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/medications');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Valor de Inventario',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(_totalInventoryValue),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/sales');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.point_of_sale,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ventas (30 días)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(_totalSalesValue),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/medications', 
                      arguments: {'filter': 'lowStock'});
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stock Bajo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _lowStockCount.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/expiring');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event_busy,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Por Expirar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _expiringCount.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Nuevo método para mostrar estantes con medicamentos por expirar
  Widget _buildShelvesWithExpiringMedications() {
    // Agrupar medicamentos por expirar por estante
    Map<String, List<MedicationFirebase>> medicationsByShelf = {};
    
    // Combinar todas las categorías de medicamentos por expirar
    List<MedicationFirebase> allExpiringMedications = [
      ...(_expiringByPeriod['expired'] ?? []),
      ...(_expiringByPeriod['sevenDays'] ?? []),
      ...(_expiringByPeriod['thirtyDays'] ?? []),
      ...(_expiringByPeriod['sixtyDays'] ?? []),
      ...(_expiringByPeriod['ninetyDays'] ?? []),
    ];
    
    // Filtrar medicamentos sin estante
    allExpiringMedications = allExpiringMedications.where((med) => med.shelfId != null && med.shelfId!.isNotEmpty).toList();
    
    // Agrupar por estante
    for (var medication in allExpiringMedications) {
      if (medication.shelfId != null) {
        if (!medicationsByShelf.containsKey(medication.shelfId)) {
          medicationsByShelf[medication.shelfId!] = [];
        }
        medicationsByShelf[medication.shelfId]!.add(medication);
      }
    }
    
    if (medicationsByShelf.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        'Estantes con Medicamentos por Expirar',
        style: Theme.of(context).textTheme.titleLarge,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/expiring/by-shelf');
      },
      child: const Text('Ver todos'),
    ),
  ],
),

        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: medicationsByShelf.length,
            itemBuilder: (context, index) {
              final shelfId = medicationsByShelf.keys.elementAt(index);
              final medications = medicationsByShelf[shelfId]!;
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
              
              return _buildShelfExpirationCard(shelf, medications.length);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShelfExpirationCard(ShelfFirebase shelf, int expiringCount) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/expiring/shelf-detail',
            arguments: {'shelfId': shelf.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                shelf.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                shelf.location,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$expiringCount medicamentos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiringMedications() {
    if (_expiringMedications.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicamentos por Expirar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No hay medicamentos por expirar',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Medicamentos por Expirar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/expiring');
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 7 days expiration
        if (_expiringByPeriod['sevenDays']?.isNotEmpty ?? false) ...[
          ExpirationNotificationCard(
            title: 'Expiran en 7 días',
            medications: _expiringByPeriod['sevenDays']!,
            color: Colors.red,
            iconColor: Colors.red,
            icon: Icons.warning_amber,
            onTap: () {
              Navigator.pushNamed(context, '/expiring');
            },
          ),
          const SizedBox(height: 12),
        ],
        
        // 30 days expiration
        if (_expiringByPeriod['thirtyDays']?.isNotEmpty ?? false) ...[
          ExpirationNotificationCard(
            title: 'Expiran en 30 días',
            medications: _expiringByPeriod['thirtyDays']!,
            color: Colors.orange,
            iconColor: Colors.orange,
            icon: Icons.warning_amber,
            onTap: () {
              Navigator.pushNamed(context, '/expiring');
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // Modificar el método _buildShelves para mejorar la carga y visualización
  Widget _buildShelves() {
    if (_shelves.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estantes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shelves,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay estantes disponibles',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/shelf-form');
                      },
                      child: const Text('Agregar Estante'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estantes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _shelves.length > 5 ? 5 : _shelves.length,
            itemBuilder: (context, index) {
              final shelf = _shelves[index];
              return _buildShelfCard(shelf);
            },
          ),
        ),
        if (_shelves.length > 5)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/shelves');
            },
            child: const Text('Ver todos'),
          ),
      ],
    );
  }

  Widget _buildShelfCard(ShelfFirebase shelf) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/shelf-detail',
            arguments: {'shelfId': shelf.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160, // Aumentado para evitar problemas de píxeles
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shelves,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                shelf.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                shelf.location,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.medication,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ver medicamentos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSales() {
    if (_recentSales.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas Recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.point_of_sale,
                    size: 48,
                    color: Colors.green.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No hay ventas recientes',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/new-sale');
                    },
                    child: const Text('Nueva Venta'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ventas Recientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/sales');
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSales.length > 5 ? 5 : _recentSales.length,
          itemBuilder: (context, index) {
            final sale = _recentSales[index];
            return Card(
              child: ListTile(
                title: Text('Venta #${sale.id.substring(0, 8)}'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.date)),
                trailing: Text(
                  CurrencyFormatter.format(sale.total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/sale-detail',
                    arguments: {'saleId': sale.id},
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
