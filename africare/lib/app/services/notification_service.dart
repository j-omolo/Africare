import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:get/get.dart';
import '../routes/app_routes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details);
      },
    );
  }

  Future<void> _handleNotificationTap(
      NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null) {
      final payloadParts = notificationResponse.payload!.split(':');
      if (payloadParts.length == 2) {
        final type = payloadParts[0];
        final id = payloadParts[1];

        switch (type) {
          case 'appointment':
            Get.toNamed(AppRoutes.appointments);
            break;
          case 'chat':
            // Navigate to specific chat
            break;
          case 'review':
            // Navigate to review screen
            break;
        }
      }
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationDetails? details,
  }) async {
    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details ??
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'africare_channel',
              'Africare Notifications',
              channelDescription:
                  'Notifications for appointments, chats, and updates',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      DateTime.now().millisecond,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'africare_scheduled',
          'Africare Scheduled Notifications',
          channelDescription: 'Scheduled notifications for appointments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Specific notification methods
  Future<void> showAppointmentReminder(
      {required String doctorName, required DateTime appointmentTime}) async {
    final scheduledTime = appointmentTime.subtract(const Duration(hours: 1));
    await scheduleNotification(
      title: 'Upcoming Appointment Reminder',
      body: 'Your appointment with Dr. $doctorName is in 1 hour',
      scheduledDate: scheduledTime,
      payload: 'appointment:reminder',
    );
  }

  Future<void> showNewMessageNotification(
      {required String senderName, required String message}) async {
    await showNotification(
      title: 'New Message from Dr. $senderName',
      body: message,
      payload: 'chat:$senderName',
    );
  }

  Future<void> showReviewRequest({required String doctorName}) async {
    await showNotification(
      title: 'How was your appointment?',
      body: 'Please take a moment to review Dr. $doctorName',
      payload: 'review:request',
    );
  }

  Future<void> showAppointmentConfirmation(
      {required String doctorName, required DateTime appointmentTime}) async {
    await showNotification(
      title: 'Appointment Confirmed',
      body:
          'Your appointment with Dr. $doctorName on ${_formatDate(appointmentTime)} has been confirmed',
      payload: 'appointment:confirmation',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute}';
  }
}
