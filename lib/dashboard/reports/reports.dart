import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: orange, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, double value, Color color) {
    return Column(
      children: [
        Container(
          height: 120 * value,
          width: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _statCard('طلبات اليوم', '34', Icons.shopping_bag),
            const SizedBox(width: 12),
            _statCard('إيراد اليوم', '720 د.ل', Icons.payments),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('طلبات الأسبوع', '210', Icons.calendar_today),
            const SizedBox(width: 12),
            _statCard('عملاء جدد', '18', Icons.person_add),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'أداء الطلبات (هذا الأسبوع)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar('س', 0.6, orange),
              _bar('ح', 0.8, orange),
              _bar('ن', 0.4, orange),
              _bar('ث', 0.9, orange),
              _bar('ر', 0.7, orange),
              _bar('خ', 0.5, orange),
              _bar('ج', 0.3, orange),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('حالات الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _statusRow('جديد', Colors.orange, 12),
        _statusRow('قيد التجهيز', Colors.blue, 9),
        _statusRow('في الطريق', Colors.purple, 7),
        _statusRow('مكتمل', Colors.green, 22),
        const SizedBox(height: 24),
        const Text('أفضل المنتجات', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _topProduct('بيتزا مارجريتا', '45 طلب'),
        _topProduct('برجر لحم', '32 طلب'),
        _topProduct('عصير فريش', '20 طلب'),
      ],
    );
  }

  Widget _statusRow(String title, Color color, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
          Text(count.toString()),
        ],
      ),
    );
  }

  Widget _topProduct(String name, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: orange),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
          Text(value),
        ],
      ),
    );
  }
}
