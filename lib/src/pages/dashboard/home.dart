import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/model/Todo.dart';
import 'package:todolist_app/src/models/project.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:todolist_app/src/pages/manajemen_project/detail_project.dart';
import 'package:todolist_app/src/utils/utils.dart';

final List<Color> listColor = [Colors.grey, Colors.red, Colors.blue];
RandomColor _randomColor = RandomColor();
List<Project> listProject = [];

final Widget placeholder = Container(color: Colors.grey);

// final List widgetCorousel =
// listProject.map((Project item) =>

// ).toList();
//   },
// ).toList();

List<T> map<T>(List list, Function handler) {
  List<T> result = [];
  for (var i = 0; i < list.length; i++) {
    result.add(handler(i, list[i]));
  }

  return result;
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  List<Todo> listTodo = [];
  int _current = 0;
  String namaUser;

  void getDataUser() async {
    DataStore user = new DataStore();
    String namaRawUser = await user.getDataString('name');
    setState(() {
      namaUser = namaRawUser;
    });
  }

  List listFilter = [
    {'index': "1", 'name': "Hari ini"},
    {'index': "2", 'name': "3 Hari"},
    {'index': "3", 'name': "7 Hari"},
    {'index': "4", 'name': "Bulan Ini"},
    {'index': "5", 'name': "Bulan Depan"}
  ];
  int currentFilter = 0;

  @override
  void initState() {
    super.initState();
    getDataProject();
    getDataUser();
    getDataToDo(1);
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

  void getDataToDo(index) async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listTodo.clear();
      isLoading = true;
    });
    try {
      final participant =
          await http.get(url('api/todo/$index'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var todos = listParticipantToJson;
        for (var i in todos) {
          Todo todo = Todo(
              id: i['id'],
              title: i['title'].toString(),
              timeend: i['end'].toString(),
              timestart: i['start'].toString(),
              colored: _randomColor.randomColor());

          listTodo.add(todo);
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "$namaUser",
                style: TextStyle(fontSize: 18),
              ),
              CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      NetworkImage('https://via.placeholder.com/140x100'))
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Project",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              InkWell(
                  onTap: () {},
                  child: Text("Lihat Semua",
                      style: TextStyle(color: Colors.grey))),
            ],
          ),
          Container(
              margin: EdgeInsets.only(top: 8.0),
              // padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                CarouselSlider(
                  items: listProject
                      .map((Project index) => InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DetailProject(idproject: index.id)));
                            },
                            child: Container(
                              // color: index.colored,

                              margin: EdgeInsets.all(5.0),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5.0)),
                                child: Stack(children: <Widget>[
                                  // Image.network(i, fit: BoxFit.cover, width: 500.0),
                                  Container(
                                    color: index.colored,
                                  ),

                                  Positioned(
                                    bottom: 0.0,
                                    left: 0.0,
                                    right: 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.fromARGB(200, 0, 0, 0),
                                            Color.fromARGB(0, 0, 0, 0)
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 20.0),
                                      child: Text(
                                        '${index.title}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ))
                      .toList(),
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 4.0,
                  onPageChanged: (index) {
                    setState(() {
                      _current = index;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var index in listProject)
                      Container(
                        width: 8.0,
                        height: 8.0,
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 2.0),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _current == index
                                ? Color.fromRGBO(0, 0, 0, 0.9)
                                : Color.fromRGBO(0, 0, 0, 0.4)),
                      )
                  ],
                ),
              ])),
          Divider(),
          Container(
            margin: EdgeInsets.only(left: 8.0, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    for (var x in listFilter)
                      Container(
                          margin: EdgeInsets.only(right: 10.0),
                          child: ButtonTheme(
                            minWidth: 0.0,
                            height: 0,
                            child: RaisedButton(
                              color: currentFilter == int.parse(x['index'])
                                  ? primaryAppBarColor
                                  : Colors.grey[100],
                              elevation: 0.0,
                              highlightColor: Colors.transparent,
                              highlightElevation: 0.0,
                              padding: EdgeInsets.only(
                                  top: 7.0,
                                  left: 15.0,
                                  right: 15.0,
                                  bottom: 7.0),
                              onPressed: () {
                                setState(() {
                                  isLoading = true;
                                  // page = 1;
                                  // delay = false;
                                  currentFilter = int.parse(x['index']);
                                  // _getAll(x['c_id'],_searchQuery);
                                  getDataToDo(int.parse(x['index']));
                                });
                              },
                              child: Text(
                                x['name'],
                                style: TextStyle(
                                    color:
                                        currentFilter == int.parse(x['index'])
                                            ? Colors.white
                                            : Colors.black54,
                                    fontWeight: FontWeight.w500),
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(18.0),
                                  side: BorderSide(
                                    color: Colors.transparent,
                                  )),
                            ),
                          )),
                  ]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "ToDo",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              // InkWell(
              //     onTap: () {},
              //     child: Text("Lihat Semua",
              //         style: TextStyle(color: Colors.grey))),
            ],
          ),
          isLoading != false
              ? listLoadingTodo()
              : Container(
                  margin: EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        for (var x in listTodo)
                          Dismissible(
                            key: ObjectKey(x),
                            background: stackBehindDismiss(),
                            child: InkWell(
                              onTap: () async {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DetailProject(idproject: x.id)));
                              },
                              child: Container(
                                height: 65,
                                child: Card(
                                    elevation: 2.0,
                                    child: ListTile(
                                      leading: Container(
                                        color: x.colored,
                                        width: 40.0,
                                        height: 40.0,
                                        child: Center(
                                            child: Text("${x.title[0]}",
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1)),
                                        // decoration: BoxDecoration(
                                        //   image: DecorationImage(
                                        //       fit: BoxFit.cover,
                                        //       image: NetworkImage(
                                        //           'https://via.placeholder.com/140x100')),
                                        //   borderRadius: BorderRadius.all(
                                        //       Radius.circular(8.0)),
                                        //   color: Colors.redAccent,
                                        // ),
                                      ),
                                      title: Text("${x.title}"),
                                      subtitle: Text(
                                          DateFormat('d/M/y')
                                                  .format(DateTime.parse(
                                                      "${x.timestart}"))
                                                  .toString() +
                                              ' - ' +
                                              DateFormat('d/M/y')
                                                  .format(DateTime.parse(
                                                      "${x.timeend}"))
                                                  .toString(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1),
                                    )),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
        ],
      ),
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
