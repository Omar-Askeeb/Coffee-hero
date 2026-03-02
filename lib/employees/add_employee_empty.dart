import 'package:flutter/material.dart';

class AddEmployeeEmpty extends StatelessWidget {
  final VoidCallback onAddPressed;

  const AddEmployeeEmpty({
    super.key,
    /// الاسم الجديد
    VoidCallback? onAddPressed,
    /// توافق مع اسم قديم كان في `employees_root_screen.dart`
    VoidCallback? onAdd,
  })  : assert(onAddPressed != null || onAdd != null),
        onAddPressed = onAddPressed ?? onAdd!;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة بسيطة بدل الصورة (بنحط صورة لاحقاً لو تبي)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8C7),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                size: 56,
                color: Color(0xFFF5A623),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'أضف موظف',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'قم بإضافة موظف لإدارة الطلبات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onAddPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'أضافه',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
