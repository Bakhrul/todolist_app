import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationLocal{

 BuildContext context;
 int id = 0;
 FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

  void mustInit(){

  var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

  }

  Future onSelectNotification(String payload) async {
      showDialog(
        context: context,
        builder:(_) => AlertDialog(
          title:Text('here your play load'),
          content:Text('playload $payload')
        )
      );
      
  }

  Future showNotificationWithSound(String title,String body) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        id.toString(), title, body,
        importance: Importance.Max,
        priority: Priority.High);
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Custom_Sound',
    );
  }

}