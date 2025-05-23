import 'package:cloud_firestore/cloud_firestore.dart';

class ShelfFirebase {
  final String id;
  final String name;
  final String? description;
  final String location;
  final int capacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShelfFirebase({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.capacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShelfFirebase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShelfFirebase(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      location: data['location'] ?? '',
      capacity: data['capacity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'capacity': capacity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ShelfFirebase copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    int? capacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShelfFirebase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
