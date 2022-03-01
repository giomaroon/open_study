import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:gio_app/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationServices {

  final notifications = FlutterLocalNotificationsPlugin();

  final BehaviorSubject<String?> streamNotification =
    BehaviorSubject<String?>();
  final BehaviorSubject<ReceivedNotification> streamNotificationIOS =
    BehaviorSubject<ReceivedNotification>();

  //String? selectedNotificationPayload;

  //..........Initialize Notifiication Settings............

  Future<void> initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: (
            int id,
            String? title,
            String? body,
            String? payload,
            ) async {
          streamNotificationIOS.add(
            ReceivedNotification(
              id: id,
              title: title,
              body: body,
              payload: payload,
            ),
          );
        });
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);
    // tz.initializeTimeZones();
    // final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    // tz.setLocalLocation(tz.getLocation(timeZoneName!));
    await notifications.initialize(initializationSettings,
        onSelectNotification: (String? _payload) async {
          if (_payload != null) {
            //print('onSelectNoficiation');
            //print('notification payload: $_payload');
          }
          payload = _payload??'';
          streamNotification.add(_payload);
        });
  }

  void requestIOSPermissions() {
    notifications
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  //.....Get payload when notification launches app....
  Future<String?> getLaunchAppPayload() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await notifications.getNotificationAppLaunchDetails();
    return notificationAppLaunchDetails?.payload;
  }

  void onClickNotification(BuildContext context) {
    streamNotification.stream.listen((String? payload) async {
      //print('onClickNotification');
      //print(payload);
      await Navigator.pushNamed(context, payload?.split(' ')[1]?? '/');
      // await Navigator.push(context, MaterialPageRoute(builder:
      //     (context) => CoursesListPage()));
      // await Navigator.pushNamed(context, payload!.substring(0,11));
    });
  }

  void onClickNotificationIOS(BuildContext context) {
    streamNotificationIOS.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title!)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body!)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.pushNamed(context, receivedNotification.payload?.split(' ')[1]?? '/');
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails('your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          styleInformation: BigTextStyleInformation('')),
      iOS: IOSNotificationDetails()
  );

  Future<void> showNotification({int id=0,String? title,String? body,String? payload}) async {
    await notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload);
  }

  Future<void> showNotificationScheduled({int id=0,String? title,String? body,
    required DateTime dateTime,String? payload}) async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
    await notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(dateTime,tz.local),
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 12)),
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload
    );
  }

}

class ReceivedNotification {
ReceivedNotification({
  required this.id,
  required this.title,
  required this.body,
  required this.payload,
});
final int id;
final String? title;
final String? body;
final String? payload;
}