import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProductsServiceClient {
  FirestoreProductsServiceClient._();
  static final instance = FirestoreProductsServiceClient._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProducts({bool onlyActive = true}) {
    Query<Map<String, dynamic>> q = _products;
    if (onlyActive) {
      q = q.where('active', isEqualTo: true);
    }
    return q.snapshots();
  }
}
