import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firestore_orders.dart';

// ✅ OneSignal sender
import '../../services/onesignal_sender.dart';

import 'order_details_screen.dart';

class DashboardOrdersScreen extends StatefulWidget {
  const DashboardOrdersScreen({super.key});

  @override
  State<DashboardOrdersScreen> createState() => _DashboardOrdersScreenState();
}

class _DashboardOrdersScreenState extends State<DashboardOrdersScreen> {
  static const Color orange = Color(0xFFF5A623);
  final TextEditingController _search = TextEditingController();

  static const List<String> flow = [
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  // ✅ فتح موقع الزبون في Google Maps (خارجي)
  Future<void> _openCustomerLocation(Map<String, dynamic> o) async {
    // جرّب أكثر من مفتاح لأن الداتا تختلف من مشروع لمشروع
    dynamic lat = o['lat'];
    dynamic lng = o['lng'];

    // احتياط: بعض الناس يحفظوها داخل location
    if ((lat == null || lng == null) && o['location'] is Map) {
      final loc = Map<String, dynamic>.from(o['location'] as Map);
      lat = loc['lat'] ?? loc['latitude'];
      lng = loc['lng'] ?? loc['longitude'];
    }

    // احتياط: GeoPoint
    if ((lat == null || lng == null) && o['location'] is GeoPoint) {
      final gp = o['location'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    }

    double? dLat;
    double? dLng;

    if (lat is num) dLat = lat.toDouble();
    if (lng is num) dLng = lng.toDouble();
    if (lat is String) dLat = double.tryParse(lat);
    if (lng is String) dLng = double.tryParse(lng);

    if (dLat == null || dLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد إحداثيات لهذا الطلب')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$dLat,$dLng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح خرائط Google')),
      );
    }
  }

  String _fmtDate(dynamic createdAt) {
    if (createdAt == null) return '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final d =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t';
    }
    return createdAt.toString();
  }

  int _qtyFromItems(dynamic items) {
    if (items is! List) return 0;
    var sum = 0;
    for (final it in items) {
      if (it is Map) {
        final q = it['qty'];
        if (q is int) sum += q;
        if (q is num) sum += q.toInt();
        if (q is String) sum += int.tryParse(q) ?? 0;
      }
    }
    return sum;
  }

  Color _statusFg(String status) {
    switch (status) {
      case OrderStatus.accepted:
        return const Color(0xFF0EA5E9);
      case OrderStatus.preparing:
        return const Color(0xFF6366F1);
      case OrderStatus.onTheWay:
        return const Color(0xFF8B5CF6);
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _prev(String s) {
    switch (s) {
      case OrderStatus.preparing:
        return OrderStatus.accepted;
      case OrderStatus.onTheWay:
        return OrderStatus.preparing;
      case OrderStatus.delivered:
        return OrderStatus.onTheWay;
      case OrderStatus.cancelled:
        return OrderStatus.cancelled;
      default:
        return OrderStatus.accepted;
    }
  }

  // ✅ نص عربي واضح حسب الحالة
  String _statusArabic(String newStatus) {
    switch (newStatus) {
      case OrderStatus.accepted:
        return 'تم قبول الطلب';
      case OrderStatus.preparing:
        return 'قيد التجهيز';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'تم إلغاء الطلب';
      default:
        return newStatus;
    }
  }

  // ✅ إرسال إشعار OneSignal للزبون (بدون ما يطيّح التطبيق لو فشل)
  Future<void> _notifyCustomer({
    required String customerExternalId,
    required String orderId,
    required String newStatus,
  }) async {
    final cid = customerExternalId.trim();
    if (cid.isEmpty) return;

    final statusText = _statusArabic(newStatus);

    try {
      await OneSignalSender.sendToCustomer(
        customerExternalId: cid,
        title: 'تحديث الطلب',
        body: 'حالة طلبك الآن: $statusText',
        data: {'orderId': orderId, 'status': newStatus},
      );
    } catch (_) {
      // ما نبوّش نوقف الداشبورد لو الإرسال فشل
    }
  }

  // ✅ نجيب customerExternalId للاشعار (مرن حسب الداتا عندك)
  // الأفضل: customerId أو customerExternalId
  // احتياط: customerPhone أو phone
  String _getCustomerExternalId(Map<String, dynamic> o) {
    String pick(String k) => (o[k] ?? '').toString().trim();

    final v1 = pick('customerId');
    if (v1.isNotEmpty) return v1;

    final v2 = pick('customerExternalId');
    if (v2.isNotEmpty) return v2;

    final v3 = pick('customerPhone');
    if (v3.isNotEmpty) return v3;

    final v4 = pick('phone');
    if (v4.isNotEmpty) return v4;

    return '';
  }

  // ✅ next/prev/cancel مع إرسال إشعار بعد تحديث الحالة
  Future<void> _nextStatusWithNotify(
      Map<String, dynamic> o, String id, String current) async {
    final next = OrderStatus.next(current);
    await FirestoreOrdersService.instance.updateStatus(id, next);

    final customerExternalId = _getCustomerExternalId(o);
    await _notifyCustomer(
      customerExternalId: customerExternalId,
      orderId: id,
      newStatus: next,
    );
  }

  Future<void> _prevStatusWithNotify(
      Map<String, dynamic> o, String id, String current) async {
    final prev = _prev(current);
    await FirestoreOrdersService.instance.updateStatus(id, prev);

    final customerExternalId = _getCustomerExternalId(o);
    await _notifyCustomer(
      customerExternalId: customerExternalId,
      orderId: id,
      newStatus: prev,
    );
  }

  Future<void> _cancelOrderWithNotify(Map<String, dynamic> o, String id) async {
    await FirestoreOrdersService.instance.updateStatus(id, OrderStatus.cancelled);

    final customerExternalId = _getCustomerExternalId(o);
    await _notifyCustomer(
      customerExternalId: customerExternalId,
      orderId: id,
      newStatus: OrderStatus.cancelled,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> o) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final id = (o['__id'] ?? '').toString().toLowerCase();
    final customerName = (o['customerName'] ?? '').toString().toLowerCase();
    final customerPhone = (o['customerPhone'] ?? '').toString().toLowerCase();
    final status = (o['status'] ?? '').toString().toLowerCase();

    return id.contains(q) ||
        customerName.contains(q) ||
        customerPhone.contains(q) ||
        status.contains(q);
  }

  // ✅ تحويل بيانات Firestore للمفاتيح اللي تتوقعها OrderDetailsScreen
  Map<String, dynamic> _toOrderDetailsMap(Map<String, dynamic> o) {
    final id = (o['__id'] ?? '—').toString();
    final createdAt = _fmtDate(o['createdAt']);

    final customerName = (o['customerName'] ?? '—').toString();
    final customerPhone = (o['customerPhone'] ?? '—').toString();
    final address = (o['addressText'] ?? '—').toString();

    final itemsRaw = o['items'];
    final items = <Map<String, dynamic>>[];

    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          items.add({
            'name': (m['title'] ?? m['name'] ?? '—').toString(),
            'qty': m['qty'] ?? 0,
            'unitPrice': m['unitPrice'] ?? m['price'] ?? 0,
          });
        }
      }
    }

    return <String, dynamic>{
      'id': id,
      'date': createdAt,
      'store': (o['storeName'] ?? 'فرع حي الاندلس').toString(),
      'customer': customerName,
      'phone': customerPhone,
      'address': address,
      'items': items,
      'discount': o['discount'] ?? 0,
      'coupon': o['coupon'] ?? 0,
      'vat': o['vat'] ?? 0,
      'deliveryFee': o['deliveryFee'] ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Text(
                  'الطلبات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'بحث: رقم الطلب / العميل / الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreOrdersService.instance.watchOrders(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('صار خطأ في تحميل الطلبات'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                final rows = docs
                    .map((d) {
                      final data = d.data();
                      return <String, dynamic>{
                        ...data,
                        '__id': d.id,
                      };
                    })
                    .where(_matchesSearch)
                    .toList(growable: false);

                if (rows.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات حالياً'));
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1250),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowHeight: 56,
                              dataRowMinHeight: 62,
                              dataRowMaxHeight: 82,
                              columns: const [
                                DataColumn(label: Text('SL')),
                                DataColumn(label: Text('Order Id')),
                                DataColumn(label: Text('Order Date')),
                                DataColumn(label: Text('Customer')),
                                DataColumn(label: Text('Qty')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('تحكم الحالة')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: List.generate(rows.length, (i) {
                                final o = rows[i];
                                final id = (o['__id'] ?? '').toString();
                                final status =
                                    (o['status'] ?? OrderStatus.accepted).toString();
                                final c = _statusFg(status);

                                final customerName =
                                    (o['customerName'] ?? '').toString();
                                final customerPhone =
                                    (o['customerPhone'] ?? '').toString();

                                final qty = _qtyFromItems(o['items']);
                                final total = (o['total'] is num)
                                    ? (o['total'] as num).toDouble()
                                    : 0.0;

                                final canNext = status != OrderStatus.delivered &&
                                    status != OrderStatus.cancelled;
                                final canPrev = status != OrderStatus.accepted &&
                                    status != OrderStatus.cancelled;
                                final canCancel = status != OrderStatus.delivered &&
                                    status != OrderStatus.cancelled;

                                return DataRow(cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(
                                    Text(
                                      id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_fmtDate(o['createdAt']))),
                                  DataCell(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(customerName.isEmpty ? '—' : customerName),
                                        const SizedBox(height: 4),
                                        Text(
                                          customerPhone.isEmpty ? '—' : customerPhone,
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text('$qty')),
                                  DataCell(Text('${total.toStringAsFixed(2)} د.ل')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: c.withOpacity(0.35)),
                                      ),
                                      child: Text(
                                        OrderStatus.label(status),
                                        style: TextStyle(
                                          color: c,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        _pillBtn(
                                          icon: Icons.chevron_right,
                                          label: 'التالي',
                                          color: Colors.green,
                                          enabled: canNext,
                                          onTap: () async =>
                                              _nextStatusWithNotify(o, id, status),
                                        ),
                                        const SizedBox(width: 8),
                                        _pillBtn(
                                          icon: Icons.chevron_left,
                                          label: 'السابق',
                                          color: const Color(0xFF0EA5E9),
                                          enabled: canPrev,
                                          onTap: () async =>
                                              _prevStatusWithNotify(o, id, status),
                                        ),
                                        const SizedBox(width: 8),
                                        _pillBtn(
                                          icon: Icons.close,
                                          label: 'إلغاء',
                                          color: Colors.red,
                                          enabled: canCancel,
                                          onTap: () async =>
                                              _cancelOrderWithNotify(o, id),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        _actionIcon(
                                          icon: Icons.location_on,
                                          color: const Color(0xFF0EA5E9),
                                          onTap: () async {
                                            await _openCustomerLocation(o);
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        _actionIcon(
                                          icon: Icons.visibility,
                                          color: Colors.orange,
                                          onTap: () {
                                            final details = _toOrderDetailsMap(o);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    OrderDetailsScreen(order: details),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.10) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: enabled ? color.withOpacity(0.55) : Colors.grey.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: enabled ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.6)),
          color: color.withOpacity(0.08),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
