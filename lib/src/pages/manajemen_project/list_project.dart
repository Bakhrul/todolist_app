import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/model/Project.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'dart:async';

import 'package:todolist_app/src/storage/storage.dart';

class ListProject extends StatefulWidget {
  @override
  _ListProjectState createState() => _ListProjectState();
}

class _ListProjectState extends State<ListProject> {
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  List<Project> listProject = [];
  bool isLoading = true;
  RandomColor _randomColor = RandomColor();

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
      isLoading = true;
    });
    try {
      final participant =
          await http.get(url('api/project'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;

        for (var i in project) {
          Project participant = Project(
              id: i['id'],
              title: i['title'].toString(),
              start: i['start'].toString(),
              end: i['end'].toString(),
              colored: _randomColor.randomColor());
          listProject.add(participant);
        }

        setState(() {
          isLoading = false;
          // isError = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          // isError = true;
        });
      } else {
        setState(() {
          isLoading = false;
          // isError = true;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        // isError = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      debugPrint('$e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Semua Project"),
      ),
      body: Container(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: listProject.length,
              itemBuilder: (BuildContext context, int index) {
                return isLoading != true
              ? listLoadingTodo():Card(
                  child: ListTile(
                    // leading: Text(""),
                    title: Text("${listProject[index].title}",
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    subtitle: Text(
                        listProject[index].start == 'null' ||
                                listProject[index].end == 'null'
                            ? '-'
                            : DateFormat('d/M/y')
                                    .format(DateTime.parse(
                                        "${listProject[index].start}"))
                                    .toString() +
                                ' - ' +
                                DateFormat('d/M/y')
                                    .format(DateTime.parse(
                                        "${listProject[index].end}"))
                                    .toString(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ),
                );
              },
            )),
      ),
    );
  }
    Widget listLoadingTodo() {
    return Container(
        margin: EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3, 4]
                  .map((_) => Padding(
                        padding: const EdgeInsets.only(bottom: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Container(
                            //   width: 150.0,
                            //   height: 13.0,
                            //   color: Colors.white,
                            // ),
                            // Padding(
                            //   padding:
                            //       const EdgeInsets.symmetric(vertical: 8.0),
                            // ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40.0,
                                  height: 40.0,
                                  color: Colors.white,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                      ),
                                      Container(
                                        width: 40.0,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        )));
  }
}
