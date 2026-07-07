import 'package:mongo_dart/mongo_dart.dart';

class Product {
  final ObjectId? id;
  final String sku;
  final String name;
  final double price;
  final double costPrice;
  final int stock;
  final String category;
  final ObjectId? supplierId;
  final String? imagePath;

  Product({
    this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.category,
    this.supplierId,
    this.imagePath,
  });

  // Convert Product to a Map for database insert/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'sku': sku,
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'category': category,
      if (supplierId != null) 'supplierId': supplierId,
      'imagePath': imagePath,
    };
  }

  // Parse Product from database Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['_id'] as ObjectId?,
      sku: map['sku'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num? ?? 0.0).toDouble(),
      costPrice: (map['costPrice'] as num? ?? 0.0).toDouble(),
      stock: map['stock'] as int? ?? 0,
      category: map['category'] as String? ?? 'General',
      supplierId: map['supplierId'] as ObjectId?,
      imagePath: map['imagePath'] as String?,
    );
  }

  // Create a copy of Product with modified fields
  Product copyWith({
    ObjectId? id,
    String? sku,
    String? name,
    double? price,
    double? costPrice,
    int? stock,
    String? category,
    ObjectId? supplierId,
    String? imagePath,
    bool clearImage = false,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      supplierId: supplierId ?? this.supplierId,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }
}
