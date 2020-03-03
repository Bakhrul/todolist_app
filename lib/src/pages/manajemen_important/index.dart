import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/model/Todo.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/pages/todolist/detail_todo.dart';

String tokenType, accessToken;
Map<String, String> requestHeaders = Map();
List<Todo> listTodoImportant = [];

class ManajemenTodoImportant extends StatefulWidget {
  ManajemenTodoImportant({Key key, this.title, this.idproject})
      : super(key: key);
  final String title;
  final int idproject;
  @override
  State<StatefulWidget> createState() {
    return _ManajemenTodoImportantState();
  }
}

class _ManajemenTodoImportantState extends State<ManajemenTodoImportant>
    with SingleTickerProviderStateMixin {
  int countTodo;
  bool actionBackAppBar, iconButtonAppbarColor;
  TextEditingController _searchQuery = TextEditingController();
  List listFilter = [
    {'index': "1", 'name': "Molor"},
    {'index': "2", 'name': "Hari Ini"},
    {'index': "3", 'name': "Besok"},
    {'index': "4", 'name': "Lusa"},
    {'index': "5", 'name': "Minggu Ini"},
    {'index': "6", 'name': "Bulan Ini"},
    {'index': "7", 'name': "Pending"}
  ];
  int currentFilter = 1;

  bool isLoading, isError, isFilter, isErrorFilter;
  @override
  void initState() {
    getHeaderHTTP();
    actionBackAppBar = false;
    iconButtonAppbarColor = true;
    isLoading = true;
    countTodo = 0;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataTodo();
  }

  Future<List<List>> getDataTodo() async {
    setState(() {
      listTodoImportant.clear();
    });
    print(widget.idproject);
    setState(() {
      isLoading = true;
    });
    try {
        
      final getDetailProject = await http
          .post(url('api/todolist_berbintang'), headers: requestHeaders, body: {
        'project': widget.idproject.toString(),
        'filter': currentFilter.toString(),
        'search': _searchQuery.text,
      });

     

      if (getDetailProject.statusCode == 200) {
        var getDetailProjectJson = json.decode(getDetailProject.body);
        // print(getDetailProjectJson);
        var todos = getDetailProjectJson['todo'];
        setState(() {
          countTodo = int.parse(getDetailProjectJson['counttodo'].toString());
        });
        for (var i in todos) {
          Todo todo = Todo(
              id: i['id'],
              title: i['title'].toString(),
              timeend: i['end'].toString(),
              timestart: i['start'].toString(),
              statuspinned: i['statuspinned'].toString(),
              allday: i['allday'],
              statusProgress: i['statusprogress'],
              coloredProgress: i['statusprogress'] == 'compleshed' 
              ? Colors.green 
              : i['statusprogress'] == 'overdue' 
              ? Colors.red
              :  i['statusprogress'] == 'pending' 
              ? Colors.grey
              : Colors.white
              );

          listTodoImportant.add(todo);
        }

        setState(() {
          isLoading = false;
          isError = false;
          isFilter = false;
          isErrorFilter = false;
        });
      } else if (getDetailProject.statusCode == 401) {
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
        print(getDetailProject.body);
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
      Fluttertoast.showToast(msg: "error");
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> filterDataTodo() async {
    setState(() {
      listTodoImportant.clear();
      listTodoImportant = [];
    });
    // print(widget.idproject);
    setState(() {
      isFilter = true;
    });
    try {
      final getDetailProject = await http
          .post(url('api/todolist_berbintang'), headers: requestHeaders, body: {
        'project': widget.idproject.toString(),
        'filter': currentFilter.toString(),
        'search': _searchQuery.text,
      });

   

      if (getDetailProject.statusCode == 200) {
        var getDetailProjectJson = json.decode(getDetailProject.body);
        print(getDetailProjectJson);
        var todos = getDetailProjectJson['todo'];
        setState(() {
          countTodo = int.parse(getDetailProjectJson['counttodo'].toString());
        });
         for (var i in todos) {
          Todo todo = Todo(
              id: i['id'],
              title: i['title'].toString(),
              timeend: i['end'].toString(),
              timestart: i['start'].toString(),
              statuspinned: i['statuspinned'].toString(),
              allday: i['allday'],
              statusProgress: i['statusprogress'],
              coloredProgress: i['statusprogress'] == 'compleshed' 
              ? Colors.green 
              : i['statusprogress'] == 'overdue' 
              ? Colors.red
              :  i['statusprogress'] == 'pending' 
              ? Colors.grey
              : Colors.white
              );

          listTodoImportant.add(todo);
        }

        setState(() {
          isFilter = false;
          isErrorFilter = false;
          isFilter = false;
          isErrorFilter = false;
        });
      } else if (getDetailProject.statusCode == 401) {
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
        print(getDetailProject.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isFilter = false;
        isErrorFilter = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isFilter = false;
        isErrorFilter = true;
        isFilter = false;
        isErrorFilter = false;
      });
      debugPrint('$e');
    }
    return null;
  }

  void _handleSearchEnd() {
    setState(() {
      _searchQuery.text = '';
    });
    filterDataTodo();
    setState(() {
      // ignore: new_with_non_type
      actionBackAppBar = false;
      iconButtonAppbarColor = true;
      this.actionIcon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "To Do Berbintang",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      );
    });
  }

  Widget appBarTitle = Text(
    "To Do Berbintang",
    style: TextStyle(fontSize: 14),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildBar(context),
      body: RefreshIndicator(
        onRefresh: getDataTodo,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              isLoading == true
                  ? firstLoad()
                  : isError == true
                      ? errorSystem(context)
                      : Container(
                          margin: EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(left: 8.0, bottom: 8),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        for (var x in listFilter)
                                          Container(
                                              margin:
                                                  EdgeInsets.only(right: 10.0),
                                              child: ButtonTheme(
                                                minWidth: 0.0,
                                                height: 0,
                                                child: RaisedButton(
                                                  color: currentFilter ==
                                                          int.parse(x['index'])
                                                      ? primaryAppBarColor
                                                      : Colors.grey[100],
                                                  elevation: 0.0,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  highlightElevation: 0.0,
                                                  padding: EdgeInsets.only(
                                                      top: 7.0,
                                                      left: 15.0,
                                                      right: 15.0,
                                                      bottom: 7.0),
                                                  onPressed: () {
                                                    if (isFilter == true) {
                                                    } else {
                                                      setState(() {
                                                        currentFilter =
                                                            int.parse(
                                                                x['index']);
                                                      });
                                                      filterDataTodo();
                                                    }
                                                  },
                                                  child: Text(
                                                    x['name'],
                                                    style: TextStyle(
                                                        color: currentFilter ==
                                                                int.parse(
                                                                    x['index'])
                                                            ? Colors.white
                                                            : Colors.black54,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(18.0),
                                                      side: BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                      )),
                                                ),
                                              )),
                                      ]),
                                ),
                              ),
                              isFilter == true
                                  ? _loadingview()
                                  : isErrorFilter == true
                                      ? _errorFilter(context)
                                      : listTodoImportant.length == 0
                                          ? Padding(
                                padding: const EdgeInsets.only(top: 25.0),
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
                              )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      top: 15.0,
                                                      left: 10.0,
                                                      bottom: 5.0),
                                                  child: Text(
                                                    '$countTodo To Do',
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                                Container(
                                                  color: Colors.white,
                                                  margin: EdgeInsets.only(
                                                    top: 10.0,
                                                    left: 10.0,
                                                    right: 10.0,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    child: Container(
                                                        child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children:
                                                          listTodoImportant
                                                              .map(
                                                                  (Todo item) =>
                                                                      InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                  builder: (context) => ManajemenDetailTodo(
                                                                                        idtodo: item.id,
                                                                                        namatodo: item.title,
                                                                                      )));
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          child: Card(
                                                                              elevation: 0.5,
                                                                              margin: EdgeInsets.only(top: 5.0, bottom: 5.0, left: 0.0, right: 0.0),
                                                                              child: ClipPath(
                                                                                clipper: ShapeBorderClipper(
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(3)
                                                                                  )
                                                                                ),
                                                                                child: Container(
                                                                                  decoration: BoxDecoration(
                                                                                    border:Border(
                                                                                      right: BorderSide(
                                                                                        color: item.coloredProgress,
                                                                                        width: 5
                                                                                      )
                                                                                    )
                                                                                  ),
                                                                                  child: ListTile(
                                                                                    leading: ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(100.0),
                                                                                      child: Container(
                                                                                          height: 40.0,
                                                                                          alignment: Alignment.center,
                                                                                          width: 40.0,
                                                                                          decoration: BoxDecoration(
                                                                                            border: Border.all(color: Colors.white, width: 2.0),
                                                                                            borderRadius: BorderRadius.all(Radius.circular(100.0) //                 <--- border radius here
                                                                                                ),
                                                                                            color: primaryAppBarColor,
                                                                                          ),
                                                                                          child: Text(
                                                                                            '${item.title[0].toUpperCase()}',
                                                                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                                                          )),
                                                                                    ),
                                                                                    trailing: Row(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: <Widget>[
                                                                                        ButtonTheme(
                                                                                          minWidth: 0.0,
                                                                                          child: FlatButton(
                                                                                              onPressed: () async {
                                                                                                try {
                                                                                                  final actionPinnedTodo = await http.post(url('api/actionpinned_todo'), headers: requestHeaders, body: {
                                                                                                    'todolist': item.id.toString(),
                                                                                                  });

                                                                                                  if (actionPinnedTodo.statusCode == 200) {
                                                                                                    var actionPinnedTodoJson = json.decode(actionPinnedTodo.body);
                                                                                                    if (actionPinnedTodoJson['status'] == 'tambah') {
                                                                                                      setState(() {
                                                                                                        item.statuspinned = item.id.toString();
                                                                                                      });
                                                                                                    } else if (actionPinnedTodoJson['status'] == 'hapus') {
                                                                                                      setState(() {
                                                                                                        item.statuspinned = null;
                                                                                                      });
                                                                                                    }
                                                                                                  } else {
                                                                                                    print(actionPinnedTodo.body);
                                                                                                  }
                                                                                                } on TimeoutException catch (_) {
                                                                                                  Fluttertoast.showToast(msg: "Timed out, Try again");
                                                                                                } catch (e) {
                                                                                                  print(e);
                                                                                                }
                                                                                              },
                                                                                              color: Colors.white,
                                                                                              child: Icon(
                                                                                                Icons.star_border,
                                                                                                color: item.statuspinned == null || item.statuspinned == 'null' ? Colors.grey : Colors.orange,
                                                                                              )),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    title: Text(
                                                                                      item.title == '' || item.title == null ? 'To Do Tidak Diketahui' : item.title,
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      softWrap: true,
                                                                                      maxLines: 1,
                                                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                                                    ),
                                                                                    subtitle: Text(
                                                                                      DateFormat(item.allday > 0 ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm:ss').format(DateTime.parse("${item.timestart}")).toString() + ' - ' + DateFormat(item.allday > 0 ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm:ss').format(DateTime.parse("${item.timeend}")).toString(),
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 1,
                                                                                      softWrap: true,
                                                                                      style: TextStyle(fontSize: 12),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              )),
                                                                        ),
                                                                      ))
                                                              .toList(),
                                                    )),
                                                  ),
                                                ),
                                              ],
                                            ),
                            ],
                          ),
                        )
            ],
          ),
        ),
      ),
    );
  }

  Widget firstLoad() {
    return Column(
      children: <Widget>[
        Column(children: <Widget>[
          Container(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
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
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
                                  ),
                                  margin: EdgeInsets.only(right: 15.0),
                                  width: 120.0,
                                  height: 20.0,
                                ))
                            .toList(),
                      ),
                    ),
                  ))),
        ]),
        Container(
            color: Colors.white,
            margin: EdgeInsets.only(
              top: 5.0,
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
    );
  }

  Widget _loadingview() {
    return Column(
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
    );
  }

  Widget errorSystem(BuildContext context) {
    return Container(
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

  Widget _errorFilter(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(
        top: 15.0,
      ),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: Column(children: <Widget>[
        new Container(
          width: 80.0,
          height: 80.0,
          child: Image.asset("images/system-eror.png"),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 10.0,
            left: 15.0,
            right: 15.0,
          ),
          child: Center(
            child: Text(
              "Gagal Memuat Data, Silahkan Coba Kembali",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildBar(BuildContext context) {
    return PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: appBarTitle,
          titleSpacing: iconButtonAppbarColor ? 15.0 : 0.0,
          backgroundColor: primaryAppBarColor,
          automaticallyImplyLeading: actionBackAppBar,
          actions: <Widget>[
            Container(
              color: iconButtonAppbarColor == true
                  ? primaryAppBarColor
                  : Colors.white,
              child: IconButton(
                icon: actionIcon,
                onPressed: isLoading == true || isError == true
                    ? null
                    : () {
                        setState(() {
                          if (this.actionIcon.icon == Icons.search) {
                            actionBackAppBar = false;
                            iconButtonAppbarColor = false;
                            this.actionIcon = new Icon(
                              Icons.close,
                              color: Colors.black87,
                            );
                            this.appBarTitle = Container(
                              height: 50.0,
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(0),
                              margin: EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                              ),
                              child: TextField(
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                controller: _searchQuery,
                                onSubmitted: (string) {
                                  if (string != null || string != '') {
                                    filterDataTodo();
                                  }
                                },
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: new Icon(Icons.search,
                                      color: Colors.black87),
                                  hintText: "Cari To Do Anda Sekarang Juga",
                                  hintStyle: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            _handleSearchEnd();
                          }
                        });
                      },
              ),
            ),
          ],
        ));
  }
}
