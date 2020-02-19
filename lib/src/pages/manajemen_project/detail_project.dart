import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:todolist_app/src/utils/utils.dart';

import 'package:todolist_app/src/model/Todo.dart';
import 'package:todolist_app/src/model/Member.dart';

String tokenType, accessToken;
var datepickerfirst, datepickerlast;
List<Todo> listTodoProject = [];
List<Member> listMemberProject = [];
bool isLoading, isError;
Map<String, String> requestHeaders = Map();

class DetailProject extends StatefulWidget {
  DetailProject({Key key, this.title, this.idproject}) : super(key: key);
  final String title;
  final int idproject;
  @override
  State<StatefulWidget> createState() {
    return _DetailProjectState();
  }
}

class _DetailProjectState extends State<DetailProject>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  @override
  void initState() {
    _tabController =
        TabController(length: 2, vsync: _DetailProjectState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    super.initState();
    getHeaderHTTP();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
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
    print(widget.idproject);
    setState(() {
      isLoading = true;
    });
    try {
      final getDetailProject = await http
          .post(url('api/detail_project'), headers: requestHeaders, body: {
        'project': widget.idproject.toString(),
      });

      if (getDetailProject.statusCode == 200) {
        var getDetailProjectJson = json.decode(getDetailProject.body);
        print(getDetailProjectJson);
        var todos = getDetailProjectJson['todo'];
        var members = getDetailProjectJson['member'];

        for (var i in todos) {
          Todo todo = Todo(
            id: i['tl_id'],
            title: i['tl_title'],
            desc: i['tl_desc'],
            timestart: i['tl_timestart'],
            timeend: i['tl_timeend'],
            progress: i['tl_progress'],
            status: i['tl_status'],
          );
          listTodoProject.add(todo);
        }

        for (var i in members) {
          Member member = Member(
            iduser: i['tl_id'],
            name: i['us_name'],
            email: i['us_email'],
            roleid: i['mp_role'],
            rolename: i['r_name'],
          );
          listMemberProject.add(member);
        }

        setState(() {
          isLoading = false;
          isError = false;
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
      Fluttertoast.showToast(msg: "error");
      debugPrint('$e');
    }
    return null;
  }

  void _handleTabIndex() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryAppBarColor,
        title: Text('Manajemen Project', style: TextStyle(fontSize: 14)),
        actions: <Widget>[],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Member'),
            Tab(icon: Icon(Icons.person), text: 'Todo'),
          ],
        ),
      ), //
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            child: Container(
              child: Column(
                children: <Widget>[
                  Text('oke'),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              child: Column(
                children: <Widget>[
                  Text('oke'),
                ],
              ),
            ),
          ),
        ],
      ),

      // floatingActionButton: isEnable != true ? Container() : _bottomButtons(),
    );
  }
}
