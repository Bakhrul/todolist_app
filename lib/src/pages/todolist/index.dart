import 'dart:convert';
import 'dart:async';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/models/category.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';

String tokenType, accessToken;
String categoriesID;
String categoriesName;
TextEditingController _dateStartController = TextEditingController();
TextEditingController _dateEndController = TextEditingController();
DateTime timestart = _dateStartController.text != '' ? DateTime.parse(_dateStartController.text) : DateTime.now();

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final _formKey = GlobalKey<FormState>();
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
   DateTime timeReplacement;
  List<Category> listCategory = [];

  TextEditingController _titleController = TextEditingController();
  
  TextEditingController _descController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  Map<String, String> requestHeaders = Map();
  
    void timeSetToMinute() {
    var time = DateTime.now();
    var newHour = 0;
    var newMinute = 0;
    var newSecond = 0;
    time = time.toLocal();
    timeReplacement = new DateTime(time.year, time.month, time.day, newHour,
        newMinute, newSecond, time.millisecond, time.microsecond);
  }
   Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return requestHeaders;
   }

 Future<List<List>> getDataCategory() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      // isLoading = true;
    });
    try {
      final participant =
          await http.get(url('api/category'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var participants = listParticipantToJson;

        for (var i in participants) {
          Category participant = Category(
            id: i['id'],
            name: i['name'].toString(),
          );
          listCategory.add(participant);
        }

        setState(() {
          // isLoading = false;
          // isError = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          // isLoading = false;
          // isError = true;
        });
      } else {
        setState(() {
          // isLoading = false;
          // isError = true;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        // isLoading = false;
        // isError = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        // isLoading = false;
        // isError = true;
      });
      debugPrint('$e');
    }
    return null;
  }

  Future<void> saveTodo() async {
    //  _isLoading = true;
     Fluttertoast.showToast(msg: "Tunggu Sebentar...");
     if(_titleController.text == ''){
     return Fluttertoast.showToast(msg: "Judul Tidak Boleh Kosong");
     }else if(categoriesID.toString() == ''){
     return Fluttertoast.showToast(msg: "Kategori Tidak Boleh Kosong");
     }

    try {
    dynamic body = {
      "title": _titleController.text.toString(),
      "planstart": _dateStartController.text.toString(),
      "planend": _dateEndController.text.toString(),
      "desc": _descController.text.toString(),
      "category": categoriesID.toString(),
    };

   final addadminevent = await http
          .post(url('api/todo/create'), headers: requestHeaders, body: 
            body
      );
     if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {

          Fluttertoast.showToast(msg: "Berhasil !");
        Navigator.pushReplacementNamed(context, '/dashboard');

        }
      } else {
        print(addadminevent.body);
        // progressApiAction.hide().then((isHidden) {
        //   // print(isHidden);
        // });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      // progressApiAction.hide().then((isHidden) {
      //   print(isHidden);
      // });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      // progressApiAction.hide().then((isHidden) {
      //   print(isHidden);
      // });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }

  }

void dispose() {
  _titleController.dispose();
  _descController.dispose();
  // _dateStartController.dispose();
  // _dateEndController.dispose();
  _categoryController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    getHeaderHTTP();
    getDataCategory();
    timeSetToMinute();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Membuat ToDo"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          saveTodo();
        },
        child: Icon(Icons.navigate_next),
      ),
      body: Container(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                    width: double.infinity,
                    // height: MediaQuery.of(context).size.height / 2,
                    padding: EdgeInsets.only(
                      left: 50.0,
                      right: 50.0,
                      top: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            child: Text('Judul',
                                style: TextStyle(color: Colors.grey))),
                        Container(
                            margin: EdgeInsets.only(bottom: 20.0),
                            child: TextFormField(
                                controller: _titleController,
                                )),

                        Container(
                          margin: EdgeInsets.only(bottom: 5.0),
                          child: Text('Tanggal Mulai',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        Container(
                            margin: EdgeInsets.only(bottom: 20.0),
                            child: DateTimeField(
                              controller: _dateStartController,
                              format: format,
                              readOnly: true,
                              decoration: InputDecoration(
                                // border: InputBorder.none,
                                hintText: '',
                                hintStyle:
                                    TextStyle(fontSize: 13, color: Colors.black),
                              ),
                              onShowPicker: (context, currentValue) async {
                                final date = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime.now(),
                                    initialDate: DateTime.now(),
                                    lastDate: DateTime(2100));
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                        currentValue ?? timeReplacement),
                                  );
                                  return DateTimeField.combine(date, time);
                                } else {
                                  return currentValue;
                                }
                              },
                            )),
                             Container(
                          margin: EdgeInsets.only(bottom: 5.0),
                          child: Text('Tanggal Selesai',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        Container(
                            margin: EdgeInsets.only(bottom: 20.0),
                            child: DateTimeField(
                              controller: _dateEndController,
                              format: format,
                              readOnly: true,
                              decoration: InputDecoration(
                                // border: InputBorder.none,
                                hintText: '',
                                hintStyle:
                                    TextStyle(fontSize: 13, color: Colors.black),
                              ),
                              onShowPicker: (context, currentValue) async {
                                final date = await showDatePicker(
                                    context: context,
                                    firstDate: timestart,
                                    initialDate: timestart,
                                    lastDate: DateTime(2100));
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                        currentValue ?? timeReplacement),
                                  );
                                  return DateTimeField.combine(date, time);
                                } else {
                                  return currentValue;
                                }
                              },
                            )),
                             Container(
                          margin: EdgeInsets.only(bottom: 5.0),
                          child: Text('Kategori',
                              style: TextStyle(color: Colors.grey)),
                        ),
                         Container(
                            child: categoriesID == null ? FlatButton(
                              child: Text("Pilih Kategori"),
                              onPressed: (){
                                showCategory();
                              },
                              
                            ) : InkWell(
                              onTap: (){showCategory();},
                              child: Text("$categoriesName")),
                                ),
                                Divider(
                                  color: Colors.black,
                                ),
                                  Container(
                          margin: EdgeInsets.only(bottom: 5.0),
                          child: Text('Deskripsi',
                              style: TextStyle(color: Colors.grey)),
                        ),
                         Container(
                            child: TextField(
                              maxLength: 200,
                                controller: _descController,
                                )),
                     
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void showCategory(){
       showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            // height: 200.0 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 15.0,
                left: 15.0,
                top: 15.0),
            child: ListView.builder(
              itemCount: listCategory.length,
              itemBuilder: (BuildContext context, int index) {
               return Center(
                 child: ListTile(
                   title: Text("${listCategory[index].name}"),
                   onTap: (){
                     setState(() {
                       categoriesID = listCategory[index].id.toString();
                       categoriesName = listCategory[index].name.toString();
                     });
                     Navigator.pop(context);
                   },

                 ),
               );
               },

            )
            
          );
        });
  }
}
