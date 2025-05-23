import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationFirebase {
  final String id;
  final String name;
  final String? genericName;
  final String? description;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final String? shelfId;
  final DateTime? expirationDate;
  final DateTime? entryDate;
  final String? laboratory;
  final String? dosage;
  final String? presentation;
  final String? category;
  final bool? prescription;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationFirebase({
    required this.id,
    required this.name,
    this.genericName,
    this.description,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    this.shelfId,
    this.expirationDate,
    this.entryDate,
    this.laboratory,
    this.dosage,
    this.presentation,
    this.category,
    this.prescription,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationFirebase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationFirebase(
      id: doc.id,
      name: data['name'] ?? '',
      genericName: data['genericName'],
      description: data['description'],
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      shelfId: data['shelfId'],
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      entryDate: (data['entryDate'] as Timestamp?)?.toDate(),
      laboratory: data['laboratory'],
      dosage: data['dosage'],
      presentation: data['presentation'],
      category: data['category'],
      prescription: data['prescription'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'genericName': genericName,
      'description': description,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'shelfId': shelfId,
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
      'entryDate': entryDate != null ? Timestamp.fromDate(entryDate!) : null,
      'laboratory': laboratory,
      'dosage': dosage,
      'presentation': presentation,
      'category': category,
      'prescription': prescription,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MedicationFirebase copyWith({
    String? id,
    String? name,
    String? genericName,
    String? description,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    String? shelfId,
    DateTime? expirationDate,
    DateTime? entryDate,
    String? laboratory,
    String? dosage,
    String? category,
    bool? prescription,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationFirebase(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      shelfId: shelfId ?? this.shelfId,
      expirationDate: expirationDate ?? this.expirationDate,
      entryDate: entryDate ?? this.entryDate,
      laboratory: laboratory ?? this.laboratory,
      dosage: dosage ?? this.dosage,
      presentation: presentation ?? this.presentation,
      category: category ?? this.category,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper properties for expiration status
  bool get isExpired {
    if (expirationDate == null) return false;
    if (stock <= 0) return false; // No mostrar medicamentos sin stock
    return expirationDate!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    if (stock <= 0) return false; // No mostrar medicamentos sin stock
    final now = DateTime.now();
    final difference = expirationDate!.difference(now).inDays;
    return difference >= 0 && difference <= 7;
  }

  bool get isExpiringInMonth {
    if (expirationDate == null) return false;
    if (stock <= 0) return false; // No mostrar medicamentos sin stock
    final now = DateTime.now();
    final difference = expirationDate!.difference(now).inDays;
    return difference > 7 && difference <= 30;
  }

  bool get isExpiringInTwoMonths {
    if (expirationDate == null) return false;
    if (stock <= 0) return false; // No mostrar medicamentos sin stock
    final now = DateTime.now();
    final difference = expirationDate!.difference(now).inDays;
    return difference > 30 && difference <= 60;
  }

  bool get isExpiringInThreeMonths {
    if (expirationDate == null) return false;
    if (stock <= 0) return false; // No mostrar medicamentos sin stock
    final now = DateTime.now();
    final difference = expirationDate!.difference(now).inDays;
    return difference > 60 && difference <= 90;
  }

  // Calculate suggested selling price based on purchase price
  double calculateSuggestedPrice() {
    // Basic markup of 30%
    double basicMarkup = purchasePrice * 1.3;
    
    // Adjust based on expiration date
    if (expirationDate != null) {
      final now = DateTime.now();
      final daysUntilExpiration = expirationDate!.difference(now).inDays;
      
      // If expiring soon, reduce the price
      if (daysUntilExpiration < 30 && daysUntilExpiration > 0) {
        // Gradually reduce price as expiration approaches
        double discountFactor = 1.0 - ((30 - daysUntilExpiration) / 100);
        return basicMarkup * discountFactor;
      }
    }
    
    // Adjust based on stock levels
    if (stock > 20) {
      // High stock, slightly lower price
      return basicMarkup * 0.95;
    } else if (stock < 5) {
      // Low stock, slightly higher price
      return basicMarkup * 1.05;
    }
    
    return basicMarkup;
  }

  // Get multiple price suggestions
  List<Map<String, dynamic>> getPriceSuggestions() {
    final basePrice = calculateSuggestedPrice();
    
    return [
      {
        'label': 'Estándar (30% margen)',
        'price': purchasePrice * 1.3,
        'description': 'Precio con margen estándar del 30%'
      },
      {
        'label': 'Competitivo',
        'price': basePrice * 0.95,
        'description': 'Precio competitivo para aumentar ventas'
      },
      {
        'label': 'Premium',
        'price': basePrice * 1.1,
        'description': 'Precio premium para productos de alta demanda'
      }
    ];
  }
}
