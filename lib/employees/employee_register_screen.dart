import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import 'employee_models.dart';

class EmployeeRegisterScreen extends StatefulWidget {
  const EmployeeRegisterScreen({super.key});

  @override
  State<EmployeeRegisterScreen> createState() => _EmployeeRegisterScreenState();
}

class _EmployeeRegisterScreenState extends State<EmployeeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  String _role = 'employee';
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = await AuthService.instance.createEmployee(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        password: _pass.text.trim(),
        role: _role,
      );

      if (!mounted) return;
      Navigator.pop(
        context,
        EmployeeModel(
          uid: uid,
          name: _name.text.trim(),
          phone: AuthService.instance.normalizePhone(_phone.text.trim()),
          role: _role,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة موظف'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الموظف'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'اكتب الاسم' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                validator: (v) {
                  final p = AuthService.instance.normalizePhone(v ?? '');
                  if (p.length < 8) return 'رقم غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('موظف')),
                  DropdownMenuItem(value: 'manager', child: Text('مدير فرعي')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'employee'),
                decoration: const InputDecoration(labelText: 'الدور'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                validator: (v) {
                  if (v == null || v.trim().length < 6) {
                    return 'كلمة المرور لازم 6 أحرف أو أكثر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass2,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                validator: (v) {
                  if (v == null || v.trim() != _pass.text.trim()) {
                    return 'كلمتا المرور غير متطابقتين';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إنشاء الموظف'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
