import 'package:todolist_app/src/pages/about/index.dart';
import 'package:todolist_app/src/pages/auth/login.dart';
import 'package:todolist_app/src/pages/dashboard.dart';
import 'package:todolist_app/src/pages/history/index.dart';
import 'package:todolist_app/src/pages/manajamen_user/edit.dart';
import 'package:todolist_app/src/pages/manajemen_project/list_project.dart';
import 'package:todolist_app/src/pages/todolist/widget_action.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

File imageProfile;

class ManajemenUser extends StatefulWidget {
  ManajemenUser({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ManajemenUser();
  }
}

class _ManajemenUser extends State<ManajemenUser> {
  String imageData;
  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  void getDataUser() async {
    DataStore user = new DataStore();
    String imageStore = await user.getDataString('photo');
    setState(() {
      imageData = imageStore;
    });
  }

  @override
  void initState() {
    getDataUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //     iconTheme: IconThemeData(
        //       color: Colors.white,
        //     ),
        //     backgroundColor: primaryAppBarColor,
        //     elevation: 0.0,
        //     actions: <Widget>[
        //       // IconButton(
        //       //     icon: Icon(Icons.edit),
        //       //     onPressed: () {
        //       //       Navigator.push(
        //       //           context,
        //       //           MaterialPageRoute(
        //       //               builder: (context) => ProfileUserEdit()));
        //       //     })
        //     ]),
        body: Container(
      child: SingleChildScrollView(
          child: Stack(
        children: <Widget>[
          Container(
            height: 150,
            width: double.infinity,
            color: primaryAppBarColor,
          ),
          Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      imageStore == '-'
                          ? Container(
                              // margin: EdgeInsets.only(top: 20),
                              height: 60,
                              width: 60,
                              child: ClipOval(
                                  child: Image.asset('images/imgavatar.png',
                                      fit: BoxFit.fill)))
                          : GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileUserEdit()));
                              },
                              child: imageData != ''
                                  ? Container(
                                      margin: EdgeInsets.only(top: 20),
                                      height: 40,
                                      width: 40,
                                      child: ClipOval(
                                        
                                          child: FadeInImage.assetNetwork(
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  'images/imgavatar.png',
                                              image: url(
                                                  'storage/profile/$imageData'))))
                                  : Container(
                                      margin: EdgeInsets.only(top: 20),
                                      height: 40,
                                      width: 40,
                                      child: ClipOval(
                                          child: Image.asset(
                                              'images/imgavatar.png',
                                              fit: BoxFit.fill))),
                            ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(namaStore == null ? 'memuat..' : namaStore,
                            style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.white,
                            )),
                      ),
                    ],
                  ),
                  Container(
                    decoration: new BoxDecoration(
                        color: Colors.white,
                        borderRadius: new BorderRadius.only(
                          topLeft: const Radius.circular(40.0),
                          topRight: const Radius.circular(40.0),
                        )),
                    margin: EdgeInsets.only(top: 20),
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: 20.0,
                    ),
                    // color: Colors.white,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ListProject()));
                          },
                          child: Container(
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(Icons.tab),
                                title: Text("Project"),
                              )),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => History()));
                          },
                          child: Container(
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(Icons.history),
                                title: Text("Riwayat"),
                              )),
                        ),
                        // InkWell(
                        //   onTap: () {
                        //     Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) => ActionTodo()));
                        //   },
                        //   child: Container(
                        //       margin: EdgeInsets.only(bottom: 8.0),
                        //       child: ListTile(
                        //         leading: Icon(Icons.history),
                        //         title: Text("Action"),
                        //       )),
                        // ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => About()));
                          },
                          child: Container(
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: Icon(Icons.info_outline),
                                title: Text("Tentang"),
                              )),
                        ),
                        Container()
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 20),
                    child: Center(
                        child: FlatButton(
                      color: Colors.white,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text('Peringatan!'),
                            content: Text('Apa anda yakin ingin logout?'),
                            actions: <Widget>[
                              FlatButton(
                                child: Text(
                                  'Tidak',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              FlatButton(
                                child: Text(
                                  'Ya',
                                  style: TextStyle(color: Colors.cyan),
                                ),
                                onPressed: () {
                                  removeSharedPrefs();
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              LoginPage()));
                                },
                              )
                            ],
                          ),
                        );
                      },
                      child: Text("Logout"),
                    )),
                  )
                ],
              ))
        ],
      )),
    ));
  }
}
