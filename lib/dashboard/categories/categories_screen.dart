import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_add_screen.dart';
import 'services/firestore_categories.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const Color orange = Color(0xFFF5A623);

  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _openAdd(List<Map<String, dynamic>> mainCats) async {
    final created = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryAddScreen(mainCategories: mainCats),
      ),
    );

    if (created == null) return;

    try {
      await FirestoreCategoriesService.instance.upsertCategory(created);
      _toast('تم حفظ القسم ✅');
    } catch (e) {
      _toast('فشل الحفظ: $e');
    }
  }

  Future<void> _openEdit(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> mainCats,
  ) async {
    final updated = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryAddScreen(
          mainCategories: mainCats,
          initial: Map<String, dynamic>.from(item),
        ),
      ),
    );

    if (updated == null) return;

    try {
      await FirestoreCategoriesService.instance.upsertCategory(updated);
      _toast('تم تحديث القسم ✅');
    } catch (e) {
      _toast('فشل التحديث: $e');
    }
  }

  String _parentName(String? parentId, List<Map<String, dynamic>> all) {
    if (parentId == null || parentId.isEmpty) return '—';
    final p = all.where((x) => x['id'].toString() == parentId).toList();
    if (p.isEmpty) return '—';
    return (p.first['nameAr'] ?? '—').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreCategoriesService.instance.watchAll(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'صار خطأ في تحميل الأقسام:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            // تحويل docs -> List<Map>
            final all = docs.map((d) {
              final data = d.data();
              final orderRaw = data['order'];
              final order = (orderRaw is num)
                  ? orderRaw.toInt()
                  : int.tryParse((orderRaw ?? '').toString()) ?? 0;

              return <String, dynamic>{
                'id': (data['id'] ?? d.id).toString(),
                'type': (data['type'] ?? 'main').toString(),
                'nameAr': (data['nameAr'] ?? '').toString(),
                'nameEn': (data['nameEn'] ?? '').toString(),
                'order': order,
                'active': data['active'] == true,
                'parentId': (data['parentId'] ?? '').toString(),
                'iconPath': (data['iconPath'] ?? '').toString(),
                'iconBase64': (data['iconBase64'] ?? '').toString(),
              };
            }).toList();

            // ترتيب محلي
            all.sort((a, b) {
              final oa = (a['order'] as int);
              final ob = (b['order'] as int);
              return oa.compareTo(ob);
            });

            final mainCats = all.where((c) => c['type'] == 'main').toList();

            // filtering
            final q = _search.text.trim().toLowerCase();
            final rows = q.isEmpty
                ? all
                : all.where((c) {
                    final a = c['nameAr'].toString().toLowerCase();
                    final e = c['nameEn'].toString().toLowerCase();
                    return a.contains(q) || e.contains(q);
                  }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      const Text(
                        'الأقسام',
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
                            hintText: 'بحث: اسم القسم...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _miniBtn(Icons.add, 'إضافة', onTap: () => _openAdd(mainCats)),
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
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                        ],
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
                                dataRowMaxHeight: 80,
                                columns: const [
                                  DataColumn(label: Text('SL')),
                                  DataColumn(label: Text('الأيقونة')),
                                  DataColumn(label: Text('الاسم')),
                                  DataColumn(label: Text('النوع')),
                                  DataColumn(label: Text('يتبع')),
                                  DataColumn(label: Text('الترتيب')),
                                  DataColumn(label: Text('نشط')),
                                  DataColumn(label: Text('إجراءات')),
                                ],
                                rows: List.generate(rows.length, (i) {
                                  final c = rows[i];
                                  final iconPath = (c['iconPath'] ?? '').toString();
                                  final iconBase64 = (c['iconBase64'] ?? '').toString();
                                  final isMain = c['type'] == 'main';

                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${i + 1}')),
                                      DataCell(
                                        SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(999),
                                            child: (iconBase64.isNotEmpty)
                                                ? Image.memory(base64Decode(iconBase64), fit: BoxFit.cover)
                                                : (iconPath.isNotEmpty && File(iconPath).existsSync())
                                                    ? Image.file(File(iconPath), fit: BoxFit.cover)
                                                    : Container(
                                                        color: Colors.grey.shade200,
                                                        child: const Icon(Icons.image, color: Colors.black38),
                                                      ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(
                                        c['nameAr'],
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      )),
                                      DataCell(Text(isMain ? 'رئيسي' : 'فرعي')),
                                      DataCell(Text(
                                        isMain ? '—' : _parentName(c['parentId']?.toString(), all),
                                      )),
                                      DataCell(Text('${c['order']}')),
                                      DataCell(
                                        Switch(
                                          value: c['active'] == true,
                                          activeColor: orange,
                                          onChanged: (v) async {
                                            final updated = Map<String, dynamic>.from(c);
                                            updated['active'] = v;
                                            try {
                                              await FirestoreCategoriesService.instance.upsertCategory(updated);
                                            } catch (e) {
                                              _toast('فشل تحديث الحالة: $e');
                                            }
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            _actionIcon(
                                              icon: Icons.edit,
                                              color: Colors.orange,
                                              onTap: () => _openEdit(c, mainCats),
                                            ),
                                            const SizedBox(width: 8),
                                            _actionIcon(
                                              icon: Icons.delete_outline,
                                              color: Colors.red,
                                              onTap: () async {
                                                try {
                                                  await FirestoreCategoriesService.instance.deleteById(c['id'].toString());
                                                  _toast('تم حذف القسم ✅');
                                                } catch (e) {
                                                  _toast('فشل الحذف: $e');
                                                }
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
        ),
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

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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