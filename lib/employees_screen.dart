// lib/employees_screen.dart
import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'bottom_bar_rtl.dart';
import 'employees/employees_root_screen.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  void _onBottomTap(BuildContext context, int i) {
    final route = AppRoutes.forIndex(i);
    if (route == AppRoutes.employees) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: BottomBarRTL(
          currentIndex: 2,
          onTap: (i) => _onBottomTap(context, i),
        ),

        // ✅ UI فقط: نفس ستايل عناوين الصفحات (أبيض + بدون ظل + العنوان يمين)
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          centerTitle: false,
          title: const Text(
            'الموظفين',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          // خط سفلي خفيف زي باقي الصفحات (اختياري)
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
          ),
        ),

        body: const EmployeesRootScreen(),
      ),
    );
  }
}
