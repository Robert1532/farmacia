import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItemFirebase {
  final String id;
  final String saleId;
  final String medicationId;
  final String medicationName;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;

  SaleItemFirebase({
    this.id = '',
    this.saleId = '',
    required this.medicationId,
    required this.medicationName,
    required this.quantity,
    required this.unitPrice,
    double? total,
    DateTime? createdAt,
  }) : 
    total = total ?? (quantity * unitPrice),
    createdAt = createdAt ?? DateTime.now();

  factory SaleItemFirebase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleItemFirebase(
      id: doc.id,
      saleId: data['saleId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      quantity: data['quantity'] ?? 0,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'saleId': saleId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Getter para calcular el subtotal
  double get subtotal => quantity * unitPrice;
}
