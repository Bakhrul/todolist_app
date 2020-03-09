import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/models/todo.dart';
import 'package:todolist_app/src/pages/auth/login.dart';
import 'package:todolist_app/src/pages/manajamen_user/edit.dart';
import 'package:todolist_app/src/pages/manajemen_project/detail_project.dart';
import 'package:todolist_app/src/pages/todolist/detail_todo.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/model/Project.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:todolist_app/src/model/FriendList.dart';
import 'confirmation_friend.dart';

enum PageEnum {
  editProfile,
  permintaanTeman,
}

class ManajemenUser extends StatefulWidget {
  @override
  _ManajemenUserState createState() => _ManajemenUserState();
}

class _ManajemenUserState extends State<ManajemenUser>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  String tokenType, accessToken;

  TextEditingController _emailPenggunaController = TextEditingController();
  String nameUser = '';
  Map<String, String> requestHeaders = Map();
  List<Project> listProject = [];
  List<Todo> listHistory = [];
  List<FriendList> listFriend = [];
  bool isLoading = true;
  bool isError = true;
  ProgressDialog progressApiAction;
  String imageData;

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
        getDataFriend();
      });
    }
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');
    var nameStorage = await storage.getDataString('name');
    String imageStore = await storage.getDataString('photo');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    nameUser = nameStorage;
    imageData = imageStore;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataProject();
  }

  Future<List<List>> getDataProject() async {
    setState(() {
      listProject.clear();
      listProject = [];
      isLoading = true;
    });
    try {
      await new Future.delayed(const Duration(seconds: 1));
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
        await new Future.delayed(const Duration(seconds: 1));

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
    setState(() {
      listHistory.clear();
      listHistory = [];
      isLoading = true;
    });
    try {
      await new Future.delayed(const Duration(seconds: 1));
      final participant =
          await http.get(url('api/history'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;
        listHistory.clear();
        listHistory = [];

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
        await new Future.delayed(const Duration(seconds: 1));

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

  Future<List<List>> getDataFriend() async {
    setState(() {
      listFriend.clear();
      listFriend = [];
      isLoading = true;
    });
    try {
      await new Future.delayed(const Duration(seconds: 1));

      final participant =
          await http.get(url('api/get_friendlist'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;
        listFriend.clear();
        listFriend = [];

        for (var i in project) {
          FriendList participant = FriendList(
            users: i['fl_users'],
            friend: i['fl_friend'],
            namafriend: i['us_name'],
            waktutambah: i['fl_added'],
            waktuditolak: i['fl_approved'],
            waktuditerima: i['fl_denied'],
            imageFriend: i['us_image'],
          );
          listFriend.add(participant);
        }
        await new Future.delayed(const Duration(seconds: 1));

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
    listFriend.clear();
    listProject.clear();
    super.dispose();
  }

  void _tambahteman() async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addadminevent = await http
          .post(url('api/tambah_teman'), headers: requestHeaders, body: {
        'email': _emailPenggunaController.text,
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        Fluttertoast.showToast(msg: addpesertaJson['message']);
        setState(() {
          _emailPenggunaController.text = '';
        });
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        getDataFriend();
      } else {
        setState(() {
          _emailPenggunaController.text = '';
        });
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      setState(() {
        _emailPenggunaController.text = '';
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        _emailPenggunaController.text = '';
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  void _deleteteman(friend) async {
    await progressApiAction.show();
    try {
      final deleteTemanUrl = await http
          .post(url('api/hapus_teman'), headers: requestHeaders, body: {
        'friend': friend.toString(),
      });

      if (deleteTemanUrl.statusCode == 200) {
        var deleteTemanUrJson = json.decode(deleteTemanUrl.body);
        if (deleteTemanUrJson['status'] == 'success') {
          Fluttertoast.showToast(msg: 'Berhasil!');
        }
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        getDataFriend();
      } else {
        print(deleteTemanUrl.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    progressApiAction = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);
    progressApiAction.style(
        message: 'Tunggu Sebentar...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.w600));

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
            ),
            child: Container(
              decoration: new BoxDecoration(
                  color: Colors.white,
                  borderRadius: new BorderRadius.only(
                    bottomLeft: const Radius.circular(18.0),
                    bottomRight: const Radius.circular(18.0),
                  )),
              // color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    // margin: EdgeInsets.all(8),
                    child: PopupMenuButton<PageEnum>(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      onSelected: (PageEnum value) {
                        switch (value) {
                          case PageEnum.editProfile:
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfileUserEdit()));
                            break;
                          case PageEnum.permintaanTeman:
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ConfirmationFriend()));
                            break;
                          default:
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          
                          value: PageEnum.editProfile,
                          child: Row(children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right:5.0),
                              child: Icon(
                                Icons.edit,
                                size: 14,
                                color:Colors.black54,
                              ),
                            ),
                            Text(
                              "Edit Data Akun",
                              style: TextStyle(color:Colors.black54,fontSize:14),
                            ),
                          ]
                              ),
                        ),
                      PopupMenuItem(
                          value: PageEnum.permintaanTeman,
                          child: Row(children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right:8.0),
                              child: Icon(
                                Icons.people,
                                size: 14,
                                color:Colors.black54,
                              ),
                            ),
                            Text(
                              "Permintaan Teman",
                              style: TextStyle(color:Colors.black54,fontSize:14),
                            ),
                          ]
                              ),
                      )])
                  ),
                  Center(
                      child: Container(
                    height: 60,
                    width: 60,
                    child: GestureDetector(
                      child: Hero(
                          tag: 'imageProfile',
                          child: ClipOval(
                              child: FadeInImage.assetNetwork(
                                  fit: BoxFit.cover,
                                  placeholder: 'images/imgavatar.png',
                                  image: imageData == null ||
                                          imageData == '' ||
                                          imageData == 'Tidak ditemukan'
                                      ? url('assets/images/imgavatar.png')
                                      : url(
                                          'storage/image/profile/$imageData')))),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) {
                          return DetailScreen(
                              tag: 'imageProfile',
                              url: imageData == null ||
                                      imageData == '' ||
                                      imageData == 'Tidak ditemukan'
                                  ? url('assets/images/imgavatar.png')
                                  : url('storage/image/profile/$imageData'));
                        }));
                      },
                    ),
                  )),
                  Center(
                    child: Container(
                        child: Padding(
                      padding:
                          const EdgeInsets.only(top: 8, left: 24, right: 24),
                      child: Text(
                        "$nameUser",
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ),
                  Center(
                      child: Container(
                    margin: EdgeInsets.only(top: 8),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(18.0),
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
                          text: 'Teman',
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
                  isLoading == true
                      ? listLoadingTodo()
                      : isError == true
                          ? errorSystemFilter(context)
                          : listProject.length == 0
                              ? RefreshIndicator(
                                  onRefresh: getHeaderHTTP,
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Column(children: <Widget>[
                                        new Container(
                                          width: 100.0,
                                          height: 100.0,
                                          child: Image.asset(
                                              "images/todo_icon2.png"),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 20.0,
                                              left: 25.0,
                                              right: 25.0,
                                              bottom: 35.0),
                                          child: Center(
                                            child: Text(
                                              "Project Yang Anda Cari Tidak Ditemukan",
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: getHeaderHTTP,
                                  child: SingleChildScrollView(
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
                                                              idproject:
                                                                  item.id,
                                                              namaproject:
                                                                  item.title)));
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
                                                                BorderRadius
                                                                    .circular(
                                                                        3))),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          border: Border(
                                                              right: BorderSide(
                                                                  color: item
                                                                      .colored,
                                                                  width: 5))),
                                                      child: ListTile(
                                                        leading: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(0.0),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        0.0),
                                                            child: Container(
                                                                height: 40.0,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                width: 40.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .white,
                                                                      width:
                                                                          2.0),
                                                                  color:
                                                                      primaryAppBarColor,
                                                                ),
                                                                child: Text(
                                                                  '${item.title[0].toUpperCase()}',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          18,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                )),
                                                          ),
                                                        ),
                                                        title: Text(
                                                            item.title == '' ||
                                                                    item.title ==
                                                                        null
                                                                ? 'To Do Tidak Diketahui'
                                                                : item.title,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            softWrap: true,
                                                            maxLines: 1,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500)),
                                                        subtitle: Text(
                                                            DateFormat('d MMM y')
                                                                    .format(DateTime
                                                                        .parse(
                                                                            "${item.start}"))
                                                                    .toString() +
                                                                ' - ' +
                                                                DateFormat(
                                                                        'd MMM y')
                                                                    .format(DateTime
                                                                        .parse(
                                                                            "${item.end}"))
                                                                    .toString(),
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1),
                                                      ),
                                                    ),
                                                  )),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  )),
                                ),
                  // LIST HISTORY
                  isError == true
                      ? Container()
                      : isLoading == true
                          ? listLoadingTodo()
                          : isError == true
                              ? errorSystemFilter(context)
                              : listHistory.length == 0
                                  ? RefreshIndicator(
                                      onRefresh: getDataHistory,
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 20.0),
                                          child: Column(children: <Widget>[
                                            new Container(
                                              width: 100.0,
                                              height: 100.0,
                                              child: Image.asset(
                                                  "images/todo_icon2.png"),
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
                                        ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: getDataHistory,
                                      child: SingleChildScrollView(
                                          physics:
                                              AlwaysScrollableScrollPhysics(),
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
                                                                      idtodo: item
                                                                          .id,
                                                                      namatodo:
                                                                          item.title)));
                                                    },
                                                    child: Container(
                                                      child: Card(
                                                          elevation: 0.5,
                                                          margin:
                                                              EdgeInsets.only(
                                                                  top: 5.0,
                                                                  bottom: 5.0,
                                                                  left: 0.0,
                                                                  right: 0.0),
                                                          child: ClipPath(
                                                            clipper: ShapeBorderClipper(
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            3))),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  border: Border(
                                                                      right: BorderSide(
                                                                          color: Colors
                                                                              .green,
                                                                          width:
                                                                              5))),
                                                              child: ListTile(
                                                                leading:
                                                                    Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          0.0),
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            100.0),
                                                                    child: Container(
                                                                        height: 40.0,
                                                                        alignment: Alignment.center,
                                                                        width: 40.0,
                                                                        decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                              color: Colors.white,
                                                                              width: 2.0),
                                                                          borderRadius: BorderRadius.all(
                                                                              Radius.circular(100.0) //                 <--- border radius here
                                                                              ),
                                                                          color:
                                                                              primaryAppBarColor,
                                                                        ),
                                                                        child: Text(
                                                                          '${item.title[0].toUpperCase()}',
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.bold),
                                                                        )),
                                                                  ),
                                                                ),
                                                                title: Text(
                                                                    item.title ==
                                                                                '' ||
                                                                            item.title ==
                                                                                null
                                                                        ? 'To Do Tidak Diketahui'
                                                                        : item
                                                                            .title,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    softWrap:
                                                                        true,
                                                                    maxLines: 1,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500)),
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
                                                                    softWrap:
                                                                        true,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines:
                                                                        1),
                                                              ),
                                                            ),
                                                          )),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          )),
                                    ),
                  // LIST Friend
                  isError == true
                      ? Container()
                      : isLoading == true
                          ? listLoadingTodo()
                          : isError == true
                              ? errorSystemFilter(context)
                              : listFriend.length == 0
                                  ? RefreshIndicator(
                                      onRefresh: getDataFriend,
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 20.0),
                                          child: Column(children: <Widget>[
                                            new Container(
                                              width: 100.0,
                                              height: 100.0,
                                              child: Image.asset(
                                                  "images/todo_icon2.png"),
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
                                        ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: getDataFriend,
                                      child: SingleChildScrollView(
                                          physics:
                                              AlwaysScrollableScrollPhysics(),
                                          child: Column(
                                            children: listFriend
                                                .map(
                                                  (FriendList item) => InkWell(
                                                    onTap: () async {},
                                                    child: Container(
                                                      child: Card(
                                                          elevation: 0.5,
                                                          margin:
                                                              EdgeInsets.only(
                                                                  top: 5.0,
                                                                  bottom: 5.0,
                                                                  left: 0.0,
                                                                  right: 0.0),
                                                          child: ClipPath(
                                                            clipper: ShapeBorderClipper(
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            3))),
                                                            child: Container(
                                                              child: ListTile(
                                                                leading:
                                                                    Container(
                                                                  height: 40.0,
                                                                  width: 40.0,
                                                                  child:
                                                                      ClipOval(
                                                                          child:
                                                                              FadeInImage.assetNetwork(
                                                                    placeholder:
                                                                        'images/loading.gif',
                                                                    image: item.imageFriend ==
                                                                                null ||
                                                                            item.imageFriend ==
                                                                                ''
                                                                        ? url(
                                                                            'assets/images/imgavatar.png')
                                                                        : url(
                                                                            'storage/image/profile/${item.imageFriend}'),
                                                                  )),
                                                                ),
                                                                trailing: buttonFriend(
                                                                    item.waktuditerima,
                                                                    item.friend),
                                                                title: Text(
                                                                    item.namafriend ==
                                                                                '' ||
                                                                            item.namafriend ==
                                                                                null
                                                                        ? 'Teman Tidak Diketahui'
                                                                        : item
                                                                            .namafriend,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    softWrap:
                                                                        true,
                                                                    maxLines: 1,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500)),
                                                                subtitle: statusFriend(
                                                                    item.waktuditerima,
                                                                    item.waktuditolak),
                                                              ),
                                                            ),
                                                          )),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          )),
                                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _bottomButtons(),
    );
  }

  Widget statusFriend(terima, tolak) {
    String textStatus;
    Color statusColor;
    if (terima == null && tolak == null) {
      textStatus = 'Belum Dikonfirmasi';
      statusColor = Colors.grey;
    } else if (terima != null) {
      textStatus = 'Terdaftar Sebagai Teman';
      statusColor = Colors.green;
    } else if (tolak != null) {
      textStatus = 'Pertemanan Ditolak';
      statusColor = Colors.red;
    } else {
      textStatus = 'Status Tidak Diketahui';
      statusColor = Colors.grey;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      child: Text(textStatus,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
    );
  }

  Widget buttonFriend(terima, friend) {
    if (terima != null) {
      return ButtonTheme(
          minWidth: 0,
          height: 0,
          child: RaisedButton(
            elevation: 0,
            padding: EdgeInsets.all(0),
            color: Colors.white,
            child: Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('Peringatan!'),
                  content: Text('Apakah Anda Ingin Menghapus Teman Ini ? '),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Tidak'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    FlatButton(
                      textColor: Colors.green,
                      child: Text('Ya'),
                      onPressed: () async {
                        Navigator.pop(context);
                        _deleteteman(friend);
                      },
                    )
                  ],
                ),
              );
            },
          ));
    } else {
      return null;
    }
  }

  void _showmodalcreatefriend() {
    setState(() {
      _emailPenggunaController.text = '';
    });
    showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            contentPadding: EdgeInsets.only(top: 10.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          "Tambah Teman",
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _emailPenggunaController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          border: OutlineInputBorder(),
                          hintText: 'Email Pengguna',
                          hintStyle:
                              TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        String emailValid = _emailPenggunaController.text;
                        final bool isValid =
                            EmailValidator.validate(emailValid);
                        if (_emailPenggunaController.text == '') {
                          Fluttertoast.showToast(
                              msg: 'Email Tidak Boleh Kosong');
                        } else if (!isValid) {
                          Fluttertoast.showToast(msg: 'Email Harus Valid');
                        } else {
                          _tambahteman();
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.all(10.0),
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: primaryAppBarColor,
                        ),
                        child: Text(
                          "Tambahkan",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _bottomButtons() {
    return _tabController.index == 2
        ? DraggableFab(
            child: FloatingActionButton(
                shape: StadiumBorder(),
                onPressed: () async {
                  _showmodalcreatefriend();
                },
                backgroundColor: Color.fromRGBO(254, 86, 14, 1),
                child: Icon(
                  Icons.add,
                  size: 20.0,
                )))
        : null;
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
                // getHeaderHTTP();
                _tabController.index == 0
                    ? getHeaderHTTP()
                    : _tabController.index == 1
                        ? getDataHistory()
                        : getDataFriend();
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

class DetailScreen extends StatefulWidget {
  final String tag;
  final String url;

  DetailScreen({Key key, @required this.tag, @required this.url})
      : assert(tag != null),
        assert(url != null),
        super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  void dispose() {
    //SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        child: Center(
          child: Hero(
            tag: widget.tag,
            child: FadeInImage.assetNetwork(
              placeholder: 'images/imgavatar.png',
              image: widget.url,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
