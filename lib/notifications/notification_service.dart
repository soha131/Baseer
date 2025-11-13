import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 🔹 إعدادات مشروع Firebase
const _serviceAccountPath = 'assets/firebase-service-account.json';
const _firebaseProjectId = 'baseer-98f34';


@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  final payload = response.payload;
  if (payload != null) {
    await NotificationService._saveNotificationToFirestore(payload);
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();


  // ------------------------------
  // 🚀 INITIALIZATION
  // ------------------------------


  static Future<void> initialize() async {
    await _initLocalNotifications();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // foreground أو المستخدم ضغط على الإشعار
        final payload = response.payload;
        if (payload != null) {
          await _saveNotificationToFirestore(payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestHeavyPermissions();
      await _initFCM();
    });

  }

  // ------------------------------
  // 🔒 Permissions ثقيلة (بعد init)
  // ------------------------------
  static Future<void> _requestHeavyPermissions() async {
    try {
      // اطلب كل الصلاحيات مرة واحدة
      final statuses = await [
        Permission.notification,
        Permission.scheduleExactAlarm,
        Permission.ignoreBatteryOptimizations,
      ].request();

      debugPrint("📋 Permission statuses:");
      statuses.forEach((perm, status) {
        debugPrint("  $perm: $status");
      });

    } catch (e) {
      debugPrint("Error in heavy permissions: $e");
    }
  }

  // ------------------------------
  // 🔔 LOCAL NOTIFICATIONS
  // ------------------------------
  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    final tzName = currentTimeZone.toString().split('(')[1].split(',').first.trim();
    tz.setLocalLocation(tz.getLocation(tzName));


    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      'scheduled_channel',
      'Medicine Reminders V5',
      description: 'Notifications for medicine times',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important instant notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(scheduledChannel);
      await androidPlugin.createNotificationChannel(highImportanceChannel);
    }
  }

  /*static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      debugPrint("🟢 Starting scheduleNotification()...");
      final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);
      debugPrint("🕒 tzScheduled: $tzScheduled | Now: ${tz.TZDateTime.now(tz.local)}");
      print("Local tz: ${tz.local.name}");

      if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint("⚠️ Scheduled time already passed — showing instantly.");
        await showInstantNotification(title: title, body: body);
        return;
      }
      print("Now: ${DateTime.now()}");
      print("Scheduled for: $scheduledTime");

      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) {
        debugPrint("❌ Android plugin not found!");
      } else {
        final existingChannels = await androidPlugin.getNotificationChannels();
        debugPrint("📡 Existing channels: ${existingChannels!.map((e) => e.id).toList()}");
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Medicine Reminders V5',
            channelDescription: 'Used for important instant notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidAllowWhileIdle: true,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,

      );

      debugPrint("✅ zonedSchedule() completed successfully!");
      print("⏰ Will trigger at: $scheduledTime, now: ${DateTime.now()}");

      debugPrint("✅ Scheduled notification for $tzScheduled with id=$id");
    } catch (e, st) {
      debugPrint("❌ Error scheduling notification: $e");
      debugPrint("🔍 Stacktrace: $st");
    }
  }*/
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,

  }) async {
    final payload = jsonEncode({
      "title": title,
      "body": body,
      "timestamp": scheduledTime.toIso8601String(),
    });
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Medicine Reminders V5',
            channelDescription: 'Used for important instant notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: payload,
      );
      await _saveNotificationToFirestore(payload);
      return;
    }

    // Timer يضمن تشغيل show() في الوقت المحدد
    Timer(difference, () async {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Medicine Reminders V5',
            channelDescription: 'Used for important instant notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: payload,
      );
      await _saveNotificationToFirestore(payload);
    });
  }
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important instant notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
  static Future<void> checkScheduledNotifications() async {
    // 1️⃣ Exact alarms permission
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted) {
      debugPrint("⚠️ Exact Alarm permission NOT granted! Scheduled notifications may not appear.");
    } else {
      debugPrint("✅ Exact Alarm permission granted");
    }

    // 2️⃣ Battery optimization
    final ignoreBattery = await Permission.ignoreBatteryOptimizations.status;
    if (!ignoreBattery.isGranted) {
      debugPrint("⚠️ Battery optimizations may block scheduled notifications.");
    } else {
      debugPrint("✅ Ignoring battery optimizations allowed");
    }

    // 3️⃣ Notification permission
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      debugPrint("⚠️ Notification permission NOT granted! Nothing will appear.");
    } else {
      debugPrint("✅ Notification permission granted");
    }

    // 4️⃣ Check existing channels (just for debugging)
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final channels = await androidPlugin.getNotificationChannels();
      debugPrint("📡 Existing notification channels: ${channels!.map((e) => e.id).toList()}");
    }
  }
  static Future<void> printPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();

    if (pending.isEmpty) {
      debugPrint("📭 No pending notifications");
    } else {
      debugPrint("📋 Pending notifications count: ${pending.length}");
      for (var n in pending) {
        debugPrint("🔹 ID: ${n.id}, Title: ${n.title}, Body: ${n.body}, Payload: ${n.payload}");
      }
    }
  }



  // ------------------------------
  // ☁️ FIREBASE CLOUD MESSAGING
  // ------------------------------
  static Future<void> _saveNotificationToFirestore(String payload) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // جلب بيانات المستخدم من Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      if (userData == null || userData['role'] != 'User') {
        // لو الدور مش 'user'، متحفظش
        debugPrint("⚠️ Notification not saved: user role is not 'user'");
        return;
      }

      final data = jsonDecode(payload);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        "title": data["title"],
        "body": data["body"],
        "createdAt": Timestamp.now(),
        "isRead": false,
        "type": "reminder",
      });

      debugPrint("✅ Notification saved to Firestore for user ${user.uid}");
    } catch (e) {
      debugPrint("❌ Error saving notification to Firestore: $e");
    }
  }

  static Future<void> _initFCM() async {

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("❌ Notifications disabled");
        return;
      }

      await FirebaseMessaging.instance.subscribeToTopic('all_users');

      // حاول نحصل على token مع retry
      String? fcmToken;
      const maxAttempts = 3;
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) break;
        } catch (e) {
          await Future.delayed(Duration(seconds: 2)); // انتظر قبل المحاولة التالية
        }
      }

      if (fcmToken == null) {
        debugPrint('❌ Could not get FCM token after $maxAttempts attempts.');
      } else {
        debugPrint('📱 FCM Token: $fcmToken');
      }

      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? message.data['title'] ?? 'No Title';
        final body = message.notification?.body ?? message.data['body'] ?? 'No Body';
        showInstantNotification(title: title, body: body);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint("✅ User opened app from notification");
      });

    } catch (e) {
      debugPrint('❌ initFCM error: $e');
    }
  }


  // ------------------------------
  // ☁️ SEND FCM
  // ------------------------------

  static Future<void> sendToAllUsers({
    required String title,
    required String body,
  }) async {
    final serviceAccountJson = await rootBundle.loadString(_serviceAccountPath);
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_firebaseProjectId/messages:send');

    final payload = {
      "message": {
        "topic": "all_users",
        "notification": {"title": title, "body": body},
        "data": {"title": title, "body": body},
        "android": {"priority": "high"},
        "apns": {"headers": {"apns-priority": "10"}}
      }
    };

    final response = await client.post(url,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));

    if (response.statusCode == 200) {
      debugPrint('✅ Notification sent to all users!');
    } else {
      debugPrint('❌ FCM send failed: ${response.statusCode}');
    }
  }

  static Future<void> sendToSpecificUser({
    required String title,
    required String body,
    required String fcmToken,
  }) async {

    final serviceAccountJson = await rootBundle.loadString(_serviceAccountPath);
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_firebaseProjectId/messages:send');

    final payload = {
      "message": {
        "token": fcmToken,
        "notification": {"title": title, "body": body},
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "title": title,
          "body": body,
          "type": "new_pharmacist"
        },
        "android": {"priority": "high", "notification": {"channel_id": "high_importance_channel"}},
        "apns": {"headers": {"apns-priority": "10"}, "payload": {"aps": {"sound": "default"}}}
      }
    };

    final response = await client.post(url,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));

    if (response.statusCode == 200) {
      debugPrint('✅ Notification sent to specific user!');
    } else {
      debugPrint('❌ Failed to send notification: ${response.statusCode}');
      debugPrint(response.body);
    }
  }
}
