import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/firestore_orders.dart';

class TrackOrderScreen extends StatelessWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  static const Color orange = Color(0xFFF5A623);

  static const steps = [
    FirestoreOrderStep(
      key: OrderStatus.accepted,
      title: 'تم قبول الطلب',
      subtitle: ' بدأت المهمة',
      icon: Icons.check_circle,
    ),
    FirestoreOrderStep(
      key: OrderStatus.preparing,
      title: 'قيد التجهيز',
      subtitle: 'يتم تجهيز الطلب',
      icon: Icons.kitchen,
    ),
    FirestoreOrderStep(
      key: OrderStatus.onTheWay,
      title: 'في الطريق',
      subtitle: 'المندوب في الطريق إليك',
      icon: Icons.delivery_dining,
    ),
    FirestoreOrderStep(
      key: OrderStatus.delivered,
      title: 'تم التسليم',
      subtitle: 'وصلتك الطلبية',
      icon: Icons.home_filled,
    ),
  ];

  int _currentIndex(String status) {
    return steps.indexWhere((e) => e.key == status).clamp(0, steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('تتبع الطلب', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreOrdersService.instance.watchOrder(orderId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data();
          if (data == null) {
            return const Center(child: Text('الطلب غير موجود'));
          }

          final status = (data['status'] ?? OrderStatus.accepted).toString();
          final current = _currentIndex(status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OrderHeader(orderId: orderId),
              const SizedBox(height: 20),

              ...List.generate(steps.length, (i) {
                final step = steps[i];
                final done = i <= current;

                return _StepTile(
                  title: step.title,
                  subtitle: step.subtitle,
                  icon: step.icon,
                  done: done,
                  isLast: i == steps.length - 1,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/* -------------------- UI COMPONENTS -------------------- */

class _OrderHeader extends StatelessWidget {
  final String orderId;
  const _OrderHeader({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'رقم الطلب',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            orderId,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool isLast;

  const _StepTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.isLast,
  });

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: done ? orange : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: done ? orange : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 30),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Color(0xFF7A7A7A), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------- MODEL -------------------- */

class FirestoreOrderStep {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const FirestoreOrderStep({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
