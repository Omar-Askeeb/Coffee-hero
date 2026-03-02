// lib/dashboard/products_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'product_add_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const Color orange = Color(0xFFF5A623);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _search = TextEditingController();

  // آخر rows نحتاجها للتصدير PDF
  List<Map<String, dynamic>> _lastRows = const [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => const ProductAddScreen()),
    );
  }

  Future<void> _openEdit(Map<String, dynamic> p) async {
    await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductAddScreen(initial: Map<String, dynamic>.from(p)),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchProducts() {
    // نعرض كل شيء في الداشبورد (حتى الغير مفعل)
    return _db.collection('products').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchCategories() {
    return _db.collection('categories').snapshots();
  }

  // ✅ PDF مضبوط + عربي + رسائل نجاح/فشل
  Future<void> _exportPdf() async {
    try {
      pw.Font? ttf;
      try {
        final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        ttf = pw.Font.ttf(fontData);
      } catch (_) {
        ttf = null;
      }

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'قائمة المنتجات',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
      pw.Text(
                    'عدد المنتجات: ${_lastRows.length}',
                    style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 14),
                ],
              ),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table.fromTextArray(
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 11),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.centerRight,
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.7),
                  1: pw.FlexColumnWidth(2.2),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.0),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(1.0),
                  6: pw.FlexColumnWidth(0.8),
                },
                headers: const ['#', 'الاسم', 'القسم', 'السعر', 'الخصم', 'المخزون', 'نشط'],
                data: List.generate(_lastRows.length, (i) {
                  final p = _lastRows[i];
                  final name = (p['name'] ?? '').toString();
                  final cat = (p['subCategoryName'] ?? p['subCategoryId'] ?? '').toString();
                  final price = (p['price'] ?? 0).toString();
                  final discType = (p['discountType'] ?? '').toString();
                  final disc = (p['discount'] ?? 0).toString();
                  final stock = (p['stock'] ?? 0).toString();
                  final active = (p['active'] == true) ? 'نعم' : 'لا';

                  return [
                    '${i + 1}',
                    name,
                    cat,
                    price,
                    '$discType $disc',
                    stock,
                    active,
                  ];
                }),
              ),
            ),
          ],
        ),
      );

      final bytes = await doc.save();

      // ✅ يفتح نافذة حفظ/طباعة PDF
      await Printing.layoutPdf(onLayout: (_) async => bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء PDF بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إنشاء PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _watchCategories(),
        builder: (context, catSnap) {
          final catDocs = catSnap.data?.docs ?? const [];
          // id -> nameAr
          final catName = <String, String>{
            for (final d in catDocs)
              (d.data()['id'] ?? d.id).toString():
                  (d.data()['nameAr'] ?? d.data()['label'] ?? d.data()['name'] ?? '').toString(),
          };

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _watchProducts(),
            builder: (context, pSnap) {
              if (pSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'صار خطأ في تحميل المنتجات:\n${pSnap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              }

              if (!pSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // docs -> rows
              final docs = pSnap.data!.docs;
              final all = docs.map((d) {
                final data = d.data();
                final mainId = (data['mainCategoryId'] ?? data['categoryId'] ?? '').toString();
                final subId = (data['subCategoryId'] ?? '').toString();
                return <String, dynamic>{
                  'docId': d.id,
                  'id': (data['id'] ?? d.id).toString(),
                  'name': (data['name'] ?? data['title'] ?? '').toString(),
                  'descAr': (data['descAr'] ?? data['desc'] ?? data['description'] ?? '').toString(),
                  'mainCategoryId': mainId,
                  'subCategoryId': subId,
                  'mainCategoryName': (catName[mainId] ?? '').toString(),
                  'subCategoryName': (catName[subId] ?? '').toString(),
                  'price': (data['price'] is num)
                      ? (data['price'] as num).toDouble()
                      : double.tryParse((data['price'] ?? 0).toString()) ?? 0.0,
                  'discountType': (data['discountType'] ?? 'Percent (%)').toString(),
                  'discount': (data['discount'] is num)
                      ? (data['discount'] as num).toDouble()
                      : double.tryParse((data['discount'] ?? 0).toString()) ?? 0.0,
                  'stock': (data['stock'] is num)
                      ? (data['stock'] as num).toInt()
                      : int.tryParse((data['stock'] ?? 0).toString()) ?? 0,
                  'active': data['active'] == true,
                  'imageUrl': (data['imageUrl'] ?? data['imageMainUrl'] ?? '').toString(),
                  'imageThumbUrl': (data['imageThumbUrl'] ?? data['imageThumb'] ?? '').toString(),
                };
              }).toList(growable: false);

              final q = _search.text.trim().toLowerCase();
              final rows = q.isEmpty
                  ? all
                  : all.where((p) {
                      final n = (p['name'] ?? '').toString().toLowerCase();
                      final subId = (p['subCategoryId'] ?? '').toString();
                      final mainId = (p['mainCategoryId'] ?? '').toString();
                      final subName = (catName[subId] ?? '').toLowerCase();
                      final mainName = (catName[mainId] ?? '').toLowerCase();
                      return n.contains(q) || subName.contains(q) || mainName.contains(q);
                    }).toList(growable: false);

              // حفظ آخر rows للتصدير
              _lastRows = rows;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        const Text(
                          'المنتجات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(rows.length.toString()),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'بحث: اسم المنتج / القسم...',
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _miniBtn(Icons.add, 'إضافة', onTap: _openAdd),
                        const SizedBox(width: 8),
                        _miniBtn(Icons.picture_as_pdf, 'PDF', onTap: _exportPdf),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1200),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowHeight: 56,
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 92,
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('SL')),
                                    DataColumn(label: Text('الصورة')),
                                    DataColumn(label: Text('الاسم')),
                                    DataColumn(label: Text('القسم الفرعي')),
                                    DataColumn(label: Text('السعر')),
                                    DataColumn(label: Text('نوع الخصم')),
                                    DataColumn(label: Text('الخصم')),
                                    DataColumn(label: Text('المخزون')),
                                    DataColumn(label: Text('نشط')),
                                    DataColumn(label: Text('إجراءات')),
                                  ],
                                  rows: List.generate(rows.length, (i) {
                                    final p = rows[i];
                                    final thumb = (p['imageThumbUrl'] ?? '').toString();
                                    final main = (p['imageUrl'] ?? '').toString();
                                    final imgUrl = thumb.isNotEmpty ? thumb : main;

                                    final subId = (p['subCategoryId'] ?? '').toString();
                                    final subName = (catName[subId] ?? subId).toString();

                                    return DataRow(
                                      cells: [
                                        DataCell(Text('${i + 1}')),
                                        DataCell(
                                          SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: imgUrl.isNotEmpty
                                                  ? Image.network(
                                                      imgUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        color: Colors.grey.shade200,
                                                        child: const Icon(Icons.image, color: Colors.black38),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.image, color: Colors.black38),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                        DataCell(Text(subName)),
                                        DataCell(Text('د.ل ${(p['price'] as double).toStringAsFixed(0)}')),
                                        DataCell(Text('${p['discountType']}')),
                                        DataCell(Text('${p['discount']}')),
                                        DataCell(Text('${p['stock']}')),
                                        DataCell(
                                          Switch(
                                            value: p['active'] == true,
                                            activeColor: orange,
                                            onChanged: (v) async {
                                              final docId = (p['docId'] ?? '').toString();
                                              if (docId.isEmpty) return;
                                              await _db.collection('products').doc(docId).set(
                                                {'active': v, 'updatedAt': FieldValue.serverTimestamp()},
                                                SetOptions(merge: true),
                                              );
                                            },
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              _actionIcon(
                                                icon: Icons.edit,
                                                color: Colors.orange,
                                                onTap: () => _openEdit(p),
                                              ),
                                              const SizedBox(width: 8),
                                              _actionIcon(
                                                icon: Icons.delete_outline,
                                                color: Colors.red,
                                                onTap: () async {
                                                  final docId = (p['docId'] ?? '').toString();
                                                  if (docId.isEmpty) return;
                                                  await _db.collection('products').doc(docId).delete();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _miniBtn(IconData icon, String text, {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.6)),
          color: color.withOpacity(0.08),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
