import 'dart:async';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

// ✅ DashboardShell (عدّل المسار إذا ملفك مختلف)
import 'package:app_for_me/dashboard/dashboard_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;

  // ✅ Timer للضغط المطوّل 7 ثواني
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(phone: _phone.text, password: _pass.text);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      showAuthErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ===============================
  /// Bottom Sheet الدخول المخفي
  /// ===============================
  void _showHiddenDashboardSheet() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'لوحة التحكم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'أدخل الرمز',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final ok = controller.text.trim() == '2580';

                      Navigator.pop(context); // اقفل الشيت
                      controller.dispose();

                      if (ok) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardShell(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرمز غير صحيح')),
                        );
                      }
                    },
                    child: const Text('دخول'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // لو المستخدم سكّر الشيت بدون زر
      try {
        controller.dispose();
      } catch (_) {}
    });
  }

  /// ===============================
  /// ضغط مطوّل 7 ثواني على صورة المتجر
  /// ===============================
  void _startHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      _showHiddenDashboardSheet();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      // ✅ هذا هو التعديل الوحيد: نفس سهم الرجوع + نفس الأنميشن زي RegisterScreen
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),

            // ✅ اضغط مطوّل 7 ثواني على صورة المتجر
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (_) => _startHold(),
                onLongPressEnd: (_) => _cancelHold(),
                onLongPressCancel: () => _cancelHold(),
                child: Image.asset(
                  'assets/icons/store.png',
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 18),
            const AuthHeader(
              title: 'مرحبا بك مجددا',
              subtitle: 'سجل الدخول لمتابعة طلباتك',
            ),
            const SizedBox(height: 22),

            AuthInputField(
              controller: _phone,
              hintText: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              left: const Icon(Icons.smartphone, size: 20),
              rightText: '+218',
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'أدخل رقم الهاتف';
                if (digits.length < 8) return 'رقم الهاتف غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),

            AuthInputField(
              controller: _pass,
              hintText: 'كلمة المرور',
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              left: const Icon(Icons.lock_outline, size: 20),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'أدخل كلمة المرور';
                if ((v ?? '').trim().length < 6) return 'كلمة المرور قصيرة';
                return null;
              },
            ),

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.forgotPhone),
                child: const Text('لقد نسيت كلمة السر'),
              ),
            ),

            const SizedBox(height: 10),
            PrimaryButton(
              label: 'تسجيل دخول',
              isLoading: _loading,
              onPressed: _login,
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ليس لديك حساب؟ '),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.register),
                  child: const Text('إنشاء حساب جديد'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
