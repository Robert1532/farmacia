import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmacia/models/sale_firebase.dart';
import 'package:farmacia/models/sale_item_firebase.dart';
import 'package:farmacia/providers/sale_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/currency_formatter.dart';
import 'package:farmacia/widgets/date_range_picker.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  bool _isLoading = true;
  List<SaleFirebase> _sales = [];
  List<SaleFirebase> _filteredSales = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Estadísticas
  double _totalSales = 0;
  double _totalProfits = 0;
  int _totalTransactions = 0;
  double _averageTicket = 0;
  
  // Datos para gráficos
  Map<String, double> _salesByDay = {};
  Map<String, int> _salesByPaymentMethod = {};
  Map<String, double> _topProducts = {};
  
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
      await saleProvider.fetchSales();
      
      _sales = saleProvider.sales;
      _filterSales();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos de ventas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterSales() {
    // Filtrar ventas por rango de fechas
    _filteredSales = _sales.where((sale) {
      return sale.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             sale.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
    
    // Calcular estadísticas
    _calculateStatistics();
    
    // Preparar datos para gráficos
    _prepareSalesByDay();
    _prepareSalesByPaymentMethod();
    _prepareTopProducts();
  }
  
  void _calculateStatistics() {
    _totalSales = _filteredSales.fold(0, (sum, sale) => sum + sale.total);
    _totalProfits = _filteredSales.fold(0, (sum, sale) => sum + sale.profit);
    _totalTransactions = _filteredSales.length;
    _averageTicket = _totalTransactions > 0 ? _totalSales / _totalTransactions : 0;
  }
  
  void _prepareSalesByDay() {
    _salesByDay = {};
    
    // Formato para las fechas
    final dateFormat = DateFormat('dd/MM');
    
    // Inicializar mapa con todas las fechas en el rango
    for (DateTime date = _startDate;
         date.isBefore(_endDate.add(const Duration(days: 1)));
         date = date.add(const Duration(days: 1))) {
      final dateKey = dateFormat.format(date);
      _salesByDay[dateKey] = 0;
    }
    
    // Sumar ventas por día
    for (final sale in _filteredSales) {
      final dateKey = dateFormat.format(sale.date);
      _salesByDay[dateKey] = (_salesByDay[dateKey] ?? 0) + sale.total;
    }
  }
  
  void _prepareSalesByPaymentMethod() {
    _salesByPaymentMethod = {};
    
    // Contar ventas por método de pago
    for (final sale in _filteredSales) {
      final method = sale.paymentMethod;
      _salesByPaymentMethod[method] = (_salesByPaymentMethod[method] ?? 0) + 1;
    }
  }
  
  void _prepareTopProducts() {
    _topProducts = {};
    
    // Agrupar ventas por producto
    for (final sale in _filteredSales) {
      for (final item in sale.items) {
        final productName = item.medicationName;
        _topProducts[productName] = (_topProducts[productName] ?? 0) + (item.quantity * item.unitPrice);
      }
    }
    
    // Ordenar y limitar a los 5 principales
    final sortedProducts = _topProducts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedProducts.length > 5) {
      _topProducts = Map.fromEntries(sortedProducts.take(5));
    }
  }
  
  Future<void> _selectDateRange() async {
    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) => DateRangePicker(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );
    
    if (result != null) {
      setState(() {
        _startDate = result['startDate']!;
        _endDate = result['endDate']!;
      });
      
      _filterSales();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rango de fechas seleccionado
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Desde: ${DateFormat('dd/MM/yyyy').format(_startDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Hasta: ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Resumen de ventas
                  _buildSalesSummary(),
                  
                  const SizedBox(height: 24),
                  
                  // Gráfico de ventas por día
                  _buildSalesByDayChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Gráfico de métodos de pago
                  _buildPaymentMethodsChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Productos más vendidos
                  _buildTopProductsChart(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSalesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Ventas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ventas Totales',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormatter.format(_totalSales),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ganancias',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormatter.format(_totalProfits),
                        style: const TextStyle(
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
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transacciones',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _totalTransactions.toString(),
                        style: const TextStyle(
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
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ticket Promedio',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormatter.format(_averageTicket),
                        style: const TextStyle(
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
          ],
        ),
      ],
    );
  }
  
  Widget _buildSalesByDayChart() {
    // Preparar datos para el gráfico
    final spots = <FlSpot>[];
    final labels = <String>[];
    
    int index = 0;
    _salesByDay.forEach((day, sales) {
      spots.add(FlSpot(index.toDouble(), sales));
      labels.add(day);
      index++;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ventas por Día',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
                        // Mostrar solo algunas fechas para evitar solapamiento
                        if (labels.length <= 10 || value.toInt() % (labels.length ~/ 10 + 1) == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          CurrencyFormatter.format(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 0,
              maxX: (labels.length - 1).toDouble(),
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentMethodsChart() {
    // Colores para el gráfico
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    
    // Preparar datos para el gráfico
    final pieChartSections = <PieChartSectionData>[];
    final legends = <Widget>[];
    
    int index = 0;
    _salesByPaymentMethod.forEach((method, count) {
      final color = colors[index % colors.length];
      final percentage = count / _totalTransactions * 100;
      
      pieChartSections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(method),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
      
      index++;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métodos de Pago',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: pieChartSections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legends,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTopProductsChart() {
    // Preparar datos para el gráfico
    final barGroups = <BarChartGroupData>[];
    final labels = <String>[];
    
    int index = 0;
    _topProducts.forEach((product, sales) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      labels.add(product);
      index++;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos Más Vendidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: 60,
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          CurrencyFormatter.format(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
