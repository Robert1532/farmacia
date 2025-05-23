import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/models/medication_firebase.dart';
import 'package:farmacia/models/sale_item_firebase.dart';
import 'package:farmacia/providers/auth_provider_firebase.dart';
import 'package:farmacia/providers/medication_provider_firebase.dart';
import 'package:farmacia/providers/sale_provider_firebase.dart';
import 'package:farmacia/utils/app_colors.dart';
import 'package:farmacia/utils/currency_formatter.dart';
import 'package:farmacia/widgets/custom_button.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({Key? key}) : super(key: key);

  @override
  _NewSaleScreenState createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<MedicationFirebase> _medications = [];
  List<MedicationFirebase> _filteredMedications = [];
  List<SaleItemFirebase> _cartItems = [];
  String _paymentMethod = 'Efectivo';
  bool _isLoading = false;
  double _subtotal = 0;
  double _discount = 0;
  double _total = 0;
  
  @override
  void initState() {
    super.initState();
    _loadMedications();
  }
  
  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _searchController.dispose();
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
        _medications = medicationProvider.medications
            .where((med) => med.stock > 0)
            .toList();
        _filteredMedications = _medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar medicamentos: $e')),
        );
      }
    }
  }
  
void _filterMedications(String query) {
  setState(() {
    if (query.isEmpty) {
      _filteredMedications = _medications;
    } else {
      _filteredMedications = _medications.where((med) {
        return med.name.toLowerCase().contains(query.toLowerCase()) ||
               (med.genericName != null && med.genericName!.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }
  });
}

  
  void _addToCart(MedicationFirebase medication) {
    // Check if already in cart
    final existingIndex = _cartItems.indexWhere(
      (item) => item.medicationId == medication.id
    );
    
    if (existingIndex >= 0) {
      // Update quantity if already in cart
      final existingItem = _cartItems[existingIndex];
      if (existingItem.quantity < medication.stock) {
        setState(() {
          _cartItems[existingIndex] = SaleItemFirebase(
            medicationId: medication.id,
            medicationName: medication.name,
            quantity: existingItem.quantity + 1,
            unitPrice: medication.sellingPrice,
          );
        });
        
        // Mostrar alerta de producto añadido
        _showAddedToCartDialog(medication.name, existingItem.quantity + 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuficiente para ${medication.name}')),
        );
      }
    } else {
      // Add new item to cart
      setState(() {
        _cartItems.add(SaleItemFirebase(
          medicationId: medication.id,
          medicationName: medication.name,
          quantity: 1,
          unitPrice: medication.sellingPrice,
        ));
      });
      
      // Mostrar alerta de producto añadido
      _showAddedToCartDialog(medication.name, 1);
    }
    
    _updateTotals();
  }
  
  // Nuevo método para mostrar diálogo de producto añadido
  void _showAddedToCartDialog(String productName, int quantity) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Cerrar automáticamente después de 1.5 segundos
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                'Producto añadido',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$productName (Cantidad: $quantity)',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    
    _updateTotals();
  }
  
  void _updateItemQuantity(int index, int newQuantity) {
    final item = _cartItems[index];
    final medication = _medications.firstWhere(
      (med) => med.id == item.medicationId,
      orElse: () => MedicationFirebase(
        id: '',
        name: '',
        purchasePrice: 0,
        sellingPrice: 0,
        stock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }
    
    if (newQuantity > medication.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente para ${medication.name}')),
      );
      return;
    }
    
    setState(() {
      _cartItems[index] = SaleItemFirebase(
        medicationId: item.medicationId,
        medicationName: item.medicationName,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
      );
    });
    
    _updateTotals();
  }
  
 void _updateTotals() {
  double subtotal = 0;

  for (final item in _cartItems) {
    subtotal += item.quantity * item.unitPrice;
  }

  final total = subtotal - _discount;

  setState(() {
    _subtotal = subtotal;
    _total = total;
  });
}

  void _applyDiscount(double discount) {
    if (discount < 0 || discount > _subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descuento inválido')),
      );
      return;
    }
    
    setState(() {
      _discount = discount;
    });
    
    _updateTotals();
  }
  
  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos al carrito')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProviderFirebase>(context, listen: false);
      final saleProvider = Provider.of<SaleProviderFirebase>(context, listen: false);
      
      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Convert cart items to the format expected by addSale
      final items = _cartItems.map((item) => {
        'medicationId': item.medicationId,
        'medicationName': item.medicationName,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'total': item.quantity * item.unitPrice,
      }).toList();
      
      // Create the sale
      final saleId = await saleProvider.addSale(
        employeeId: user.id,
        employeeName: user.name,
        items: items,
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        customerName: _customerNameController.text.isEmpty ? null : _customerNameController.text,
        customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        paymentMethod: _paymentMethod,
        date: DateTime.now(),
      );
      
      if (saleId != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta completada con éxito. ID: $saleId')),
        );
        
        // Clear form and cart
        _customerNameController.clear();
        _customerPhoneController.clear();
        _notesController.clear();
        setState(() {
          _cartItems = [];
          _subtotal = 0;
          _discount = 0;
          _total = 0;
        });
        
        // Navigate back or to receipt screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al completar la venta: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
      ),
      body: _isLoading && _medications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: _buildMobileLayout(),
            ),
    );
  }
  
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar medicamentos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterMedications('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterMedications,
          ),
        ),
        
        // Tab view for products and cart
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Productos'),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart),
                          SizedBox(width: 8),
                          Text('Carrito'),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Products grid
                      _buildProductsGrid(),
                      
                      // Cart
                      _buildCartView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Customer info and payment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Customer name
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              
              // Customer phone
              TextFormField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              
              // Payment method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Efectivo',
                    child: Text('Efectivo'),
                  ),
                  DropdownMenuItem(
                    value: 'Tarjeta',
                    child: Text('Tarjeta'),
                  ),
                  DropdownMenuItem(
                    value: 'Transferencia',
                    child: Text('Transferencia'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Complete sale button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Completar Venta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProductsGrid() {
    return _filteredMedications.isEmpty
        ? const Center(child: Text('No se encontraron medicamentos'))
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _filteredMedications.length,
            itemBuilder: (context, index) {
              final medication = _filteredMedications[index];
              return _buildProductCard(medication);
            },
          );
  }
  
  Widget _buildCartView() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.shopping_cart),
                SizedBox(width: 8),
                Text(
                  'Carrito de Compras',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Cart items
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Text('No hay productos en el carrito'),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(index);
                    },
                  ),
          ),
          
          // Cart summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(
                      CurrencyFormatter.format(_subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
              
                // Discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Descuento:'),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(_discount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: _showDiscountDialog,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductCard(MedicationFirebase medication) {
    return Card(
      child: InkWell(
        onTap: () => _addToCart(medication),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Product icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              // Product name
              Text(
                medication.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // Product price
              Text(
                CurrencyFormatter.format(medication.sellingPrice),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // Stock
              Text(
                'Stock: ${medication.stock}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCartItem(int index) {
    final item = _cartItems[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _removeFromCart(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CurrencyFormatter.format(item.unitPrice)} x ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  CurrencyFormatter.format(item.unitPrice * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateItemQuantity(index, item.quantity - 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDiscountDialog() {
    final discountController = TextEditingController(text: _discount.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aplicar Descuento'),
        content: TextField(
          controller: discountController,
          decoration: const InputDecoration(
            labelText: 'Monto del Descuento',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text) ?? 0;
              _applyDiscount(discount);
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
