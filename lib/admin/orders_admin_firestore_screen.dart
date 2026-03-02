import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_orders.dart';

/// شاشة أدمن للطلبات (Realtime من Firestore)
/// - جدول مبسط
/// - تفاصيل الطلب
/// - تمرير الحالة للمرحلة التالية + إلغاء
class OrdersAdminFirestoreScreen extends StatefulWidget {
  const OrdersAdminFirestoreScreen({super.key});

  @override
  State<OrdersAdminFirestoreScreen> createState() => _OrdersAdminFirestoreScreenState();
}

class _OrdersAdminFirestoreScreenState extends State<OrdersAdminFirestoreScreen> {
  String filterStatus = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('الطلبات'),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (v) => setState(() => filterStatus = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: '', child: Text('الكل')),
                ...OrderStatus.all.map(
                  (s) => PopupMenuItem(value: s, child: Text(OrderStatus.label(s))),
                ),
              ],
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreOrdersService.instance
              .watchOrders(status: filterStatus.isEmpty ? null : filterStatus),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('خطأ: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('لا توجد طلبات'));
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _OrdersTableHeader(),
                const SizedBox(height: 10),
                for (final d in docs) ...[
                  _OrderRow(
                    docId: d.id,
                    data: d.data(),
                    onOpen: () => _openDetails(context, d.id),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailsAdminScreen(orderId: orderId)),
    );
  }
}

class _OrdersTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          _HCell('رقم'),
          _HCell('العميل'),
          _HCell('الهاتف'),
          _HCell('العنوان'),
          _HCell('الإجمالي'),
          _HCell('الحالة'),
          SizedBox(width: 120, child: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String t;
  const _HCell(this.t);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onOpen;

  const _OrderRow({
    required this.docId,
    required this.data,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final orderNo = (data['orderNo'] ?? '—').toString();
    final name = (data['customerName'] ?? '—').toString();
    final phone = (data['customerPhone'] ?? '—').toString();
    final address = (data['addressText'] ?? '—').toString();
    final total = (data['total'] ?? 0).toString();
    final status = (data['status'] ?? '').toString();

    final isCancelled = status == OrderStatus.cancelled;
    final isDelivered = status == OrderStatus.delivered;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x0D000000),
          )
        ],
      ),
      child: Row(
        children: [
          _Cell(orderNo),
          _Cell(name),
          _Cell(phone),
          _Cell(address, flex: 2),
          _Cell(total),
          _StatusPill(status: status),
          SizedBox(
            width: 120,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                IconButton(
                  tooltip: 'تفاصيل',
                  onPressed: onOpen,
                  icon: const Icon(Icons.remove_red_eye_outlined),
                ),
                if (!isCancelled && !isDelivered)
                  ElevatedButton(
                    onPressed: () => FirestoreOrdersService.instance
                        .moveToNextStatus(docId, status),
                    child: const Text('تمرير'),
                  ),
                if (!isCancelled && !isDelivered)
                  OutlinedButton(
                    onPressed: () => FirestoreOrdersService.instance
                        .updateStatus(docId, OrderStatus.cancelled),
                    child: const Text('إلغاء'),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String t;
  final int flex;
  const _Cell(this.t, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(OrderStatus.label(status), style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class OrderDetailsAdminScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailsAdminScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب'), centerTitle: true),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreOrdersService.instance.watchOrder(orderId),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final data = snap.data!.data();
            if (data == null) return const Center(child: Text('الطلب غير موجود'));

            final status = (data['status'] ?? '').toString();
            final items = (data['items'] as List?) ?? const [];
            final total = data['total'] ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _kv('رقم الطلب', (data['orderNo'] ?? '—').toString()),
                _kv('العميل', (data['customerName'] ?? '—').toString()),
                _kv('الهاتف', (data['customerPhone'] ?? '—').toString()),
                _kv('العنوان', (data['addressText'] ?? '—').toString()),
                _kv('طريقة الدفع', (data['paymentMethod'] ?? '—').toString()),
                const SizedBox(height: 14),
                const Text('العناصر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...items.map((e) {
                  final m = (e as Map).cast<String, dynamic>();
                  final title = (m['title'] ?? '—').toString();
                  final qty = (m['qty'] ?? 1).toString();
                  final price = (m['price'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('الكمية: $qty • السعر: $price'),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                _kv('الإجمالي', total.toString()),
                const SizedBox(height: 18),
                const Text('الحالة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in OrderStatus.all)
                      ChoiceChip(
                        selected: s == status,
                        label: Text(OrderStatus.label(s)),
                        onSelected: (_) => FirestoreOrdersService.instance.updateStatus(orderId, s),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w900)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
