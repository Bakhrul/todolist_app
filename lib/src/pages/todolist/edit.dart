// import 'dart:convert';
// import 'dart:async';
// import 'dart:ui';
// import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
// import 'package:expandable/expandable.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:todolist_app/src/pages/todolist/add_peserta.dart';
// import 'package:todolist_app/src/utils/utils.dart';
// import 'package:todolist_app/src/models/category.dart';
// import 'package:todolist_app/src/routes/env.dart';
// import 'package:shimmer/shimmer.dart';
// import 'choose_project.dart';
// import 'package:todolist_app/src/storage/storage.dart';
// import 'package:progress_dialog/progress_dialog.dart';

// String tokenType, accessToken;
// String categoriesID;
// String categoriesName;
// bool isLoading, isError;
// String idProjectChoose;
// String namaProjectChoose;

// class EditTodo extends StatefulWidget {
//   EditTodo({Key key, this.idTodo}) : super(key: key);
//   final idTodo;
//   @override
//   _EditTodoState createState() => _EditTodoState();
// }

// class _EditTodoState extends State<EditTodo> {
//   ProgressDialog progressApiAction;
//   final _formKey = GlobalKey<FormState>();
//   final format = DateFormat("yyyy-MM-dd HH:mm:ss");
//   DateTime timeReplacement;
//   List<Category> listCategory = [];
//   String titleTodo, planStartTodo, planEndTodo, categoryTodo, descTodo;

//   TextEditingController _titleController = TextEditingController();
//   TextEditingController _dateStartController = TextEditingController();
//   TextEditingController _dateEndController = TextEditingController();
//   TextEditingController _descController = TextEditingController();
//   TextEditingController _categoryController = TextEditingController();
//   Map<String, String> requestHeaders = Map();

//   void timeSetToMinute() {
//     var time = DateTime.now();
//     var newHour = 0;
//     var newMinute = 0;
//     var newSecond = 0;
//     time = time.toLocal();
//     timeReplacement = new DateTime(time.year, time.month, time.day, newHour,
//         newMinute, newSecond, time.millisecond, time.microsecond);
//   }

//   Future<void> getHeaderHTTP() async {
//     var storage = new DataStore();

//     var tokenTypeStorage = await storage.getDataString('token_type');
//     var accessTokenStorage = await storage.getDataString('access_token');

//     tokenType = tokenTypeStorage;
//     accessToken = accessTokenStorage;

//     requestHeaders['Accept'] = 'application/json';
//     requestHeaders['Authorization'] = '$tokenType $accessToken';
//     return getDataEdit();
//   }

//   Future<List<List>> getDataEdit() async {
//     var storage = new DataStore();
//     var tokenTypeStorage = await storage.getDataString('token_type');
//     var accessTokenStorage = await storage.getDataString('access_token');

//     tokenType = tokenTypeStorage;
//     accessToken = accessTokenStorage;
//     requestHeaders['Accept'] = 'application/json';
//     requestHeaders['Authorization'] = '$tokenType $accessToken';

//     setState(() {
//       isLoading = true;
//     });
//     try {
//       final participant = await http.get(url('api/todo/edit/${widget.idTodo}'),
//           headers: requestHeaders);

//       if (participant.statusCode == 200) {
//         var listParticipantToJson = json.decode(participant.body);
//         var todos = listParticipantToJson;

//         setState(() {
//           isLoading = false;
//           isError = false;
//           _titleController.text = todos['title'];
//           _dateStartController.text = todos['planstart'];
//           _dateEndController.text = todos['plnend'];
//           _descController.text = todos['desc'];
//           categoriesName = todos['category_name'];
//           categoriesID = todos['category_id'].toString();
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

//   Future<List<List>> getDataCategory() async {
//     var storage = new DataStore();
//     var tokenTypeStorage = await storage.getDataString('token_type');
//     var accessTokenStorage = await storage.getDataString('access_token');

//     tokenType = tokenTypeStorage;
//     accessToken = accessTokenStorage;
//     requestHeaders['Accept'] = 'application/json';
//     requestHeaders['Authorization'] = '$tokenType $accessToken';

