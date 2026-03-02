import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductAddScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const ProductAddScreen({super.key, this.initial});

  @override
  State<ProductAddScreen> createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  static const Color teal = Color(0xFF0F766E);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _saving = false;
  bool _uploadingMain = false;
  bool _uploadingThumb = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _priceCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  final _stockCtrl = TextEditingController(text: '0');
  final _maxQtyCtrl = TextEditingController(text: '10');
  final _tagsCtrl = TextEditingController();

  String? store;

  /// ✅ نخزّن IDs مش أسماء
  String? mainCategoryId;
  String? subCategoryId;
  String unit = 'Kg';

  String discountType = 'Percent (%)';
  bool active = true;

  File? imageMain;
  File? imageThumb;

  // ✅ نخلي المتاجر ثابتة (لو عندك متاجر في Firestore بعدين نربطها)
  final List<String> stores = const ['Store 1', 'Store 2'];

  // ✅ قوائم Firestore
  List<Map<String, dynamic>> _mainCats = const [];
  List<Map<String, dynamic>> _subCats = const [];

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _nameCtrl.text = (p['name'] ?? p['title'] ?? '').toString();
      _descCtrl.text = (p['descAr'] ?? p['desc'] ?? p['description'] ?? '').toString();

      store = _ensureInList(p['store'] as String?, stores);

      // IDs
      mainCategoryId = (p['mainCategoryId'] ?? p['categoryId'] ?? p['category'] ?? '').toString();
      if (mainCategoryId != null && mainCategoryId!.isEmpty) mainCategoryId = null;

      subCategoryId = (p['subCategoryId'] ?? p['subCategory'] ?? '').toString();
      if (subCategoryId != null && subCategoryId!.isEmpty) subCategoryId = null;

      unit = (p['unit'] ?? unit).toString();

      _priceCtrl.text = (p['price'] ?? 0).toString();
      discountType = _ensureInList(p['discountType'] as String?, const ['Percent (%)', 'Fixed']) ?? discountType;
      _discountCtrl.text = (p['discount'] ?? 0).toString();
      _stockCtrl.text = (p['stock'] ?? 0).toString();
      _maxQtyCtrl.text = (p['maxQty'] ?? 10).toString();

      active = p['active'] == true;
    }

    // تحميل الأقسام
    _bootstrapCategories();
  }

  Future<void> _bootstrapCategories() async {
    // نستخدم stream + setState مرة أولى باش dropdown ما يطيحش
    // (الـ ProductsScreen بيبقى يتابع live، وهنا نحتاج مرة واحدة للتعبئة)
    try {
      final mainSnap = await _db
          .collection('categories')
          .where('type', isEqualTo: 'main')
          .get();

      final mains = mainSnap.docs.map((d) {
        final data = d.data();
        return <String, dynamic>{
          'id': (data['id'] ?? d.id).toString(),
          'nameAr': (data['nameAr'] ?? data['label'] ?? data['name'] ?? '').toString(),
          'order': (data['order'] is num)
              ? (data['order'] as num).toInt()
              : int.tryParse((data['order'] ?? '').toString()) ?? 0,
          'active': data['active'] != false,
        };
      }).where((e) => e['active'] == true).toList();

      mains.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      if (!mounted) return;
      setState(() {
        _mainCats = mains;
        // لو ما اختارش، خليه أول واحد
        if (mainCategoryId == null && _mainCats.isNotEmpty) {
          mainCategoryId = _mainCats.first['id'].toString();
        }
      });

      await _loadSubCatsForMain(mainCategoryId);
    } catch (_) {
      // لو فشل ما نكسرش الشاشة
    }
  }

  Future<void> _loadSubCatsForMain(String? mainId) async {
    if (mainId == null || mainId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _subCats = const [];
        subCategoryId = null;
      });
      return;
    }

    try {
      final subSnap = await _db
          .collection('categories')
          .where('type', isEqualTo: 'sub')
          .where('parentId', isEqualTo: mainId)
          .get();

      final subs = subSnap.docs.map((d) {
        final data = d.data();
        return <String, dynamic>{
          'id': (data['id'] ?? d.id).toString(),
          'nameAr': (data['nameAr'] ?? data['label'] ?? data['name'] ?? '').toString(),
          'order': (data['order'] is num)
              ? (data['order'] as num).toInt()
              : int.tryParse((data['order'] ?? '').toString()) ?? 0,
          'active': data['active'] != false,
        };
      }).where((e) => e['active'] == true).toList();

      subs.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      if (!mounted) return;
      setState(() {
        _subCats = subs;

        // لو subCategoryId مش موجود في القائمة، اختر أول واحد
        if (subCategoryId == null && _subCats.isNotEmpty) {
          subCategoryId = _subCats.first['id'].toString();
        } else if (subCategoryId != null &&
            !_subCats.any((x) => x['id'].toString() == subCategoryId)) {
          subCategoryId = _subCats.isNotEmpty ? _subCats.first['id'].toString() : null;
        }
      });
    } catch (_) {
      // ignore
    }
  }

  String? _ensureInList(String? v, List<String> list) {
    if (v == null) return null;
    return list.contains(v) ? v : null; // ✅ يمنع الخطأ
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _stockCtrl.dispose();
    _maxQtyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool thumb}) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() {
      if (thumb) {
        imageThumb = File(x.path);
      } else {
        imageMain = File(x.path);
      }
    });
  }

  Future<String> _uploadToStorage({
    required XFile xfile,
    required String folder,
  }) async {
    final bytes = await File(xfile.path).readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = xfile.name.isNotEmpty ? xfile.name : 'image.png';
    final fileName = '${ts}_$safeName';
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
    final metadata = SettableMetadata(
      contentType: 'image/${safeName.toLowerCase().endsWith(".png") ? "png" : "jpeg"}',
    );
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_saving) return;

    // تحقق بسيط
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسم المنتج')),
      );
      return;
    }

    if (mainCategoryId == null || mainCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار القسم الرئيسي')),
      );
      return;
    }

    if (subCategoryId == null || subCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار القسم الفرعي')),
      );
      return;
    }

    setState(() => _saving = true);

    String? mainImageUrl;
    String? thumbUrl;

    try {
      // رفع الصور لو موجودة
      if (imageMain != null) {
        setState(() => _uploadingMain = true);
        final x = XFile(imageMain!.path);
        mainImageUrl = await _uploadToStorage(xfile: x, folder: 'product_images');
        if (mounted) setState(() => _uploadingMain = false);
      }

      if (imageThumb != null) {
        setState(() => _uploadingThumb = true);
        final x = XFile(imageThumb!.path);
        thumbUrl = await _uploadToStorage(xfile: x, folder: 'product_thumbs');
        if (mounted) setState(() => _uploadingThumb = false);
      }

      // doc id
      final existingId = (widget.initial?['docId'] ?? widget.initial?['id'])?.toString();
      final docRef = (existingId != null && existingId.isNotEmpty)
          ? _db.collection('products').doc(existingId)
          : _db.collection('products').doc();

      final product = <String, dynamic>{
        'id': docRef.id,
        'name': name,
        // النص اللي تحت الكرت من فايربيس (تغيره وقت ما تبي)
        'descAr': _descCtrl.text.trim(),

        // ربط الأقسام
        'mainCategoryId': mainCategoryId,
        'subCategoryId': subCategoryId,

        'store': store,
        'unit': unit,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'discountType': discountType,
        'discount': double.tryParse(_discountCtrl.text.trim()) ?? 0.0,
        'maxQty': int.tryParse(_maxQtyCtrl.text.trim()) ?? 10,
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'active': active,

        // صور (روابط) - ضروري للمستخدمين مش admin فقط
        if (mainImageUrl != null) 'imageUrl': mainImageUrl,
        if (thumbUrl != null) 'imageThumbUrl': thumbUrl,

        'tags': _tagsCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (existingId == null || existingId.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(product, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploadingMain = false;
        _uploadingThumb = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ المنتج: $e')),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(isEdit ? 'تعديل منتج' : 'إضافة منتج'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _nameDescForm()),
                  const SizedBox(width: 12),
                  Expanded(child: _imagesForm()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(child: _storeCategoryForm()),
            const SizedBox(height: 12),
            _card(child: _tagsForm()),
            const SizedBox(height: 12),
            _card(child: _priceForm()),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'حفظ التعديل' : 'حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameDescForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'مثال: بيتزا مارجريتا',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        const Text('وصف قصير', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'اكتب وصف المنتج...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _imagesForm() {
    Widget box({required String title, required File? file, required VoidCallback onPick}) {
      return Expanded(
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: file == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 26),
                        const SizedBox(height: 8),
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('اضغط لاختيار صورة', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الصور', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            box(
              title: 'صورة المنتج',
              file: imageMain,
              onPick: () => _pickImage(thumb: false),
            ),
            const SizedBox(width: 12),
            box(
              title: 'صورة مصغرة',
              file: imageThumb,
              onPick: () => _pickImage(thumb: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _storeCategoryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المتجر & الأقسام', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: store,
                items: stores
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => store = v),
                decoration: InputDecoration(
                  labelText: 'Store',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: mainCategoryId,
                items: _mainCats
                    .map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text((c['nameAr'] ?? '').toString()),
                        ))
                    .toList(),
                onChanged: (v) async {
                  setState(() {
                    mainCategoryId = v;
                    subCategoryId = null; // يتحدث بعد ما نجيب subs
                  });
                  await _loadSubCatsForMain(v);
                },
                decoration: InputDecoration(
                  labelText: 'القسم *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: subCategoryId,
                items: _subCats
                    .map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text((c['nameAr'] ?? '').toString()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => subCategoryId = v),
                decoration: InputDecoration(
                  labelText: 'قسم فرعي',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: unit,
                items: const [
                  DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                  DropdownMenuItem(value: 'Piece', child: Text('Piece')),
                  DropdownMenuItem(value: 'Liter', child: Text('Liter')),
                ],
                onChanged: (v) => setState(() => unit = v ?? 'Kg'),
                decoration: InputDecoration(
                  labelText: 'الوحدة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: active,
          onChanged: (v) => setState(() => active = v),
          title: const Text('المنتج مفعل'),
        ),
      ],
    );
  }

  Widget _tagsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _tagsCtrl,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'مثال: spicy, cheese, hot',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _priceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('السعر والمخزون', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'السعر *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: discountType,
                items: const [
                  DropdownMenuItem(value: 'Percent (%)', child: Text('Percent (%)')),
                  DropdownMenuItem(value: 'Fixed', child: Text('Fixed')),
                ],
                onChanged: (v) => setState(() => discountType = v ?? 'Percent (%)'),
                decoration: InputDecoration(
                  labelText: 'نوع الخصم',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _discountCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'الخصم',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _maxQtyCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'الحد الأقصى للشراء',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'المخزون',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: child,
    );
  }
}
