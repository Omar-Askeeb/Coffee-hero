// lib/purchases_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_routes.dart';
import 'auth/auth_service.dart';
import 'order_models.dart' as m;
import 'services/firestore_orders.dart' as fs;

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  static const Color cardBg = Color(0xFFF3F4F8);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final customerId = (user == null)
        ? ''
        : (user.role == 'employee' ? (user.ownerPhone ?? '') : user.phone);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشتريات', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: (AuthService.instance.isGuest || customerId.isEmpty)
          ? const Center(child: Text('سجّل دخول باش تشوف المشتريات'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.FirestoreOrdersService.instance.watchOrdersForCustomer(customerId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('صارت مشكلة في تحميل المشتريات'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                final all = docs.map(m.Order.fromFirestore).toList(growable: false);

                // ✅ المشتريات = الطلبات المكتملة (Delivered) فقط
                final orders = all
                    .where((o) => o.status == m.OrderStatus.delivered)
                    .toList(growable: false);

                final totalOrders = orders.length;
                final totalAmount = orders.fold<double>(0.0, (a, b) => a + b.total);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'إجمالي المشتريات',
                              value: '${totalAmount.toStringAsFixed(0)} د.ل',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'إجمالي الطلبات',
                              value: '$totalOrders',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('الفواتير الكلية', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: orders.isEmpty
                            ? const Center(child: Text('لا توجد فواتير حالياً'))
                            : ListView.separated(
                                itemCount: orders.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final o = orders[i];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(AppRoutes.invoice, arguments: o.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              o.lines.isNotEmpty
                                                  ? o.lines.first.imageUrl
                                                  : 'https://via.placeholder.com/60',
                                              width: 58,
                                              height: 58,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 58,
                                                height: 58,
                                                color: const Color(0xFFE9E9E9),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  size: 18,
                                                  color: Color(0xFF8A8A8A),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  o.storeName,
                                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '#${o.id}',
                                                  style: const TextStyle(color: Color(0xFF777777)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${o.total.toStringAsFixed(0)} د.ل  •  ${_fmtDate(o.createdAt)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF777777),
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'الفاتورة',
                                              style: TextStyle(fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF666666))),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        ],
      ),
    );
  }
}