//     setState(() {
//       isLoading = true;
//     });
//     try {
//       final participant =
//           await http.get(url('api/category'), headers: requestHeaders);

//       if (participant.statusCode == 200) {
//         var listParticipantToJson = json.decode(participant.body);
//         var participants = listParticipantToJson;
//         print(participants);
//         for (var i in participants) {
//           Category participant = Category(
//             id: i['id'],
//             name: i['name'].toString(),
//           );
//           listCategory.add(participant);
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

//   Future<void> saveTodo() async {
//     await progressApiAction.show();
//     try {
//       dynamic body = {
//         "title": _titleController.text.toString(),
//         "planstart": _dateStartController.text.toString(),
//         "planend": _dateEndController.text.toString(),
//         "desc": _descController.text.toString(),
//         "category": categoriesID.toString(),
//         'project': idProjectChoose.toString(),
//       };

//       final addadminevent = await http.patch(url('api/todo/update/${widget.idTodo}'),
//           headers: requestHeaders, body: body);
//       print(addadminevent.statusCode);
//       if (addadminevent.statusCode == 200) {
//         var addpesertaJson = json.decode(addadminevent.body);
//         if (addpesertaJson['status'] == 'success') {
//           Fluttertoast.showToast(msg: "Berhasil !");
//           progressApiAction.hide().then((isHidden) {});
//           Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
//         }
//       } else {
//         print(addadminevent.body);
//         progressApiAction.hide().then((isHidden) {});
//         Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
//       }
//     } on TimeoutException catch (_) {
//       progressApiAction.hide().then((isHidden) {});
//       Fluttertoast.showToast(msg: "Timed out, Try again");
//     } catch (e) {
//       progressApiAction.hide().then((isHidden) {});
//       Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
//       print(e);
//     }
//   }

