import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/src/pages/dashboard.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
bool isLoading,isError;
  Future<Null> getSharedPrefs() async {
    String _status;
    DataStore dataStore = new DataStore();
    _status = await dataStore.getDataString("name");

    if (_status == "Tidak ditemukan") {
      Timer(Duration(seconds: 2),
          () => Navigator.pushReplacementNamed(context, "/login"));
    } else{
      Timer(Duration(seconds: 2),
          () => Navigator.pushReplacementNamed(context, "/dashboard"));
    }
  }

  @override
  void initState() {
    isLoading = true;
    isError = true;
    getSharedPrefs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(color: Colors.white),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 200.0,
                height: 80.0,
                child: Image.asset("images/logo.png"),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0.0,bottom: 16.0),
                child: Text(
                  'Kelola Aktifitas Anda',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
              isLoading == true ? Align(alignment: Alignment.bottomCenter,child: CircularProgressIndicator(),) : Container,
            ],
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text("Version : ${versionNumber.toString().substring(0, 1) + '.'+versionNumber.toString().substring(1, 3)}",style: TextStyle(color:Colors.black54),),
                ),
              ],
            )),
      ),
    );
  }

  void showModalVersionDanger(BuildContext context) {
    showDialog(
      barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            contentPadding: EdgeInsets.only(top: 0.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 60,
                      decoration: new BoxDecoration(
                          color: Colors.red,
                          borderRadius: new BorderRadius.only(
                            topLeft: const Radius.circular(8.0),
                            topRight: const Radius.circular(8.0),
                          )),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.warning,color: Colors.white , size: 40,),
                            Padding(
                              padding: const EdgeInsets.only(left:8.0),
                              child: Text(
                                "Version Update",
                                style: TextStyle(fontSize: 16.0,color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.only(left:16.0,right:16.0,bottom:8.0),
                      child: Text("Versi Terbaru Telah Tersedia",style: TextStyle(fontSize: 14),)
                      
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Todolist menyarankan anda untuk mengupdate ke versi terbaru. Versi yang anda gunakan telah kadaluarsa",style: TextStyle(fontSize: 12,color:Colors.grey,height: 1.5),textAlign: TextAlign.justify,)

                    ),
                    Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () {  },
                          child: Text("UPDATE",style: TextStyle(color:primaryAppBarColor)),
                        )

                      ],

                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class OutDateVersion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
            Center(
              child: Container(
                margin: EdgeInsets.only(bottom:16.0),
                width: 150,
                height: 250,
                child: Image.asset("images/caution.png")),
            ),

            Text("Versi Aplikasi Ini Telah Kadaluarsa, Silahkan Update Versi Terbaru Di App Store.",
            style: TextStyle(fontSize: 14,color:Colors.black,decoration: TextDecoration.none,),textAlign: TextAlign.justify,),
            
            Container(
              margin: EdgeInsets.only(top: 16),
              child: CupertinoButton(
                color: Colors.deepOrange,
                onPressed: () {  },
              child: Text("Update"),

              ),
            )
        
          ],)
          
          
        ),
      ),
    );
  }
  
  
}
