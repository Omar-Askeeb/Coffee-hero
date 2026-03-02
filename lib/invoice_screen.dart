// lib/invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_screen.dart';
import 'models.dart'; // CartLine
import 'services/firestore_orders.dart' as fs;
import 'order_models.dart' as m;

class InvoiceScreen extends StatelessWidget {
  final String orderId;
  const InvoiceScreen({super.key, required this.orderId});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفاتورة', style: TextStyle(fontWeight: FontWeight.w900)),
      ),

      // ✅ نجيب الطلب من Firestore مباشرة
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('صار خطأ في تحميل الفاتورة'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data!;
          if (!doc.exists) {
            return const Center(child: Text('لم يتم العثور على الفاتورة'));
          }

          // ✅ مهم: نستعمل موديلنا بالـ alias (m.Order) باش ما يصيرش تعارض مع Firestore Order
          final m.Order order = m.Order.fromFirestore(doc);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(order: order),
              const SizedBox(height: 12),
              _LinesCard(order: order),
              const SizedBox(height: 12),
              _TotalsCard(order: order),
              const SizedBox(height: 14),

              // ✅ زر إعادة الطلب: يعبي السلة من عناصر الطلب
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final cart = CartStore.instance;

                    // نحول خطوط الطلب لسلة
                    final lines = order.lines.map((l) {
                      return CartLine(
                        id: l.id,
                        title: l.title,
                        description: '',
                        imageUrl: l.imageUrl,
                        price: l.price,
                        qty: l.qty,
                      );
                    }).toList(growable: false);

                    // ✅ تعمير السلة بنفس الطلب
                    await cart.replaceAll(lines);

                    if (!context.mounted) return;

                    // ✅ فتح السلة
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Directionality(
                          textDirection: TextDirection.rtl,
                          child: CartScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'إعادة الطلب',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final m.Order order;
  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9E9E9)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'رقم الطلب: ${order.id}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(order.storeName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            order.address.isEmpty ? '—' : order.address,
            style: const TextStyle(color: Color(0xFF777777)),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _LinesCard extends StatelessWidget {
  final m.Order order;
  const _LinesCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final lines = order.lines;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9E9E9)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('المنتجات', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          if (lines.isEmpty)
            const Text('لا توجد عناصر', style: TextStyle(color: Color(0xFF777777)))
          else
            ...lines.map((l) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        l.imageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFFF3F3F3),
                          child: const Icon(Icons.image_not_supported_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(l.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('الكمية: ${l.qty}', style: const TextStyle(color: Color(0xFF777777))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${l.price.toStringAsFixed(0)} د.ل', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final m.Order order;
  const _TotalsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9E9E9)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('الفاتورة', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          _Row(label: 'سعر العناصر', value: '${order.itemsSubtotal.toStringAsFixed(0)} د.ل'),
          _Row(label: 'سعر التوصيل', value: 'مجانا'),
          _Row(label: 'رسوم الخدمة', value: order.serviceFee == 0 ? 'مجانا' : '${order.serviceFee.toStringAsFixed(0)} د.ل'),

          const Divider(height: 26),

          Row(
            children: [
              Text('${order.total.toStringAsFixed(0)} د.ل', style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                order.paymentMethod,
                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              const Text('طريقة الدفع', style: TextStyle(color: Color(0xFF777777))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const Spacer(),
          Text(label, style: const TextStyle(color: Color(0xFF777777))),
        ],
      ),
    );
  }
}
