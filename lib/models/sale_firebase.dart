import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmacia/models/sale_item_firebase.dart';

class SaleFirebase {
  final String id;
  final String employeeId;
  final String employeeName;
  final List<SaleItemFirebase> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final String paymentMethod;
  final bool isPaid;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  SaleFirebase({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.customerName,
    this.customerPhone,
    this.notes,
    required this.paymentMethod,
    this.isPaid = true,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleFirebase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir la lista de items
    List<SaleItemFirebase> items = [];
    if (data['items'] != null) {
      items = (data['items'] as List).map((item) {
        return SaleItemFirebase(
          medicationId: item['medicationId'] ?? '',
          medicationName: item['medicationName'] ?? '',
          quantity: item['quantity'] ?? 0,
          unitPrice: (item['unitPrice'] ?? 0.0).toDouble(),
          total: (item['total'] ?? 0.0).toDouble(),
        );
      }).toList();
    }
    
    return SaleFirebase(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      items: items,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      notes: data['notes'],
      paymentMethod: data['paymentMethod'] ?? 'Efectivo',
      isPaid: data['isPaid'] ?? true,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'items': items.map((item) => item.toFirestore()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Getter para calcular la ganancia (asumiendo un 30% de margen)
  double get profit => total * 0.3;
}
