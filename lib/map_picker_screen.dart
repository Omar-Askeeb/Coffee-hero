import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  /// 🟡 لون التطبيق
  static const Color orange = Color(0xFFF5A623);

  GoogleMapController? _controller;

  /// 📍 موقع افتراضي
  LatLng _currentLatLng = const LatLng(32.8872, 13.1913);

  /// 🏠 العنوان النصي
  String _address = "";

  /// 🔑 مفتاح الخرائط
  static const String _apiKey = "AIzaSyBoQ4mEbaJ-0a_dWWiImIMaFVD345OBpMM";

  /// جلب العنوان من الإحداثيات
  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=$_apiKey";

      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["results"] != null && data["results"].isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _address = data["results"][0]["formatted_address"];
        });
      }
    } catch (e) {
      debugPrint("GEOCODE ERROR: $e");
    }
  }

  void _onCameraMove(CameraPosition pos) {
    _currentLatLng = pos.target;
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_currentLatLng);
  }

  /// 💾 حفظ العنوان في Firebase (مع حماية من الأخطاء)
  Future<bool> _saveLocation(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ USER NULL");
        return false;
      }

      await FirebaseFirestore.instance
          .collection("customers")
          .doc(user.uid)
          .collection("locations")
          .add({
        "name": name,
        "address": _address,
        "lat": _currentLatLng.latitude,
        "lng": _currentLatLng.longitude,
        "createdAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ LOCATION SAVED");
      return true;
    } catch (e) {
      debugPrint("🔥 FIREBASE ERROR: $e");
      return false;
    }
  }

  /// نافذة اسم العنوان (معدلة لتفادي الصفحة الحمراء مع الكيبورد)
  void _openAddressSheet() {
    final parentContext = context; // ✅ سياق الصفحة (الخريطة)
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// الشَرطة الرمادية
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "بيانات إضافية للموقع",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(sheetContext).unfocus(),
                decoration: InputDecoration(
                  hintText: "حدد اسم العنوان",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    // ✅ 1) سكّر الكيبورد تلقائياً قبل أي Pop
                    FocusScope.of(sheetContext).unfocus();

                    // ✅ 2) احفظ في فايربيس
                    final ok = await _saveLocation(name);
                    if (!mounted) return;

                    if (!ok) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text("فشل حفظ الموقع، تأكد من تسجيل الدخول والإنترنت"),
                        ),
                      );
                      return;
                    }

                    // ✅ 3) اقفل الـ BottomSheet بسياقه الصحيح
                    Navigator.of(sheetContext).pop();

                    // ✅ 4) بعد ما يقفل الشيت فعلاً، ارجع من صفحة الخريطة (بدون صفحة حمراء)
                    await Future.delayed(const Duration(milliseconds: 120));
                    if (!mounted) return;

                    Navigator.of(parentContext).pop(true);
                  },
                  child: const Text(
                    "استمرار",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// الخريطة
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLatLng,
              zoom: 14,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (c) => _controller = c,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          /// أيقونة الموقع
          const Center(
            child: Icon(Icons.location_pin, size: 55, color: orange),
          ),

          /// ويدجت تأكيد العنوان
          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.location_on, color: orange),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "أكد عنوانك",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "سيتم توصيل طلبك في هذا الموقع",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          /// زر الرجوع
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          /// البطاقة السفلية
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openAddressSheet,
                      child: const Text(
                        "تأكيد",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
