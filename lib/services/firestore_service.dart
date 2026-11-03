import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item.dart';

// ---------------------------------------------------------------------------
// Custom exception for duplicate SKU
// ---------------------------------------------------------------------------

class DuplicateSkuException implements Exception {
  final String sku;
  const DuplicateSkuException(this.sku);

  @override
  String toString() =>
      'A stock item with SKU "$sku" already exists. Please use a unique SKU.';
}

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('stockItems');

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Returns true if a document with [sku] already exists in the collection.
  Future<bool> skuExists(String sku) async {
    final query =
        await _collection.where('sku', isEqualTo: sku).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Adds a new stock item and waits until the Firestore write completes.
  ///
  /// Throws a [DuplicateSkuException] if the SKU is already in use.
  /// Throws [FirebaseException] on other Firestore failures.
  Future<void> addStockItem(StockItem item) async {
    if (await skuExists(item.sku)) {
      throw DuplicateSkuException(item.sku);
    }
    await _collection.add(item.toFirestore());
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns a stream of all stock items ordered by creation time (newest last).
  Stream<List<StockItem>> stockItemsStream() {
    return _collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(StockItem.fromFirestore).toList());
  }
}
