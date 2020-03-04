import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/models/attachment.dart';
import 'package:todolist_app/src/models/user.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/pages/dashboard.dart';

String radioItem = 'Admin';
enum PageEnum { editPeserta, hapusPeserta }

class AddUserFileTodo extends StatefulWidget {
  final idTodo;
  AddUserFileTodo({Key key, this.idTodo});
  @override
  _AddUserFileTodoState createState() => _AddUserFileTodoState();
}

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _AddUserFileTodoState extends State<AddUserFileTodo>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  bool isLoading, isError, isAccess, isFilter, isErrorfilter, isCreate;
  String tokenType, accessToken;
  final _debouncer = Debouncer(milliseconds: 500);
  List<User> listUserItem = [];
  List<User> listFilterItem = [];
  List<Attachment> listAttachmentItem = [];
  ProgressDialog progressApiAction;
  String userID;
  FileType _pickingType;
  bool _hasValidMime = false;
  Map<String, String> requestHeaders = Map();
  TextEditingController _searchQuery = new TextEditingController();
  String pathname;
  String fileImage;
  String filename;

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var userId = await storage.getDataString('id');
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    userID = userId;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return listUser(1);
  }

  Future<List<List>> listUser(access) async {
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
    listUserItem.clear();
    try {
      final getUser = await http.get(
        url('api/todo/peserta/${widget.idTodo}/$access'),
        headers: requestHeaders,
      );
      print(widget.idTodo);

      if (getUser.statusCode == 200) {
        var listuserJson = json.decode(getUser.body);
        var listUsers = listuserJson['users'];
        var roleUser = listuserJson['roleUser'];
        listUserItem = [];
        for (var i in listUsers) {
          User willcomex = User(
              id: i['id'],
              name: i['name'],
              email: i['email'],
              todo: i['todo'],
              owner: i['owner'],
              access: i['access']);
          listUserItem.add(willcomex);

          if (roleUser == 1 || roleUser == 2) {
            setState(() {
              isAccess = true;
            });
          } else {
            setState(() {
              isAccess = false;
            });
          }
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
        listAttachment();
      } else if (getUser.statusCode == 401) {
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
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> listUserfilter() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      isFilter = true;
    });
    listFilterItem.clear();
    try {
      final getUserFilter = await http.get(
        url('api/todo/search/peserta?email=${_searchQuery.text}'),
        headers: requestHeaders,
      );

      if (getUserFilter.statusCode == 200) {
        var listUsers = json.decode(getUserFilter.body);
        // var listUsers = listuserJson['participant'];
        print(getUserFilter.statusCode);
        print(json.decode(getUserFilter.body));
        for (var i in listUsers) {
          User willcomex = User(id: i['id'], name: i['name'], email: i['email']
              // image: i['us_image'],
              );
          listFilterItem.add(willcomex);
        }
        setState(() {
          isFilter = false;
          isErrorfilter = false;
          isLoading = false;
          isError = false;
        });
      } else if (getUserFilter.statusCode == 401) {
        setState(() {
          isFilter = false;
          isErrorfilter = true;
          isLoading = false;
          isError = false;
        });
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
      } else {
        setState(() {
          isFilter = false;
          isErrorfilter = true;
          isLoading = false;
          isError = false;
        });
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isFilter = false;
        isErrorfilter = true;
        isLoading = false;
        isError = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      // setState(() {
      //   isFilter = false;
      //   isErrorfilter = true;
      //   isLoading = false;
      //   isError = false;
      // });
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> listAttachment() async {
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
    listAttachmentItem.clear();
    try {
      final getUser = await http.get(
        url('api/todo/attachment/${widget.idTodo}'),
        headers: requestHeaders,
      );
      print(widget.idTodo);

      if (getUser.statusCode == 200) {
        var listUsers = json.decode(getUser.body);
        // var listUsers = listuserJson['users'];
        // var idOwner = listuserJson['idowner'];
        for (var i in listUsers) {
          Attachment willcomex =
              Attachment(id: i['id'], path: i['path'], todo: i['todo']);
          listAttachmentItem.add(willcomex);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getUser.statusCode == 401) {
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
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      debugPrint('$e');
    }
    return null;
  }

  void _tambahpeserta(idpeserta) async {
    await progressApiAction.show();
    try {
      Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
      final addpeserta = await http
          .post(url('api/todo/peserta/create'), headers: requestHeaders, body: {
        'todo': widget.idTodo.toString(),
        'user': idpeserta.toString(),
        'role': radioItem.toString(),
        'own': 'T'
      });

      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          getHeaderHTTP();
          setState(() {
            isCreate = false;
          });
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
          listUserItem.clear();
        } else if (addpesertaJson['status'] == 'owner') {
          Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else if (addpesertaJson['status'] == 'exists') {
          Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Status Tidak Diketahui");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
          setState(() {
            isCreate = false;
          });
        }
      } else {
        print(addpeserta.body);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
        setState(() {
          isCreate = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      print(e);
    }
  }

  void _tambahFile() async {
    await progressApiAction.show();
    try {
      Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
      final addpeserta = await http
          .post(url('api/todo/attachment'), headers: requestHeaders, body: {
        'file64': fileImage.toString(),
        'pathname': pathname,
        'filename': filename,
        'todolist': widget.idTodo.toString(),
      });
      print(widget.idTodo.toString());
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          getHeaderHTTP();
          setState(() {
            pathname = '';
            isCreate = false;
          });
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'owner') {
          Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else if (addpesertaJson['status'] == 'exists') {
          Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Status Tidak Diketahui");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
          setState(() {
            isCreate = false;
          });
        }
      } else {
        print(addpeserta.body);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
        setState(() {
          isCreate = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      print(e);
    }
  }

  void deleteFile(int index, int id) async {
    await progressApiAction.show();
    try {
      Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
      final addpeserta = await http.delete(
        url('api/todo/attachment/$id'),
        headers: requestHeaders,
      );

      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          listAttachmentItem.removeAt(index);
          setState(() {
            pathname = '';
            isCreate = false;
          });
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'owner') {
          Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else if (addpesertaJson['status'] == 'exists') {
          Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Status Tidak Diketahui");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
          setState(() {
            isCreate = false;
          });
        }
      } else {
        print(addpeserta.body);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
        setState(() {
          isCreate = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      print(e);
    }
  }

  void deletePeserta(index) async {
    await progressApiAction.show();
    try {
      final removeConfirmation = await http.delete(
          url('api/todo/peserta/delete/${listUserItem[index].id.toString()}/${listUserItem[index].todo.toString()}'),
          headers: requestHeaders);
      print(removeConfirmation);
      if (removeConfirmation.statusCode == 200) {
        var removeConfirmationJson = json.decode(removeConfirmation.body);
        if (removeConfirmationJson['status'] == 'success') {
          setState(() {
            listUserItem.remove(listUserItem[index]);
          });

          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (removeConfirmationJson['status'] == 'Error') {
          Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Lagi");
          progressApiAction.hide().then((isHidden) {});
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Lagi");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}'");
      progressApiAction.hide().then((isHidden) {});
      print(e);
    }
  }

  @override
  void initState() {
    getHeaderHTTP();
    _searchQuery.text = '';
    _tabController = TabController(
        length: 2, vsync: _AddUserFileTodoState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    super.initState();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    super.dispose();
  }

  Future<bool> _willPopCallback() async {
    // await showDialog or Show add banners or whatever
    // then
    return false; // return true if the route to be popped
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
    return WillPopScope(
        onWillPop: () => _willPopCallback(),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryAppBarColor,
            title: Text('Tambah Peserta Dan Document',
                style: TextStyle(
                  fontSize: 14,
                )),
            automaticallyImplyLeading: false,
            actions: <Widget>[
              IconButton(
                onPressed: () async {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => Dashboard()),
                      ModalRoute.withName('/'));
                },
                icon: Icon(Icons.check),
              )
            ],
          ),
          body: Container(
            child: Stack(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: primaryAppBarColor,
                    indicatorWeight: 2.0,
                    tabs: [
                      Tab(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5.0, bottom: 5.0),
                              child: Text('Peserta',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black38)),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5.0, bottom: 5.0),
                              child: Text('Tambah Attachment',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black38)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 60.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Container(
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              isLoading == true
                                  ? _loadingview()
                                  : Column(
                                      children: <Widget>[
                                        isError == true
                                            ? Container(
                                                color: Colors.white,
                                                margin: EdgeInsets.only(
                                                    top: 0.0,
                                                    left: 10.0,
                                                    right: 10.0),
                                                padding: const EdgeInsets.only(
                                                    top: 10.0, bottom: 15.0),
                                                child: RefreshIndicator(
                                                  onRefresh: () =>
                                                      getHeaderHTTP(),
                                                  child:
                                                      Column(children: <Widget>[
                                                    new Container(
                                                      width: 100.0,
                                                      height: 100.0,
                                                      child: Image.asset(
                                                          "images/system-eror.png"),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        top: 30.0,
                                                        left: 15.0,
                                                        right: 15.0,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Gagal memuat halaman, tekan tombol muat ulang halaman untuk refresh halaman",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black54,
                                                            height: 1.5,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 15.0,
                                                              left: 15.0,
                                                              right: 15.0,
                                                              bottom: 15.0),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        child: RaisedButton(
                                                          color: Colors.white,
                                                          textColor:
                                                              primaryAppBarColor,
                                                          disabledColor:
                                                              Colors.grey,
                                                          disabledTextColor:
                                                              Colors.black,
                                                          padding:
                                                              EdgeInsets.all(
                                                                  15.0),
                                                          onPressed: () async {
                                                            // getDataProject();
                                                          },
                                                          child: Text(
                                                            "Muat Ulang Halaman",
                                                            style: TextStyle(
                                                                fontSize: 14.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.white,
                                                margin: EdgeInsets.only(
                                                  top: 0.0,
                                                ),
                                                child: SingleChildScrollView(
                                                  child: Container(
                                                    child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          for (int item = 0;
                                                              item <
                                                                  listUserItem
                                                                      .length;
                                                              item++)
                                                            Card(
                                                                elevation: 0.6,
                                                                child: ListTile(
                                                                    title: Text(
                                                                        listUserItem[item].name == '' || listUserItem[item].name == null
                                                                            ? 'Nama Peserta Tidak Diketahui'
                                                                            : listUserItem[item]
                                                                                .name,
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        softWrap:
                                                                            true,
                                                                        maxLines:
                                                                            1,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight: FontWeight
                                                                                .w500)),
                                                                    trailing: isAccess ==
                                                                            false
                                                                        ? Icon(Icons
                                                                            .lock)
                                                                        : PopupMenuButton<
                                                                            PageEnum>(
                                                                            onSelected:
                                                                                (PageEnum value) {
                                                                              switch (value) {
                                                                                case PageEnum.editPeserta:
                                                                                  dialogAddPermision(item);
                                                                                  break;

                                                                                case PageEnum.hapusPeserta:
                                                                                  showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) => AlertDialog(
                                                                                      title: Text('Peringatan!'),
                                                                                      content: Text("Apakah Anda Yakin?"),
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
                                                                                            setState(() {
                                                                                              isCreate = true;
                                                                                            });
                                                                                            Navigator.pop(context);
                                                                                            deletePeserta(item);
                                                                                          },
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  );

                                                                                  break;
                                                                                default:
                                                                              }
                                                                            },
                                                                            itemBuilder: (context) =>
                                                                                [
                                                                              PopupMenuItem(
                                                                                value: PageEnum.editPeserta,
                                                                                child: Text("Edit"),
                                                                              ),
                                                                              PopupMenuItem(
                                                                                value: PageEnum.hapusPeserta,
                                                                                child: Text("Hapus"),
                                                                              ),
                                                                            ],
                                                                          )

                                                                    // subtitle:
                                                                    //     Text(
                                                                    //   '${item.start} - ${item.end}',
                                                                    //   style: TextStyle(fontSize:12),
                                                                    //   overflow:
                                                                    //       TextOverflow
                                                                    //           .ellipsis,
                                                                    //   softWrap:
                                                                    //       true,
                                                                    //   maxLines:
                                                                    //       1,
                                                                    // ),
                                                                    ))
                                                        ]),
                                                  ),
                                                )),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              isLoading == true
                                  ? _loadingview()
                                  : Column(
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.all(15.0),
                                          color: Colors.white,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              for (int item = 0;
                                                  item <
                                                      listAttachmentItem.length;
                                                  item++)
                                                Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: 10.0),
                                                    child: Card(
                                                      child: ListTile(
                                                        leading: Icon(
                                                          Icons
                                                              .insert_drive_file,
                                                          color: Colors.red,
                                                        ),
                                                        title: Text(
                                                          "${listAttachmentItem[item].path}",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                              fontSize: 14),
                                                        ),
                                                        trailing:
                                                            isAccess == false
                                                                ? Icon(
                                                                    Icons.lock)
                                                                : ButtonTheme(
                                                                    minWidth: 0,
                                                                    height: 0,
                                                                    child: FlatButton(
                                                                        padding: EdgeInsets.all(0),
                                                                        onPressed: () {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder: (BuildContext context) =>
                                                                                AlertDialog(
                                                                              title: Text('Peringatan!'),
                                                                              content: Text("Apakah Anda Yakin?"),
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
                                                                                    setState(() {
                                                                                      isCreate = true;
                                                                                    });
                                                                                    Navigator.pop(context);
                                                                                    deleteFile(item, listAttachmentItem[item].id);
                                                                                  },
                                                                                )
                                                                              ],
                                                                            ),
                                                                          );
                                                                        },
                                                                        child: Icon(Icons.delete, color: Colors.red)),
                                                                  ),
                                                      ),
                                                    )),
                                              Divider(),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isAccess == false
              ? Container()
              : FloatingActionButton(
                  backgroundColor: primaryAppBarColor,
                  onPressed: () {
                    _tabController.index == 0
                        ? showModalAddPeserta()
                        : showModalAddFile();
                  },
                  child: Icon(Icons.add),
                ),
        ));
  }

  void _openFileExplorer() async {
    if (_pickingType != FileType.CUSTOM || _hasValidMime) {
      // setState(() => _loadingPath = true);
      try {
        //  _path = await FilePicker. getFilePath(
        //     type: _pickingType, fileExtension: _extension,);
        File file = await FilePicker.getFile(type: FileType.ANY);
        setState(() {
          pathname = file.toString();
          fileImage = base64Encode(file.readAsBytesSync());
          filename = file.toString().split('/').last;

          // _loadingPath = false;
        });
        // print("Extensi");
        // print(file.toString().split('/').last);

      } on PlatformException catch (e) {
        print("Unsupported operation" + e.toString());
      }
      if (!mounted) return;
      // setState(() {
      //   _loadingPath = false;
      //   _fileName = _path != null
      //       ? _path.split('/').last
      //       : _paths != null ? _paths.keys.toString() : '...';
      // });
    }
  }

  void showModalAddPeserta() {
    setState(() {
      _searchQuery.text = '';
      listFilterItem.clear();
    });

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 400 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 5.0,
                left: 5.0,
                top: 40.0),
            child: Column(children: <Widget>[
              TextFormField(
                autofocus: true,
                controller: _searchQuery,
                onChanged: (string) {
                  if (string != null || string != '') {
                    _debouncer.run(() {
                      listUserfilter();
                    });
                  }
                },
                decoration: InputDecoration(
                    prefixIcon: isFilter == true
                        ? SizedBox(
                            child: CircularProgressIndicator(),
                            height: 1.0,
                            width: 1.0,
                          )
                        : Icon(Icons.search),
                    hintText: "Cari ...",
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(25.0),
                      borderSide: new BorderSide(),
                    )),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: <Widget>[
                    for (int index = 0; index < listFilterItem.length; index++)
                      listFilterItem[index].access == 'Owner'
                          ? Container()
                          : listFilterItem[index].access == null
                              ? InkWell(
                                  child: Container(
                                    child: Card(
                                        color: listFilterItem[index].access ==
                                                'Owner'
                                            ? Colors.grey[200]
                                            : Colors.white,
                                        child: ListTile(
                                          title: Text(
                                              listFilterItem[index].name == null
                                                  ? 'Unknown Nama'
                                                  : listFilterItem[index].name),
                                          subtitle: Text(listFilterItem[index]
                                                      .email ==
                                                  null
                                              ? 'Unknown Email'
                                              : listFilterItem[index].email),
                                          trailing: listFilterItem[index]
                                                      .access !=
                                                  null
                                              ? listFilterItem[index].access ==
                                                      'Owner'
                                                  ? Icon(Icons.lock_outline)
                                                  : Container(
                                                      child: Text(
                                                        listFilterItem[index]
                                                            .access
                                                            .toUpperCase(),
                                                      ),
                                                    )
                                              : Icon(Icons.add),
                                        )),
                                  ),
                                  onTap: isCreate == true
                                      ? null
                                      : () async {
                                          listFilterItem[index].access ==
                                                  'Owner'
                                              ? Fluttertoast.showToast(
                                                  msg:
                                                      "Owner Tidak Dapat Diubah")
                                              : isAccess != true
                                                  ? Fluttertoast.showToast(
                                                      msg:
                                                          "Anda Tidak Memiliki Akses")
                                                  : showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                        title: Text(
                                                            'Pilih Hak Akses!'),
                                                        content: RadioGroup(),
                                                        actions: <Widget>[
                                                          FlatButton(
                                                            child:
                                                                Text('Tidak'),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          FlatButton(
                                                            textColor:
                                                                Colors.green,
                                                            child: Text('Ya'),
                                                            onPressed:
                                                                () async {
                                                              setState(() {
                                                                isCreate = true;
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                              _tambahpeserta(
                                                                  listFilterItem[
                                                                          index]
                                                                      .id);
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    );
                                        },
                                )
                              : Container()
                  ]),
                ),
              ),
            ]),
          );
        });
  }

  void showModalAddFile() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 200 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 5.0,
                left: 5.0,
                top: 20.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("Tambahkan File"),
                  Divider(),
                  Row(
                    children: <Widget>[
                      FlatButton(
                        onPressed: () {
                          _openFileExplorer();
                        },
                        child: Text("Pilih File : "),
                      ),
                      pathname != null
                          ? Flexible(
                              child: Text(
                              "$pathname",
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ))
                          : Container()
                    ],
                  ),
                  Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FlatButton(
                      color: primaryAppBarColor,
                      onPressed: () {
                        _tambahFile();
                      },
                      child: Text(
                        "Simpan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ]),
          );
        });
  }

  void dialogAddPermision(index) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Pilih Hak Akses!'),
        content: RadioGroup(),
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
              setState(() {
                isCreate = true;
              });
              Navigator.pop(context);
              _tambahpeserta(listFilterItem[index].id);
            },
          )
        ],
      ),
    );
  }

  Widget _loadingview() {
    return Container(
        color: Colors.white,
        margin: EdgeInsets.only(
          top: 0.0,
        ),
        padding: EdgeInsets.all(15.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3, 4, 5]
                  .map((_) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(bottom: 25.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(100.0)),
                                  ),
                                  width: 35.0,
                                  height: 35.0,
                                ),
                                Expanded(
                                  flex: 9,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(left: 15.0),
                                        width: double.infinity,
                                        height: 10.0,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(
                                            left: 15.0, top: 15.0),
                                        width: 100.0,
                                        height: 10.0,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        )));
  }
}

class RadioGroup extends StatefulWidget {
  @override
  RadioGroupWidget createState() => RadioGroupWidget();
}

class RoleList {
  String name;
  int index;
  RoleList({this.name, this.index});
}

class RadioGroupWidget extends State {
  // Default Radio Button Item

  // Group Value for Radio Button.
  int id = 1;

  List<RoleList> fList = [
    RoleList(
      index: 1,
      name: "Admin",
    ),
    RoleList(
      index: 2,
      name: "Executor",
    ),
    RoleList(
      index: 3,
      name: "Viewer",
    )
  ];

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        child: Column(
          children: fList
              .map((data) => RadioListTile(
                    title: Text("${data.name}"),
                    groupValue: id,
                    value: data.index,
                    onChanged: (val) {
                      setState(() {
                        radioItem = data.name;
                        id = data.index;
                      });
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
