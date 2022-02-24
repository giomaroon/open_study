import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gio_app/Pages/EventsPage.dart';
import 'package:gio_app/Pages/GradesPage.dart';
import 'package:gio_app/Pages/PostsPage.dart';
import 'package:gio_app/Services/NotificationServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'Pages/HomePage.dart';
import 'Pages/LoginPage.dart';
import 'Services/BackgroundServices.dart';


var activeUserId;
var initialRoute;
var payload;

NotificationServices notificationServices = NotificationServices();

void main() async {
  // needed if you intend to initialize notifications in the `main` function
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(
      callbackDispatcher,
      //isInDebugMode: true
  );

  HttpOverrides.global = new MyHttpOverrides();

  // .....Get active user id.........
  var prefs = await SharedPreferences.getInstance();
  activeUserId = prefs.getInt('userId') ?? 0;
  //print(activeUserId);

  //...initialize notification plugin....
  await notificationServices.initializeNotifications();

  //..... check if app is launched by notification and set initialRoute.......
  payload = await notificationServices.getLaunchAppPayload();
  if (activeUserId==0) {
    initialRoute='LoginPage';
  } else if (payload==null) {
    initialRoute='/';
  } else {
    initialRoute = payload.split(' ')[1]?? '/';
    payload='';
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        initialRoute: initialRoute,
        routes: <String, WidgetBuilder>{
          'LoginPage': (_) => LoginPage(),
          '/': (_) => HomePage(),
          '/EventsPage': (_) => EventsPage(),
          '/PostsPage': (_) => PostsPage(payloadDiscussionId: payload.split(' ')[0]),
          '/GradesPage': (_) => GradesPage(payloadCourseId: payload.split(' ')[0]),
        }
    );
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}


