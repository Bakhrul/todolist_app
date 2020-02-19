import 'package:todolist_app/src/pages/dashboard.dart';
import 'package:todolist_app/src/pages/manajamen_user/edit.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';

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
  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
            backgroundColor: primaryAppBarColor,
            elevation: 0.0,
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfileUserEdit()));
                  })
            ]),
        body: SingleChildScrollView(
            child: Stack(
          children: <Widget>[
            Container(
              height: 200,
              width: double.infinity,
              color: primaryAppBarColor,
            ),
            Container(
                child: Column(
              children: <Widget>[
                imageStore == '-' ?
                Container(
                      margin: EdgeInsets.only(top:20),
                      height: 90,
                      width: 90,
                      child : ClipOval(
                        child: Image.asset('images/imgavatar.png',fit:BoxFit.fill)
                      )
                    ):
                Container(
                  margin: EdgeInsets.only(top: 20),
                  height: 90,
                  width: 90,
                  child : ClipOval(
                    child: imageProfile == null ?
                    FadeInImage.assetNetwork(
                      fit: BoxFit.cover,
                      placeholder : 'images/imgavatar.png',
                      image:url('storage/image/profile/$imageStore')
                    ):
                    Image.file(imageProfile)
                  )
                ),

                Container(
                  margin: EdgeInsets.only(bottom: 5.0, top: 10.0),
                  child: Text(namaStore == null ? 'memuat..' : namaStore,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.white,
                      )),
                ),

                Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: 50.0,
                      right: 50.0,
                      top: 20.0,
                    ),
                    color: Colors.white,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileUserEdit()));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                              margin: EdgeInsets.only(bottom: 5.0),
                              child: Text('Nama',
                                  style: TextStyle(color: Colors.grey))),
                          Container(
                            margin: EdgeInsets.only(bottom: 20.0),
                            child:
                                Text(namaStore == null ? 'memuat..' : namaStore,
                                    style: TextStyle(
                                      fontSize: 20.0,
                                    )),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 5.0),
                            child: Text('Email',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          Container(
                              margin: EdgeInsets.only(bottom: 20.0),
                              child: Text(
                                  emailStore == null ? 'memuat..' : emailStore,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ))),
                          Container()
                        ],
                      ),
                    )),
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
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                    context, "/login");
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
        )));
  }
}
