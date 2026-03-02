import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCategoriesService {
  FirestoreCategoriesService._();
  static final FirestoreCategoriesService instance =
      FirestoreCategoriesService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('categories');

  /// Watch all categories
  /// ملاحظة: بدون orderBy لتجنب فشل لو فيه documents ما عندهاش order
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAll() {
    return _col.snapshots();
  }

  /// Create / Update category
  /// - لو فيه id => تعديل
  /// - لو ما فيش id => إضافة جديدة و Firestore يولد id تلقائي
  Future<void> upsertCategory(Map<String, dynamic> data) async {
    final rawId = (data['id'] ?? '').toString().trim();
    final hasId = rawId.isNotEmpty;

    // تأكيد الأنواع + defaults
    final type = (data['type'] ?? 'main').toString(); // main/sub
    final nameAr = (data['nameAr'] ?? '').toString();
    final nameEn = (data['nameEn'] ?? '').toString();

    final parentIdRaw = data['parentId'];
    final parentId = (parentIdRaw == null || parentIdRaw.toString().trim().isEmpty)
        ? null
        : parentIdRaw.toString().trim();

    int order;
    final orderRaw = data['order'];
    if (orderRaw is num) {
      order = orderRaw.toInt();
    } else {
      order = int.tryParse((orderRaw ?? '').toString()) ?? 0;
    }

    final activeRaw = data['active'];
    final active = (activeRaw is bool) ? activeRaw : true;

    // payload موحد
    final payload = <String, dynamic>{
      ...data,
      'type': type,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'parentId': parentId,
      'order': order,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (hasId) {
      // ✅ تعديل
      final id = rawId;
      await _col.doc(id).set(
        {
          ...payload,
          'id': id,
          if (data['createdAt'] == null) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      // ✅ إضافة جديدة: Firestore يولّد id
      final ref = await _col.add({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // نخزّن id داخل نفس الدوك
      await ref.set({'id': ref.id}, SetOptions(merge: true));
    }
  }

  Future<void> deleteById(String id) async {
    final v = id.trim();
    if (v.isEmpty) return;
    await _col.doc(v).delete();
  }
}
