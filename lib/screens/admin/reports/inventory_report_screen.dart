import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/currency_formatter.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  bool _isLoading = true;
  List<MedicationFirebase> _medications = [];
  Map<String, List<MedicationFirebase>> _expiringMedications = {};
  double _totalInventoryValue = 0;
  int _totalMedications = 0;
  int _lowStockCount = 0;
  int _expiringCount = 0;
  
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
      await medicationProvider.fetchMedications();
      
      _medications = medicationProvider.medications;
      _expiringMedications = medicationProvider.getExpiringMedications();
      
      // Calcular estadísticas
      _totalInventoryValue = _medications.fold(0, (sum, med) => sum + (med.sellingPrice * med.stock));
      _totalMedications = _medications.length;
      _lowStockCount = _medications.where((med) => med.stock < 10).length;
      
      // Contar medicamentos por expirar
      _expiringCount = [
        ...?_expiringMedications['sevenDays'],
        ...?_expiringMedications['thirtyDays'],
        ...?_expiringMedications['sixtyDays'],
        ...?_expiringMedications['ninetyDays'],
      ].length;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos de inventario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Inventario'),
        actions: [
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
                  // Resumen de inventario
                  _buildInventorySummary(),
                  
                  const SizedBox(height: 24),
                  
                  // Gráfico de valor de inventario por categoría
                  _buildInventoryValueByCategory(),
                  
                  const SizedBox(height: 24),
                  
                  // Gráfico de medicamentos por expirar
                  _buildExpiringMedicationsChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Tabla de medicamentos con bajo stock
                  _buildLowStockTable(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInventorySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Inventario',
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
                            'Valor Total',
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
                            Icons.medication,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Medicamentos',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _totalMedications.toString(),
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
                            Icons.warning_amber,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock Bajo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lowStockCount.toString(),
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
                            Icons.event_busy,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Por Expirar',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _expiringCount.toString(),
                        style: const TextStyle(
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
          ],
        ),
      ],
    );
  }
  
  Widget _buildInventoryValueByCategory() {
    // Agrupar medicamentos por categoría
    final Map<String, double> valueByCategory = {};
    
    for (final med in _medications) {
      final category = med.category ?? 'Sin categoría';
      final value = med.sellingPrice * med.stock;
      
      if (valueByCategory.containsKey(category)) {
        valueByCategory[category] = valueByCategory[category]! + value;
      } else {
        valueByCategory[category] = value;
      }
    }
    
    // Ordenar por valor
    final sortedCategories = valueByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Colores para el gráfico
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    // Preparar datos para el gráfico
    final pieChartSections = <PieChartSectionData>[];
    
    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final color = colors[i % colors.length];
      
      pieChartSections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valor de Inventario por Categoría',
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
                  children: [
                    for (int i = 0; i < sortedCategories.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: colors[i % colors.length],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sortedCategories[i].key,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(sortedCategories[i].value),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpiringMedicationsChart() {
    // Preparar datos para el gráfico
    final expiringData = [
      _expiringMedications['sevenDays']?.length ?? 0,
      _expiringMedications['thirtyDays']?.length ?? 0,
      _expiringMedications['sixtyDays']?.length ?? 0,
      _expiringMedications['ninetyDays']?.length ?? 0,
    ];
    
    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: expiringData[0].toDouble(),
            color: Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: expiringData[1].toDouble(),
            color: Colors.orange,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: expiringData[2].toDouble(),
            color: Colors.amber,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: expiringData[3].toDouble(),
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicamentos por Expirar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (expiringData.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      switch (value.toInt()) {
                        case 0:
                          text = '7 días';
                          break;
                        case 1:
                          text = '30 días';
                          break;
                        case 2:
                          text = '60 días';
                          break;
                        case 3:
                          text = '90 días';
                          break;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(text),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(value.toInt().toString()),
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
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('7 días', Colors.red),
            const SizedBox(width: 16),
            _buildLegendItem('30 días', Colors.orange),
            const SizedBox(width: 16),
            _buildLegendItem('60 días', Colors.amber),
            const SizedBox(width: 16),
            _buildLegendItem('90 días', Colors.green),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
  
  Widget _buildLowStockTable() {
    // Filtrar medicamentos con bajo stock
    final lowStockMeds = _medications
        .where((med) => med.stock < 10)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicamentos con Bajo Stock',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        lowStockMeds.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay medicamentos con bajo stock',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockMeds.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final med = lowStockMeds[index];
                    return ListTile(
                      title: Text(med.name),
                      subtitle: Text(med.genericName ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: med.stock <= 5 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: ${med.stock}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/medication-detail',
                          arguments: {'medicationId': med.id},
                        );
                      },
                    );
                  },
                ),
              ),
      ],
    );
  }
}
