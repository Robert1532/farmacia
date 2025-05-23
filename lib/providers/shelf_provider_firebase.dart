import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shelf_firebase.dart';
import '../services/firebase_service.dart';

class ShelfProviderFirebase with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<ShelfFirebase> _shelves = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  List<ShelfFirebase> get shelves => _shelves;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Obtener todos los estantes
  Future<List<ShelfFirebase>> fetchShelves() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final querySnapshot = await _firebaseService.shelvesCollection
          .orderBy('name')
          .get();
      
      _shelves = querySnapshot.docs
          .map((doc) => ShelfFirebase.fromFirestore(doc))
          .toList();
      
      notifyListeners();
      return _shelves;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener un estante por ID
  ShelfFirebase? getShelfById(String id) {
    try {
      return _shelves.firstWhere((shelf) => shelf.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Obtener un estante por ID desde Firebase
  Future<ShelfFirebase?> fetchShelfById(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final docSnapshot = await _firebaseService.shelvesCollection.doc(id).get();
      
      if (!docSnapshot.exists) {
        _errorMessage = 'Estante no encontrado';
        notifyListeners();
        return null;
      }
      
      final shelf = ShelfFirebase.fromFirestore(docSnapshot);
      
      // Actualizar la lista local si ya existe
      final index = _shelves.indexWhere((s) => s.id == id);
      if (index >= 0) {
        _shelves[index] = shelf;
      } else {
        _shelves.add(shelf);
      }
      
      notifyListeners();
      return shelf;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Crear un nuevo estante
  Future<bool> addShelf({
    required String name,
    String? location,
    int? capacity,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Crear documento en Firestore
      final docRef = _firebaseService.shelvesCollection.doc();
      
      final shelfData = {
        'name': name,
        'location': location ?? '',
        'capacity': capacity ?? 0,
        'description': description,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      await docRef.set(shelfData);
      
      // Crear objeto local
      final newShelf = ShelfFirebase(
        id: docRef.id,
        name: name,
        location: location ?? '',
        capacity: capacity ?? 0,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Actualizar lista local
      _shelves.add(newShelf);
      
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
  
  // Actualizar un estante existente
  Future<bool> updateShelf(ShelfFirebase shelf) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Actualizar documento en Firestore
      await _firebaseService.shelvesCollection.doc(shelf.id).update({
        'name': shelf.name,
        'location': shelf.location,
        'capacity': shelf.capacity,
        'description': shelf.description,
        'updatedAt': Timestamp.now(),
      });
      
      // Actualizar objeto local
      final index = _shelves.indexWhere((s) => s.id == shelf.id);
      if (index >= 0) {
        _shelves[index] = shelf.copyWith(
          updatedAt: DateTime.now(),
        );
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
  
  // Eliminar un estante
  Future<bool> deleteShelf(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Comprobar si hay medicamentos asociados a este estante
      final medicationsSnapshot = await _firebaseService.medicationsCollection
          .where('shelfId', isEqualTo: id)
          .get();
      
      if (medicationsSnapshot.docs.isNotEmpty) {
        _errorMessage = 'No se puede eliminar el estante porque tiene medicamentos asociados';
        notifyListeners();
        return false;
      }
      
      // Eliminar documento en Firestore
      await _firebaseService.shelvesCollection.doc(id).delete();
      
      // Actualizar lista local
      _shelves.removeWhere((shelf) => shelf.id == id);
      
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
  
  // Obtener estantes con medicamentos próximos a vencer
  Future<List<Map<String, dynamic>>> getShelvesWithExpiringMedications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Primero, obtener todos los estantes
      await fetchShelves();
      
      // Luego, para cada estante, obtener los medicamentos que están próximos a vencer
      final result = <Map<String, dynamic>>[];
      
      for (final shelf in _shelves) {
        // Obtener medicamentos de este estante
        final medicationsSnapshot = await _firebaseService.medicationsCollection
            .where('shelfId', isEqualTo: shelf.id)
            .get();
        
        // Filtrar medicamentos que vencen en los próximos 30 días
        final now = DateTime.now();
        final expiringMedications = medicationsSnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) return null;
              
              final expirationDate = data['expirationDate'] != null
                  ? (data['expirationDate'] as Timestamp).toDate()
                  : null;
              
              return {
                'id': doc.id,
                'name': data['name'] ?? '',
                'expirationDate': expirationDate,
                'isExpiring': expirationDate != null &&
                    expirationDate.isAfter(now) &&
                    expirationDate.difference(now).inDays <= 30,
              };
            })
            .where((med) => med != null && med['isExpiring'] == true)
            .toList();
        
        if (expiringMedications.isNotEmpty) {
          result.add({
            'shelf': shelf,
            'expiringMedications': expiringMedications,
          });
        }
      }
      
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
