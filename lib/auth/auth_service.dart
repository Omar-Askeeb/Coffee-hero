import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../services/firebase_schema.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

@immutable
class AuthUser {
  final String uid;
  final String cafeName;
  final String phone; // normalized digits-only
  final String role; // 'owner' | 'employee'
  final String? avatarPath; // optional (local path)
  final String? ownerUid; // for employee
  final String? ownerPhone; // for employee (used to read orders)

  const AuthUser({
    required this.uid,
    required this.cafeName,
    required this.phone,
    required this.role,
    this.avatarPath,
    this.ownerUid,
    this.ownerPhone,
  });
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kIsGuest = 'auth_is_guest_v2';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  /// توافق مع أجزاء قديمة في الواجهات اللي تقرا `auth.user`
  AuthUser? get user => _currentUser;

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  /// ✅ NEW: ربط OneSignal بالهوية الحالية (phone كـ external_id)
  void _syncOneSignalIdentity() {
    try {
      final u = _currentUser;
      final phone = (u?.phone ?? '').trim();
      if (_isGuest || phone.isEmpty) {
        OneSignal.logout();
      } else {
        OneSignal.login(phone);
      }
    } catch (_) {
      // ما نطيّحوش التطبيق لو OneSignal مش جاهز
    }
  }

  /// دخول زائر (بدون حساب). هذا يخلي نافذة "ضيفنا العزيز" تشتغل زي ما هي.
  Future<void> signInAsGuest() async {
    await setGuest(true);
  }

  String normalizePhone(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  String _emailFromPhone(String phone) {
    final p = normalizePhone(phone);
    if (p.isEmpty) return '';
    // Email "مخفي" داخل النظام — المستخدم ما يشوفهش
    return '$p@cafes.app';
  }

  /// استرجاع حالة الدخول (Firebase + Guest flag)
  Future<void> restore() async {
    final sp = await SharedPreferences.getInstance();
    _isGuest = sp.getBool(_kIsGuest) ?? false;

    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      _currentUser = null;
      _syncOneSignalIdentity(); // ✅ NEW
      notifyListeners();
      return;
    }

    _currentUser = await _loadProfileForUid(fbUser.uid);
    _syncOneSignalIdentity(); // ✅ NEW
    notifyListeners();
  }

