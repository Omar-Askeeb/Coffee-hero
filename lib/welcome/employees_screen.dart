// lib/employees_screen.dart
import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'bottom_bar_rtl.dart';
import 'employees/employees_root_screen.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  void _onBottomTap(BuildContext context, int i) {
    final route = AppRoutes.forIndex(i);
    if (route == AppRoutes.employees) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
          BottomBarRTL(currentIndex: 2, onTap: (i) => _onBottomTap(context, i)),
      appBar: AppBar(
        title: const Text('الموظفين'),
        automaticallyImplyLeading: false, // ✅ يلغي سهم الرجوع
        centerTitle: true,
      ),
      body: const EmployeesRootScreen(),
    );
  }
}
