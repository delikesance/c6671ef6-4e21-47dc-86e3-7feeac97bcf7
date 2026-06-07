import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — MUST be a top-level function.
///
/// FCM delivers data-only messages here when the app is in background/terminated.
/// We show a local notification so the app controls the display.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Received data-only message');
  _showLocalNotificationSync(
    id: message.hashCode,
    title: message.data['title'] ?? 'Bot Creator',
    body: message.data['body'] ?? '',
  );
}

/// Synchronous local notification display for background handler.
void _showLocalNotificationSync({
  required int id,
  required String title,
  required String body,
}) {
  // In background, flutter_local_notifications may not be initialized
  // the same way. We use a minimal setup.
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  const settings = InitializationSettings(android: android, iOS: ios);
  plugin.initialize(settings).then((_) {
    const androidDetails = AndroidNotificationDetails(
      'bot_creator_general',
      'Bot Creator',
      channelDescription: 'General notifications from Bot Creator',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    plugin.show(id, title, body, details);
  });
}

/// Broadcast topic categories the app subscribes to.
enum NotificationTopic {
  broadcast,
  updates,
  botAlerts,
  billing,
}

/// Central service for FCM push notifications via data-only topic broadcast.
///
/// The Manager sends **data-only** FCM messages (no `notification` block).
/// The app receives the data payload and displays its own local notification,
/// giving full control over appearance and behavior.
///
/// Topics are environment-prefixed: `prod-broadcast`, `staging-broadcast`, etc.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  String _topicPrefix = 'prod-';

  void Function(Map<String, dynamic> data)? onNotificationTap;

  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return false;
      default:
        return false;
    }
  }

  /// - dev.bot-creator.fr, localhost → "staging-"
  /// - api.bot-creator.fr → "prod-"
  static String detectTopicPrefix(String managerBaseUrl) {
    final lower = managerBaseUrl.toLowerCase();
    if (lower.contains('dev.') ||
        lower.contains('staging') ||
        lower.contains('preprod') ||
        lower.contains('localhost') ||
        lower.contains('127.0.0.1')) {
      return 'staging-';
    }
    if (lower.contains('api.')) {
      return 'prod-';
    }
    return 'prod-';
  }

  Future<void> initialize({
    String managerBaseUrl = '',
    List<NotificationTopic> topics = const [],
  }) async {
    if (_initialized) return;
    if (!isPlatformSupported) return;

    if (managerBaseUrl.isNotEmpty) {
      _topicPrefix = detectTopicPrefix(managerBaseUrl);
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
        carPlay: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('[NotificationService] Notifications not authorized.');
        return;
      }

      await _configureLocalNotifications();

      // Register background handler for data-only messages
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

      _fcmToken = await _messaging.getToken();
      debugPrint('[NotificationService] FCM token: $_fcmToken');

      final topicsToSubscribe = topics.isEmpty
          ? NotificationTopic.values
          : topics;
      for (final topic in topicsToSubscribe) {
        final fullTopic = '$_topicPrefix${topic.name}';
        await _messaging.subscribeToTopic(fullTopic);
        debugPrint('[NotificationService] Subscribed: $fullTopic');
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[NotificationService] Token refreshed: $newToken');
      });

      // Foreground: data-only → show local notification
      FirebaseMessaging.onMessage.listen(_handleDataMessage);

      // Background tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Terminated launch
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('[NotificationService] Initialized (prefix=$_topicPrefix, data-only).');
    } catch (error, stack) {
      debugPrint('[NotificationService] Init failed: $error\n$stack');
    }
  }

  Future<void> subscribeToTopic(NotificationTopic topic) async {
    if (!_initialized) return;
    final fullTopic = '$_topicPrefix${topic.name}';
    await _messaging.subscribeToTopic(fullTopic);
  }

  Future<void> unsubscribeFromTopic(NotificationTopic topic) async {
    if (!_initialized) return;
    final fullTopic = '$_topicPrefix${topic.name}';
    await _messaging.unsubscribeFromTopic(fullTopic);
  }

  String? get fcmToken => _fcmToken;
  String get topicPrefix => _topicPrefix;

  // ──────────────────────────────────────────────
  // Private — data-only message handling
  // ──────────────────────────────────────────────

  /// Handles data-only FCM messages (foreground).
  ///
  /// Extracts title/body from `message.data` and shows a local notification.
  void _handleDataMessage(RemoteMessage message) {
    final data = message.data;
    final title = data['title'] ?? 'Bot Creator';
    final body = data['body'] ?? '';

    debugPrint('[NotificationService] Data message: title="$title" body="$body"');

    _showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[NotificationService] Tap: data=${message.data}');
    onNotificationTap?.call(Map<String, dynamic>.from(message.data));
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bot_creator_general',
      'Bot Creator',
      channelDescription: 'General notifications from Bot Creator',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }
}