  Future<void> setGuest(bool v) async {
    _isGuest = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kIsGuest, v);
    if (v) {
      // Guest يعني ما فيش حساب
      _currentUser = null;
      try {
        await _auth.signOut();
      } catch (_) {}
    }
    _syncOneSignalIdentity(); // ✅ NEW
    notifyListeners();
  }

  Future<void> signOut() async {
    _isGuest = false;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kIsGuest, false);

    await _auth.signOut();
    _currentUser = null;

    _syncOneSignalIdentity(); // ✅ NEW
    notifyListeners();
  }

  /// ✅ NEW: حذف الحساب نهائياً (Firestore + Auth)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    final profile = _currentUser;
    if (user == null || profile == null) return;

    try {
      // 1) حذف البيانات من Firestore
      if (profile.role == 'owner') {
        // حذف وثيقة صاحب المقهى
        await _db.collection(FirebaseSchema.customers).doc(user.uid).delete();
      } else if (profile.role == 'employee') {
        // حذف وثيقة الموظف من القائمة العامة
        await _db.collection(FirebaseSchema.employeeProfiles).doc(user.uid).delete();
        // حذف الموظف من قائمة صاحب المقهى (لو متوفر)
        if (profile.ownerUid != null) {
          await _db
              .collection(FirebaseSchema.customers)
              .doc(profile.ownerUid)
              .collection(FirebaseSchema.employees)
              .doc(user.uid)
              .delete();
        }
      }

      // 2) حذف الحساب من Firebase Auth
      await user.delete();

      // 3) مسح الحالة المحلية
      await signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException('العملية تتطلب تسجيل دخول حديث. يرجى إعادة تسجيل الدخول والمحاولة مرة أخرى.');
      }
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw AuthException('فشل حذف الحساب: $e');
    }
  }

  /// تسجيل دخول (Owner أو Employee) برقم + كلمة مرور (بدون OTP)
  Future<void> signIn({required String phone, required String password}) async {
    final email = _emailFromPhone(phone);
    if (email.isEmpty) throw AuthException('رقم الهاتف غير صحيح');

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) throw AuthException('فشل تسجيل الدخول');

      _isGuest = false;
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kIsGuest, false);

      _currentUser = await _loadProfileForUid(uid);

      _syncOneSignalIdentity(); // ✅ NEW
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// تسجيل Owner (صاحب مقهى) — بدون OTP
  Future<void> signUpOwner({
    required String cafeName,
    required String phone,
    required String password,
  }) async {
    final p = normalizePhone(phone);
    final email = _emailFromPhone(p);
    if (email.isEmpty) throw AuthException('رقم الهاتف غير صحيح');

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) throw AuthException('فشل إنشاء الحساب');

      // Firestore: customers/{uid}
      await _db.collection(FirebaseSchema.customers).doc(uid).set({
        'cafeName': cafeName.trim(),
        'phone': p,
        'role': 'owner',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isGuest = false;
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kIsGuest, false);

      _currentUser = AuthUser(
        uid: uid,
        cafeName: cafeName.trim(),
        phone: p,
        role: 'owner',
      );

      _syncOneSignalIdentity(); // ✅ NEW
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// تغيير كلمة المرور للحساب الحالي (لا يعمل للزائر)
  Future<void> updatePasswordForCurrentUser(String newPassword) async {
    if (_auth.currentUser == null) throw AuthException('لازم تسجّل دخول أولاً');
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// إنشاء موظف (يتبع صاحب المقهى الحالي).
  /// ملاحظة: نستخدم Secondary FirebaseApp باش ما نطلعوش الـ Owner من حسابه.
  Future<String> createEmployee({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    final owner = _currentUser;
    if (owner == null || owner.role != 'owner') {
      throw AuthException('لازم تسجّل كصاحب مقهى باش تضيف موظف');
    }

    final p = normalizePhone(phone);
    final email = _emailFromPhone(p);
    if (email.isEmpty) throw AuthException('رقم الهاتف غير صحيح');

    FirebaseApp? secondary;
    try {
      final opts = Firebase.app().options;
      try {
        secondary = Firebase.app('employeeCreator');
      } catch (_) {
        secondary = await Firebase.initializeApp(
          name: 'employeeCreator',
          options: opts,
        );
      }

      final empAuth = FirebaseAuth.instanceFor(app: secondary);
      final cred = await empAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final empUid = cred.user?.uid;
      if (empUid == null) throw AuthException('فشل إنشاء الموظف');

      // customers/{ownerUid}/employees/{empUid}
      await _db
          .collection(FirebaseSchema.customers)
          .doc(owner.uid)
          .collection(FirebaseSchema.employees)
          .doc(empUid)
          .set({
        'name': name.trim(),
        'phone': p,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': owner.uid,
      });

      // employeeProfiles/{empUid}
      await _db.collection(FirebaseSchema.employeeProfiles).doc(empUid).set({
        'ownerUid': owner.uid,
        'ownerPhone': owner.phone,
        'name': name.trim(),
        'phone': p,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await empAuth.signOut();
      return empUid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } finally {}
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEmployeesForOwner(String ownerUid) {
    return _db
        .collection(FirebaseSchema.customers)
        .doc(ownerUid)
        .collection(FirebaseSchema.employees)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<AuthUser?> _loadProfileForUid(String uid) async {
    // 1) Owner?
    final ownerDoc = await _db.collection(FirebaseSchema.customers).doc(uid).get();
    if (ownerDoc.exists) {
      final d = ownerDoc.data()!;
      return AuthUser(
        uid: uid,
        cafeName: (d['cafeName'] ?? '') as String,
        phone: (d['phone'] ?? '') as String,
        role: 'owner',
      );
    }

    // 2) Employee?
    final empDoc =
        await _db.collection(FirebaseSchema.employeeProfiles).doc(uid).get();
    if (empDoc.exists) {
      final d = empDoc.data()!;
      return AuthUser(
        uid: uid,
        cafeName: (d['name'] ?? '') as String,
        phone: (d['phone'] ?? '') as String,
        role: 'employee',
        ownerUid: d['ownerUid'] as String?,
        ownerPhone: d['ownerPhone'] as String?,
      );
    }

    await _auth.signOut();
    throw AuthException('الحساب غير مربوط في قاعدة البيانات');
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'الحساب غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غلط';
      case 'email-already-in-use':
        return 'الرقم مسجّل قبل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-email':
        return 'رقم الهاتف غير صحيح';
      case 'network-request-failed':
        return 'فيه مشكلة في الاتصال بالإنترنت';
      default:
        return e.message ?? 'صار خطأ في تسجيل الدخول';
    }
  }
}
