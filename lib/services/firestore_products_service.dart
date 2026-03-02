import 'package:cloud_firestore/cloud_firestore.dart';

/// products collection schema (recommended):
/// {
///  name: string,
///  desc: string,
///  category: string,
///  subCategory: string?,
///  store: string?,
///  unit: string,
///  price: number,
///  discountType: string,
///  discount: number,
///  maxQty: number,
///  stock: number,
///  active: bool,
///  imageMainPath: string?,
///  imageThumbPath: string?,
///  tags: string,
///  createdAt: serverTimestamp,
///  updatedAt: serverTimestamp
/// }
class FirestoreProductsService {
  FirestoreProductsService._();
  static final instance = FirestoreProductsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> upsertProduct(Map<String, dynamic> p) async {
    // Prefer an explicit id if provided; otherwise auto-id.
    final String? id = (p['id'] ?? p['docId'])?.toString();

    if (id == null || id.isEmpty) {
      final doc = _products.doc();
      await doc.set({
        ...p,
        'id': doc.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final doc = _products.doc(id);
    final snap = await doc.get();

    final data = <String, dynamic>{
      ...p,
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await _products.doc(id).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }
}
