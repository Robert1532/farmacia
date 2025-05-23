import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_firebase.dart';
import '../models/sale_item_firebase.dart';
import '../services/firebase_service.dart';
import 'medication_provider_firebase.dart';

class SaleProviderFirebase with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final MedicationProviderFirebase _medicationProvider;

  List<SaleFirebase> _sales = [];
  bool _isLoading = false;
  String _errorMessage = '';

  SaleProviderFirebase(this._medicationProvider);

  List<SaleFirebase> get sales => _sales;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Obtener todas las ventas
  Future<List<SaleFirebase>> fetchSales() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final querySnapshot = await _firebaseService.salesCollection
          .orderBy('date', descending: true)
          .get();
      
      _sales = querySnapshot.docs
          .map((doc) => SaleFirebase.fromFirestore(doc))
          .toList();
      
      notifyListeners();
      return _sales;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener una venta por ID
  Future<SaleFirebase?> fetchSaleById(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final docSnapshot = await _firebaseService.salesCollection.doc(id).get();
      
      if (!docSnapshot.exists) {
        _errorMessage = 'Venta no encontrada';
        notifyListeners();
        return null;
      }
      
      final sale = SaleFirebase.fromFirestore(docSnapshot);
      
      // Actualizar la lista local si ya existe
      final index = _sales.indexWhere((s) => s.id == id);
      if (index >= 0) {
        _sales[index] = sale;
      } else {
        _sales.add(sale);
      }
      
      notifyListeners();
      return sale;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear una nueva venta
  Future<String?> addSale({
    required String employeeId,
    required String employeeName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double total,
    String? customerName,
    String? customerPhone,
    String? notes,
    required String paymentMethod,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Crear un nuevo documento con ID generado
      final docRef = _firebaseService.salesCollection.doc();
      
      // Convertir items a formato adecuado
      final saleItems = items.map((item) => SaleItemFirebase(
        medicationId: item['medicationId'],
        medicationName: item['medicationName'],
        quantity: item['quantity'],
        unitPrice: (item['unitPrice'] as num).toDouble(),
      )).toList();
      
      // Crear objeto de venta
      final newSale = SaleFirebase(
        id: docRef.id,
        employeeId: employeeId,
        employeeName: employeeName,
        items: saleItems,
        subtotal: subtotal,
        discount: discount,
        total: total,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        paymentMethod: paymentMethod,
        date: date,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Guardar en Firestore
      await docRef.set(newSale.toFirestore());
      
      // Actualizar inventario
      for (final item in items) {
        final medicationId = item['medicationId'];
        final quantity = item['quantity'] as int;
        
        // Obtener medicamento actual
        final medication = await _medicationProvider.fetchMedicationById(medicationId);
        
        if (medication != null) {
          // Actualizar stock
          final newStock = medication.stock - quantity;
          await _medicationProvider.updateMedicationStock(
            medicationId,
            newStock,
            'Venta: ${docRef.id}',
          );
        }
      }
      
      // Actualizar lista local
      _sales.add(newSale);
      notifyListeners();
      
      return docRef.id;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar una venta
  Future<bool> deleteSale(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Obtener la venta para restaurar el inventario
      final saleDoc = await _firebaseService.salesCollection.doc(id).get();
      
      if (!saleDoc.exists) {
        _errorMessage = 'Venta no encontrada';
        notifyListeners();
        return false;
      }
      
      final saleData = saleDoc.data() as Map<String, dynamic>?;
      if (saleData == null) {
        _errorMessage = 'Datos de venta no encontrados';
        notifyListeners();
        return false;
      }
      
      final items = saleData['items'] as List<dynamic>?;
      if (items != null) {
        // Restaurar inventario
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            await _restoreInventory(
              medicationId: item['medicationId'],
              quantity: item['quantity'],
            );
          }
        }
      }
      
      // Eliminar documento en Firestore
      await _firebaseService.salesCollection.doc(id).delete();
      
      // Actualizar lista local
      _sales.removeWhere((sale) => sale.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método interno para restaurar el inventario
  Future<void> _restoreInventory({
    required String medicationId,
    required int quantity,
  }) async {
    try {
      // Obtener medicamento
      final medicationDoc = await _firebaseService.medicationsCollection.doc(medicationId).get();
      
      if (!medicationDoc.exists) {
        throw Exception('Medicamento no encontrado');
      }
      
      final data = medicationDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Datos de medicamento no encontrados');
      }
      
      // Obtener stock actual
      final currentStock = data['stock'] ?? 0;
      
      // Actualizar stock
      await _firebaseService.medicationsCollection.doc(medicationId).update({
        'stock': currentStock + quantity,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al restaurar inventario: ${e.toString()}');
    }
  }
}
