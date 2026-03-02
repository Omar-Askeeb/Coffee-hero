import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();

  bool _loading = false;
  bool _ob1 = true;
  bool _ob2 = true;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _submit(String phone) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.updatePasswordForCurrentUser(_p1.text.trim());

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } on AuthException catch (e) {
      if (!mounted) return;
      showAuthErrorSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showAuthErrorSnack(context, 'حدث خطأ غير متوقع');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = (ModalRoute.of(context)?.settings.arguments as String?) ?? '';

    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const AuthHeader(
              title: 'تغيير كلمة المرور',
              subtitle: 'اكتب كلمة مرور جديدة ثم أكدها',
            ),
            const SizedBox(height: 24),

            // ✅ كلمة المرور الجديدة + عين
            AuthInputField(
              controller: _p1,
              hintText: 'كلمة المرور الجديدة',
              obscureText: _ob1,
              left: Icon(
                _ob1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onLeftTap: () => setState(() => _ob1 = !_ob1),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'أدخل كلمة المرور';
                if (s.length < 6) return 'كلمة المرور قصيرة';
                return null;
              },
            ),

            const SizedBox(height: 14),

            // ✅ تأكيد كلمة المرور + عين
            AuthInputField(
              controller: _p2,
              hintText: 'تأكيد كلمة المرور الجديدة',
              obscureText: _ob2,
              left: Icon(
                _ob2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onLeftTap: () => setState(() => _ob2 = !_ob2),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'أكد كلمة المرور';
                if (s != _p1.text.trim()) return 'كلمتا المرور غير متطابقتين';
                return null;
              },
            ),

            const SizedBox(height: 18),

            PrimaryButton(
              label: 'حفظ',
              isLoading: _loading,
              onPressed: () => _submit(phone),
            ),
          ],
        ),
      ),
    );
  }
}