//   void dispose() {
//     _titleController.dispose();
//     _descController.dispose();
//     _dateStartController.dispose();
//     _dateEndController.dispose();
//     _categoryController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     getHeaderHTTP();
//     namaProjectChoose = null;
//     _titleController.text = '';
//     _dateStartController.text = '';
//     _dateEndController.text = '';
//     _descController.text = '';
//     categoriesID = null;
//     idProjectChoose = null;
//     getDataCategory();
//     timeSetToMinute();
//     super.initState();
//   }

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
//       backgroundColor:
//           isError == true ? Colors.white : Color.fromRGBO(242, 242, 242, 1),
//       appBar: AppBar(
//         backgroundColor: primaryAppBarColor,
//         title: Text(
//           "Edit To Do",
//           style: TextStyle(
//             fontSize: 14,
//           ),
//         ),
//       ),
//       body: Container(
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: <Widget>[
//                 isLoading == true
//                     ? _loadingview()
//                     : isError == true
//                         ? Container(
//                             color: Colors.white,
//                             margin: EdgeInsets.only(
//                                 top: 15.0, left: 10.0, right: 10.0),
//                             padding:
//                                 const EdgeInsets.only(top: 10.0, bottom: 25.0),
//                             child: RefreshIndicator(
//                               onRefresh: () => getDataCategory(),
//                               child: Column(children: <Widget>[
//                                 new Container(
//                                   width: 100.0,
//                                   height: 100.0,
//                                   child: Image.asset("images/system-eror.png"),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.only(
//                                     top: 30.0,
//                                     left: 15.0,
//                                     right: 15.0,
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       "Gagal memuat halaman, tekan tombol muat ulang halaman untuk refresh halaman",
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         color: Colors.black54,
//                                         height: 1.5,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.only(
//                                       top: 15.0,
//                                       left: 15.0,
//                                       right: 15.0,
//                                       bottom: 15.0),
//                                   child: SizedBox(
//                                     width: double.infinity,
//                                     child: RaisedButton(
//                                       color: Colors.white,
//                                       textColor: primaryAppBarColor,
//                                       disabledColor: Colors.grey,
//                                       disabledTextColor: Colors.black,
//                                       padding: EdgeInsets.all(15.0),
//                                       onPressed: () async {
//                                         getDataCategory();
//                                       },
//                                       child: Text(
//                                         "Muat Ulang Halaman",
//                                         style: TextStyle(
//                                             fontSize: 14.0,
//                                             fontWeight: FontWeight.w500),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ]),
//                             ),
//                           )
//                         : Container(
//                             margin: EdgeInsets.only(top: 10.0),
//                             color: Colors.white,
//                             width: double.infinity,
//                             padding: EdgeInsets.only(
//                               left: 10.0,
//                               right: 10.0,
//                               top: 20.0,
//                               bottom: 15.0,
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Container(
//                                   margin: EdgeInsets.only(bottom: 10.0),
//                                   child: Text(
//                                     'Edit To Do',
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.w500),
//                                   ),
//                                 ),
//                                 Divider(),
//                                 Container(
//                                     alignment: Alignment.center,
//                                     height: 45.0,
//                                     margin: EdgeInsets.only(
//                                         bottom: 10.0, top: 10.0),
//                                     child: TextField(
//                                       textAlignVertical:
//                                           TextAlignVertical.center,
//                                       decoration: InputDecoration(
//                                           border: OutlineInputBorder(),
//                                           hintText: 'Nama To Do',
//                                           hintStyle: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.black)),
//                                       controller: _titleController,
//                                     )),
//                                 Container(
//                                     alignment: Alignment.center,
//                                     height: 45.0,
//                                     margin: EdgeInsets.only(bottom: 10.0),
//                                     child: DateTimeField(
//                                       controller: _dateStartController,
//                                       format: format,
//                                       readOnly: true,
//                                       decoration: InputDecoration(
//                                         contentPadding: EdgeInsets.only(
//                                             top: 2,
//                                             bottom: 2,
//                                             left: 10,
//                                             right: 10),
//                                         border: OutlineInputBorder(),
//                                         hintText: 'Tanggal Berakhirnya To Do',
//                                         hintStyle: TextStyle(
//                                             fontSize: 12, color: Colors.black),
//                                       ),
//                                       onShowPicker:
//                                           (context, currentValue) async {
//                                         final date = await showDatePicker(
//                                             context: context,
//                                             firstDate: DateTime.now(),
//                                             initialDate: DateTime.now(),
//                                             lastDate: DateTime(2100));
//                                         if (date != null) {
//                                           final time = await showTimePicker(
//                                             context: context,
//                                             initialTime: TimeOfDay.fromDateTime(
//                                                 currentValue ??
//                                                     timeReplacement),
//                                           );
//                                           return DateTimeField.combine(
//                                               date, time);
//                                         } else {
//                                           return currentValue;
//                                         }
//                                       },
//                                       onChanged: (ini) {
//                                         setState(() {
//                                           _dateEndController.text = '';
//                                         });
//                                       },
//                                     )),
//                                 Container(
//                                     alignment: Alignment.center,
//                                     height: 45.0,
//                                     margin: EdgeInsets.only(bottom: 10.0),
//                                     child: DateTimeField(
//                                       controller: _dateEndController,
//                                       format: format,
//                                       readOnly: true,
//                                       decoration: InputDecoration(
//                                         border: OutlineInputBorder(),
//                                         contentPadding: EdgeInsets.only(
//                                             top: 2,
//                                             bottom: 2,
//                                             left: 10,
//                                             right: 10),
//                                         hintText: 'Tanggal Berakhirnya To Do',
//                                         hintStyle: TextStyle(
//                                             fontSize: 12, color: Colors.black),
//                                       ),
//                                       onShowPicker:
//                                           (context, currentValue) async {
//                                         final date = await showDatePicker(
//                                             context: context,
//                                             firstDate: _dateStartController
//                                                         .text ==
//                                                     ''
//                                                 ? DateTime.now()
//                                                 : DateTime.parse(
//                                                     _dateStartController.text),
//                                             initialDate: _dateStartController
//                                                         .text ==
//                                                     ''
//                                                 ? DateTime.now()
//                                                 : DateTime.parse(
//                                                     _dateStartController.text),
//                                             lastDate: DateTime(2100));
//                                         if (date != null) {
//                                           final time = await showTimePicker(
//                                             context: context,
//                                             initialTime: TimeOfDay.fromDateTime(
//                                                 currentValue ??
//                                                     timeReplacement),
//                                           );
//                                           return DateTimeField.combine(
//                                               date, time);
//                                         } else {
//                                           return currentValue;
//                                         }
//                                       },
//                                     )),
//                                 InkWell(
//                                   onTap: () async {
//                                     showCategory();
//                                   },
//                                   child: Container(
//                                     height: 45.0,
//                                     padding: EdgeInsets.only(
//                                         left: 10.0, right: 10.0),
//                                     width: double.infinity,
//                                     decoration: BoxDecoration(
//                                         border:
//                                             Border.all(color: Colors.black45),
//                                         borderRadius: BorderRadius.all(
//                                             Radius.circular(5.0))),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: <Widget>[
//                                         Text(
//                                             categoriesID == null
//                                                 ? "Pilih Kategori"
//                                                 : 'Kategori - $categoriesName',
//                                             style: TextStyle(fontSize: 12),
//                                             textAlign: TextAlign.left),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 categoriesID == '1'
//                                     ? GestureDetector(
//                                         onTap: () async {
//                                           await Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       ChooseProjectAvailable()));
//                                           setState(() {
//                                             namaProjectChoose =
//                                                 namaProjectChoose;
//                                           });
//                                         },
//                                         child: Container(
//                                           height: 45.0,
//                                           margin: EdgeInsets.only(top: 10.0),
//                                           padding: EdgeInsets.only(
//                                               left: 10.0, right: 10.0),
//                                           width: double.infinity,
//                                           decoration: BoxDecoration(
//                                               border: Border.all(
//                                                   color: Colors.black45),
//                                               borderRadius: BorderRadius.all(
//                                                   Radius.circular(5.0))),
//                                           child: Row(
//                                             // crossAxisAlignment:
//                                             //     CrossAxisAlignment.start,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: <Widget>[
//                                               Expanded(
//                                                 child: Text(
//                                                     namaProjectChoose == null
//                                                         ? 'Pilih Project'
//                                                         : 'Project $namaProjectChoose',
//                                                     style: TextStyle(
//                                                       fontSize: 12,
//                                                     ),
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     softWrap: true,
//                                                     maxLines: 1,
//                                                     textAlign: TextAlign.left),
//                                               ),
//                                               Icon(Icons.chevron_right),
//                                             ],
//                                           ),
//                                         ),
//                                       )
//                                     : Container(),
//                                 Container(
//                                     margin: EdgeInsets.only(
//                                         bottom: 10.0, top: 10.0),
//                                     height: 120.0,
//                                     child: TextField(
//                                       maxLines: 10,
//                                       controller: _descController,
//                                       textAlignVertical:
//                                           TextAlignVertical.center,
//                                       decoration: InputDecoration(
//                                           border: OutlineInputBorder(),
//                                           hintText: 'Deskripsi',
//                                           hintStyle: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.black)),
//                                     )),
//                                 ExpandablePanel(
//                                   header: Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Row(
//                                       children:<Widget>[
//                                         Text("Tambah Peserta",style: TextStyle(fontWeight: FontWeight.bold),),
//                                       Icon(Icons.arrow_drop_down),
//                                       ]
                                       

//                                     ),
//                                   ),
//                                   hasIcon: false,
//                                   tapHeaderToExpand: true,
                                  
//                                   expanded: Column(children: <Widget>[
//                                 //     InkWell(
//                                 //   onTap: () async {
                                    
//                                 //   },
//                                 //   child: Container(
//                                 //     height: 45.0,
//                                 //     padding: EdgeInsets.only(
//                                 //         left: 10.0, right: 10.0),
//                                 //     width: double.infinity,
//                                 //     decoration: BoxDecoration(
//                                 //         border:
//                                 //             Border.all(color: Colors.black45),
//                                 //         borderRadius: BorderRadius.all(
//                                 //             Radius.circular(5.0))),
//                                 //     child: Column(
//                                 //       crossAxisAlignment:
//                                 //           CrossAxisAlignment.start,
//                                 //       mainAxisAlignment:
//                                 //           MainAxisAlignment.center,
//                                 //       children: <Widget>[
//                                 //         Text(
//                                 //             categoriesID == null
//                                 //                 ? "Tambahkan Peserta"
//                                 //                 : 'Peserta - $categoriesName',
//                                 //             style: TextStyle(fontSize: 12),
//                                 //             textAlign: TextAlign.left),
//                                 //       ],
//                                 //     ),
//                                 //   ),
//                                 // ),
//                                 FlatButton(
//                                   child: Text("Pilih Peserta"),
//                                   onPressed: (){
//                                     Navigator.push(context,MaterialPageRoute(builder: (context) => AddPeserta( idtodo: widget.idTodo)));
//                                   },
//                                 )
//                                   ],)
//                                   // tapHeaderToExpand: true,
//                                   // hasIcon: true,
//                                 ),
//                                 Center(
//                                     child: Container(
//                                         margin: EdgeInsets.only(top: 10.0),
//                                         width: double.infinity,
//                                         height: 40.0,
//                                         child: RaisedButton(
//                                             onPressed: () async {
//                                               if (_titleController.text == '') {
//                                                 Fluttertoast.showToast(
//                                                     msg:
//                                                         "Nama To Do Tidak Boleh Kosong");
//                                               } else if (categoriesID
//                                                           .toString() ==
//                                                       '' ||
//                                                   categoriesID == null) {
//                                                 Fluttertoast.showToast(
//                                                     msg:
//                                                         "Kategori Tidak Boleh Kosong");
//                                               } else if (_dateStartController
//                                                       .text ==
//                                                   '') {
//                                                 Fluttertoast.showToast(
//                                                     msg:
//                                                         "Tanggal Dimulainya To Do Tidak Boleh Kosong");
//                                               } else if (_dateEndController
//                                                       .text ==
//                                                   '') {
//                                                 Fluttertoast.showToast(
//                                                     msg:
//                                                         "Tanggal Berakhirnya To Do Tidak Boleh Kosong");
//                                               } else if (_descController.text ==
//                                                   '') {
//                                                 Fluttertoast.showToast(
//                                                     msg:
//                                                         "Deskripsi tidak boleh kosong");
//                                               } else if (categoriesID
//                                                       .toString() ==
//                                                   '1') {
//                                                 if (idProjectChoose == null) {
//                                                   Fluttertoast.showToast(
//                                                       msg:
//                                                           "Silahkan Pilih Project Terlebih Dahulu");
//                                                 } else {
//                                                   saveTodo();
//                                                 }
//                                               } else {
//                                                 saveTodo();
//                                               }
//                                             },
//                                             color: primaryAppBarColor,
//                                             textColor: Colors.white,
//                                             disabledColor: Color.fromRGBO(
//                                                 254, 86, 14, 0.7),
//                                             disabledTextColor: Colors.white,
//                                             splashColor: Colors.blueAccent,
//                                             child: Text("SImpan To Do",
//                                                 style: TextStyle(
//                                                     fontSize: 12,
//                                                     color: Colors.white)))))
//                               ],
//                             )),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

// void showPeserta() {
//     showModalBottomSheet(
//         isScrollControlled: true,
//         context: context,
//         builder: (builder) {
//           return Container(
//             height: 200.0 + MediaQuery.of(context).viewInsets.bottom,
//             padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//                 // right: 5.0,
//                 // left: 5.0,
//                 // top: 24.5
//                 ),
//             child: Column(
//               children: <Widget>[
//                 Container(
//                         height: 85.0,
//                         alignment: Alignment.center,
//                         padding: EdgeInsets.all(0),
//                         margin: EdgeInsets.all(0),
//                         decoration: BoxDecoration(
//                           color: primaryAppBarColor,
//                         ),
//                         child: TextField(
//                           autofocus: true,
//                           // controller: _searchQuery,
//                           onChanged: (string) {
//                             // if (string != null || string != '') {
//                             //   _debouncer.run(() {
//                             //     listUserfilter();
//                             //   });
//                             // }
//                           },
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                           ),
//                           textAlignVertical: TextAlignVertical.center,
//                           decoration: InputDecoration(
//                             border: InputBorder.none,
//                             hintText: "Cari Berdasarkan Email Pengguna",
//                             hintStyle: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                             ),
//                              prefixIcon:
//                                 new Icon(Icons.search, color: Colors.white),
//                           ),
//                         ),
//                   ),
//                SizedBox.expand(
//         child: DraggableScrollableSheet(
//           builder: (BuildContext context, ScrollController scrollController) {
//             return Container(
//               color: Colors.blue[100],
//               child: ListView.builder(
//                 // controller: scrollController,
//                 itemCount: 25,
//                 itemBuilder: (BuildContext context, int index) {
//                   return ListTile(title: Text('Item $index'));
//                 },
//               ),
//             );
//           }
//         )
//                ),
//                 //  ListView(children: <Widget>[
                    
