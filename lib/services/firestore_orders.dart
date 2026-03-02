import 'package:cloud_firestore/cloud_firestore.dart';

/// حالات الطلب في Firestore:
/// accepted | preparing | on_the_way | delivered | cancelled
class OrderStatus {
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const onTheWay = 'on_the_way';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const all = <String>[accepted, preparing, onTheWay, delivered, cancelled];

  static String label(String s) {
    switch (s) {
      case accepted:
        return 'قبول';
      case preparing:
        return 'تجهيز';
      case onTheWay:
        return 'في الطريق';
      case delivered:
        return 'تسليم';
      case cancelled:
        return 'ملغي';
      default:
        return s;
    }
  }

  static String next(String s) {
    switch (s) {
      case accepted:
        return preparing;
      case preparing:
        return onTheWay;
      case onTheWay:
        return delivered;
      case delivered:
        return delivered;
      case cancelled:
        return cancelled;
      default:
        return preparing;
    }
  }
}

class FirestoreOrdersService {
  FirestoreOrdersService._();
  static final instance = FirestoreOrdersService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  /// ✅ Stream لطلبات عميل محدد (Realtime)
  /// ✅ بدون orderBy (باش ما يحتاجش Index في Firestore)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrdersForCustomer(String customerId) {
    return _orders.where('customerId', isEqualTo: customerId).snapshots();
  }

  /// Stream للطلبات (Realtime) للداشبورد
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrders({String? status}) {
    Query<Map<String, dynamic>> q = _orders.orderBy('createdAt', descending: true);
    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String id) {
    return _orders.doc(id).snapshots();
  }

  Future<String> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String addressText,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod, // cash | wallet
    double? lat,
    double? lng,
  }) async {
    final doc = _orders.doc();
    await doc.set({
      'orderNo': DateTime.now().millisecondsSinceEpoch,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'addressText': addressText,
      'lat': lat,
      'lng': lng,
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': OrderStatus.accepted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateStatus(String id, String status) async {
    await _orders.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> moveToNextStatus(String id, String current) async {
    await updateStatus(id, OrderStatus.next(current));
  }
}
