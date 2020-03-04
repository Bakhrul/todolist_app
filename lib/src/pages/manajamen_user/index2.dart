import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/models/todo.dart';
import 'package:todolist_app/src/pages/auth/login.dart';
import 'package:todolist_app/src/pages/manajemen_project/detail_project.dart';
import 'package:todolist_app/src/pages/todolist/detail_todo.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/model/Project.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';

enum PageEnum {
  editProfile,
  deletePhoto,
}

class ManajemenUser extends StatefulWidget {
  @override
  _ManajemenUserState createState() => _ManajemenUserState();
}

class _ManajemenUserState extends State<ManajemenUser>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  String tokenType, accessToken;
  String nameUser = '';
  Map<String, String> requestHeaders = Map();
  List<Project> listProject = [];
  List<Todo> listHistory = [];
  List<Todo> listArchive = [];
  bool isLoading = true;
  bool isError = true;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    isError = false;
    getHeaderHTTP();
    _tabController =
        TabController(length: 3, vsync: _ManajemenUserState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
  }
    Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  void _handleTabIndex() {
    if (_tabController.index == 0) {
      setState(() {
        getDataProject();
      });
    } else if (_tabController.index == 1) {
      setState(() {
        getDataHistory();
      });
    } else {
      setState(() {
        getDataArchive();        
      });
    }
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');
    var nameStorage = await storage.getDataString('name');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    nameUser = nameStorage;

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
      listProject.clear();
      listProject = [];
      isLoading = true;
      
    });
    try {
       await new Future.delayed(const Duration(seconds : 1));
      final participant =
          await http.get(url('api/dashboard'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson['project'];
        listProject.clear();
        listProject = [];
        print(project);

        for (var i in project) {
          Project participant = Project(
              id: i['id'],
              title: i['title'].toString(),
              start: i['created_date'].toString(),
              end: i['finish_date'].toString(),
              colored: i['status'] == 'compleshed'
                  ? Colors.green
                  : i['status'] == 'overdue'
                      ? Colors.red
                      : i['status'] == 'pending' ? Colors.grey : Colors.white);
          listProject.add(participant);
        }
        await new Future.delayed(const Duration(seconds : 1));

        setState(() {
          isLoading = false;
          isError = false;
        });

        print(listProject.length);

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

  Future<List<List>> getDataHistory() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listHistory.clear();
      listHistory =[];
      isLoading = true;
    });
    try {
    await new Future.delayed(const Duration(seconds : 1));
      final participant =
          await http.get(url('api/history'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;
        listHistory.clear();
        listHistory =[];

        for (var i in project) {
          Todo participant = Todo(
            id: i['id'],
            title: i['title'].toString(),
            start: i['start'].toString(),
            end: i['end'].toString(),
            status: i['status'].toString(),
            allday: i['allday'],
          );
          listHistory.add(participant);
        }
    await new Future.delayed(const Duration(seconds : 1));

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

  Future<List<List>> getDataArchive() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listArchive.clear();
      listArchive = [];
      isLoading = true;
    });
    try {
    await new Future.delayed(const Duration(seconds : 1));

      final participant =
          await http.get(url('api/archive'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;
         listArchive.clear();
        listArchive = [];

        for (var i in project) {
          Todo participant = Todo(
            id: i['id'],
            title: i['title'].toString(),
            start: i['start'].toString(),
            end: i['end'].toString(),
            status: i['status'].toString(),
            allday: i['allday'],
          );
          listArchive.add(participant);
        }
    await new Future.delayed(const Duration(seconds : 1));

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
  void dispose() {
    listHistory.clear();
    listArchive.clear();
    listProject.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: new ListView(
        children: <Widget>[
          new Container(
            // color: Colors.white,
            height: 250.0,
            margin: new EdgeInsets.only(bottom: 8.0),
            decoration: new BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[300],
                  blurRadius: 6.0, // has the effect of softening the shadow
                  spreadRadius: 1.0, // has the effect of extending the shadow
                  offset: Offset(
                    1.0, // horizontal, move right 10
                    1.0, // vertical, move down 10
                  ),
                )
              ],
              // borderRadius: new BorderRadius.all(...),
              // gradient: new LinearGradient(...),
            ),
            child: Container(
              decoration: new BoxDecoration(
                  color: Colors.white,
                  // gradient: LinearGradient(
                  //   begin: Alignment.topCenter,
                  //   end: Alignment.bottomCenter,
                  //   // stops: [0.1, 0.5, 0.7, 0.9],
                  //   stops: [0.1, 0.5, 0.9],
                  //   colors: [
                  //     primaryAppBarColor,
                  //     // Colors.deepOrange[300],
                  //     Colors.deepOrange[100],
                  //     Colors.white,
                  //   ],
                  // ),
                  borderRadius: new BorderRadius.only(
                    bottomLeft: const Radius.circular(18.0),
                    bottomRight: const Radius.circular(18.0),
                  )),
              // color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(8),
                    child: InkWell(
                      child: Icon(Icons.more_vert),
                      onTap: () {

                      },
                    ),
                  ),
                  Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 8),
                        height: 60,
                        width: 60,
                        child: ClipOval(
                            child: Image.asset('images/imgavatar.png',
                                fit: BoxFit.fill))),
                  ),
                  Center(
                    child: Container(
                        // padding: EdgeInsets.only(top: 6,bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.only(top:8,left:24,right:24),
                          child: Text("$nameUser",softWrap: true,overflow: TextOverflow.ellipsis,),
                        )),
                  ),
                  Center(
                        child: Container(
                          margin: EdgeInsets.only(top:8),
                          child: RaisedButton(
                      shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(18.0),
                            // side: BorderSide(color: Colors.red)
                            ),
                      color: primaryAppBarColor,
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
                      child: Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                      ),
                    ),
                        )),
                  
                  Expanded(
                    child: TabBar(
                      labelColor: Colors.black,
                      controller: _tabController,
                      indicatorColor: primaryAppBarColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        new Tab(
                          text: 'Project',
                        ),
                        new Tab(
                          text: 'Riwayat',
                        ),
                        new Tab(
                          text: 'Archive',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              height: MediaQuery.of(context).size.height / 2,
              child: new TabBarView(
                controller: _tabController,
                children: <Widget>[
                  isError == true
                ? Container()
                : isLoading == true 
                    ? listLoadingTodo()
                    : isError == true
                        ? errorSystemFilter(context)
                        : listProject.length == 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(children: <Widget>[
                                  new Container(
                                    width: 100.0,
                                    height: 100.0,
                                    child: Image.asset("images/todo_icon2.png"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20.0,
                                        left: 25.0,
                                        right: 25.0,
                                        bottom: 35.0),
                                    child: Center(
                                      child: Text(
                                        "To Do Yang Anda Cari Tidak Ditemukan",
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ]),
                              ):
                  SingleChildScrollView(
                      child: Column(
                    children: listProject
                        .map(
                          (Project item) => InkWell(
                            onTap: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ManajemenDetailProjectAll(
                                              idproject: item.id,
                                              namaproject: item.title)));
                            },
                            child: Container(
                              child: Card(
                                  elevation: 0.5,
                                  margin: EdgeInsets.only(
                                      top: 5.0,
                                      bottom: 5.0,
                                      left: 0.0,
                                      right: 0.0),
                                  child: ClipPath(
                                    clipper: ShapeBorderClipper(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border(
                                              right: BorderSide(
                                                  color: item.colored,
                                                  width: 5))),
                                      child: ListTile(
                                        leading: Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: Container(
                                                height: 40.0,
                                                alignment: Alignment.center,
                                                width: 40.0,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2.0),
                                                  color: primaryAppBarColor,
                                                ),
                                                child: Text(
                                                  '${item.title[0].toUpperCase()}',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )),
                                          ),
                                        ),
                                        title: Text(
                                            item.title == '' ||
                                                    item.title == null
                                                ? 'To Do Tidak Diketahui'
                                                : item.title,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(
                                            DateFormat('d MMM y')
                                                    .format(DateTime.parse(
                                                        "${item.start}"))
                                                    .toString() +
                                                ' - ' +
                                                DateFormat('d MMM y')
                                                    .format(DateTime.parse(
                                                        "${item.end}"))
                                                    .toString(),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1),
                                      ),
                                    ),
                                  )),
                            ),
                          ),
                        )
                        .toList(),
                  )),
                  // LIST HISTORY
                  isError == true
                ? Container()
                : isLoading == true 
                    ? listLoadingTodo()
                    : isError == true
                        ? errorSystemFilter(context)
                        : listHistory.length == 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(children: <Widget>[
                                  new Container(
                                    width: 100.0,
                                    height: 100.0,
                                    child: Image.asset("images/todo_icon2.png"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20.0,
                                        left: 25.0,
                                        right: 25.0,
                                        bottom: 35.0),
                                    child: Center(
                                      child: Text(
                                        "To Do Yang Anda Cari Tidak Ditemukan",
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ]),
                              ):
                  SingleChildScrollView(
                      child: Column(
                    children: listHistory
                        .map(
                          (Todo item) => InkWell(
                            onTap: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ManajemenDetailTodo(
                                              idtodo:  item.id,
                                              namatodo: item.title)));
                            },
                            child: Container(
                              child: Card(
                                  elevation: 0.5,
                                  margin: EdgeInsets.only(
                                      top: 5.0,
                                      bottom: 5.0,
                                      left: 0.0,
                                      right: 0.0),
                                  child: ClipPath(
                                    clipper: ShapeBorderClipper(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                    child: Container(
                                      child: ListTile(
                                        leading: Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            child: Container(
                                                height: 40.0,
                                                alignment: Alignment.center,
                                                width: 40.0,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2.0),
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(
                                                          100.0) //                 <--- border radius here
                                                      ),
                                                  color: primaryAppBarColor,
                                                ),
                                                child: Text(
                                                  '${item.title[0].toUpperCase()}',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )),
                                          ),
                                        ),
                                        title: Text(
                                            item.title == '' ||
                                                    item.title == null
                                                ? 'To Do Tidak Diketahui'
                                                : item.title,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(
                                            DateFormat(item.allday > 0
                                                        ? 'd MMM y'
                                                        : 'd MMM y HH:mm')
                                                    .format(DateTime.parse(
                                                        "${item.start}"))
                                                    .toString() +
                                                ' - ' +
                                                DateFormat(item.allday > 0
                                                        ? 'd MMM y'
                                                        : 'd MMM y HH:mm')
                                                    .format(DateTime.parse(
                                                        "${item.end}"))
                                                    .toString(),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1),
                                      ),
                                    ),
                                  )),
                            ),
                          ),
                        )
                        .toList(),
                  )),
                  // LIST ARCHIVE
                  isError == true
                ? Container()
                : isLoading == true 
                    ? listLoadingTodo()
                    : isError == true
                        ? errorSystemFilter(context)
                        : listArchive.length == 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(children: <Widget>[
                                  new Container(
                                    width: 100.0,
                                    height: 100.0,
                                    child: Image.asset("images/todo_icon2.png"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20.0,
                                        left: 25.0,
                                        right: 25.0,
                                        bottom: 35.0),
                                    child: Center(
                                      child: Text(
                                        "To Do Yang Anda Cari Tidak Ditemukan",
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ]),
                              ):
                 SingleChildScrollView(
                      child: Column(
                    children: listArchive
                        .map(
                          (Todo item) => InkWell(
                            onTap: () async {
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (context) =>
                              //             ManajemenDetailProjectAll(
                              //                 idproject: item.id,
                              //                 namaproject: item.title)));
                            },
                            child: Container(
                              child: Card(
                                  elevation: 0.5,
                                  margin: EdgeInsets.only(
                                      top: 5.0,
                                      bottom: 5.0,
                                      left: 0.0,
                                      right: 0.0),
                                  child: ClipPath(
                                    clipper: ShapeBorderClipper(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                    child: Container(
                                      child: ListTile(
                                        leading: Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            child: Container(
                                                height: 40.0,
                                                alignment: Alignment.center,
                                                width: 40.0,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2.0),
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(
                                                          100.0) //                 <--- border radius here
                                                      ),
                                                  color: primaryAppBarColor,
                                                ),
                                                child: Text(
                                                  '${item.title[0].toUpperCase()}',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )),
                                          ),
                                        ),
                                        title: Text(
                                            item.title == '' ||
                                                    item.title == null
                                                ? 'To Do Tidak Diketahui'
                                                : item.title,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(
                                            DateFormat(item.allday > 0
                                                        ? 'd MMM y'
                                                        : 'd MMM y HH:mm')
                                                    .format(DateTime.parse(
                                                        "${item.start}"))
                                                    .toString() +
                                                ' - ' +
                                                DateFormat(item.allday > 0
                                                        ? 'd MMM y'
                                                        : 'd MMM y HH:mm')
                                                    .format(DateTime.parse(
                                                        "${item.end}"))
                                                    .toString(),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1),
                                      ),
                                    ),
                                  )),
                            ),
                          ),
                        )
                        .toList(),
                  )),
                ],
              ),
            ),
          ),
        ],
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
    );
  }
}
