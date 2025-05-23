import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/sale_firebase.dart';
import '../../providers/sale_provider_firebase.dart';
import '../../utils/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_button.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<SaleFirebase> _allSales = [];
  List<SaleFirebase> _todaySales = [];
  List<SaleFirebase> _weekSales = [];
  List<SaleFirebase> _monthSales = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSales();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final saleProvider = Provider.of<SaleProviderFirebase>(context, listen: false);
      
      // Cargar todas las ventas
      await saleProvider.fetchSales();
      _allSales = saleProvider.sales;
      
      // Filtrar ventas por período
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      
      _todaySales = _allSales.where((sale) => 
        sale.date.isAfter(today) || 
        (sale.date.day == today.day && sale.date.month == today.month && sale.date.year == today.year)
      ).toList();
      
      _weekSales = _allSales.where((sale) => 
        sale.date.isAfter(weekStart) || 
        (sale.date.day == weekStart.day && sale.date.month == weekStart.month && sale.date.year == weekStart.year)
      ).toList();
      
      _monthSales = _allSales.where((sale) => 
        sale.date.isAfter(monthStart) || 
        (sale.date.day == monthStart.day && sale.date.month == monthStart.month && sale.date.year == monthStart.year)
      ).toList();
      
      if (mounted) {
        setState(() {
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
  
  double _calculateTotalSales(List<SaleFirebase> sales) {
    double total = 0;
    for (var sale in sales) {
      total += sale.total;
    }
    return total;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Hoy'),
            Tab(text: 'Semana'),
            Tab(text: 'Mes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSales,
            tooltip: 'Actualizar',
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
                        'Error: $_errorMessage',
                        style: TextStyle(color: Colors.red.withAlpha(26)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Reintentar',
                        onPressed: _loadSales,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesList(_allSales, 'No hay ventas registradas'),
                    _buildSalesList(_todaySales, 'No hay ventas hoy'),
                    _buildSalesList(_weekSales, 'No hay ventas esta semana'),
                    _buildSalesList(_monthSales, 'No hay ventas este mes'),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/new-sale',
          );
          
          if (result == true) {
            _loadSales();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Nueva venta',
      ),
    );
  }
  
  Widget _buildSalesList(List<SaleFirebase> sales, String emptyMessage) {
    if (sales.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    final totalSales = _calculateTotalSales(sales);
    
    return Column(
      children: [
        // Resumen
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withAlpha(26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total de ventas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.format(totalSales),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de ventas
        Expanded(
          child: ListView.builder(
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'Venta #${sale.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha: ${_formatDate(sale.date)}'),
                      Text('Vendedor: ${sale.employeeName}'),
                      Text('Items: ${sale.items.length}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(sale.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        sale.paymentMethod,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/sale-detail',
                      arguments: {'saleId': sale.id},
                    );
                    
                    if (result == true) {
                      _loadSales();
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
