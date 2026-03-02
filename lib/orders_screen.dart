// lib/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_routes.dart';
import 'bottom_bar_rtl.dart';
import 'order_models.dart' as m;
import 'auth/auth_service.dart';
import 'services/firestore_orders.dart' as fs;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int navIndex = 1;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final customerId = (user == null)
        ? ''
        : (user.role == 'employee' ? (user.ownerPhone ?? '') : user.phone);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomBarRTL(
        currentIndex: navIndex,
        onTap: (i) {
          final route = AppRoutes.forIndex(i);
          if (route == AppRoutes.orders) return;
          Navigator.of(context).pushReplacementNamed(route);
        },
      ),
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF5A623).withOpacity(0.18),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: const Color(0xFF8A8A8A),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'الحالية'),
                    Tab(text: 'السجل'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: (AuthService.instance.isGuest || customerId.isEmpty)
                  ? const Center(
                      child: Text(
                        'سجّل دخول باش تشوف طلباتك',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: fs.FirestoreOrdersService.instance
                          .watchOrdersForCustomer(customerId),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(
                            child: Text(
                              'صارت مشكلة في تحميل الطلبات',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          );
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snap.data!.docs;

                        final orders =
                            docs.map(m.Order.fromFirestore).toList(growable: false);

                        final active = orders
                            .where((o) =>
                                o.status != m.OrderStatus.delivered &&
                                o.status != m.OrderStatus.cancelled)
                            .toList(growable: false);

                        final history = orders
                            .where((o) =>
                                o.status == m.OrderStatus.delivered ||
                                o.status == m.OrderStatus.cancelled)
                            .toList(growable: false);

                        return TabBarView(
                          children: [
                            _OrdersList(
                              emptyText: 'لا توجد طلبات حالية',
                              orders: active,
                            ),
                            _OrdersList(
                              emptyText: 'لا يوجد سجل طلبات',
                              orders: history,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, required this.emptyText});

  final List<m.Order> orders;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF8A8A8A),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final m.Order order;

  Color _statusColor(m.OrderStatus s) {
    switch (s) {
      case m.OrderStatus.cancelled:
        return const Color(0xFFE74C3C);
      case m.OrderStatus.delivered:
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFFF5A623);
    }
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d • $t';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final thumbs = order.lines.take(4).toList(growable: false);

    return InkWell(
      onTap: () {
        final isHistory = order.status == m.OrderStatus.delivered ||
            order.status == m.OrderStatus.cancelled;

        // ✅ السجل -> فاتورة
        // ✅ الحالية -> تتبع حالات
        Navigator.of(context).pushNamed(
          isHistory ? AppRoutes.invoice : AppRoutes.trackOrder,
          arguments: order.id,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.label(compact: true),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // ✅ المربع الصغير (أقصى اليسار): يفتح الفاتورة دائماً
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.invoice,
                    arguments: order.id,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                    ),
                    child: const Icon(Icons.copy_outlined, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(order.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${order.itemsCount} عناصر',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: thumbs
                  .map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          l.imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFF3F3F3),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final isHistory = order.status ==
                              m.OrderStatus.delivered ||
                          order.status == m.OrderStatus.cancelled;

                      if (isHistory) {
                        // (إعادة الطلب) خلّيناها للمرحلة الجاية
                        Navigator.of(context).pushNamed(
                          AppRoutes.invoice,
                          arguments: order.id,
                        );
                        return;
                      }

                      fs.FirestoreOrdersService.instance
                          .updateStatus(order.id, fs.OrderStatus.cancelled);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFFE6E6E6)),
                    ),
                    child: Text(
                      (order.status == m.OrderStatus.delivered ||
                              order.status == m.OrderStatus.cancelled)
                          ? 'إعادة الطلب'
                          : 'إلغاء الطلب',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: (order.status == m.OrderStatus.delivered ||
                                order.status == m.OrderStatus.cancelled)
                            ? Colors.black
                            : (order.status == m.OrderStatus.cancelled
                                ? const Color(0xFFB0B0B0)
                                : Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