//                 //     for (int i = 0; i < listCategory.length; i++)
//                 //       InkWell(
//                 //           onTap: () async {
//                 //             setState(() {
//                 //               categoriesID = listCategory[i].id.toString();
//                 //               categoriesName = listCategory[i].name.toString();
//                 //             });
//                 //             Navigator.pop(context);
//                 //           },
//                 //           child: Container(
//                 //             width: double.infinity,
//                 //             child: Card(
//                 //               child: Padding(
//                 //                 padding: const EdgeInsets.all(15.0),
//                 //                 child: Text(listCategory[i].name),
//                 //               ),
//                 //             ),
//                 //           )),
//                 //   ]),
                
//               ],
//             ),
//           );
//         });
//   }

//   void showCategory() {
//     showModalBottomSheet(
//         isScrollControlled: true,
//         context: context,
//         builder: (builder) {
//           return Container(
//             // height: 200.0 + MediaQuery.of(context).viewInsets.bottom,
//             padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//                 right: 5.0,
//                 left: 5.0,
//                 top: 40.0),
//             child: Column(children: <Widget>[
//               for (int i = 0; i < listCategory.length; i++)
//                 InkWell(
//                     onTap: () async {
//                       setState(() {
//                         categoriesID = listCategory[i].id.toString();
//                         categoriesName = listCategory[i].name.toString();
//                       });
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       width: double.infinity,
//                       child: Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(15.0),
//                           child: Text(listCategory[i].name),
//                         ),
//                       ),
//                     )),
//             ]),
//           );
//         });
//   }

