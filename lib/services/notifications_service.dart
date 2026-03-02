// lib/services/notifications_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../auth/auth_service.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _dashboardMode = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocal();
    await _requestPermissions();

    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    FirebaseMessaging.onMessage.listen((m) async {
      await _showLocal(m);
    });

    await syncIdentity();
  }

  Future<void> enableDashboardMode(bool v) async {
    _dashboardMode = v;
    if (!_initialized) return;

    if (v) {
      await _safeSubscribeDashboard();
    }
  }

  Future<void> syncIdentity() async {
    if (!_initialized) return;

    final token = await _fcm.getToken();
    if (token == null || token.isEmpty) return;

    final user = AuthService.instance.user; // ✅ مطابق لمشروعك
    if (user != null && user.phone.isNotEmpty) {
      await _saveToken(phone: user.phone, token: token);
    }

    if (_dashboardMode) {
      await _safeSubscribeDashboard();
    }
  }

  Future<void> _saveToken({required String phone, required String token}) async {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) return;

    await _db.collection('deviceTokens').doc(normalized).set({
      'token': token,
      'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _normalizePhone(String p) {
    // خليك بسيط: خذ الأرقام فقط
    final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
    return digits;
  }

  Future<void> _safeSubscribeDashboard() async {
    try {
      await _fcm.subscribeToTopic('dashboard_orders');
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(settings);

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'orders_channel',
        'Orders',
        description: 'Order updates',
        importance: Importance.max,
      );

      final androidPlugin =
          _local.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocal(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;

    const android = AndroidNotificationDetails(
      'orders_channel',
      'Orders',
      channelDescription: 'Order updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      n.title ?? 'تحديث',
      n.body ?? '',
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  // مهم: ما نكتبوش هنا كود يعتمد على UI
}
