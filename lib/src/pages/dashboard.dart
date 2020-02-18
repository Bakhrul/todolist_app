import 'package:todolist_app/src/pages/dashboard/home.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

String tokenType, accessToken;
Map dataUser;
Map<String, String> requestHeaders = Map();

class Dashboard extends StatefulWidget {
  Dashboard({Key key, this.title}) : super(key: key);
  final String title;
  @override
  State<StatefulWidget> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return true;
  }

  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  Widget appBarTitle = Text(
    "Dashboard",
    style: TextStyle(fontSize: 16),
  );
  Icon notifIcon = Icon(
    Icons.more_vert,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        // key: _scaffoldKeyDashboard,
        appBar: new AppBar(
          backgroundColor: primaryAppBarColor,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: new Text(
            "Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        // drawer: Drawer(
        //   child: GestureDetector(
        //       onTap: () {},
        //       child: Container(
        //         child: Column(
        //           children: <Widget>[
        //             // Profil Drawer Here
        //             UserAccountsDrawerHeader(
        //               // accountName: Text("Muhammad Bakhrul Bila Sakhil"),
        //               accountName: Text('Muhammad Bakhrul'),
        //               accountEmail: Text('Bakhrulrpl@gmail.com'),
        //               decoration: BoxDecoration(
        //                 color: Color.fromRGBO(254, 86, 14, 1),
        //               ),
        //               // currentAccountPicture: CircleAvatar(
        //               //   backgroundColor: Colors.white,
        //               //   child: imageStore == '-'
        //               //       ? Container(
        //               //           height: 90,
        //               //           width: 90,
        //               //           child: ClipOval(
        //               //               child: Image.asset('images/imgavatar.png',
        //               //                   fit: BoxFit.fill)))
        //               //       : Container(
        //               //           height: 90,
        //               //           width: 90,
        //               //           child: ClipOval(
        //               //               child: imageDashboardProfile == null
        //               //                   ? FadeInImage.assetNetwork(
        //               //                       fit: BoxFit.cover,
        //               //                       placeholder: 'images/imgavatar.png',
        //               //                       image: url(
        //               //                           'storage/image/profile/$imageprofile'))
        //               //                   : Image.file(imageDashboardProfile))),
        //               // ),
        //             ),
        //             //  Menu Section Here
        //             Expanded(
        //               child: Container(
        //                 // color: Colors.red,
        //                 child: ListView(
        //                   padding: EdgeInsets.zero,
        //                   children: <Widget>[
        //                     ListTile(
        //                       title: Text(
        //                         'Cari Event',
        //                         style: TextStyle(
        //                           fontSize: 16.0,
        //                           fontFamily: 'Roboto',
        //                           color: Color(0xff25282b),
        //                         ),
        //                       ),
        //                       onTap: () {
        //                         Navigator.pushNamed(context, "/semua_event");
        //                       },
        //                     ),
        //                     ListTile(
        //                       title: Text(
        //                         'Event Saya',
        //                         style: TextStyle(
        //                           fontSize: 16.0,
        //                           fontFamily: 'Roboto',
        //                           color: Color(0xff25282b),
        //                         ),
        //                       ),
        //                       onTap: () {
        //                         Navigator.pushNamed(context, "/personal_event");
        //                       },
        //                     ),
        //                     ListTile(
        //                       title: Text(
        //                         'Event Yang di Ikuti',
        //                         style: TextStyle(
        //                           fontSize: 16.0,
        //                           fontFamily: 'Roboto',
        //                           color: Color(0xff25282b),
        //                         ),
        //                       ),
        //                       onTap: () {
        //                         Navigator.pushNamed(context, "/follow_event");
        //                       },
        //                     ),
        //                     ListTile(
        //                       title: Text(
        //                         'Event Order',
        //                         style: TextStyle(
        //                           fontSize: 16.0,
        //                           fontFamily: 'Roboto',
        //                           color: Color(0xff25282b),
        //                         ),
        //                       ),
        //                       onTap: () {
        //                         Navigator.pushNamed(context, "/event_order");
        //                       },
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ),
        //             Container(
        //               decoration: BoxDecoration(
        //                 border: Border(
        //                   top: BorderSide(
        //                     width: 0.5,
        //                     color: Colors.black54,
        //                   ),
        //                 ),
        //               ),
        //               child: ListTile(
        //                 title: Text(
        //                   'Logout',
        //                   style: TextStyle(
        //                     fontSize: 16.0,
        //                     fontFamily: 'Roboto',
        //                     color: Color(0xff25282b),
        //                   ),
        //                 ),
        //                 trailing: Icon(Icons.exit_to_app),
        //                 onTap: () {
        //                   showDialog(
        //                     context: context,
        //                     builder: (BuildContext context) => AlertDialog(
        //                       title: Text('Peringatan!'),
        //                       content: Text('Apa anda yakin ingin logout?'),
        //                       actions: <Widget>[
        //                         FlatButton(
        //                           child: Text(
        //                             'Tidak',
        //                             style: TextStyle(color: Colors.black54),
        //                           ),
        //                           onPressed: () {
        //                             Navigator.pop(context);
        //                           },
        //                         ),
        //                         FlatButton(
        //                           child: Text(
        //                             'Ya',
        //                             style: TextStyle(color: Colors.cyan),
        //                           ),
        //                           onPressed: () {
        //                             removeSharedPrefs();
        //                             Navigator.pop(context);
        //                             Navigator.pop(context);
        //                             Navigator.pushReplacementNamed(
        //                                 context, "/login");
        //                           },
        //                         )
        //                       ],
        //                     ),
        //                   );
        //                 },
        //               ),
        //             ),
        //           ],
        //         ),
        //       )),
        // ),
        body: Center(
          child: Home(),
       
        ),
           bottomNavigationBar:  BottomNavigationBar(
            
            // type: BottomNavigationBarType.shifting,
            unselectedItemColor: Colors.grey,
            selectedItemColor:Color.fromRGBO(254, 86, 14, 1),
            // currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                ),
                title: new Text('Beranda'),
              ),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.search,
                  ),
                  title: new Text('Cari')),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person,
                  ),
                  title: new Text('Profile'))
            ],
          )
        // ),
        );
        
  }
}
