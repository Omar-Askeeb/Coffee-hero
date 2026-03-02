import 'package:flutter/material.dart';

import '../services/firestore_orders.dart';

/// شاشة تجريبية لإنشاء طلب (باش تتأكد انه يطلع فوراً في داشبورد الأدمن)
/// تقدر تحذفها بعد ما تربط شاشة السلة/الدفع.
class PlaceOrderDemo extends StatelessWidget {
  const PlaceOrderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تجربة إنشاء طلب'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'اضغط الزر لإنشاء طلب تجريبي.\nبعدها افتح داشبورد الأدمن -> الطلبات وشوفه يطلع فوراً.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إنشاء طلب تجريبي'),
                onPressed: () async {
                  final id = await FirestoreOrdersService.instance.createOrder(
                    customerId: 'guest_0912345678',
                    customerName: 'عميل تجريبي',
                    customerPhone: '0912345678',
                    addressText: 'طرابلس - حي الاندلس',
                    items: const [
                      {'title': 'بن', 'qty': 2, 'price': 12.5},
                      {'title': 'تورالدو', 'qty': 1, 'price': 18.0},
                    ],
                    total: 43.0,
                    paymentMethod: 'cash',
                    lat: 32.887,
                    lng: 13.187,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم إنشاء الطلب: $id')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
