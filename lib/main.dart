
import 'package:flutter/material.dart';

//pages
import 'src/pages/auth/login.dart';
import 'src/pages/dashboard.dart';
import 'splash_screen.dart';
// import 'dart:isolate';
// import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:todolist_app/src/utils/notif_local.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:permission_handler/permission_handler.dart';

Map<String, WidgetBuilder> routesX = <String, WidgetBuilder>{
  "/dashboard": (BuildContext context) => Dashboard(),
  "/login" : (BuildContext context) => LoginPage(),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();

  runApp(new MyApp());
}

class MyApp extends StatefulWidget{
  MyApp({Key key}) : super(key: key);

  State<StatefulWidget> createState() {
    return _MyApp();
  }
}
String messageX;
class _MyApp extends State<MyApp> {
FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  NotificationLocal notif = new NotificationLocal();

  // This widget is the root of your application.
  // Platform messages are asynchronous, so we initialize in an async method.
  @override
  void initState(){
    messageX = '';
    getMessage();
    notif.mustInit(); 
    register();
    super.initState();
  }

     register() {
    _firebaseMessaging.getToken().then((token) => print("j"));
  }

  void getMessage(){

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
          notif.showNotificationWithSound(message["notification"]["title"],message["notification"]["body"]);
          // print('on message $message');
          setState(() {
            messageX = message["notification"]["title"];
          });
    }, onResume: (Map<String, dynamic> message) async {
          // print('on resume $message');
          setState(() {
            messageX = message["notification"]["title"];
          });
    }, onLaunch: (Map<String, dynamic> message) async {
          // print('on launch $message');
          setState(() {
            messageX = message["notification"]["title"];
          });
    });

  }

  
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todolist',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: routesX,
    );
  }
}