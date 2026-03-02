import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Color orange = Color(0xFFF5A623);

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString()) ?? 0.0;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse((v ?? '').toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;

    final itemsRaw = o['items'];
    final items = <Map<String, dynamic>>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map) items.add(Map<String, dynamic>.from(e));
      }
    }

    if (items.isEmpty) {
      items.add({'name': 'لا توجد عناصر', 'qty': 0, 'unitPrice': 0.0});
    }

    double subtotal = 0;
    for (final it in items) {
      final qty = _asInt(it['qty']);
      final unit = _asDouble(it['unitPrice'] ?? it['price']);
      subtotal += qty * unit;
    }

    final discount = _asDouble(o['discount']);
    final coupon = _asDouble(o['coupon']);
    final vat = _asDouble(o['vat']);
    final deliveryFee = _asDouble(o['deliveryFee']);
    final total = subtotal - discount - coupon + vat + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: orange,
        title: Text('طلب #${o['id']}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Order #${o['id']}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text((o['date'] ?? '').toString(),
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    _kv('المتجر', (o['store'] ?? '—').toString()),
                    _kv('العميل', (o['customer'] ?? '—').toString()),
                    _kv('الهاتف', (o['phone'] ?? '—').toString()),
                    _kv('العنوان', (o['address'] ?? '—').toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('عناصر الطلب',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 680),
                      child: Table(
                        border: TableBorder(
                          horizontalInside:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(40),
                          2: FixedColumnWidth(90),
                          3: FixedColumnWidth(120),
                          4: FixedColumnWidth(120),
                        },
                        children: [
                          _tableHeader(),
                          ...List.generate(items.length, (i) {
                            final it = items[i];
                            final name = (it['name'] ?? '—').toString();
                            final qty = _asInt(it['qty']);
                            final unit = _asDouble(it['unitPrice'] ?? it['price']);
                            final line = qty * unit;
                            return _tableRow(
                              index: i + 1,
                              name: name,
                              qty: qty,
                              unit: unit,
                              total: line,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _totalRow('Subtotal', subtotal),
                  _totalRow('Discount', -discount),
                  _totalRow('Coupon', -coupon),
                  _totalRow('Vat/Tax', vat),
                  _totalRow('Delivery fee', deliveryFee),
                  const Divider(height: 24),
                  _totalRow('Total', total, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('$k:', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  TableRow _tableHeader() {
    const h = TextStyle(fontWeight: FontWeight.bold);
    return TableRow(children: [
      _cell('#', h),
      _cell('الصنف', h),
      _cell('الكمية', h),
      _cell('سعر الوحدة', h),
      _cell('الإجمالي', h),
    ]);
  }

  TableRow _tableRow({
    required int index,
    required String name,
    required int qty,
    required double unit,
    required double total,
  }) {
    const t = TextStyle(color: Colors.black87);
    return TableRow(children: [
      _cell('$index', t, pad: 14),
      _cell(name, t, pad: 14),
      _cell('$qty', t, pad: 14),
      _cell(unit.toStringAsFixed(2), t, pad: 14),
      _cell(total.toStringAsFixed(2), t, pad: 14),
    ]);
  }

  Widget _cell(String text, TextStyle style, {double pad = 12}) {
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Text(text, style: style),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    final isNeg = value < 0;
    final show = value.abs().toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            '${isNeg ? '-' : ''} $show د.ل',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: isNeg ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
