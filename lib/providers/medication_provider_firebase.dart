import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_firebase.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class MedicationProviderFirebase with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<MedicationFirebase> _medications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  List<MedicationFirebase> get medications => _medications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Obtener todos los medicamentos
  Future<List<MedicationFirebase>> fetchMedications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final querySnapshot = await _firebaseService.medicationsCollection.get();
      
      _medications = querySnapshot.docs
          .map((doc) => MedicationFirebase.fromFirestore(doc))
          .toList();
      
      notifyListeners();
      return _medications;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener un medicamento por ID
  Future<MedicationFirebase?> fetchMedicationById(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final docSnapshot = await _firebaseService.medicationsCollection.doc(id).get();
      
      if (!docSnapshot.exists) {
        _errorMessage = 'Medicamento no encontrado';
        notifyListeners();
        return null;
      }
      
      final medication = MedicationFirebase.fromFirestore(docSnapshot);
      
      // Actualizar la lista local si ya existe
      final index = _medications.indexWhere((med) => med.id == id);
      if (index >= 0) {
        _medications[index] = medication;
      } else {
        _medications.add(medication);
      }
      
      notifyListeners();
      return medication;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Agregar un nuevo medicamento
  Future<String?> addMedication(MedicationFirebase medication) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Crear un nuevo documento con ID generado
      final docRef = _firebaseService.medicationsCollection.doc();
      
      // Crear objeto con ID asignado
      final newMedication = MedicationFirebase(
        id: docRef.id,
        name: medication.name,
        genericName: medication.genericName,
        description: medication.description,
        purchasePrice: medication.purchasePrice,
        sellingPrice: medication.sellingPrice,
        expirationDate: medication.expirationDate,
        laboratory: medication.laboratory,
        dosage: medication.dosage,
        presentation: medication.presentation,
        stock: medication.stock,
        shelfId: medication.shelfId,
        entryDate: medication.entryDate ?? DateTime.now(),
        category: medication.category,
        prescription: medication.prescription,
        notes: medication.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Guardar en Firestore
      await docRef.set(newMedication.toFirestore());
      
      // Actualizar lista local
      _medications.add(newMedication);
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
  
  // Actualizar un medicamento existente
  Future<bool> updateMedication(MedicationFirebase medication) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Actualizar fecha de modificación
      final updatedMedication = medication.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Actualizar en Firestore
      await _firebaseService.medicationsCollection
          .doc(medication.id)
          .update(updatedMedication.toFirestore());
      
      // Actualizar lista local
      final index = _medications.indexWhere((med) => med.id == medication.id);
      if (index >= 0) {
        _medications[index] = updatedMedication;
      }
      
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
  
  // Actualizar solo el stock de un medicamento
  Future<bool> updateMedicationStock(String id, int newStock, String reason) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Obtener el medicamento actual
      final docSnapshot = await _firebaseService.medicationsCollection.doc(id).get();
      
      if (!docSnapshot.exists) {
        _errorMessage = 'Medicamento no encontrado';
        notifyListeners();
        return false;
      }
      
      final medication = MedicationFirebase.fromFirestore(docSnapshot);
      
      // Actualizar stock y fecha de modificación
      final updatedMedication = medication.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      
      // Actualizar en Firestore
      await _firebaseService.medicationsCollection
          .doc(id)
          .update({
            'stock': newStock,
            'updatedAt': Timestamp.now(),
          });
      
      // Registrar el ajuste de inventario (opcional)
      await _firebaseService.firestore.collection('inventory_adjustments').add({
        'medicationId': id,
        'medicationName': medication.name,
        'previousStock': medication.stock,
        'newStock': newStock,
        'difference': newStock - medication.stock,
        'reason': reason,
        'timestamp': Timestamp.now(),
      });
      
      // Actualizar lista local
      final index = _medications.indexWhere((med) => med.id == id);
      if (index >= 0) {
        _medications[index] = updatedMedication;
      }
      
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
  
  // Eliminar un medicamento
  Future<bool> deleteMedication(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Eliminar de Firestore
      await _firebaseService.medicationsCollection.doc(id).delete();
      
      // Eliminar de la lista local
      _medications.removeWhere((med) => med.id == id);
      
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
  
  // Obtener medicamentos por estante
  List<MedicationFirebase> getMedicationsByShelf(String shelfId) {
    return _medications.where((med) => med.shelfId == shelfId).toList();
  }
  
  // Obtener medicamentos con bajo stock
  List<MedicationFirebase> getLowStockMedications(int threshold) {
    return _medications.where((med) => med.stock < threshold && med.stock > 0).toList();
  }
  
  // Obtener medicamentos por vencer
  Map<String, List<MedicationFirebase>> getExpiringMedications() {
    final now = DateTime.now();
    
    // Filtrar medicamentos con stock > 0
    final medicationsWithStock = _medications.where((med) => med.stock > 0).toList();
    
    // Medicamentos vencidos
    final expired = medicationsWithStock
        .where((med) => med.expirationDate != null && med.expirationDate!.isBefore(now))
        .toList();
    
    // Medicamentos que vencen en 7 días
    final sevenDays = medicationsWithStock
        .where((med) => 
          med.expirationDate != null && 
          !med.isExpired &&
          med.isExpiringSoon)
        .toList();
    
    // Medicamentos que vencen en 30 días
    final thirtyDays = medicationsWithStock
        .where((med) => 
          med.expirationDate != null && 
          !med.isExpired &&
          !med.isExpiringSoon &&
          med.isExpiringInMonth)
        .toList();
    
    // Medicamentos que vencen en 60 días
    final sixtyDays = medicationsWithStock
        .where((med) => 
          med.expirationDate != null && 
          !med.isExpired &&
          !med.isExpiringSoon &&
          !med.isExpiringInMonth &&
          med.isExpiringInTwoMonths)
        .toList();
    
    // Medicamentos que vencen en 90 días
    final ninetyDays = medicationsWithStock
        .where((med) => 
          med.expirationDate != null && 
          !med.isExpired &&
          !med.isExpiringSoon &&
          !med.isExpiringInMonth &&
          !med.isExpiringInTwoMonths &&
          med.isExpiringInThreeMonths)
        .toList();
    
    return {
      'expired': expired,
      'sevenDays': sevenDays,
      'thirtyDays': thirtyDays,
      'sixtyDays': sixtyDays,
      'ninetyDays': ninetyDays,
    };
  }
  
  // Buscar medicamentos por nombre, código de barras o descripción
  List<MedicationFirebase> searchMedications(String query) {
    if (query.isEmpty) return _medications;
    
    final lowercaseQuery = query.toLowerCase();
    
    return _medications.where((med) {
      return med.name.toLowerCase().contains(lowercaseQuery) ||
             (med.description != null && med.description!.toLowerCase().contains(lowercaseQuery)) ||
             (med.genericName != null && med.genericName!.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
  
  // Obtener un medicamento por ID (versión sincrónica)
  MedicationFirebase? getMedicationById(String id) {
    try {
      return _medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }

  // Método para actualizar medicamentos (reemplaza refreshMedications)
  Future<void> refreshMedications() async {
    await fetchMedications();
  }

  // Método para actualizar la cantidad de un medicamento
  Future<bool> updateMedicationQuantity(String id, int newQuantity) async {
    return updateMedicationStock(id, newQuantity, 'Actualización manual de stock');
  }
  
  // Obtener sugerencias de precio para un medicamento
  List<Map<String, dynamic>> getPriceSuggestions(String id) {
    final medication = getMedicationById(id);
    if (medication == null) {
      return [];
    }
    
    return medication.getPriceSuggestions();
  }
}