//   Widget _loadingview() {
//     return Container(
//         color: Colors.white,
//         margin: EdgeInsets.only(
//           top: 15.0,
//         ),
//         padding: EdgeInsets.all(15.0),
//         child: SingleChildScrollView(
//             child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 10.0),
//           child: Shimmer.fromColors(
//             baseColor: Colors.grey[300],
//             highlightColor: Colors.grey[100],
//             child: Column(
//               children: [
//                 0,
//                 1,
//                 2,
//                 3,
//                 4,
//                 5,
//                 6,
//                 7,
//               ]
//                   .map((_) => Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: <Widget>[
//                           Container(
//                             margin: EdgeInsets.only(bottom: 25.0),
//                             child: Row(
//                               children: <Widget>[
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius:
//                                         BorderRadius.all(Radius.circular(5.0)),
//                                   ),
//                                   width: 35.0,
//                                   height: 35.0,
//                                 ),
//                                 Expanded(
//                                   flex: 9,
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.start,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: <Widget>[
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           color: Colors.white,
//                                           borderRadius: BorderRadius.all(
//                                               Radius.circular(5.0)),
//                                         ),
//                                         margin: EdgeInsets.only(left: 15.0),
//                                         width: double.infinity,
//                                         height: 10.0,
//                                       ),
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           color: Colors.white,
//                                           borderRadius: BorderRadius.all(
//                                               Radius.circular(5.0)),
//                                         ),
//                                         margin: EdgeInsets.only(
//                                             left: 15.0, top: 15.0),
//                                         width: 100.0,
//                                         height: 10.0,
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         ],
//                       ))
//                   .toList(),
//             ),
//           ),
//         )));
//   }
// }
