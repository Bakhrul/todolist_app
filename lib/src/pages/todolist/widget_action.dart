// import 'dart:convert';
// import 'dart:async';
// import 'package:http/http.dart' as http;

// import 'package:expandable/expandable.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:progress_dialog/progress_dialog.dart';
// import 'package:todolist_app/src/models/todo_action.dart';
// import 'package:todolist_app/src/routes/env.dart';
// import 'package:todolist_app/src/storage/storage.dart';
// import 'package:todolist_app/src/utils/utils.dart';

// class ActionTodo extends StatefulWidget {
//   @override
//   _ActionTodoState createState() => _ActionTodoState();
// }

// class _ActionTodoState extends State<ActionTodo> {
//   String tokenType, accessToken;
//   bool isLoading, isError,isDone;
//   Map<String, String> requestHeaders = Map();
//   List<TodoAction> listTodoAction = [];
//   ProgressDialog progressApiAction;
//   TextEditingController _titleController = TextEditingController();
  
//   @override
//   void initState() {
//     getHeaderHTTP();
//     super.initState();
//   }

//  @override
//   void dispose(){
//     _titleController.dispose();

//     super.dispose();
//   }

//   Future<void> getHeaderHTTP() async {
//     var storage = new DataStore();
    

//     var tokenTypeStorage = await storage.getDataString('token_type');
//     var accessTokenStorage = await storage.getDataString('access_token');

//     tokenType = tokenTypeStorage;
//     accessToken = accessTokenStorage;

//     requestHeaders['Accept'] = 'application/json';
//     requestHeaders['Authorization'] = '$tokenType $accessToken';
//     return getDataTodoAction();
//   }

//   Future<List<List>> getDataTodoAction() async {
//     var storage = new DataStore();
//     var tokenTypeStorage = await storage.getDataString('token_type');
//     var accessTokenStorage = await storage.getDataString('access_token');

//     tokenType = tokenTypeStorage;
//     accessToken = accessTokenStorage;
//     requestHeaders['Accept'] = 'application/json';
//     requestHeaders['Authorization'] = '$tokenType $accessToken';

//     listTodoAction.clear();
//     setState(() {
//       isLoading = true;
//     });
//     try {
//       final participant =
//           await http.get(url('api/todo/list/actions'), headers: requestHeaders);

//       if (participant.statusCode == 200) {
//         var listParticipantToJson = json.decode(participant.body);
//         var participants = listParticipantToJson;
//         print(participants);
//         for (var i in participants) {
//           // if(i['done'] == null){
//           //   isDone = false;
//           // }else{
//           //   isDone = true;
//           // }
//           TodoAction participant = TodoAction(
//             id: i['id'],
//             title: i['title'].toString(),
//             created: DateTime.parse(i['created']),
//             done: i['done'],
//             valid: i['valid']

//           );
//           listTodoAction.add(participant);
//         }

//         setState(() {
          
//           isLoading = false;
//           isError = false;
//         });
//       } else if (participant.statusCode == 401) {
//         Fluttertoast.showToast(
//             msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
//         setState(() {
//           isLoading = false;
//           isError = true;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//           isError = true;
//         });
//         print(participant.body);
//         return null;
//       }
//     } on TimeoutException catch (_) {
//       setState(() {
//         isLoading = false;
//         isError = true;
//       });
//       Fluttertoast.showToast(msg: "Timed out, Try again");
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         isError = true;
//       });
//       debugPrint('$e');
//     }
//     return null;
//   }

//   void checkedDone(value,index) async {
//     // await progressApiAction.show();
//     try {
//       // Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
//       print(listTodoAction[index].id);
//       var body = {
//         'id': listTodoAction[index].id.toString(),
//         'todo': '10',
//         'done':value.toString()
//       };
//       final addpeserta = await http
//           .patch(url('api/todo/list/actions/${listTodoAction[index].id}'), headers: requestHeaders, body: body );
//     print(body);
//       if (addpeserta.statusCode == 200) {
//         var addpesertaJson = json.decode(addpeserta.body);
//     print(addpesertaJson);

