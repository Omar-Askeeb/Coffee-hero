// lib/services/onesignal_sender.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OneSignalSender {
  // ✅ من OneSignal Dashboard -> Settings -> Keys & IDs
  // ملاحظة: الأفضل ما تحطهمش هنا (أمانياً) لكن خليتهم زي ما طلبت.
  static const String appId = "ONESIGNAL_APP_ID";
  static const String restApiKey = "ONESIGNAL_REST_API_KEY";

  static const String _endpoint = "https://onesignal.com/api/v1/notifications";

  static Future<void> sendToCustomer({
    required String customerExternalId, // مثال: رقم الهاتف
    required String title,
    required String body,
    Map<String, dynamic>? data, // ✅ FIX: خليها dynamic
  }) async {
    final cid = customerExternalId.trim();
    if (cid.isEmpty) return;

    final uri = Uri.parse(_endpoint);

    final payload = <String, dynamic>{
      "app_id": appId,

      // ✅ مهم مع External User IDs
      "include_external_user_ids": [cid],
      "channel_for_external_user_ids": "push",

      // ✅ محتوى الإشعار
      "headings": {"ar": title, "en": title},
      "contents": {"ar": body, "en": body},

      // ✅ بيانات إضافية (اختياري)
      if (data != null) "data": data,

      // ✅ Android/iOS additional (اختياري لكن مفيد)
      "android_channel_id": null, // تقدر تحدد Channel ID لو عندك
    };

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Basic $restApiKey",
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("OneSignal send failed: ${res.statusCode} ${res.body}");
    }
  }
}
