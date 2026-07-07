import 'package:mongo_dart/mongo_dart.dart';

class Supplier {
  final ObjectId? id;
  final String name;
  final String phone;
  final String email;
  final String address;

  Supplier({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['_id'] as ObjectId?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  Supplier copyWith({
    ObjectId? id,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}
