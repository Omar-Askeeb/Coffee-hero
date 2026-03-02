import 'package:flutter/material.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  Widget _card(String title, String value, IconData icon) {
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
            Icon(icon, color: orange, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _card('طلبات اليوم', '12', Icons.shopping_bag),
              const SizedBox(width: 12),
              _card('قيد التنفيذ', '5', Icons.sync),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _card('مكتملة', '20', Icons.check_circle),
              const SizedBox(width: 12),
              _card('إجمالي اليوم', '250 د.ل', Icons.payments),
            ],
          ),
        ],
      ),
    );
  }
}
