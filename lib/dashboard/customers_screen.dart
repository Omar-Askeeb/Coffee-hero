import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  static const Color teal = Color(0xFF0B6B63);
  final TextEditingController _search = TextEditingController();

  int _page = 0;
  static const int _pageSize = 8;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _fmtDate(dynamic createdAt) {
    DateTime d;
    if (createdAt is Timestamp) {
      d = createdAt.toDate();
    } else if (createdAt is DateTime) {
      d = createdAt;
    } else {
      return '-';
    }
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static List<Map<String, dynamic>> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final items = docs.map((d) {
      final data = d.data();
      final name = (data['cafeName'] ?? data['name'] ?? data['fullName'] ?? '').toString().trim();
      final phone = (data['phone'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();

      final totalOrdersRaw = data['totalOrders'];
      final totalOrders = (totalOrdersRaw is num) ? totalOrdersRaw.toInt() : 0;

      final totalAmountRaw = data['totalAmount'];
      final totalAmount = (totalAmountRaw is num) ? totalAmountRaw.toDouble() : 0.0;

      final createdAt = data['createdAt'];

      DateTime? created;
      if (createdAt is Timestamp) {
        created = createdAt.toDate();
      } else if (createdAt is DateTime) {
        created = createdAt;
      }

      return <String, dynamic>{
        'id': d.id,
        'name': name.isEmpty ? '—' : name,
        'email': email.isEmpty ? '—' : email,
        'phone': phone.isEmpty ? '—' : phone,
        'totalOrders': totalOrders,
        'totalAmount': totalAmount,
        'joinDate': _fmtDate(createdAt),
        'createdAt': created, // for local sorting only
        'active': true,
      };
    }).toList(growable: false);

    items.sort((a, b) {
      final da = a['createdAt'] as DateTime?;
      final db = b['createdAt'] as DateTime?;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return items;
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> items) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('العملاء', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('customers').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('صار خطأ في تحميل العملاء'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = _mapDocs(snap.data!.docs);
          final customers = _applySearch(all);

          // pagination
          final totalPages = (customers.length / _pageSize).ceil().clamp(1, 999);
          if (_page >= totalPages) _page = totalPages - 1;

          final start = _page * _pageSize;
          final end = (start + _pageSize).clamp(0, customers.length);
          final pageItems = (start < end) ? customers.sublist(start, end) : const <Map<String, dynamic>>[];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SearchBar(
                  controller: _search,
                  onChanged: (_) => setState(() => _page = 0),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, 6))],
                    ),
                    child: Column(
                      children: [
                        _HeaderRow(),
                        const Divider(height: 1),
                        Expanded(
                          child: pageItems.isEmpty
                              ? const Center(child: Text('لا توجد بيانات'))
                              : ListView.separated(
                                  itemCount: pageItems.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, i) => _CustomerRow(
                                    data: pageItems[i],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Pager(
                  page: _page,
                  totalPages: totalPages,
                  onPrev: _page == 0 ? null : () => setState(() => _page -= 1),
                  onNext: _page >= totalPages - 1 ? null : () => setState(() => _page += 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'بحث بالاسم/الهاتف/الإيميل',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('العميل', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(flex: 3, child: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(flex: 2, child: Text('الطلبات', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(flex: 2, child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CustomerRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? '—';
    final phone = data['phone']?.toString() ?? '—';
    final totalOrders = data['totalOrders']?.toString() ?? '0';
    final totalAmount = (data['totalAmount'] is num) ? (data['totalAmount'] as num).toDouble() : 0.0;
    final joinDate = data['joinDate']?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(phone, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(totalOrders)),
          Expanded(flex: 2, child: Text(totalAmount.toStringAsFixed(0))),
          Expanded(flex: 2, child: Text(joinDate)),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pager({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text('${page + 1} / $totalPages', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
