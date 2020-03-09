import 'dart:io';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';

//import file kebutuhan auth
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';

//import model detail todo
import 'package:todolist_app/src/model/TodoMember.dart';
import 'package:todolist_app/src/model/TodoActivity.dart';
import 'package:todolist_app/src/model/TodoAttachment.dart';
import 'edit_todo.dart';

//import model  todo action, ready, done, normal
import 'package:todolist_app/src/model/TodoAction.dart';
import 'package:todolist_app/src/model/TodoNormal.dart';
import 'package:todolist_app/src/model/TodoReady.dart';
import 'package:todolist_app/src/model/TodoDone.dart';

//import package package pendukung
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

String tokenType, accessToken;
String textValue;
Map<String, String> requestHeaders = Map();

class ManajemenDetailTodo extends StatefulWidget {
  ManajemenDetailTodo({Key key, this.idtodo, this.namatodo, this.platform})
      : super(key: key);
  final int idtodo;
  final String namatodo;
  final TargetPlatform platform;
  @override
  State<StatefulWidget> createState() {
    return _ManajemenDetailTodoState();
  }
}

class _ManajemenDetailTodoState extends State<ManajemenDetailTodo>
    with SingleTickerProviderStateMixin {
  int _value;
  List<MemberTodo> todoMemberDetail = [];
  List<TodoActivity> todoActivityDetail = [];
  List<FileTodo> todoAttachmentDetail = [];
  List<ToDoNormal> listTodoNormal = [];
  List<ToDoDone> listTodoDone = [];
  List<ToDoReady> listTodoReady = [];
  List<ToDoAction> listTodoAction = [];
  int minimalRealisasi, currentIndex;
  bool isLoading,
      isError,
      isLoadingTodoAll,
      isErrorTodoAll,
      isLoadingActivity,
      isErrorActivity;
  ProgressDialog progressApiAction;
  String projectPercent;
  TabController _tabController;
  TextEditingController _titleTodoListAction = TextEditingController();
  TextEditingController _catatanrealisasiController = TextEditingController();
  Map dataTodo, dataStatusKita;
  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  @override
  void initState() {
    super.initState();
    getHeaderHTTP();
    textValue = null;
    _value = 1;
    minimalRealisasi = 1;
    currentIndex = 0;
    projectPercent = '0';
    _tabController = TabController(
        length: 6,
        vsync: _ManajemenDetailTodoState(),
        initialIndex: currentIndex);
    _tabController.addListener(_handleTabIndex);
  }

  void _handleTabIndex() {
    setState(() {
      currentIndex = _tabController.index;
    });
    new Timer(new Duration(seconds: 1), () {
      if (_tabController.index == 3) {
        setState(() {
          listTodoReadyData();
        });
      } else if (_tabController.index == 2) {
        setState(() {
          listTodoActionData();
        });
      } else if (_tabController.index == 4) {
        setState(() {
          listTodoNormalData();
        });
      } else if (_tabController.index == 5) {
        setState(() {
          listTodoDoneData();
        });
      } else if (_tabController.index == 0) {
        setState(() {
          getHeaderHTTP();
        });
      } else if (_tabController.index == 1) {
        todoActivity();
      }
    });
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return detailProject();
  }

  Future<List<List>> detailProject() async {
    setState(() {
      isLoading = true;
    });
    try {
      final getDetailProject = await http
          .post(url('api/detail_todo'), headers: requestHeaders, body: {
        'todolist': widget.idtodo.toString(),
      });

      if (getDetailProject.statusCode == 200) {
        setState(() {
          todoMemberDetail.clear();
          todoMemberDetail = [];
          todoActivityDetail.clear();
          todoActivityDetail = [];
          todoAttachmentDetail.clear();
          todoAttachmentDetail = [];
        });
        var getDetailProjectJson = json.decode(getDetailProject.body);
        var members = getDetailProjectJson['todo_member'];
        var filetodos = getDetailProjectJson['todo_file'];
        Map rawTodo = getDetailProjectJson['todo'];
        Map rawStatusKita = getDetailProjectJson['status_kita'];
        if (mounted) {
          setState(() {
            dataTodo = rawTodo;
            dataStatusKita = rawStatusKita;
            minimalRealisasi = rawTodo['tl_progress'];
          });
        }

        for (var i in members) {
          MemberTodo member = MemberTodo(
            iduser: i['tlr_users'],
            name: i['us_name'],
            email: i['us_email'],
            roleid: i['tlr_role'].toString(),
            image: i['us_image'],
          );
          todoMemberDetail.add(member);
        }

        for (var t in filetodos) {
          FileTodo files = FileTodo(
            id: t['id'],
            path: t['path'],
            filename: t['filename'],
          );
          todoAttachmentDetail.add(files);
        }
        new Timer(new Duration(seconds: 2), () {
          setState(() {
            isLoading = false;
            isError = false;
          });
        });
      } else if (getDetailProject.statusCode == 401) {
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
        print(getDetailProject.body);
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
      Fluttertoast.showToast(msg: "error, silahkan coba kembali");
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> todoActivity() async {
    setState(() {
      isLoadingActivity = true;
    });
    try {
      final getDetailProject = await http
          .post(url('api/todo_activity'), headers: requestHeaders, body: {
        'todolist': widget.idtodo.toString(),
      });

      if (getDetailProject.statusCode == 200) {
        setState(() {
          todoActivityDetail.clear();
          todoActivityDetail = [];
        });
        var getDetailProjectJson = json.decode(getDetailProject.body);

        var activitys = getDetailProjectJson;

        for (var t in activitys) {
          TodoActivity todo = TodoActivity(
              id: t['tll_id'],
              name: t['us_name'],
              email: t['us_email'],
              image: t['us_image'],
              activity: t['tlt_activity'],
              progress: t['tlt_progress'].toString(),
              note: t['tlt_note'],
              updateat: DateFormat("dd MMM yyyy HH:mm:ss")
                  .format(DateTime.parse(t['tlt_created'])));
          todoActivityDetail.add(todo);
        }
        new Timer(new Duration(seconds: 2), () {
          setState(() {
            isLoadingActivity = false;
            isErrorActivity = false;
          });
        });
      } else if (getDetailProject.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoadingActivity = false;
          isErrorActivity = true;
        });
      } else {
        setState(() {
          isLoadingActivity = false;
          isErrorActivity = true;
        });
        print(getDetailProject.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoadingActivity = false;
        isErrorActivity = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoadingActivity = false;
        isErrorActivity = true;
      });
      Fluttertoast.showToast(msg: "error, silahkan coba kembali");
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> listTodoReadyData() async {
    setState(() {
      isLoadingTodoAll = true;
      listTodoReady.clear();
      listTodoReady = [];
    });
    try {
      final getTodoReadyurl = await http.get(
        url('api/todo/todo_ready/${widget.idtodo}'),
        headers: requestHeaders,
      );

      if (getTodoReadyurl.statusCode == 200) {
        setState(() {
          listTodoReady.clear();
          listTodoReady = [];
        });
        var getTodoReadyurlJson = json.decode(getTodoReadyurl.body);
        print(getTodoReadyurlJson);
        var members = getTodoReadyurlJson['todo_ready'];

        for (var i in members) {
          ToDoReady member = ToDoReady(
            idtodo: i['tlr_todolist'],
            number: i['tlr_number'],
            title: i['tlr_title'],
            created: i['tlr_title'],
            selesai: i['tlr_executed'],
            validation: i['tlr_validation'],
          );
          listTodoReady.add(member);
        }
        new Timer(new Duration(seconds: 2), () {
          setState(() {
            isLoadingTodoAll = false;
            isErrorTodoAll = false;
          });
        });
      } else if (getTodoReadyurl.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
      } else {
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
        print(getTodoReadyurl.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "error, silahkan coba kembali");
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> listTodoDoneData() async {
    setState(() {
      isLoadingTodoAll = true;
      listTodoDone.clear();
      listTodoDone = [];
    });
    try {
      final getTodoDoneyurl = await http.get(
        url('api/todo/todo_done/${widget.idtodo}'),
        headers: requestHeaders,
      );

      if (getTodoDoneyurl.statusCode == 200) {
        setState(() {
          listTodoDone.clear();
          listTodoDone = [];
        });
        var getTodoDoneyurlJson = json.decode(getTodoDoneyurl.body);
        print(getTodoDoneyurlJson);
        var dones = getTodoDoneyurlJson['todo_done'];

        for (var i in dones) {
          ToDoDone donex = ToDoDone(
            idtodo: i['tld_todolist'],
            number: i['tld_number'],
            title: i['tld_title'],
            created: i['tld_title'],
            selesai: i['tld_executed'],
            validation: i['tld_validation'],
          );
          listTodoDone.add(donex);
        }
        new Timer(new Duration(seconds: 2), () {
          setState(() {
            isLoadingTodoAll = false;
            isErrorTodoAll = false;
          });
        });
      } else if (getTodoDoneyurl.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
      } else {
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
        print(getTodoDoneyurl.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "error, silahkan coba kembali");
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> listTodoActionData() async {
    setState(() {
      listTodoAction.clear();
      listTodoAction = [];
    });
    setState(() {
      isLoadingTodoAll = true;
    });
    try {
      final getTodoActionUrl = await http.get(
          url('api/todo/list/actions/${widget.idtodo}'),
          headers: requestHeaders);

      if (getTodoActionUrl.statusCode == 200) {
        setState(() {
          listTodoAction.clear();
          listTodoAction = [];
        });
        var getTodoActionUrlJson = json.decode(getTodoActionUrl.body);
        var actions = getTodoActionUrlJson;
        print(actions);
        for (var i in actions) {
          ToDoAction participant = ToDoAction(
              idtodo: i['todo'],
              number: i['id'],
              title: i['title'].toString(),
              created: i['created'],
              selesai: i['done'],
              validation: i['valid']);
          listTodoAction.add(participant);
        }

        new Timer(new Duration(seconds: 2), () {
          setState(() {
            isLoadingTodoAll = false;
            isErrorTodoAll = false;
          });
        });
      } else if (getTodoActionUrl.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
      } else {
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
        print(getTodoActionUrl.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> listTodoNormalData() async {
    setState(() {
      isLoadingTodoAll = true;
      listTodoNormal.clear();
      listTodoNormal = [];
    });
    try {
      final getTodoNormalurl = await http.get(
        url('api/todo/todo_normal/${widget.idtodo}'),
        headers: requestHeaders,
      );

      if (getTodoNormalurl.statusCode == 200) {
        setState(() {
          listTodoNormal.clear();
          listTodoNormal = [];
        });
        var getTodoNormalurlJson = json.decode(getTodoNormalurl.body);
        print(getTodoNormalurlJson);
        var normals = getTodoNormalurlJson['todo_normal'];

        for (var i in normals) {
          ToDoNormal normalx = ToDoNormal(
            idtodo: i['tln_todolist'],
            number: i['tln_number'],
            title: i['tln_title'],
            created: i['tln_title'],
            selesai: i['tln_executed'],
            validation: i['tln_validation'],
          );
          listTodoNormal.add(normalx);
        }
        new Timer(new Duration(seconds: 2), () {
          setState(() {
            isLoadingTodoAll = false;
            isErrorTodoAll = false;
          });
        });
      } else if (getTodoNormalurl.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
      } else {
        setState(() {
          isLoadingTodoAll = false;
          isErrorTodoAll = true;
        });
        print(getTodoNormalurl.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoadingTodoAll = false;
        isErrorTodoAll = true;
      });
      Fluttertoast.showToast(msg: "error, silahkan coba kembali");
      debugPrint('$e');
    }
    return null;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _showdetailMemberProject(idMember) async {
    print(idMember);
    await progressApiAction.show();
    try {
      final detailMemberUrl = await http
          .post(url('api/detail_member_todo'), headers: requestHeaders, body: {
        'member': idMember.toString(),
        'todo': widget.idtodo.toString(),
      });
      if (detailMemberUrl.statusCode == 200) {
        var detailMemberjson = json.decode(detailMemberUrl.body);
        print(detailMemberjson);
        var dataMemberProject = detailMemberjson;
        String imageDetailMember = dataMemberProject['us_image'];
        String namaDetailMember = dataMemberProject['us_name'];
        String statusDetailMember = dataMemberProject['tlr_role'].toString();
        String addressDetailMember = dataMemberProject['us_address'];
        String phoneDetailMember = dataMemberProject['us_phone'];
        String emailDetailMember = dataMemberProject['us_email'];
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        showModalDetailMember(
            imageDetailMember,
            namaDetailMember,
            statusDetailMember,
            addressDetailMember,
            phoneDetailMember,
            emailDetailMember);
      } else {
        print(detailMemberUrl.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: 'Gagal, Silahkan Coba Kembali');
      }
    } on TimeoutException {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: 'Time Out, Try Again');
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      print(e.toString());
      Fluttertoast.showToast(msg: 'Gagal, Silahkan Coba Kembali');
    }
  }

  void _realisasiTodo() async {
    await progressApiAction.show();
    try {
      final detailMemberUrl = await http
          .post(url('api/realisasi_todo'), headers: requestHeaders, body: {
        'progress': textValue.toString(),
        'todolist': widget.idtodo.toString(),
        'catatan': _catatanrealisasiController.text,
      });
      if (detailMemberUrl.statusCode == 200) {
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        setState(() {
          textValue = null;
          _value = 1;
          _catatanrealisasiController.text = '';
        });
        todoActivity();
      } else {
        print(detailMemberUrl.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: 'Gagal, Silahkan Coba Kembalis');
      }
    } on TimeoutException {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: 'Time Out, Try Again');
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      print(e.toString());
      Fluttertoast.showToast(msg: 'Gagal, Silahkan Coba Kembalie');
    }
  }

  void showModalDetailMember(image, name, status, address, phone, email) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
              height: 370.0 + MediaQuery.of(context).viewInsets.bottom,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  right: 15.0,
                  left: 15.0,
                  top: 15.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(
                            top: 10.0,
                          ),
                          height: 60.0,
                          width: 60.0,
                          child: GestureDetector(
                            child: Hero(
                                tag: 'imageDetail',
                                child: ClipOval(
                                    child: FadeInImage.assetNetwork(
                                        fit: BoxFit.cover,
                                        placeholder: 'images/imgavatar.png',
                                        image: image == null ||
                                                image == '' ||
                                                image == 'Tidak ditemukan'
                                            ? url('assets/images/imgavatar.png')
                                            : url(
                                                'storage/image/profile/$image')))),
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) {
                                return DetailScreen(
                                    tag: 'imageDetail',
                                    url: image == null ||
                                            image == '' ||
                                            image == 'Tidak ditemukan'
                                        ? url('assets/images/imgavatar.png')
                                        : url('storage/image/profile/$image'));
                              }));
                            },
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
                            child: Text(
                              name == null || name == '' || name == 'null'
                                  ? 'Member Tidak Diketahui'
                                  : name,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                        Container(
                          margin: EdgeInsets.only(bottom: 15.0),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(right: 3.0),
                                child: Text(
                                  'Status : ',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(
                                    top: 5,
                                    left: 10.0,
                                    bottom: 5.0,
                                    right: 10.0),
                                decoration: BoxDecoration(
                                  color: primaryAppBarColor,
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          5.0) //                 <--- border radius here
                                      ),
                                ),
                                child: Text(
                                  status == '1'
                                      ? 'Owner'
                                      : status == '2'
                                          ? 'Admin'
                                          : status == '3'
                                              ? 'Executor'
                                              : status == '4'
                                                  ? 'Viewer'
                                                  : "Tidak Diketehui",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 0, bottom: 0, left: 10.0, right: 10.0),
                          leading: Icon(
                            Icons.location_on,
                            color: primaryAppBarColor,
                          ),
                          title: Text(
                            address == null || address == ''
                                ? 'Alamat belum ditambahkan'
                                : address,
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                        Container(height: 5.0, child: Divider()),
                        ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 0, bottom: 0, left: 10.0, right: 10.0),
                          leading: Icon(
                            Icons.phone,
                            color: primaryAppBarColor,
                          ),
                          title: Text(
                            phone == null || phone == ''
                                ? 'Nomor telepon belum ditambahkan'
                                : phone,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Container(height: 5.0, child: Divider()),
                        ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 0, bottom: 0, left: 10.0, right: 10.0),
                          leading: Icon(
                            Icons.email,
                            color: primaryAppBarColor,
                          ),
                          title: Text(
                            email == null || email == ''
                                ? 'Email belum ditambahkan'
                                : email,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ));
        });
  }

  void _requestDownload(url) async {
    try {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.contacts);
      if (permission != PermissionStatus.denied) {
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
        Directory tempDir = await getExternalStorageDirectory();
        var dirPath = await new Directory('${tempDir.path}/Tudulis').create();

        print(tempDir.path);
        await FlutterDownloader.enqueue(
          url: url,
          savedDir: dirPath.path,
          showNotification:
              true, // show download progress in status bar (for Android)
          openFileFromNotification:
              true, // click on notification to open downloaded file (for Android)
        );
      }
    } catch (Exception) {
      // print()

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
      body: DefaultTabController(
          length: 5,
          child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 150.0,
                    floating: false,
                    pinned: true,
                    centerTitle: false,
                    actions: <Widget>[
                      dataStatusKita == null
                          ? Container()
                          : dataStatusKita['tlr_role'] == 1 ||
                                  dataStatusKita['tlr_role'] == 2
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Edit Data Todo',
                                  onPressed: () async {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ManajemenEditTodo(
                                                  idTodo: widget.idtodo,
                                                )));
                                  },
                                )
                              : Container(),
                    ],
                    // automaticallyImplyLeading: false,
                    backgroundColor: primaryAppBarColor,
                    flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Container(
                          margin: EdgeInsets.only(
                              left: 50.0, right: 50.0, bottom: 0.0),
                          padding: EdgeInsets.only(
                              left: 15.0, bottom: 5.0, top: 5.0, right: 15.0),
                          child: Text("${widget.namatodo}",
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              )),
                        ),
                        background: Image.asset(
                          "images/manajemen_project.png",
                          fit: BoxFit.cover,
                        )),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        indicatorColor: primaryAppBarColor,
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: "Deskripsi"),
                          Tab(text: "Aktifitas"),
                          Tab(text: "To Do Action"),
                          Tab(text: "To Do Ready"),
                          Tab(text: "To Do Normal"),
                          Tab(text: "To Do Done"),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(controller: _tabController, children: [
                RefreshIndicator(
                    onRefresh: getHeaderHTTP,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          children: <Widget>[
                            isLoading == true
                                ? loadingPage(context)
                                : isError == true
                                    ? errorSystem(context)
                                    : detailTodo(),
                          ],
                        ),
                      ),
                    )),
                RefreshIndicator(
                  onRefresh: todoActivity,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          isLoadingActivity == true
                              ? loadingTodoActivity(context)
                              : isErrorActivity == true
                                  ? errorSystem(context)
                                  : dataActivityTodo(),
                        ],
                      ),
                    ),
                  ),
                ),
                isLoadingTodoAll == true
                    ? widgetLoadingTodo()
                    : isErrorTodoAll == true
                        ? errorSystem(context)
                        : listTodoAction.length == 0
                            ? emptyTodoAction()
                            : Container(
                                child: Column(
                                  children: <Widget>[
                                    dataTodoAction(),
                                  ],
                                ),
                              ),
                isLoadingTodoAll == true
                    ? widgetLoadingTodo()
                    : isErrorTodoAll == true
                        ? errorSystem(context)
                        : listTodoReady.length == 0
                            ? emptyTodoAction()
                            : Container(
                                child: Column(
                                  children: <Widget>[
                                    dataTodoReady(),
                                  ],
                                ),
                              ),
                isLoadingTodoAll == true
                    ? widgetLoadingTodo()
                    : isErrorTodoAll == true
                        ? errorSystem(context)
                        : listTodoNormal.length == 0
                            ? emptyTodoAction()
                            : Container(
                                child: Column(
                                  children: <Widget>[
                                    dataTodoNormal(),
                                  ],
                                ),
                              ),
                isLoadingTodoAll == true
                    ? widgetLoadingTodo()
                    : isErrorTodoAll == true
                        ? errorSystem(context)
                        : listTodoDone.length == 0
                            ? emptyTodoAction()
                            : Container(
                                child: Column(
                                  children: <Widget>[
                                    dataTodoDone(),
                                  ],
                                ),
                              ),
              ]))),
      floatingActionButton: _bottomButtons(),
      bottomNavigationBar: bottomvaigation(),
    );
  }

  Widget bottomvaigation() {
    if (_tabController.index != 0) {
      return null;
    } else if (dataTodo == null) {
      return null;
    } else if (dataTodo['tl_status'] == 'Open' &&
        dataTodo['tl_exestart'] == null) {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(0),
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: () async {
                            if (dataStatusKita == null) {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            }
                            if (dataStatusKita['tlr_role'] == 4 ||
                                dataStatusKita['tlr_role'] == '4') {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            } else {
                              actionmulaimengerjakan('baru mengerjakan');
                            }
                          },
                          child: Text(
                            "Mulai Mengerjakan",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    } else if (dataTodo['tl_status'] == 'Open' &&
        dataTodo['tl_exestart'] != null) {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 3.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: Colors.grey,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(0),
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: () async {
                            if (dataStatusKita == null) {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            }
                            if (dataStatusKita['tlr_role'] == 4 ||
                                dataStatusKita['tlr_role'] == '4') {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            } else {
                              actionmulaimengerjakan('pending');
                            }
                          },
                          child: Text(
                            "Pending",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 3, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: Colors.green,
                          padding: EdgeInsets.all(0),
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: () async {
                            if (dataStatusKita == null) {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            }
                            if (dataStatusKita['tlr_role'] == 4 ||
                                dataStatusKita['tlr_role'] == '4') {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            } else {
                              actionmulaimengerjakan('selesai');
                            }
                          },
                          child: Text(
                            "Selesai",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    } else if (dataTodo['tl_status'] == 'Pending') {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          padding: EdgeInsets.all(0),
                          color: primaryAppBarColor,
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: () async {
                            if (dataStatusKita == null) {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            }
                            if (dataStatusKita['tlr_role'] == 4 ||
                                dataStatusKita['tlr_role'] == '4') {
                              Fluttertoast.showToast(
                                  msg:
                                      'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                            } else {
                              actionmulaimengerjakan(
                                  'mulai mengerjakan kembali');
                            }
                          },
                          child: Text(
                            "Mulai Mengerjakan Lagi",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    } else if (dataTodo['tl_status'] == 'Finish') {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: primaryAppBarColor,
                          padding: EdgeInsets.all(0),
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: null,
                          child: Text(
                            "To Do Sudah Selesai",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    }
    return null;
  }

  Widget _bottomButtons() {
    if (_tabController.index == 0 || _tabController.index == 1) {
      return null;
    } else {
      return dataStatusKita == null
          ? null
          : dataStatusKita['tlr_role'] == 1 || dataStatusKita['tlr_role'] == 2
              ? DraggableFab(
                  child: FloatingActionButton(
                      shape: StadiumBorder(),
                      onPressed: () async {
                        _showModal();
                      },
                      backgroundColor: Color.fromRGBO(254, 86, 14, 1),
                      child: Icon(
                        Icons.add,
                        size: 20.0,
                      )))
              : null;
    }
  }

  void _showModal() {
    setState(() {
      _titleTodoListAction.text = '';
    });
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 200.0 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 15.0,
                left: 15.0,
                top: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(bottom: 20.0, top: 10.0),
                    child: TextField(
                      controller: _titleTodoListAction,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Isilah dengan detail action',
                          hintStyle: TextStyle(
                            fontSize: 12,
                          )),
                    )),
                Center(
                    child: Container(
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: () async {
                              tambahAction();
                            },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Tambahkan Action",
                                style: TextStyle(color: Colors.white)))))
              ],
            ),
          );
        });
  }

  void tambahAction() async {
    String type;
    if (_tabController.index == 2) {
      type = 'Action';
    } else if (_tabController.index == 3) {
      type = 'Ready';
    } else if (_tabController.index == 4) {
      type = 'Normal';
    } else if (_tabController.index == 5) {
      type = 'Done';
    } else if (_tabController.index == 0 || _tabController.index == 1) {
      Navigator.pop(context);
      return null;
    }
    if (_titleTodoListAction.text == '') {
      Fluttertoast.showToast(msg: 'Masukkan Judul To Do Action');
      return null;
    }
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addpeserta = await http
          .post(url('api/todo/list/actions'), headers: requestHeaders, body: {
        'todo': widget.idtodo.toString(),
        'title': _titleTodoListAction.text.toString(),
        'type': type,
      });
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          if (_tabController.index == 2) {
            listTodoActionData();
          } else if (_tabController.index == 3) {
            listTodoReadyData();
          } else if (_tabController.index == 4) {
            listTodoNormalData();
          } else if (_tabController.index == 5) {
            listTodoDoneData();
          }
          progressApiAction.hide().then((isHidden) {});
        }
      } else {
        print(addpeserta.body);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});

      print(e);
    }
  }

  void actionmulaimengerjakan(type) async {
    await progressApiAction.show();
    try {
      final addpeserta = await http
          .post(url('api/todo/started-todo'), headers: requestHeaders, body: {
        'todo': widget.idtodo.toString(),
        'type': type,
      });
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
          getHeaderHTTP();
        }
      } else {
        print(addpeserta.body);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});

      print(e);
    }
  }

  Widget detailTodo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        dataTodo == null
            ? Text('Belum Ada Keterangan Tanggal')
            : dataTodo['tl_allday'] == 0
                ? Column(
                    children: <Widget>[
                      Text(
                        DateFormat('dd MMM yyyy HH:mm').format(
                                DateTime.parse(dataTodo['tl_planstart'])) +
                            ' - ' +
                            DateFormat('dd MMM yyyy HH:mm')
                                .format(DateTime.parse(dataTodo['tl_planend'])),
                        style: TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Text(
                        DateFormat('dd MMM yyyy').format(
                                DateTime.parse(dataTodo['tl_planstart'])) +
                            ' - ' +
                            DateFormat('dd MMM yyyy')
                                .format(DateTime.parse(dataTodo['tl_planend'])),
                        style: TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ],
                  ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            dataTodo == null
                ? 'Belum ada deskripsi Todo'
                : dataTodo['tl_desc'] == null ||
                        dataTodo['tl_desc'] == '' ||
                        dataTodo['tl_desc'] == 'null'
                    ? 'Belum ada deskripsi Todo'
                    : dataTodo['tl_desc'],
            style: TextStyle(height: 2),
          ),
        ),
        todoAttachmentDetail.length == 0
            ? Container()
            : Container(
                margin: EdgeInsets.only(top: 20.0),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    'File To Do',
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                )),
        Container(
          margin: EdgeInsets.only(top: 0.0, bottom: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: todoAttachmentDetail
                .map((FileTodo item) => InkWell(
                    onTap: () async {
                      _requestDownload(item.path);
                    },
                    child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 10.0),
                        padding: EdgeInsets.only(
                            top: 10.0, left: 5, bottom: 10.0, right: 5),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey[300], width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.insert_drive_file,
                              size: 13,
                              color: Colors.red,
                            ),
                            Expanded(
                              child: Text(
                                item.path == '' || item.filename == ''
                                    ? 'FIle Tidak Diketahui'
                                    : item.filename,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ))))
                .toList(),
          ),
        ),
        Container(
            margin: EdgeInsets.only(bottom: 15.0),
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'To Do Progress',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            )),
        Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 5.0,
                animation: true,
                percent: dataTodo == null
                    ? 0.00
                    : double.parse(dataTodo['tl_progress'].toString()) / 100,
                center: new Text(
                  dataTodo == null ? '0.00 %' : "${dataTodo['tl_progress']}%",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12.0),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.green,
              ),
              Container(
                margin: EdgeInsets.only(left: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.only(top: 15.0),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100.0),
                              child: Container(
                                margin: EdgeInsets.only(right: 3.0),
                                height: 10.0,
                                alignment: Alignment.center,
                                width: 10.0,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Color.fromRGBO(0, 204, 65, 1.0),
                                      width: 1.0),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          100.0) //                 <--- border radius here
                                      ),
                                  color: Color.fromRGBO(0, 204, 65, 1.0),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                'Sudah Selesai',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        )),
                    Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100.0),
                              child: Container(
                                margin: EdgeInsets.only(right: 3.0),
                                height: 10.0,
                                alignment: Alignment.center,
                                width: 10.0,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Color.fromRGBO(0, 204, 65, 1.0),
                                      width: 1.0),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          100.0) //                 <--- border radius here
                                      ),
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                'Belum Selesai',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              )
            ],
          ),
        ),
        Container(
            margin: EdgeInsets.only(bottom: 15.0, top: 15.0),
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'To Do Member',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            )),
        Container(
          color: Colors.white,
          margin: EdgeInsets.only(
            top: 0.0,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              child: Row(
                children: todoMemberDetail
                    .map((MemberTodo item) => InkWell(
                          onTap: () async {
                            _showdetailMemberProject(item.iduser);
                          },
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            margin: EdgeInsets.only(right: 15.0),
                            child: ClipOval(
                              child: FadeInImage.assetNetwork(
                                placeholder: 'images/loading.gif',
                                image: item.image == null || item.image == ''
                                    ? url('assets/images/imgavatar.png')
                                    : url(
                                        'storage/image/profile/${item.image}'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget dataActivityTodo() {
    return Column(
      children: <Widget>[
        textValue == null || textValue == ''
            ? Container()
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0.0, top: 15.0),
                    child: Text(
                      textValue == '' || textValue == null
                          ? ''
                          : 'Realisasi: $textValue %',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
        Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SliderTheme(
                      data: SliderThemeData(
                        trackShape: CustomTrackShape(),
                      ),
                      child: Slider(
                          value: _value.toDouble(),
                          min: 1,
                          max: 100,
                          activeColor: primaryAppBarColor,
                          inactiveColor: Colors.grey[400],
                          onChanged: (double newValue) {
                            setState(() {
                              _value = newValue.round();
                              textValue = newValue.toStringAsFixed(0);
                            });
                          },
                          semanticFormatterCallback: (double newValue) {
                            return '${newValue.round()} dollars';
                          })),
                  Container(
                    child: TextField(
                      controller: _catatanrealisasiController,
                      maxLines: 2,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Catatan',
                          hintStyle:
                              TextStyle(fontSize: 13, color: Colors.black)),
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.only(
                        top: 10.0,
                      ),
                      width: double.infinity,
                      height: 40.0,
                      child: ButtonTheme(
                        child: FlatButton(
                            onPressed: () async {
                              if (dataTodo == null) {
                              } else if (dataTodo['tl_status'] == 'Open' &&
                                  dataTodo['tl_exestart'] == null) {
                                Fluttertoast.showToast(
                                    msg:
                                        'Tidak Dapat Melakukan Realisasi, To Do Belum Mulai Dikerjakan');
                              } else if (dataTodo['tl_status'] == 'Pending') {
                                Fluttertoast.showToast(
                                    msg:
                                        'Tidak Dapat Melakukan Realisasi, To Do Masih Tahap Pending');
                              } else if (dataStatusKita == null) {
                                Fluttertoast.showToast(
                                    msg:
                                        'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                              } else if (dataStatusKita['tlr_role'] == 4 ||
                                  dataStatusKita['tlr_role'] == '4') {
                                Fluttertoast.showToast(
                                    msg:
                                        'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                              } else {
                                _realisasiTodo();
                              }
                            },
                            shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(10.0),
                            ),
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            child: Text('Tambahkan Aktifitas')),
                      )),
                  Container(height: 15.0),
                  todoActivityDetail.length > 0 ? Divider() : Container(),
                  Container(height: 15.0),
                ],
              ),
            ),
          ],
        )),
        Container(
          child: Column(
            children: todoActivityDetail
                .map((TodoActivity item) => Container(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 10.0, right: 15.0),
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            child: ClipOval(
                              child: Image.asset('images/imgavatar.png'),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: Text(
                                  '${item.updateat}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                      child: Text(
                                    item.name == null || item.name == ''
                                        ? 'Member Tidak Diketahui'
                                        : item.name,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  )),
                                  Text(
                                    item.progress == null || item.progress == ''
                                        ? 'update 0%'
                                        : 'update ${item.progress} %',
                                    style: TextStyle(
                                        color: primaryAppBarColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, bottom: 10.0),
                                  child: Text(
                                    item.note == null || item.note == ''
                                        ? 'Tidak ada catatan'
                                        : item.note,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  )),
                              Container(
                                  margin: EdgeInsets.only(bottom: 5.0),
                                  child: Divider()),
                            ],
                          ),
                        ),
                      ],
                    )))
                .toList(),
          ),
        )
      ],
    );
  }

  Widget dataTodoReady() {
    return Expanded(
        child: Scrollbar(
      child: RefreshIndicator(
        onRefresh: listTodoReadyData,
        child: ListView.builder(
          padding: EdgeInsets.all(0),
          itemCount: listTodoReady.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                  leading: Checkbox(
                    activeColor: primaryAppBarColor,
                    value: dataTodo == null
                        ? false
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? false
                            : dataTodo['tl_status'] == 'Pending'
                                ? false
                                : listTodoReady[index].selesai == null ||
                                        listTodoReady[index].selesai == ''
                                    ? false
                                    : true,
                    onChanged: (bool value) async {
                      if (dataTodo['tl_status'] == 'Open' &&
                          dataTodo['tl_exestart'] == null) {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Belum Dikerjakan, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Pending') {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Tahap Pending, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Finish') {
                        Fluttertoast.showToast(msg: 'To Do Sudah Selesai');
                      } else if (dataStatusKita == null) {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else if (dataStatusKita['tlr_role'] == 4 ||
                          dataStatusKita['tlr_role'] == '4') {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else {
                        await progressApiAction.show();
                        actionDoneTodo(
                            listTodoReady[index].number,
                            listTodoReady[index].idtodo,
                            listTodoReady[index].selesai,
                            listTodoReady[index].validation,
                            listTodoReady[index],
                            'Ready');
                      }
                    },
                  ),
                  title: listTodoReady[index].selesai == null ||
                          listTodoReady[index].selesai == ''
                      ? Text(
                          "${listTodoReady[index].title}",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          "${listTodoReady[index].title}",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                  subtitle: statusTodo(listTodoReady[index].selesai,
                      listTodoReady[index].validation),
                  trailing: dataTodo == null
                        ? null
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? null
                            : dataTodo['tl_status'] == 'Pending'
                                ? null
                                : listTodoReady[index].selesai == null ||
                          listTodoReady[index].selesai == ''
                      ? null
                      : dataStatusKita == null
                          ? null
                          : dataStatusKita['tlr_role'] == 1 ||
                                  dataStatusKita['tlr_role'] == 2
                              ? ButtonTheme(
                                  minWidth: 0,
                                  height: 0,
                                  child: FlatButton(
                                    padding: EdgeInsets.all(0),
                                    color: Colors.white,
                                    child: Icon(
                                        listTodoReady[index].validation ==
                                                    null ||
                                                listTodoReady[index]
                                                        .validation ==
                                                    ''
                                            ? Icons.check
                                            : Icons.close,
                                        color:
                                            listTodoReady[index].validation ==
                                                        null ||
                                                    listTodoReady[index]
                                                            .validation ==
                                                        ''
                                                ? Colors.green
                                                : Colors.red),
                                    onPressed: () async {
                                      accValidation(
                                          listTodoReady[index].number,
                                          listTodoReady[index].idtodo,
                                          listTodoReady[index].selesai,
                                          listTodoReady[index].validation,
                                          listTodoReady[index],
                                          'Ready');
                                    },
                                  ),
                                )
                              : null),
            );
          },
        ),
      ),
    ));
  }

  Widget dataTodoAction() {
    return Expanded(
        child: Scrollbar(
      child: RefreshIndicator(
        onRefresh: listTodoActionData,
        child: ListView.builder(
          padding: EdgeInsets.all(0),
          itemCount: listTodoAction.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                  leading: Checkbox(
                    activeColor: primaryAppBarColor,
                    value: dataTodo == null
                        ? false
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? false
                            : dataTodo['tl_status'] == 'Pending'
                                ? false
                                : listTodoAction[index].selesai == null ||
                                        listTodoAction[index].selesai == ''
                                    ? false
                                    : true,
                    onChanged: (bool value) async {
                      if (dataTodo['tl_status'] == 'Open' &&
                          dataTodo['tl_exestart'] == null) {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Belum Dikerjakan, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Pending') {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Tahap Pending, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Finish') {
                        Fluttertoast.showToast(msg: 'To Do Sudah Selesai');
                      } else if (dataStatusKita == null) {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else if (dataStatusKita['tlr_role'] == 4 ||
                          dataStatusKita['tlr_role'] == '4') {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else {
                        await progressApiAction.show();
                        actionDoneTodo(
                            listTodoAction[index].number,
                            listTodoAction[index].idtodo,
                            listTodoAction[index].selesai,
                            listTodoAction[index].validation,
                            listTodoAction[index],
                            'Action');
                      }
                    },
                  ),
                  title: listTodoAction[index].selesai == null ||
                          listTodoAction[index].selesai == ''
                      ? Text(
                          "${listTodoAction[index].title}",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          "${listTodoAction[index].title}",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                  subtitle: statusTodo(listTodoAction[index].selesai,
                      listTodoAction[index].validation),
                  trailing: dataTodo == null
                        ? null
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? null
                            : dataTodo['tl_status'] == 'Pending'
                                ? null
                                : listTodoAction[index].selesai == null ||
                          listTodoAction[index].selesai == ''
                      ? null
                      : dataStatusKita == null
                          ? null
                          : dataStatusKita['tlr_role'] == 1 ||
                                  dataStatusKita['tlr_role'] == 2
                              ? ButtonTheme(
                                  minWidth: 0,
                                  height: 0,
                                  child: FlatButton(
                                    padding: EdgeInsets.all(0),
                                    color: Colors.white,
                                    child: Icon(
                                        listTodoAction[index].validation ==
                                                    null ||
                                                listTodoAction[index]
                                                        .validation ==
                                                    ''
                                            ? Icons.check
                                            : Icons.close,
                                        color:
                                            listTodoAction[index].validation ==
                                                        null ||
                                                    listTodoAction[index]
                                                            .validation ==
                                                        ''
                                                ? Colors.green
                                                : Colors.red),
                                    onPressed: () async {
                                      accValidation(
                                          listTodoAction[index].number,
                                          listTodoAction[index].idtodo,
                                          listTodoAction[index].selesai,
                                          listTodoAction[index].validation,
                                          listTodoAction[index],
                                          'Action');
                                    },
                                  ),
                                )
                              : null),
            );
          },
        ),
      ),
    ));
  }

  Widget dataTodoDone() {
    return Expanded(
        child: Scrollbar(
      child: RefreshIndicator(
        onRefresh: listTodoDoneData,
        child: ListView.builder(
          padding: EdgeInsets.all(0),
          itemCount: listTodoDone.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                  leading: Checkbox(
                    activeColor: primaryAppBarColor,
                    value: dataTodo == null
                        ? false
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? false
                            : dataTodo['tl_status'] == 'Pending'
                                ? false
                                : listTodoDone[index].selesai == null ||
                                        listTodoDone[index].selesai == ''
                                    ? false
                                    : true,
                    onChanged: (bool value) async {
                      if (dataTodo['tl_status'] == 'Open' &&
                          dataTodo['tl_exestart'] == null) {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Belum Dikerjakan, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Pending') {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Tahap Pending, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Finish') {
                        Fluttertoast.showToast(msg: 'To Do Sudah Selesai');
                      } else if (dataStatusKita == null) {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else if (dataStatusKita['tlr_role'] == 4 ||
                          dataStatusKita['tlr_role'] == '4') {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else {
                        await progressApiAction.show();
                        actionDoneTodo(
                            listTodoDone[index].number,
                            listTodoDone[index].idtodo,
                            listTodoDone[index].selesai,
                            listTodoDone[index].validation,
                            listTodoDone[index],
                            'Done');
                      }
                    },
                  ),
                  title: listTodoDone[index].selesai == null ||
                          listTodoDone[index].selesai == ''
                      ? Text(
                          "${listTodoDone[index].title}",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          "${listTodoDone[index].title}",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                  subtitle: statusTodo(listTodoDone[index].selesai,
                      listTodoDone[index].validation),
                  trailing:dataTodo == null
                        ? null
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? null
                            : dataTodo['tl_status'] == 'Pending'
                                ? null
                                : listTodoDone[index].selesai == null ||
                          listTodoDone[index].selesai == ''
                      ? null
                      : dataStatusKita == null
                          ? null
                          : dataStatusKita['tlr_role'] == 1 ||
                                  dataStatusKita['tlr_role'] == 2
                              ? ButtonTheme(
                                  minWidth: 0,
                                  height: 0,
                                  child: FlatButton(
                                    padding: EdgeInsets.all(0),
                                    color: Colors.white,
                                    child: Icon(
                                        listTodoDone[index].validation ==
                                                    null ||
                                                listTodoReady[index]
                                                        .validation ==
                                                    ''
                                            ? Icons.check
                                            : Icons.close,
                                        color: listTodoDone[index].validation ==
                                                    null ||
                                                listTodoDone[index]
                                                        .validation ==
                                                    ''
                                            ? Colors.green
                                            : Colors.red),
                                    onPressed: () async {
                                      accValidation(
                                          listTodoDone[index].number,
                                          listTodoDone[index].idtodo,
                                          listTodoDone[index].selesai,
                                          listTodoDone[index].validation,
                                          listTodoDone[index],
                                          'Done');
                                    },
                                  ),
                                )
                              : null),
            );
          },
        ),
      ),
    ));
  }

  Widget dataTodoNormal() {
    return Expanded(
        child: Scrollbar(
      child: RefreshIndicator(
        onRefresh: listTodoNormalData,
        child: ListView.builder(
          padding: EdgeInsets.all(0),
          itemCount: listTodoNormal.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                  leading: Checkbox(
                    activeColor: primaryAppBarColor,
                    value: dataTodo == null
                        ? false
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? false
                            : dataTodo['tl_status'] == 'Pending'
                                ? false
                                : listTodoNormal[index].selesai == null ||
                                        listTodoNormal[index].selesai == ''
                                    ? false
                                    : true,
                    onChanged: (bool value) async {
                      if (dataTodo['tl_status'] == 'Open' &&
                          dataTodo['tl_exestart'] == null) {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Belum Dikerjakan, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Pending') {
                        Fluttertoast.showToast(
                            msg:
                                'To Do Masih Tahap Pending, Tidak Dapat Melakukan Konfirmasi Selesai');
                      } else if (dataTodo['tl_status'] == 'Finish') {
                        Fluttertoast.showToast(msg: 'To Do Sudah Selesai');
                      } else if (dataStatusKita == null) {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else if (dataStatusKita['tlr_role'] == 4 ||
                          dataStatusKita['tlr_role'] == '4') {
                        Fluttertoast.showToast(
                            msg:
                                'Anda Tidak Memiliki Akses Untuk Melakukan Aksi Ini');
                      } else {
                        await progressApiAction.show();
                        actionDoneTodo(
                            listTodoNormal[index].number,
                            listTodoNormal[index].idtodo,
                            listTodoNormal[index].selesai,
                            listTodoNormal[index].validation,
                            listTodoNormal[index],
                            'Normal');
                      }
                    },
                  ),
                  title: listTodoNormal[index].selesai == null ||
                          listTodoNormal[index].selesai == ''
                      ? Text(
                          "${listTodoNormal[index].title}",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          "${listTodoNormal[index].title}",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                  subtitle: statusTodo(listTodoNormal[index].selesai,
                      listTodoNormal[index].validation),
                  trailing:dataTodo == null
                        ? null
                        : dataTodo['tl_status'] == 'Open' &&
                                dataTodo['tl_exestart'] == null
                            ? null
                            : dataTodo['tl_status'] == 'Pending'
                                ? null
                                : listTodoNormal[index].selesai == null ||
                          listTodoNormal[index].selesai == ''
                      ? null
                      : dataStatusKita == null
                          ? null
                          : dataStatusKita['tlr_role'] == 1 ||
                                  dataStatusKita['tlr_role'] == 2
                              ? ButtonTheme(
                                  minWidth: 0,
                                  height: 0,
                                  child: FlatButton(
                                    padding: EdgeInsets.all(0),
                                    color: Colors.white,
                                    child: Icon(
                                        listTodoNormal[index].validation ==
                                                    null ||
                                                listTodoReady[index]
                                                        .validation ==
                                                    ''
                                            ? Icons.check
                                            : Icons.close,
                                        color:
                                            listTodoNormal[index].validation ==
                                                        null ||
                                                    listTodoNormal[index]
                                                            .validation ==
                                                        ''
                                                ? Colors.green
                                                : Colors.red),
                                    onPressed: () async {
                                      accValidation(
                                          listTodoNormal[index].number,
                                          listTodoNormal[index].idtodo,
                                          listTodoNormal[index].selesai,
                                          listTodoNormal[index].validation,
                                          listTodoNormal[index],
                                          'Normal');
                                    },
                                  ),
                                )
                              : null),
            );
          },
        ),
      ),
    ));
  }

  Widget widgetLoadingTodo() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300],
          highlightColor: Colors.grey[100],
          child: Column(
            children: [0, 1, 3, 4, 5, 6, 7, 8, 9, 10]
                .map((_) => Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50.0,
                            height: 50.0,
                            color: Colors.white,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 8.0,
                                  color: Colors.white,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 8.0,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget statusTodo(selesai, validation) {
    String textstatus;
    Color textColor;
    if (dataTodo == null) {
      textstatus = 'Belum Selesai';
      textColor = Colors.grey;
    } else if (dataTodo['tl_status'] == 'Open' &&
        dataTodo['tl_exestart'] == null) {
      textstatus = 'Belum Selesai';
      textColor = Colors.grey;
    } else if (dataTodo['tl_status'] == 'Pending') {
      textstatus = 'Belum Selesai';
      textColor = Colors.grey;
    } else if (selesai == null || selesai == '') {
      textstatus = 'Belum Selesai';
      textColor = Colors.grey;
    } else if (validation == null || validation == '') {
      textstatus = 'Belum Divalidasi';
      textColor = Colors.grey;
    } else {
      textstatus = 'Sudah Divalidasi';
      textColor = Colors.green;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
      child: Text(
        textstatus,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  void accValidation(number, idtodo, selesai, validation, index, type) async {
    await progressApiAction.show();
    try {
      var body = {
        'id': number.toString(),
        'todo': idtodo.toString(),
        'type': type,
      };
      final addpeserta = await http.post(url('api/todo/list/validation'),
          headers: requestHeaders, body: body);
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'validation') {
          setState(() {
            index.validation = 'valid';
          });
          Fluttertoast.showToast(msg: 'Berhasil');
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'belum validation') {
          setState(() {
            index.validation = null;
          });
          Fluttertoast.showToast(msg: 'Berhasil');
          progressApiAction.hide().then((isHidden) {});
        } else {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: 'To Do tidak ditemukan');
        }
      } else {
        print(addpeserta.body);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {});
    }
  }

  Widget errorSystem(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
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
                    if (_tabController.index == 0) {
                      getHeaderHTTP();
                    } else if (_tabController.index == 1) {
                      todoActivity();
                    } else if (_tabController.index == 2) {
                      listTodoActionData();
                    } else if (_tabController.index == 3) {
                      listTodoReadyData();
                    } else if (_tabController.index == 4) {
                      listTodoNormalData();
                    } else if (_tabController.index == 5) {
                      listTodoDoneData();
                    }
                  },
                  child: Text(
                    "Muat Ulang Halaman",
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget loadingPage(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
            child: SingleChildScrollView(
                child: Container(
          margin: EdgeInsets.only(top: 15.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3]
                  .map((_) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                        margin: EdgeInsets.only(right: 15.0, top: 10.0),
                        width: double.infinity,
                        height: 10.0,
                      ))
                  .toList(),
            ),
          ),
        ))),
        Container(
            child: SingleChildScrollView(
                child: Container(
          margin: EdgeInsets.only(top: 15.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                0,
              ]
                  .map((_) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                        margin: EdgeInsets.only(right: 15.0, top: 10.0),
                        width: 120.0,
                        height: 10.0,
                      ))
                  .toList(),
            ),
          ),
        ))),
        Container(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  margin: EdgeInsets.only(top: 15.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300],
                    highlightColor: Colors.grey[100],
                    child: Row(
                      children: [0, 1, 2, 3, 4, 5, 6]
                          .map((_) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(100.0)),
                                ),
                                margin: EdgeInsets.only(right: 15.0, top: 10.0),
                                width: 40.0,
                                height: 40.0,
                              ))
                          .toList(),
                    ),
                  ),
                ))),
        Container(
            margin: EdgeInsets.only(top: 20.0),
            child: SingleChildScrollView(
                child: Container(
              margin: EdgeInsets.only(top: 15.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300],
                highlightColor: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    0,
                  ]
                      .map((_) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            margin: EdgeInsets.only(right: 15.0, top: 10.0),
                            width: 120.0,
                            height: 10.0,
                          ))
                      .toList(),
                ),
              ),
            ))),
        Container(
            color: Colors.white,
            margin: EdgeInsets.only(
              top: 15.0,
            ),
            padding: EdgeInsets.all(15.0),
            child: SingleChildScrollView(
                child: Container(
              width: double.infinity,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
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
            ))),
      ],
    ));
  }

  Widget loadingTodoActivity(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
            color: Colors.white,
            margin: EdgeInsets.only(
              top: 15.0,
            ),
            padding: EdgeInsets.all(15.0),
            child: SingleChildScrollView(
                child: Container(
              width: double.infinity,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
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
            ))),
      ],
    ));
  }

  Widget emptyTodoAction() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_tabController.index == 2) {
          listTodoActionData();
        } else if (_tabController.index == 3) {
          listTodoReadyData();
        } else if (_tabController.index == 4) {
          listTodoNormalData();
        } else if (_tabController.index == 5) {
          listTodoDoneData();
        }
      },
      child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Column(children: <Widget>[
              new Container(
                width: 100.0,
                height: 100.0,
                child: Image.asset("images/todo_icon2.png"),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 20.0, left: 25.0, right: 25.0, bottom: 35.0),
                child: Center(
                  child: Text(
                    "To Do Action Yang Anda Cari Tidak Ditemukan",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ]),
          )),
    );
  }

  void actionDoneTodo(number, idtodo, selesai, validation, index, type) async {
    try {
      var body = {
        'id': number.toString(),
        'todo': idtodo.toString(),
        'type': type,
      };
      final addpeserta = await http.patch(url('api/todo/list/actions/$number'),
          headers: requestHeaders, body: body);
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);

        if (addpesertaJson['status'] == 'selesai') {
          setState(() {
            index.selesai = 'selesai';
            index.validation =
                addpesertaJson['validation'] == null ? null : 'valid';
          });
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'belum selesai') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            index.selesai = null;
            index.validation =
                addpesertaJson['validation'] == null ? null : 'valid';
          });
        } else if (addpesertaJson['status'] ==
            'type todolist tidak ditemukan') {
          Fluttertoast.showToast(msg: "To Do List Tidak Ditemukan");
          progressApiAction.hide().then((isHidden) {});
        } else {
          Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
          progressApiAction.hide().then((isHidden) {});
        }
      } else {
        print(addpeserta.body);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {});
    }
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(
            width: 1.0,
            color: Colors.grey[300],
          ))),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
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
