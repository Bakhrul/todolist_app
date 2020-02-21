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

final Widget placeholder = Container(color: Colors.grey);

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
  final List<Color> listColor = [Colors.grey, Colors.red, Colors.blue];
  RandomColor _randomColor = RandomColor();
  List<Project> listProject = [];
  bool isFilter, isErrorFilter, isLoading, isError;
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
  int currentFilter = 1;

  @override
  void initState() {
    super.initState();
    getDataProject();
    getDataUser();
    isLoading = true;
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
      listProject.clear();
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

        return getDataToDo(1);
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> getDataToDo(index) async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listTodo.clear();
      listTodo = [];
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
              statuspinned: i['statuspinned'].toString(),
              colored: _randomColor.randomColor());

          listTodo.add(todo);
        }

        setState(() {
          isLoading = false;
          isError = false;
          isFilter = false;
          isErrorFilter = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      debugPrint('$e');
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
    }
    return null;
  }

  void filterDataTodo(index) async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listTodo.clear();
      listTodo = [];
      isFilter = true;
    });
    try {
      final participant =
          await http.get(url('api/todo/$index'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var todos = listParticipantToJson;
        print(todos);
        for (var i in todos) {
          Todo todo = Todo(
              id: i['id'],
              title: i['title'].toString(),
              timeend: i['end'].toString(),
              timestart: i['start'].toString(),
              statuspinned: i['statuspinned'].toString(),
              colored: _randomColor.randomColor());

          listTodo.add(todo);
        }

        setState(() {
          isFilter = false;
          isErrorFilter = false;
          isFilter = false;
          isErrorFilter = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isFilter = false;
          isErrorFilter = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        setState(() {
          isFilter = false;
          isErrorFilter = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isErrorFilter = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isErrorFilter = true;
        isFilter = false;
        isErrorFilter = false;
      });
      debugPrint('$e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: getDataProject,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            isLoading == true
                ? Container()
                : listProject.length == 0
                    ? Container()
                    : Container(
                        margin: EdgeInsets.only(bottom: 10.0, top: 15.0),
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(('Project').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
            isLoading == true
                ? listLoadingProject()
                : listProject.length == 0
                    ? Container()
                    : Container(
                        child: Column(children: [
                        CarouselSlider(
                          items: listProject
                              .map((Project index) => InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailProject(
                                                      idproject: index.id)));
                                    },
                                    child: Container(
                                      margin: EdgeInsets.all(5.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5.0)),
                                        child: Stack(children: <Widget>[
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
                                                    Color.fromARGB(
                                                        200, 0, 0, 0),
                                                    Color.fromARGB(0, 0, 0, 0)
                                                  ],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10.0,
                                                  horizontal: 20.0),
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
            isLoading == true
                ? Container(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          margin: EdgeInsets.only(top: 15.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300],
                            highlightColor: Colors.grey[100],
                            child: Row(
                              children: [0, 1, 2, 3, 4]
                                  .map((_) => Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(right: 15.0),
                                        width: 120.0,
                                        height: 20.0,
                                      ))
                                  .toList(),
                            ),
                          ),
                        )))
                : Container(
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
                                      color:
                                          currentFilter == int.parse(x['index'])
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
                                          currentFilter = int.parse(x['index']);
                                          if (isFilter == true) {
                                          } else {
                                            filterDataTodo(
                                                int.parse(x['index']));
                                          }
                                        });
                                      },
                                      child: Text(
                                        x['name'],
                                        style: TextStyle(
                                            color: currentFilter ==
                                                    int.parse(x['index'])
                                                ? Colors.white
                                                : Colors.black54,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              new BorderRadius.circular(18.0),
                                          side: BorderSide(
                                            color: Colors.transparent,
                                          )),
                                    ),
                                  )),
                          ]),
                    ),
                  ),
            isLoading == true
                ? Container()
                : Container(
                    margin: EdgeInsets.only(bottom: 10.0),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(('List To Do').toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ),
            isLoading == true || isFilter == true
                ? listLoadingTodo()
                : isErrorFilter == true
                    ? errorSystemFilter(context)
                    : listTodo.length == 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(children: <Widget>[
                              new Container(
                                width: 100.0,
                                height: 100.0,
                                child:
                                    Image.asset("images/empty-white-box.png"),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 20.0,
                                  left: 15.0,
                                  right: 15.0,
                                ),
                                child: Center(
                                  child: Text(
                                    "Anda Tidak Memiliki To Do Sama Sekali",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black45,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ]),
                          )
                        : Container(
                            margin: EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                children: <Widget>[
                                  for (var x in listTodo)
                                    InkWell(
                                      onTap: () async {},
                                      child: Container(
                                        height: 65,
                                        child: Card(
                                            elevation: 2.0,
                                            child: ListTile(
                                              leading: Padding(
                                                padding:
                                                    const EdgeInsets.all(0.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100.0),
                                                  child: Container(
                                                      height: 40.0,
                                                      alignment:
                                                          Alignment.center,
                                                      width: 40.0,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors.white,
                                                            width: 2.0),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    100.0) //                 <--- border radius here
                                                                ),
                                                        color:
                                                            primaryAppBarColor,
                                                      ),
                                                      child: Text(
                                                        '${x.title[0].toUpperCase()}',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )),
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  ButtonTheme(
                                                    minWidth: 0.0,
                                                    child: FlatButton(
                                                        onPressed: () async {
                                                          try {
                                                            final actionPinnedTodo =
                                                                await http.post(
                                                                    url(
                                                                        'api/actionpinned_todo'),
                                                                    headers:
                                                                        requestHeaders,
                                                                    body: {
                                                                  'todolist': x
                                                                      .id
                                                                      .toString(),
                                                                });

                                                            if (actionPinnedTodo
                                                                    .statusCode ==
                                                                200) {
                                                              var actionPinnedTodoJson =
                                                                  json.decode(
                                                                      actionPinnedTodo
                                                                          .body);
                                                              if (actionPinnedTodoJson[
                                                                      'status'] ==
                                                                  'tambah') {
                                                                setState(() {
                                                                  x.statuspinned = x
                                                                      .id
                                                                      .toString();
                                                                });
                                                              } else if (actionPinnedTodoJson[
                                                                      'status'] ==
                                                                  'hapus') {
                                                                setState(() {
                                                                  x.statuspinned =
                                                                      null;
                                                                });
                                                              }
                                                            } else {
                                                              print(
                                                                  actionPinnedTodo
                                                                      .body);
                                                            }
                                                          } on TimeoutException catch (_) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    "Timed out, Try again");
                                                          } catch (e) {
                                                            print(e);
                                                          }
                                                        },
                                                        color: Colors.white,
                                                        child: Icon(
                                                          Icons.star_border,
                                                          color: x.statuspinned ==
                                                                      null ||
                                                                  x.statuspinned ==
                                                                      'null'
                                                              ? Colors.grey
                                                              : Colors.orange,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                              title: Text(
                                                  x.title == '' ||
                                                          x.title == null
                                                      ? 'To Do Tidak Diketahui'
                                                      : x.title,
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5.0, bottom: 15.0),
                                                child: Text(
                                                    DateFormat('d/M/y HH:mm:ss')
                                                            .format(DateTime.parse(
                                                                "${x.timestart}"))
                                                            .toString() +
                                                        ' - ' +
                                                        DateFormat(
                                                                'd/M/y H:mm:ss')
                                                            .format(
                                                                DateTime.parse(
                                                                    "${x.timeend}"))
                                                            .toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1),
                                              ),
                                            )),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
          ],
        ),
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

  Widget listLoadingProject() {
    return Container(
        margin: EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0]
                  .map((_) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                        padding: const EdgeInsets.only(bottom: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 40.0,
                                    margin:
                                        EdgeInsets.only(right: 10.0, top: 10.0),
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    height: 60.0,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(left: 10.0, top: 10.0),
                                    height: 40.0,
                                    color: Colors.white,
                                  ),
                                ),
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

  Widget errorSystemFilter(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
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
                filterDataTodo(int.parse(currentFilter.toString()));
              },
              child: Text(
                "Muat Ulang Halaman",
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ]),
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
