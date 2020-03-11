import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:http/http.dart' as http;

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  TextEditingController _controllerPasswordLama = new TextEditingController();
  TextEditingController _controllerPasswordBaru = new TextEditingController();
  TextEditingController _controllerConfirmPassword =
      new TextEditingController();
  ProgressDialog progressApiAction;
  var storageApp = new DataStore();
  Map<String, String> requestHeaders = Map();
  bool load = false;
  String validatePasswordLama, validatePasswordBaru, validateConfirmPassword;

  editData(password) async {
    if (load) {
      return false;
    }
    if (password == 'Y') {
      if (_controllerPasswordLama.text == '') {
        Fluttertoast.showToast(msg: "Password Lama Tidak Boleh Kosong");
        return false;
      } else if (_controllerPasswordBaru.text == '') {
        Fluttertoast.showToast(msg: "Password Baru Tidak Boleh Kosong");
        return false;
      } else if (_controllerConfirmPassword.text == '') {
        Fluttertoast.showToast(
            msg: "Konfirmasi Password Baru Tidak Boleh Kosong");
        return false;
      } else if (_controllerPasswordBaru.text !=
          _controllerConfirmPassword.text) {
        Fluttertoast.showToast(
            msg: "Password Baru Dan Konfirmasi Password Baru Harus Sama");
        return false;
      }
    }
    await progressApiAction.show();
    setState(() {
      load = true;
    });
    Map body = {
      "ispassword": password,
      'oldpassword': _controllerPasswordLama.text,
      'newpassword': _controllerPasswordBaru.text,
      'confirmpassword': _controllerConfirmPassword.text,
    };
    print(body);

    try {
      var data = await http.patch(url('api/user'),
          headers: requestHeaders,
          body: body,
          encoding: Encoding.getByName("utf-8"));

      print(data.body);

      var dataUserToJson = json.decode(data.body);
      if (data.statusCode == 200) {
        if (dataUserToJson['status'] == 'password baru tidak sama') {
          Fluttertoast.showToast(
              msg: "Password Baru Dan Konfirmasi Password Baru Tidak Sama");
          setState(() {
            load = false;
          });
          progressApiAction.hide().then((isHidden) {});
        } else if (dataUserToJson['status'] == 'password lama tidak sama') {
          Fluttertoast.showToast(msg: "Password Lama Tidak Sama");
          print(dataUserToJson['msg']);
          setState(() {
            load = false;
          });
          progressApiAction.hide().then((isHidden) {});
        } else if (dataUserToJson['status'] == 'emailnotavailable') {
          Fluttertoast.showToast(msg: "Email Sudah Digunakan");
          setState(() {
            load = false;
          });
          progressApiAction.hide().then((isHidden) {});
        } else if (dataUserToJson['status'] == 'success') {
          storageApp.setDataString("name", body['name']);
          storageApp.setDataString("email", body['email']);
          setState(() {
            load = false;
          });

          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
          setState(() {
            load = false;
          });
          progressApiAction.hide().then((isHidden) {});
        }
      } else {
        setState(() {
          load = false;
        });
        progressApiAction.hide().then((isHidden) {});
        Fluttertoast.showToast(msg: "Error: Gagal Memperbarui");
      }
    } on TimeoutException catch (_) {
      setState(() {
        load = false;
      });
      progressApiAction.hide().then((isHidden) {});
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } on SocketException catch (_) {
      setState(() {
        load = false;
      });
      Fluttertoast.showToast(msg: "No Internet Connection");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      setState(() {
        load = false;
      });
      Fluttertoast.showToast(msg: "$e");
      progressApiAction.hide().then((isHidden) {});
    }
  }

  @override
  void initState() {
    super.initState();
    validatePasswordLama = null;
    validatePasswordBaru = null;
    validateConfirmPassword = null;
  }

  @override
  void dispose() {
   _controllerPasswordLama.dispose();
   _controllerPasswordBaru.dispose();
   _controllerConfirmPassword.dispose();
    super.dispose();
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
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
        backgroundColor: Colors.white,
        title: Text("Ubah Password",style:TextStyle(color:Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40.0),
          padding: EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  child: Text('Password Lama',
                      style: TextStyle(color: Colors.black45))),
              Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  child: TextField(
                    obscureText: true,
                    controller: _controllerPasswordLama,
                    decoration: InputDecoration(
                      errorText: validatePasswordLama == null
                          ? null
                          : validatePasswordLama,
                    ),
                  )),
              Container(
                  child: Text('Password Baru',
                      style: TextStyle(color: Colors.black45))),
              Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  child: TextField(
                    obscureText: true,
                    controller: _controllerPasswordBaru,
                    decoration: InputDecoration(
                      errorText: validatePasswordBaru == null
                          ? null
                          : validatePasswordBaru,
                    ),
                  )),
              Container(
                  child: Text('Konfirmasi Password Baru',
                      style: TextStyle(color: Colors.black45))),
              Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      errorText: validateConfirmPassword == null
                          ? null
                          : validateConfirmPassword,
                    ),
                    controller: _controllerConfirmPassword,
                  )),
              Center(
                  child: Container(
                      width: double.infinity,
                      height: 45.0,
                      child: RaisedButton(
                          onPressed: load == true
                              ? null
                              : () async {
                                  editData('Y');
                                },
                          color: primaryAppBarColor,
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          child: load == true
                              ? Container(
                                  height: 25.0,
                                  width: 25.0,
                                  child: CircularProgressIndicator(
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                              Colors.white)))
                              : Text("Ubah password",
                                  style: TextStyle(color: Colors.white)))))
            ],
          ),
        ),
      ),
    );
  }
}
