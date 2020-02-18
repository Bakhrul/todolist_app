
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/models/project.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

List<Project> listProject = [];

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  
  
   @override
  void initState() {
    super.initState();
    getDataProject();
  }
  
  Future getDataProject() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');
    
    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    try {
      final getProject = await http.get(url('api/project'),
          headers: requestHeaders);
    print(getProject.statusCode);

      if (getProject.statusCode == 200) {
        // if (_isSwitched == false) {
        var listProject = json.decode(getProject.body);
        var projects = listProject;
        
        for (var i in projects) {
          Project participant = Project(
              // id: i['id'],
              title: i['title'],
              start: i['start'],
              end: i['end']
              );
          listProject.add(participant);
        }
        
        // return Navigator.pop(context);
      } else if (getProject.statusCode == 401) {
        Fluttertoast.showToast(msg: "Gagal Membatalkan Event");
        setState(() {
          // isLoading = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Time out, silahkan coba lagi nanti");
      setState(() {
        // isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "$e");
      setState(() {
        // isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    print("SALAH OPOE");
    print(listProject);
    return Container(
               child: ListView.builder(
                 itemCount: listProject.length,
                 itemBuilder: (BuildContext context, int index) { 
                   return Card(
                     child: Text("listProject[index].title"),

                   );
                  },
                 
               ),
             );
  }
}