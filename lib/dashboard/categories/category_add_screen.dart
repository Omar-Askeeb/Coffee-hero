import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CategoryAddScreen extends StatefulWidget {
  final List<Map<String, dynamic>> mainCategories;
  final Map<String, dynamic>? initial;

  const CategoryAddScreen({
    super.key,
    required this.mainCategories,
    this.initial,
  });

  @override
  State<CategoryAddScreen> createState() => _CategoryAddScreenState();
}

class _CategoryAddScreenState extends State<CategoryAddScreen> {
  static const Color teal = Color(0xFF0B6B63);

  String type = 'main';

  final nameArCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final orderCtrl = TextEditingController();

  bool active = true;

  String? parentId;

  /// للمعاينة داخل الداشبورد فقط
  String? iconPath;

  /// ✅ هذا اللي بنخزّنه في Firestore
  String? iconUrl;

  bool _uploadingIcon = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final init = widget.initial;
    if (init != null) {
      type = (init['type'] ?? 'main').toString();
      nameArCtrl.text = (init['nameAr'] ?? '').toString();
      nameEnCtrl.text = (init['nameEn'] ?? '').toString();
      orderCtrl.text = (init['order'] ?? '').toString();
      active = init['active'] == true;
      parentId = init['parentId']?.toString();

      // القديم كان iconPath (محلي) - نخلّيه للمعاينة فقط لو موجود
      iconPath = init['iconPath']?.toString();

      // ✅ الجديد
      iconUrl = init['iconUrl']?.toString();

      if (type == 'sub') {
        final ok = widget.mainCategories.any(
          (c) => c['id'].toString() == parentId,
        );
        if (!ok) parentId = null;
      }
    }
  }

  @override
  void dispose() {
    nameArCtrl.dispose();
    nameEnCtrl.dispose();
    orderCtrl.dispose();
    super.dispose();
  }

  /// يرفع الصورة لـ Firebase Storage ويرجع الرابط
  Future<String> _uploadIconToStorage({
    required XFile xfile,
  }) async {
    final bytes = await File(xfile.path).readAsBytes();

    // اسم ملف فريد
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = xfile.name.isNotEmpty ? xfile.name : 'icon.png';
    final fileName = '${ts}_$safeName';

    // مكان التخزين
    final ref = FirebaseStorage.instance.ref().child('category_icons/$fileName');

    // رفع
    final metadata = SettableMetadata(
      contentType: 'image/${safeName.toLowerCase().endsWith(".png") ? "png" : "jpeg"}',
    );
    await ref.putData(bytes, metadata);

    // رابط
    return await ref.getDownloadURL();
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x == null) return;

    setState(() {
      _uploadingIcon = true;
      iconPath = x.path; // معاينة
    });

    try {
      final url = await _uploadIconToStorage(xfile: x);
      if (!mounted) return;

      setState(() {
        iconUrl = url;
        _uploadingIcon = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingIcon = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الأيقونة: $e')),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (type == 'sub' && (parentId == null || parentId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار القسم الرئيسي اللي يتبعه القسم الفرعي')),
      );
      return;
    }

    // لو اليوزر ضغط حفظ وهو يرفع الأيقونة
    if (_uploadingIcon) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('استنى… الأيقونة توها تترفع')),
      );
      return;
    }

    final result = <String, dynamic>{
      // ✅ مهم: في حالة التعديل فقط نرجع id
      if (widget.initial != null && widget.initial!['id'] != null) 'id': widget.initial!['id'],

      'type': type,
      'nameAr': nameArCtrl.text.trim(),
      'nameEn': nameEnCtrl.text.trim(),
      'order': int.tryParse(orderCtrl.text.trim()) ?? 0,
      'active': active,
      'parentId': (type == 'sub') ? parentId : null,

      // نخلي iconPath اختياري للمعاينة فقط (مش لازم تخزنه)
      'iconPath': iconPath,

      // ✅ هذا اللي لازم يعتمد عليه الهوم
      'iconUrl': iconUrl,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(isEdit ? 'تعديل قسم' : 'إضافة قسم'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('بيانات القسم', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: type,
                            items: const [
                              DropdownMenuItem(value: 'main', child: Text('قسم رئيسي')),
                              DropdownMenuItem(value: 'sub', child: Text('قسم فرعي')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                type = v;
                                if (type == 'main') parentId = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'نوع القسم *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<bool>(
                            value: active,
                            items: const [
                              DropdownMenuItem(value: true, child: Text('مفعل')),
                              DropdownMenuItem(value: false, child: Text('غير مفعل')),
                            ],
                            onChanged: (v) => setState(() => active = v ?? true),
                            decoration: InputDecoration(
                              labelText: 'حالة القسم',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (type == 'sub') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: parentId,
                        items: widget.mainCategories.map((c) {
                          final id = c['id'].toString();
                          final title = (c['nameAr'] ?? '').toString();
                          return DropdownMenuItem(value: id, child: Text(title));
                        }).toList(),
                        onChanged: (v) => setState(() => parentId = v),
                        decoration: InputDecoration(
                          labelText: 'يتبع قسم رئيسي *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameArCtrl,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'اسم القسم (عربي) مطلوب';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'اسم القسم (عربي) *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameEnCtrl,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        labelText: 'اسم القسم (English) (اختياري)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: orderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ترتيب الظهور (اختياري)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('أيقونة القسم (اللي في أعلى الهوم)', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('يفضل PNG بخلفية شفافة.', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: _uploadingIcon
                                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                : (iconPath != null &&
                                        iconPath!.isNotEmpty &&
                                        File(iconPath!).existsSync())
                                    ? Image.file(File(iconPath!), fit: BoxFit.cover)
                                    : (iconUrl != null && iconUrl!.isNotEmpty)
                                        ? Image.network(iconUrl!, fit: BoxFit.cover)
                                        : const Icon(Icons.category_outlined, color: Colors.black38, size: 30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _uploadingIcon ? null : _pickIcon,
                                icon: const Icon(Icons.upload),
                                label: const Text('رفع أيقونة'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: ((iconUrl == null || iconUrl!.isEmpty) && (iconPath == null || iconPath!.isEmpty))
                                    ? null
                                    : () => setState(() {
                                          iconPath = null;
                                          iconUrl = null;
                                        }),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('حذف الأيقونة'),
                              ),
                              const SizedBox(height: 6),
                              if (iconUrl != null && iconUrl!.isNotEmpty)
                                Text(
                                  'تم رفع الأيقونة ✅',
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _save,
                      child: Text(isEdit ? 'حفظ التعديل' : 'حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}
