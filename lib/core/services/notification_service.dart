import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'health_track_channel';
  static const _channelName = 'HealthTrack Reminders';
  static const _goalReminderId = 1;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    await _requestPermission();
    await _initLocal();
    _listenForegroundMessages();
  }

  Future<String?> getToken() => _fcm.getToken();

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // Channel WAJIB dibuat eksplisit. Notifikasi terjadwal yang fire dari
    // background receiver tidak membuat channel secara implisit — tanpa channel,
    // Android 8+ membuang notifikasi diam-diam.
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      ),
    );
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'HealthTrack',
          body: notification.body ?? '',
        );
      }
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Schedules a daily reminder at [hour]:[minute] (device local time).
  /// Returns false if the user denies exact alarm permission.
  ///
  /// TESTING: ganti ke periodicallyShow(everyMinute) di bawah.
  /// PRODUKSI: pakai zonedSchedule + matchDateTimeComponents.time.
  Future<bool> scheduleGoalReminder(int hour, int minute) async {
    await cancelGoalReminder();

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestExactAlarmsPermission();
      if (granted == false) return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _local.zonedSchedule(
      _goalReminderId,
      'Target Harian',
      'Jangan lupa update progres target harianmu! 🎯',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return true;
  }

  Future<void> cancelGoalReminder() async {
    await _local.cancel(_goalReminderId);
  }
}
