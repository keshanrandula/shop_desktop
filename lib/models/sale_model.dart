import 'package:mongo_dart/mongo_dart.dart';
import 'cart_item_model.dart';

class Sale {
  final ObjectId? id;
  final List<CartItem> items;
  final double subTotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final DateTime dateTime;
  final String status; // 'Completed' or 'Refunded'

  Sale({
    this.id,
    required this.items,
    required this.subTotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.dateTime,
    this.status = 'Completed',
  });

  // Calculate total cost of items in this sale for profit calculations
  double get totalCost => items.fold(0.0, (sum, item) => sum + item.totalCost);

  // Profit earned from this transaction
  double get profit => total - totalCost;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'subTotal': subTotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'dateTime': dateTime,
      'totalCost': totalCost,
      'profit': profit,
      'status': status,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['_id'] as ObjectId?,
      items: (map['items'] as List? ?? [])
          .map((itemMap) => CartItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      subTotal: (map['subTotal'] as num? ?? 0.0).toDouble(),
      discount: (map['discount'] as num? ?? 0.0).toDouble(),
      total: (map['total'] as num? ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as DateTime).toLocal()
          : DateTime.now(),
      status: map['status'] as String? ?? 'Completed',
    );
  }

  Sale copyWith({
    ObjectId? id,
    List<CartItem>? items,
    double? subTotal,
    double? discount,
    double? total,
    String? paymentMethod,
    DateTime? dateTime,
    String? status,
  }) {
    return Sale(
      id: id ?? this.id,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
    );
  }
}
