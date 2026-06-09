import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  plugin.initialize(settings: settings).then((_) {
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
    plugin.show(id: id, title: title, body: body, notificationDetails: details);
  });
}

/// Broadcast topic categories the app subscribes to.
enum NotificationTopic {
  broadcast('broadcast'),
  updates('updates'),
  botAlerts('bot_alerts'),
  billing('billing');

  const NotificationTopic(this.topicName);
  final String topicName;
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

  /// Per-topic enabled state, persisted via SharedPreferences.
  /// Defaults to `true` for all topics.
  final Map<NotificationTopic, bool> _topicEnabled = {
    for (final topic in NotificationTopic.values) topic: true,
  };
  static const String _prefPrefix = 'notif_topic_';

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

      // Load per-topic notification preferences
      await _loadTopicPreferences();

      // Register background handler for data-only messages
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

      _fcmToken = await _messaging.getToken();
      debugPrint('[NotificationService] FCM token: $_fcmToken');

      final topicsToSubscribe = topics.isEmpty
          ? NotificationTopic.values
          : topics;
      for (final topic in topicsToSubscribe) {
        if (!_topicEnabled[topic]!) {
          debugPrint('[NotificationService] Skipping disabled topic: $topic');
          continue;
        }
        final fullTopic = '$_topicPrefix${topic.topicName}';
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
    final fullTopic = '$_topicPrefix${topic.topicName}';
    await _messaging.subscribeToTopic(fullTopic);
  }

  Future<void> unsubscribeFromTopic(NotificationTopic topic) async {
    if (!_initialized) return;
    final fullTopic = '$_topicPrefix${topic.topicName}';
    await _messaging.unsubscribeFromTopic(fullTopic);
  }

  String? get fcmToken => _fcmToken;
  String get topicPrefix => _topicPrefix;

  /// Returns whether notifications for the given [topic] are enabled.
  bool isTopicEnabled(NotificationTopic topic) =>
      _topicEnabled[topic] ?? true;

  /// Enables or disables notifications for the given [topic].
  ///
  /// Persists the choice and subscribes/unsubscribes from the FCM topic
  /// immediately if the service has already been initialized.
  Future<void> setTopicEnabled(NotificationTopic topic, bool enabled) async {
    _topicEnabled[topic] = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix${topic.topicName}', enabled);

    if (!_initialized) return;

    if (enabled) {
      await subscribeToTopic(topic);
    } else {
      await unsubscribeFromTopic(topic);
    }
  }

  // ──────────────────────────────────────────────
  // Private — data-only message handling
  // ──────────────────────────────────────────────

  /// Loads per-topic enabled state from SharedPreferences.
  ///
  /// Called once during [initialize]. Missing entries default to `true`.
  Future<void> _loadTopicPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final topic in NotificationTopic.values) {
      final key = '$_prefPrefix${topic.topicName}';
      if (prefs.containsKey(key)) {
        _topicEnabled[topic] = prefs.getBool(key) ?? true;
      }
    }
    debugPrint(
      '[NotificationService] Topic preferences: '
      '${_topicEnabled.entries.map((e) => '${e.key.topicName}=${e.value}').join(', ')}',
    );
  }

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
      settings: initSettings,
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

    await _localNotifications.show(id: id, title: title, body: body, notificationDetails: details, payload: payload);
  }
}
