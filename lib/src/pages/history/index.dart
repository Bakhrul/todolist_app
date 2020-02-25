import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:random_color/random_color.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/models/project.dart';
import 'package:todolist_app/src/pages/manajemen_project/edit_project.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'dart:async';

import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  List<Project> listProject = [];
  bool isLoading = true;
  bool isError = true;
  RandomColor _randomColor = RandomColor();

  @override
  void initState() {
    super.initState();
    getHeaderHTTP();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataProject();
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
          await http.get(url('api/history'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;

        for (var i in project) {
          Project participant = Project(
              id: i['id'],
              title: i['title'].toString(),
              start: i['start'].toString(),
              end: i['end'].toString(),
              status: i['status'].toString(),
              progress: i['progress'].toString(),
              isProject: i['isproject'],
              colored: _randomColor.randomColor());
          listProject.add(participant);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
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
        title: Text("Riwayat"),
        backgroundColor: primaryAppBarColor,
      ),
      body: isLoading != false
          ? listLoadingTodo()
          : isError == true
              ? errorSystem(context)
              : Container(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: listProject.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            child: ListTile(
                              // leading: Text(""),
                              title: Text(listProject[index].isProject == true ?"Project: " + "${listProject[index].title}" : "Todo : " + "${listProject[index].title}",
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
                              trailing:  Container(
                                child: CircularPercentIndicator(
                  radius: 40.0,
                  lineWidth: 4.0,
                  percent: double.parse(listProject[index].progress),
                  center: new Text((double.parse(listProject[index].progress)*100).round().toString()+"%",style: TextStyle(fontSize: 12),),
                  progressColor: Colors.green,
                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DetailProject(
                                              idproject: listProject[index].id,
                                            )));
                              },
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

  Widget errorSystem(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: RefreshIndicator(
        onRefresh: () => getHeaderHTTP(),
        child: Column(children: <Widget>[
          new Container(
            width: 100.0,
            height: 100.0,
            child: Image.asset("images/system-eror.png"),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 30.0,
              left: 15.0,
              right: 15.0,
            ),
            child: Center(
              child: Text(
                "Gagal memuat halaman, tekan tombol muat ulang halaman untuk refresh halaman",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: 15.0, left: 15.0, right: 15.0, bottom: 15.0),
            child: SizedBox(
              width: double.infinity,
              child: RaisedButton(
                color: Colors.white,
                textColor: primaryAppBarColor,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(15.0),
                onPressed: () async {
                  getHeaderHTTP();
                },
                child: Text(
                  "Muat Ulang Halaman",
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