//         if (addpesertaJson['status'] == 'success') {
//           // getHeaderHTTP();
//           setState(() {
//             listTodoAction[index].done = value.toString();
//           });
//           Fluttertoast.showToast(msg: "Berhasil");
//           // progressApiAction.hide().then((isHidden) {});
//         } else if (addpesertaJson['status'] == 'owner') {
//           Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
//           // progressApiAction.hide().then((isHidden) {});
//           // setState(() {
//           //   isCreate = false;
//           // });
//         } else if (addpesertaJson['status'] == 'exists') {
//           Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
//           // progressApiAction.hide().then((isHidden) {});
//           // setState(() {
//           //   isCreate = false;
//           // });
//         } else {
//           Fluttertoast.showToast(msg: "Status Tidak Diketahui");
//           // progressApiAction.hide().then((isHidden) {});
//           Navigator.pop(context);
//           // setState(() {
//           //   isCreate = false;todo/list/actions
//           // });
//         }
//       } else {
//         print(addpeserta.body);
//         Navigator.pop(context);
//         Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
//         // progressApiAction.hide().then((isHidden) {});
//         // setState(() {
//         //   isCreate = false;
//         // });
//       }
//     } on TimeoutException catch (_) {
//       Fluttertoast.showToast(msg: "Timed out, Try again");
//       // progressApiAction.hide().then((isHidden) {});
//       // setState(() {
//       //   isCreate = false;
//       // });
//       Navigator.pop(context);
//     } catch (e) {
//       Fluttertoast.showToast(msg: "${e.toString()}");
//       // progressApiAction.hide().then((isHidden) {});
//       // setState(() {
//       //   isCreate = false;
//       // });
//       print(e);
//     }
//   }

//   void tambahAction() async {
//     await progressApiAction.show();
//     try {
//       Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
//       final addpeserta = await http
//           .post(url('api/todo/list/actions'), headers: requestHeaders, body: {
//         'todo': '10',
//         'title': _titleController.text.toString(),
//       });
//       Navigator.pop(context);
//       if (addpeserta.statusCode == 200) {
//         var addpesertaJson = json.decode(addpeserta.body);
//         if (addpesertaJson['status'] == 'success') {
//           getHeaderHTTP();
//           setState(() {
//             _titleController.text = '';
//             // listTodoAction[index].done = value.toString();
//           });
//           Fluttertoast.showToast(msg: "Berhasil");
//           progressApiAction.hide().then((isHidden) {});
//         } else if (addpesertaJson['status'] == 'owner') {
//           Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
//           progressApiAction.hide().then((isHidden) {});
//           // setState(() {
//           //   isCreate = false;
//           // });
//         } else if (addpesertaJson['status'] == 'exists') {
//           Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
//           progressApiAction.hide().then((isHidden) {});
//           // setState(() {
//           //   isCreate = false;
//           // });
//         } else {
//           Fluttertoast.showToast(msg: "Status Tidak Diketahui");
//           progressApiAction.hide().then((isHidden) {});
//           Navigator.pop(context);
//           // setState(() {
//           //   isCreate = false;
//           // });
//         }
//       } else {
//         print(addpeserta.body);
//         Navigator.pop(context);
//         Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
//         progressApiAction.hide().then((isHidden) {});
//         // setState(() {
//         //   isCreate = false;
//         // });
//       }
//     } on TimeoutException catch (_) {
//       Fluttertoast.showToast(msg: "Timed out, Try again");
//       progressApiAction.hide().then((isHidden) {});
//       // setState(() {
//       //   isCreate = false;
//       // });
//       Navigator.pop(context);
//     } catch (e) {
//       Fluttertoast.showToast(msg: "${e.toString()}");
//       progressApiAction.hide().then((isHidden) {});
//       // setState(() {
//       //   isCreate = false;
//       // });
//       print(e);
//     }
//   }

