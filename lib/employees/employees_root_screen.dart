import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../auth/auth_service.dart';
import 'add_employee_empty.dart';
import 'employee_card_widget.dart';
import 'employee_models.dart';
import 'employee_pending_orders_screen.dart';

class EmployeesRootScreen extends StatefulWidget {
  const EmployeesRootScreen({super.key});

  @override
  State<EmployeesRootScreen> createState() => _EmployeesRootScreenState();
}

class _EmployeesRootScreenState extends State<EmployeesRootScreen> {
  int _retryTick = 0; // ✅ لإعادة بناء الـ Stream عند الضغط على "إعادة المحاولة"

  Future<void> _addEmployeeFlow() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.employeeRegister,
    );

    if (result is EmployeeModel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الموظف بنجاح')),
      );
      // ✅ بعد إضافة موظف، حدث الصفحة
      setState(() => _retryTick++);
    }
  }

  void _openEmployeeOrders(EmployeeModel emp) {
    final uid = emp.uid ?? '';
    if (uid.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeePendingOrdersScreen(
          employeeUid: uid,
          employeeName: emp.name,
        ),
      ),
    );
  }

  void _retry() {
    setState(() => _retryTick++);
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.currentUser;

    if (AuthService.instance.isGuest || me == null) {
      return const Center(child: Text('سجّل دخول حتى تتمكن من اضافه موظف'));
    }
    if (me.role != 'owner') {
      return const Center(child: Text('هالصفحة خاصة بصاحب المقهى فقط'));
    }

    return StreamBuilder(
      // ✅ نربط الستريم بـ _retryTick حتى نقدر نعمل Retry
      stream: AuthService.instance.watchEmployeesForOwner(me.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          // ✅ هذا يطبع السبب الحقيقي في الكونسل (ضروري لمعرفة هل هو Rules أو Index أو غيره)
          debugPrint('EmployeesRootScreen stream error: ${snap.error}');
          debugPrintStack(stackTrace: snap.stackTrace);

          // ✅ بدل ما توقف الصفحة على رسالة عامة، نعطي خيارات للمستخدم
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'صارت مشكلة في تحميل الموظفين',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'جرّب إعادة المحاولة أو أضف موظف جديد.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addEmployeeFlow,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('إضافة موظف'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ✅ للمطور فقط: نعرض الخطأ داخل الشاشة (يساعدك إذا ما تبيش تفتح الكونسل)
                  Text(
                    '${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        // ✅ حماية إضافية: لو parsing يضرب، ما يطيّحش الصفحة
        final List<EmployeeModel> employees = [];
        for (final d in docs) {
          try {
            employees.add(EmployeeModel.fromFirestore(d.id, d.data()));
          } catch (e, st) {
            debugPrint('EmployeeModel.fromFirestore failed for ${d.id}: $e');
            debugPrintStack(stackTrace: st);
          }
        }

        if (employees.isEmpty) {
          return AddEmployeeEmpty(onAdd: _addEmployeeFlow);
        }

        // ✅ زر الإضافة آخر القائمة
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: employees.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i < employees.length) {
              final emp = employees[i];
              return EmployeeCardWidget(
                employee: emp,
                onTap: () => _openEmployeeOrders(emp),
              );
            }

            return Align(
              alignment: Alignment.centerRight,
              child: _AddEmployeeMiniButton(onTap: _addEmployeeFlow),
            );
          },
        );
      },
    );
  }
}

class _AddEmployeeMiniButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddEmployeeMiniButton({required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: orange.withOpacity(.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: orange.withOpacity(.35)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.person, color: orange, size: 26),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}