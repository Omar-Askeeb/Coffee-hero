import 'package:flutter/material.dart';
import 'pending_employee_order.dart';
import 'pending_orders_store.dart';

class EmployeePendingOrdersScreen extends StatefulWidget {
  const EmployeePendingconst OrdersScreen()({super.key});

  @override
  State<EmployeePendingOrdersScreen> createState() => _EmployeePendingOrdersScreenState();
}

class _EmployeePendingOrdersScreenState extends State<EmployeePendingOrdersScreen> {
  List<PendingEmployeeOrder> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await PendingOrdersStore.instance.seedDemoIfEmpty();
    final list = await PendingOrdersStore.instance.load();
    if (!mounted) return;
    setState(() {
      orders = list;
      loading = false;
    });
  }

  Future<void> _approve(PendingEmployeeOrder order) async {
    // ✅ هنا مكان إضافة العناصر للسلة (حنربطها بعد ما تبعت CartStore)
    // حاليا: نحذف الطلب من قائمة الانتظار بعد "الموافقة"
    final newList = orders.where((o) => o.id != order.id).toList();
    await PendingOrdersStore.instance.save(newList);

    if (!mounted) return;
    setState(() => orders = newList);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الموافقة وإضافة الطلب للسلة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الموظف'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('لا توجد طلبات في انتظار الموافقة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return _orderCard(o);
                  },
                ),
    );
  }

  Widget _orderCard(PendingEmployeeOrder o) {
    return InkWell(
      onTap: () => _approve(o),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x11000000))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFFF5A623)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      o.status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF5A623),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
