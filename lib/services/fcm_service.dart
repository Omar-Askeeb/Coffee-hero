import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _db = FirebaseFirestore.instance;

  Future<void> saveTokenForUser({
    required String userId, // رقم الهاتف أو UID
  }) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    await _db.collection('customers').doc(userId).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
