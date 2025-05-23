import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/medication_firebase.dart';
import '../../models/sale_firebase.dart';
import '../../models/sale_item_firebase.dart';
import '../../providers/medication_provider_firebase.dart';
import '../../providers/sale_provider_firebase.dart';
import '../../utils/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/dashboard_summary_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<SaleFirebase> _sales = [];
  List<MedicationFirebase> _medications = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, double> _monthlySales = {};
  Map<String, double> _monthlyProfits = {};
  double _totalSales = 0;
  double _totalProfits = 0;
  int _totalTransactions = 0;
  
  // Filtros
  String _selectedPeriod = 'month'; // 'week', 'month', 'year'
  
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
      final saleProvider = Provider.of<SaleProviderFirebase>(context, listen: false);
      final medicationProvider = Provider.of<MedicationProviderFirebase>(context, listen: false);
      
      await saleProvider.fetchSales();
      await medicationProvider.fetchMedications();
      
      _sales = saleProvider.sales;
      _medications = medicationProvider.medications;
      
      _processData();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _processData() {
    final now = DateTime.now();
    DateTime startDate;
    
    // Determinar fecha de inicio según el período seleccionado
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = DateTime(now.year, now.month - 1, now.day);
    }
    
    // Filtrar ventas por período
    final filteredSales = _sales.where((sale) => sale.date.isAfter(startDate)).toList();
    
    // Calcular totales
    _totalSales = filteredSales.fold(0, (sum, sale) => sum + sale.total);
    _totalProfits = filteredSales.fold(0, (sum, sale) => sum + (sale.total - _calculateCost(sale)));
    _totalTransactions = filteredSales.length;
    
    // Calcular ventas y ganancias mensuales
    _monthlySales = {};
    _monthlyProfits = {};
    
    for (final sale in filteredSales) {
      final monthKey = DateFormat('MM-yyyy').format(sale.date);
      final monthName = DateFormat('MMM', 'es').format(sale.date);
      
      _monthlySales[monthName] = (_monthlySales[monthName] ?? 0) + sale.total;
      _monthlyProfits[monthName] = (_monthlyProfits[monthName] ?? 0) + (sale.total - _calculateCost(sale));
    }
    
    // Calcular productos más vendidos
    final productSales = <String, Map<String, dynamic>>{};
    
    for (final sale in filteredSales) {
      for (final item in sale.items) {
        if (!productSales.containsKey(item.medicationId)) {
          final medication = _medications.firstWhere(
            (med) => med.id == item.medicationId,
            orElse: () => MedicationFirebase(
              id: item.medicationId,
              name: 'Desconocido',
              description: '',
              stock: 0,
              purchasePrice: 0,
              sellingPrice: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          productSales[item.medicationId] = {
            'id': item.medicationId,
            'name': medication.name,
            'quantity': 0,
            'total': 0.0,
            'profit': 0.0,
          };
        }
        
        productSales[item.medicationId]!['quantity'] += item.quantity;
        productSales[item.medicationId]!['total'] += item.unitPrice * item.quantity;
        
        // Calcular ganancia
        final medication = _medications.firstWhere(
          (med) => med.id == item.medicationId,
          orElse: () => MedicationFirebase(
            id: item.medicationId,
            name: 'Desconocido',
            description: '',
            stock: 0,
            purchasePrice: 0,
            sellingPrice: item.unitPrice,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        final profit = (item.unitPrice - medication.purchasePrice) * item.quantity;
        productSales[item.medicationId]!['profit'] += profit;
      }
    }
    
    // Ordenar productos por cantidad vendida
    _topProducts = productSales.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    
    // Limitar a los 10 más vendidos
    if (_topProducts.length > 10) {
      _topProducts = _topProducts.sublist(0, 10);
    }
  }
  
  double _calculateCost(SaleFirebase sale) {
    double cost = 0;
    
    for (final item in sale.items) {
      final medication = _medications.firstWhere(
        (med) => med.id == item.medicationId,
        orElse: () => MedicationFirebase(
          id: item.medicationId,
          name: 'Desconocido',
          description: '',
          stock: 0,
          purchasePrice: 0,
          sellingPrice: item.unitPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      cost += medication.purchasePrice * item.quantity;
    }
    
    return cost;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrativo'),
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
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros de período
                    _buildPeriodFilter(),
                    const SizedBox(height: 16),
                    
                    // Tarjetas de resumen
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    
                    // Gráfico de ventas mensuales
                    _buildMonthlySalesChart(),
                    const SizedBox(height: 24),
                    
                    // Gráfico de ganancias mensuales
                    _buildMonthlyProfitsChart(),
                    const SizedBox(height: 24),
                    
                    // Productos más vendidos
                    _buildTopProducts(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildPeriodFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por período',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'week',
                  label: Text('Última semana'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: 'month',
                  label: Text('Último mes'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment(
                  value: 'year',
                  label: Text('Último año'),
                  icon: Icon(Icons.calendar_today),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedPeriod = selection.first;
                });
                _processData();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: DashboardSummaryCard(
            title: 'Ventas Totales',
            value: CurrencyFormatter.format(_totalSales),
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardSummaryCard(
            title: 'Ganancias',
            value: CurrencyFormatter.format(_totalProfits),
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardSummaryCard(
            title: 'Transacciones',
            value: _totalTransactions.toString(),
            icon: Icons.receipt_long,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMonthlySalesChart() {
    if (_monthlySales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay datos de ventas disponibles'),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas Mensuales',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _monthlySales.values.isEmpty ? 100 : _monthlySales.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = _monthlySales.keys.elementAt(groupIndex);
                        final sales = _monthlySales.values.elementAt(groupIndex);
                        return BarTooltipItem(
                          '$month\n${CurrencyFormatter.format(sales)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= _monthlySales.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _monthlySales.keys.elementAt(value.toInt()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _monthlySales.values.isEmpty ? 20 : _monthlySales.values.reduce((a, b) => a > b ? a : b) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(
                    _monthlySales.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _monthlySales.values.elementAt(index),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
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
      ),
    );
  }
  
  Widget _buildMonthlyProfitsChart() {
    if (_monthlyProfits.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay datos de ganancias disponibles'),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganancias Mensuales',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _monthlyProfits.values.isEmpty ? 100 : _monthlyProfits.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = _monthlyProfits.keys.elementAt(groupIndex);
                        final profits = _monthlyProfits.values.elementAt(groupIndex);
                        return BarTooltipItem(
                          '$month\n${CurrencyFormatter.format(profits)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= _monthlyProfits.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _monthlyProfits.keys.elementAt(value.toInt()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _monthlyProfits.values.isEmpty ? 20 : _monthlyProfits.values.reduce((a, b) => a > b ? a : b) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(
                    _monthlyProfits.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _monthlyProfits.values.elementAt(index),
                          color: Colors.green,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
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
      ),
    );
  }
  
  Widget _buildTopProducts() {
    if (_topProducts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay datos de productos disponibles'),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos Más Vendidos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topProducts.length,
              itemBuilder: (context, index) {
                final product = _topProducts[index];
                final name = product['name'] as String;
                final quantity = product['quantity'] as int;
                final total = product['total'] as double;
                final profit = product['profit'] as double;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Cantidad vendida: $quantity'),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        CurrencyFormatter.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ganancia: ${CurrencyFormatter.format(profit)}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
