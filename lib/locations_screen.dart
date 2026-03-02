import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_routes.dart';

/// 🔥 BottomSheet تسجيل الدخول بالشكل الاحترافي الجديد
Future<void> showGuestLoginSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// الخط الصغير فوق
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              /// أيقونة المستخدم
              Image.asset(
                'assets/icons/add-user.png',
                height: 95,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 12),

              /// العنوان
              const Text(
                'مرحباً بك ضيفنا العزيز!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 6),

              /// الوصف
              const Text(
                'سجّل الآن لتتمكن من حفظ عناوينك والوصول لجميع المزايا.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              /// زر تسجيل الدخول
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRoutes.login);
                  },
                  child: const Text(
                    'تسجيل الدخول / إنشاء حساب',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// زر لاحقاً
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'لاحقاً',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF2F80ED),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  bool get isGuest => FirebaseAuth.instance.currentUser == null;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> _locations() {
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('locations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<String?> _selectedId() {
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .snapshots()
        .map((e) => e.data()?['selectedLocationId'] as String?);
  }

  Future<void> _selectLocation(String id) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .update({'selectedLocationId': id});
  }

  Future<void> _deleteLocation(String id) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('locations')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'عناويني',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      /// زر إضافة موقع
      floatingActionButton: FloatingActionButton(
        backgroundColor: orange,
        onPressed: () async {
          if (isGuest) {
            await showGuestLoginSheet(context);
            return;
          }
          await Navigator.of(context).pushNamed(AppRoutes.mapPicker);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      /// الجسم
      body: isGuest
          ? const Center(
              child: Text(
                'تقدر تتصفح عادي 👌\nلكن لازم تسجل دخول باش تحفظ عناوينك',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<String?>(
                stream: _selectedId(),
                builder: (context, selectedSnap) {
                  final selectedId = selectedSnap.data;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _locations(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snap.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text('لا توجد عناوين'));
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final d = docs[i];
                          final data = d.data();
                          final isSelected = d.id == selectedId;

                          return InkWell(
                            onTap: () => _selectLocation(d.id),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F8),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  /// دائرة التحديد
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? orange
                                          : Colors.transparent,
                                      border: Border.all(color: orange, width: 2),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                  ),

                                  const SizedBox(width: 10),

                                  /// النصوص
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          data['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['address'] ?? '',
                                          style: const TextStyle(
                                              color: Color(0xFF777777)),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// زر الحذف
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _deleteLocation(d.id),
                                  ),

                                  const Icon(Icons.location_on, color: orange),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
