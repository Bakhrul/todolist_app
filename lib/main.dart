
import 'package:flutter/material.dart';

//pages
import 'src/pages/auth/login.dart';
import 'src/pages/dashboard.dart';
import 'splash_screen.dart';

Map<String, WidgetBuilder> routesX = <String, WidgetBuilder>{
  "/dashboard": (BuildContext context) => Dashboard(),
  "/login" : (BuildContext context) => LoginPage(),
};

void main() => runApp(MyApp());

class MyApp extends StatefulWidget{
  MyApp({Key key}) : super(key: key);

  State<StatefulWidget> createState() {
    return _MyApp();
  }
}
String messageX;
class _MyApp extends State<MyApp> {


  // This widget is the root of your application.
  // Platform messages are asynchronous, so we initialize in an async method.
  @override
  void initState(){
    messageX = '';
    super.initState();
  }



  
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TodoList',
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