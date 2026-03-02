// lib/order_details_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'models.dart';
import 'order_models.dart' as m;
import 'services/firestore_orders.dart' as fs;

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    if (orderId.trim().isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'الطلب غير موجود',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تفاصيل الطلب',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: fs.FirestoreOrdersService.instance.watchOrder(orderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text(
                'صارت مشكلة في تحميل الطلب',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data!;
          if (!doc.exists) {
            return const Center(
              child: Text(
                'الطلب غير موجود',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          // ✅ تحويل بيانات Firestore إلى موديل موحد
          final order = m.Order.fromFirestore(doc);

          final isHistory =
              order.status == m.OrderStatus.delivered || order.status == m.OrderStatus.cancelled;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _HeaderCard(order: order),
              const SizedBox(height: 12),
              _LinesCard(lines: order.lines),
              const SizedBox(height: 12),
              _InvoiceCard(order: order),

              // ✅ زر إعادة الطلب تحت الفاتورة (فقط في السجل)
              if (isHistory) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _reOrder(context, order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'إعادة الطلب',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _reOrder(BuildContext context, m.Order order) async {
    // ✅ نحول OrderLine إلى CartLine ونبدل السلة بالكامل
    await CartStore.instance.replaceAll(
      order.lines.map(
        (l) => CartLine(
          id: l.id,
          title: l.title,
          description: '',
          imageUrl: l.imageUrl,
          price: l.price,
          qty: l.qty,
        ),
      ),
    );

    if (!context.mounted) return;

    // ✅ نفتح السلة
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const Directionality(
          textDirection: TextDirection.rtl,
          child: CartScreen(),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});
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
    final c = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'رقم الطلب: ${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.status.label(compact: false),
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(order.createdAt),
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            order.storeName,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            order.address,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesCard extends StatelessWidget {
  const _LinesCard({required this.lines});
  final List<m.OrderLine> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المنتجات',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      l.imageUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 46,
                        height: 46,
                        color: const Color(0xFFF3F3F3),
                        child: const Icon(Icons.image_not_supported_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الكمية: ${l.qty}',
                          style: const TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(l.price * l.qty).toStringAsFixed(2)} د.ل',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.order});
  final m.Order order;

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
                color: bold ? Colors.black : const Color(0xFF8A8A8A),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الفاتورة',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          _row('سعر العناصر', '${order.itemsSubtotal.toStringAsFixed(2)} د.ل'),
          _row('سعر التوصيل', '${order.deliveryFee.toStringAsFixed(2)} د.ل'),
          _row('رسوم الخدمة', order.serviceFee == 0 ? 'مجانا' : '${order.serviceFee.toStringAsFixed(2)} د.ل'),
          const Divider(height: 18),
          _row('الإجمالي', '${order.total.toStringAsFixed(2)} د.ل', bold: true),
          const SizedBox(height: 6),
          _row('طريقة الدفع', order.paymentMethod, valueColor: const Color(0xFF2ECC71)),
        ],
      ),
    );
  }
}