//  void _showModal(){
//    setState(() {
//      _titleController.text = '';
//    });
//         showModalBottomSheet(
//             context: context,
//             builder: (builder){
//               return new Container(
//                 height: 350.0,
//                 color: Colors.transparent, //could change this to Color(0xFF737373), 
//                            //so you don't have to change MaterialApp canvasColor
//                 child: new Container(
//                     decoration: new BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: new BorderRadius.only(
//                             topLeft: const Radius.circular(40.0),
//                             topRight: const Radius.circular(40.0))),
//                     child: new Column(
//                       children: <Widget>[
//                         ListTile(
//                           leading: InkWell(
//                             onTap: (){
//                               Navigator.pop(context);
//                             },
//                             child: Icon(Icons.arrow_back)),
//                           title: Center(child: Text("Tambah Action")),
//                         ),
//                         Divider(),
//                         Row(
//                           children: <Widget>[
//                             Expanded(
//                               child:  Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Container(
//                                       alignment: Alignment.center,
//                                       height: 45.0,
//                                       margin: EdgeInsets.only(
//                                           bottom: 10.0, top: 10.0),
//                                       child: TextField(
//                                         textAlignVertical:
//                                             TextAlignVertical.center,
//                                         decoration: InputDecoration(
//                                             border: OutlineInputBorder(),
//                                             hintText: 'Judul Action',
//                                             hintStyle: TextStyle(
//                                                 fontSize: 12,
//                                                 color: Colors.black)),
//                                         controller: _titleController,
//                                       )),
//                               ),
//                             ),
                            
//                           ],
                        
//                         ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Align(
//                               alignment: Alignment.bottomRight,
//                                 child: RaisedButton(
//                                   onPressed: (){
//                                     tambahAction();
//                                   },
//                                   child: Text("Simpan"),
//                                 ),),
//                           )
//                       ],
//                     )),
//               );
//             }
//         );
//       }


//   @override
//   Widget build(BuildContext context) {
//     progressApiAction = new ProgressDialog(context,
//         type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);
//     progressApiAction.style(
//         message: 'Tunggu Sebentar...',
//         borderRadius: 10.0,
//         backgroundColor: Colors.white,
//         progressWidget: CircularProgressIndicator(),
//         elevation: 10.0,
//         insetAnimCurve: Curves.easeInOut,
//         messageTextStyle: TextStyle(
//             color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.w600));
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Action"),
//         backgroundColor: primaryAppBarColor,
//       ),

//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Container(
//           child: SingleChildScrollView(
//             child: Column(children: <Widget>[
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: RaisedButton(
//                     onPressed: (){
//                       _showModal();
//                     },
//                     child: Icon(Icons.add),
//                   ),
//                 ),
//                 Divider(),
//                 ExpandablePanel(
                  
//                   header: Center(child: Text("Action",style:TextStyle(fontWeight: FontWeight.bold)),),
//                   collapsed: Column(
//                     children: <Widget>[
//                       // for(int index = 0; index < 3; index++)
//                       // Card(
//                       // child: ListTile(
//                       //   leading: Checkbox(
//                       //     activeColor: Colors.green,
//                       //     value: listTodoAction[index].done == 'false' ? false : true, onChanged: (bool value) { 
//                       //       checkedDone(value,index);
//                       //      },
//                       //   ),
//                       //   title: 
//                       //   listTodoAction[index].done == 'true' ?
//                       //   Text("${listTodoAction[index].title}",  style: TextStyle(decoration:TextDecoration.lineThrough),)
//                       //   : 
//                       //   Text("${listTodoAction[index].title}")
//                       // ),)
//                     ],
//                   ),
//                   expanded: 
//                   Column(children: <Widget>[
//                     for(int index = 0; index < listTodoAction.length; index++)
//                     Card(
//                       child: ListTile(
//                         leading: Checkbox(
//                           activeColor: listTodoAction[index].done != null && listTodoAction[index].valid != null ? Colors.green : Colors.yellow,
//                           value: listTodoAction[index].done != null ? true : false, onChanged: (bool value) { 
//                             checkedDone(value,index);
//                            },
//                         ),
//                         title: 
//                         listTodoAction[index].done != null ?
//                         Text("${listTodoAction[index].title}",  style: TextStyle(decoration:TextDecoration.lineThrough),)
//                         : 
//                         Text("${listTodoAction[index].title}")
//                       ),)
//                   ],)
//                   ,
//                   tapHeaderToExpand: true,
//                   hasIcon: true,
//                 )
//             ],),),),
//       ),
//     );
//   }
// }