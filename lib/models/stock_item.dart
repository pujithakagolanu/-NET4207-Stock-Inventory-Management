import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  final String id;
  final String sku;
  final String itemName;
  final String category;
  final int quantity;
  final double unitPrice;
  final int reorderLevel;
  final Timestamp? createdAt;

  const StockItem({
    required this.id,
    required this.sku,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.reorderLevel,
    this.createdAt,
  });

  /// Whether this item is at or below its reorder level.
  bool get isLowStock => quantity <= reorderLevel;

  factory StockItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockItem(
      id: doc.id,
      sku: data['sku'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      category: data['category'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (data['reorderLevel'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'sku': sku,
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'reorderLevel': reorderLevel,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
