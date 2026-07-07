import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Calculate total price for this cart item
  double get total => product.price * quantity;

  // Calculate total cost for profit tracking
  double get totalCost => product.costPrice * quantity;

  // Convert to Map for inclusion inside a Sale document
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'sku': product.sku,
      'name': product.name,
      'price': product.price,
      'costPrice': product.costPrice,
      'quantity': quantity,
      'total': total,
    };
  }

  // Create CartItem from Map (e.g. when loading sales records)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product(
        id: map['productId'],
        sku: map['sku'] as String? ?? '',
        name: map['name'] as String? ?? '',
        price: (map['price'] as num? ?? 0.0).toDouble(),
        costPrice: (map['costPrice'] as num? ?? 0.0).toDouble(),
        stock: 0, // Stock not loaded inside a cart transaction log
        category: '',
      ),
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}
