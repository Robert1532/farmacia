import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/sale_firebase.dart';
import '../../providers/sale_provider_firebase.dart';
import '../../utils/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_button.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;
  
  const SaleDetailScreen({
    Key? key,
    required this.saleId,
  }) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool _isLoading = true;
  SaleFirebase? _sale;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final saleProvider = Provider.of<SaleProviderFirebase>(context, listen: false);
      final sale = await saleProvider.fetchSaleById(widget.saleId);
      
      if (mounted) {
        setState(() {
          _sale = sale;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar la venta: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta venta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final saleProvider = Provider.of<SaleProviderFirebase>(context, listen: false);
        final success = await saleProvider.deleteSale(widget.saleId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venta eliminada correctamente')),
          );
          Navigator.of(context).pop(true); // Volver a la pantalla anterior
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Error al eliminar la venta';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error al eliminar la venta: ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        actions: [
          if (_sale != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSale,
              tooltip: 'Eliminar venta',
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
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.withAlpha(26)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Reintentar',
                        onPressed: _loadSale,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                )
              : _buildSaleDetails(),
    );
  }

  Widget _buildSaleDetails() {
    if (_sale == null) {
      return const Center(child: Text('No se encontró la venta'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información general
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Venta #${_sale!.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Chip(
                        label: Text(
                          _sale!.isPaid ? 'Pagado' : 'Pendiente',
                          style: TextStyle(
                            color: _sale!.isPaid ? Colors.white : Colors.black,
                          ),
                        ),
                        backgroundColor: _sale!.isPaid
                            ? Colors.green.withAlpha(204)
                            : Colors.amber.withAlpha(204),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Fecha', _formatDate(_sale!.date)),
                  _buildInfoRow('Vendedor', _sale!.employeeName),
                  _buildInfoRow('Método de pago', _sale!.paymentMethod),
                  if (_sale!.customerName != null)
                    _buildInfoRow('Cliente', _sale!.customerName!),
                  if (_sale!.customerPhone != null)
                    _buildInfoRow('Teléfono', _sale!.customerPhone!),
                  if (_sale!.notes != null && _sale!.notes!.isNotEmpty)
                    _buildInfoRow('Notas', _sale!.notes!),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Items de la venta
          const Text(
            'Productos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sale!.items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _sale!.items[index];
                return ListTile(
                  title: Text(item.medicationName),
                  subtitle: Text('${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}'),
                  trailing: Text(
                    CurrencyFormatter.format(item.quantity * item.unitPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Resumen de la venta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotalRow('Subtotal', _sale!.subtotal),
                  _buildTotalRow('Descuento', _sale!.discount, isDiscount: true),
                  const Divider(),
                  _buildTotalRow('Total', _sale!.total, isTotal: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            isDiscount ? '-${CurrencyFormatter.format(amount)}' : CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
