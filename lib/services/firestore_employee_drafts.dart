import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import 'firebase_schema.dart';

/// Firestore drafts prepared by employees for the owner to approve.
/// Path: customers/{ownerUid}/draftOrders/{draftId}
class FirestoreEmployeeDraftsService {
  FirestoreEmployeeDraftsService._();
  static final FirestoreEmployeeDraftsService instance =
      FirestoreEmployeeDraftsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Owner watches pending drafts for a specific employee.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingForEmployee({
    required String ownerUid,
    required String employeeUid,
  }) {
    // NOTE: avoid orderBy to reduce Firestore composite-index requirements.
    return _db
        .collection(FirebaseSchema.customers)
        .doc(ownerUid)
        .collection(FirebaseSchema.draftOrders)
        .where('employeeUid', isEqualTo: employeeUid)
        .where('status', isEqualTo: 'pending_manager')
        .snapshots();
  }

  /// Employee submits his current cart as a draft for the owner.
  Future<String> submitEmployeeCart({
    required String ownerUid,
    required String employeeUid,
    required String employeeName,
    required List<Map<String, dynamic>> items,
    required int count,
    required double total,
  }) async {
    final ref = _db
        .collection(FirebaseSchema.customers)
        .doc(ownerUid)
        .collection(FirebaseSchema.draftOrders)
        .doc();

    await ref.set({
      'status': 'pending_manager',
      'employeeUid': employeeUid,
      'employeeName': employeeName,
      'count': count,
      'total': total,
      'items': items,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Owner marks a draft as approved (so it disappears from pending list).
  Future<void> markApproved({
    required String ownerUid,
    required String draftId,
  }) async {
    final me = AuthService.instance.currentUser;
    await _db
        .collection(FirebaseSchema.customers)
        .doc(ownerUid)
        .collection(FirebaseSchema.draftOrders)
        .doc(draftId)
        .update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      if (me != null) 'approvedBy': me.uid,
    });
  }
}
