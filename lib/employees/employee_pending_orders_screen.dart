import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../cart_screen.dart';
import '../models.dart';
import '../services/firestore_employee_drafts.dart';

class EmployeePendingOrdersScreen extends StatelessWidget {
  final String employeeUid;
  final String employeeName;

  const EmployeePendingOrdersScreen({
    super.key,
    required this.employeeUid,
    required this.employeeName,
  });

  static const Color orange = Color(0xFFF5A623);

  Future<void> _confirmAndApprove({
    required BuildContext context,
    required String ownerUid,
    required String draftId,
    required List<dynamic> itemsRaw,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد', textDirection: TextDirection.rtl),
        content: const Text(
          'هل تريد إضافة هذه الطلبية إلى السلة؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('أكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // 1) add items to cart
    for (final it in itemsRaw) {
      if (it is! Map) continue;
      final m = Map<String, dynamic>.from(it);

      final id = (m['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final title = (m['title'] ?? '').toString();
      final desc = (m['description'] ?? '').toString();
      final imageUrl = (m['imageUrl'] ?? '').toString();
      final priceRaw = m['price'];
      final price = (priceRaw is num) ? priceRaw.toDouble() : 0.0;
      final qtyRaw = m['qty'];
      final qty = (qtyRaw is num) ? qtyRaw.toInt() : 1;

      // CartStore.addOrInc يزيد 1 فقط، لذلك نكرر حسب الكمية
      for (int i = 0; i < qty; i++) {
        CartStore.instance.addOrInc(
          CartLine(
            id: id,
            title: title,
            description: desc,
            imageUrl: imageUrl,
            price: price,
            qty: 1,
          ),
        );
      }
    }

    // 2) mark approved so it disappears from pending list
    await FirestoreEmployeeDraftsService.instance.markApproved(
      ownerUid: ownerUid,
      draftId: draftId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الإضافة للسلة وتم اعتماد الطلب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.currentUser;

    if (AuthService.instance.isGuest || me == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل دخول أولاً')),
      );
    }
    if (me.role != 'owner') {
      return const Scaffold(
        body: Center(child: Text('هذه الصفحة خاصة بصاحب المقهى فقط')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('طلبات $employeeName'),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreEmployeeDraftsService.instance.watchPendingForEmployee(
            ownerUid: me.uid,
            employeeUid: employeeUid,
          ),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(
                  'صار خطأ في تحميل الطلبات\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد طلبات جاهزة لهذا الموظف',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();

                final totalRaw = data['total'];
                final total = (totalRaw is num) ? totalRaw.toDouble() : 0.0;
                final countRaw = data['count'];
                final count = (countRaw is num) ? countRaw.toInt() : 0;
                final itemsRaw = (data['items'] as List?) ?? const <dynamic>[];

                return InkWell(
                  onTap: () => _confirmAndApprove(
                    context: context,
                    ownerUid: me.uid,
                    draftId: d.id,
                    itemsRaw: itemsRaw,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 10,
                          offset: Offset(0, 6),
                          color: Color(0x11000000),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلبية جاهزة',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'عدد الأصناف: $count • الإجمالي: د.ل${total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_left),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
