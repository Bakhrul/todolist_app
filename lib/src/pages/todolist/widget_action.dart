import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/models/todo_action.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';

class ActionTodo extends StatefulWidget {
  @override
  _ActionTodoState createState() => _ActionTodoState();
}

class _ActionTodoState extends State<ActionTodo> {
  String tokenType, accessToken;
  bool isLoading, isError;
  Map<String, String> requestHeaders = Map();
  List<TodoAction> listTodoAction = [];
  
  @override
  void initState() {
    getHeaderHTTP();
    super.initState();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataTodoAction();
  }

  Future<List<List>> getDataTodoAction() async {
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
          await http.get(url('api/todo/list/actions'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var participants = listParticipantToJson;
        print(participants);
        for (var i in participants) {
          TodoAction participant = TodoAction(
            id: i['id'],
            title: i['title'].toString(),
            created: DateTime.parse(i['created']) ,
            done: i['done']
          );
          listTodoAction.add(participant);
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
      setState(() {
        isLoading = false;
        isError = true;
      });
      debugPrint('$e');
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Widget"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: SingleChildScrollView(
            child: Column(children: <Widget>[
                ExpandablePanel(
                  header: Text("Action"),
                  collapsed: Text("Action 1"),
                  expanded: 
                  Column(children: <Widget>[
                    for(int index = 0; index < listTodoAction.length; index++)
                    Card(
                      child: ListTile(
                        leading: Checkbox(
                          activeColor: Colors.green,
                          value: true, onChanged: (bool value) { 

                           },
                        ),
                        title: Text("${listTodoAction[index].title}",style: TextStyle(decoration:TextDecoration.lineThrough),),
                      ),)
                  ],)
                  ,
                  tapHeaderToExpand: true,
                  hasIcon: true,
                )
            ],),),),
      ),
    );
  }
}