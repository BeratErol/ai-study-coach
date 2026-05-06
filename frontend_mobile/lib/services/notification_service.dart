import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();

const _androidDetails = AndroidNotificationDetails(
  'pomodoro_channel',
  'Pomodoro',
  channelDescription: 'Pomodoro zamanlayıcı bildirimleri',
  importance: Importance.high,
  priority: Priority.high,
  icon: '@mipmap/ic_launcher',
);

Future<void> initNotifications() async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );
  await _plugin.initialize(settings);
}

Future<void> showWorkDoneNotification(int workMinutes) async {
  await _plugin.show(
    1,
    'Tebrikler! 🎉',
    '$workMinutes dakika tamamlandı. Mola zamanı!',
    const NotificationDetails(
      android: _androidDetails,
      iOS: DarwinNotificationDetails(),
    ),
  );
}

Future<void> showBreakDoneNotification() async {
  await _plugin.show(
    2,
    'Mola bitti! 💪',
    'Çalışmaya devam etme vakti.',
    const NotificationDetails(
      android: _androidDetails,
      iOS: DarwinNotificationDetails(),
    ),
  );
}
