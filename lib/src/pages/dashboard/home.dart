import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/models/project.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:todolist_app/src/pages/manajemen_project/detail_project.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  List<Project> listProject = [];

  @override
  void initState() {
    super.initState();
    getDataProject();
  }

  Future<List<List>> getDataProject() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      // isLoading = true;
    });
    try {
      final participant =
          await http.get(url('api/project'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var participants = listParticipantToJson;

        for (var i in participants) {
          Project participant = Project(
            id: i['id'],
            title: i['title'].toString(),
          );
          listProject.add(participant);
        }

        setState(() {
          // isLoading = false;
          // isError = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          // isLoading = false;
          // isError = true;
        });
      } else {
        setState(() {
          // isLoading = false;
          // isError = true;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        // isLoading = false;
        // isError = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        // isLoading = false;
        // isError = true;
      });
      debugPrint('$e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    print(listProject);
    return ListView.builder(
      itemCount: listProject.length,
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          key: ObjectKey(listProject[index]),
          background: stackBehindDismiss(),
          child: InkWell(
            onTap: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          DetailProject(idproject: listProject[index].id)));
            },
            child: Container(
              height: 100,
              child: Card(
                  elevation: 2.0,
                  child: ListTile(
                    leading: new Container(
                        color: Colors.black,
                        child: new Container(
                            decoration: new BoxDecoration(
                                color: Colors.green,
                                borderRadius: new BorderRadius.only(
                                    topLeft: const Radius.circular(40.0),
                                    topRight: const Radius.circular(40.0))),
                            child: Image.network(
                                "http://www.kaosfutsal.com/wp-content/uploads/2019/12/placeholder.png"))),
                    title: Text(
                      "${listProject[index].title}",
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text("Deskripsi Project"),
                  )),
            ),
          ),
        );
      },
    );
  }

  Widget stackBehindDismiss() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }
}
