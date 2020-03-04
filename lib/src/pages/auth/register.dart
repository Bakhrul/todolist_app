// import 'package:checkin_app/auth/login.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
// import 'login.dart';
import 'dart:convert';
import 'dart:io';
import 'package:todolist_app/src/routes/env.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:todolist_app/src/storage/storage.dart';


Map<String, dynamic> formSerialize;
Map<String, String> requestHeaders = Map();
TextEditingController namalengkap = TextEditingController();
TextEditingController email = TextEditingController();
TextEditingController password = TextEditingController();
bool isLoading, isRegister;
String fcmToken;
String msg = '';

class Register extends StatefulWidget {
  @override
  _Register createState() => _Register();
}

class _Register extends State<Register> {
  void initState() {
    super.initState();
    isLoading = true;
    isRegister = false;
    namalengkap.text = '';
    email.text = '';
    password.text = '';
  }

  

  _login() async {
    try {
      final getToken = await http.post(url('oauth/token'), body: {
        'grant_type': grantType,
        'client_id': clientId,
        'client_secret': clientSecret,
        "username": email.text,
        "password": password.text,
      });


      var getTokenDecode = json.decode(getToken.body);
      if (getToken.statusCode == 200) {
        if (getTokenDecode['error'] == 'invalid_credentials') {
          Fluttertoast.showToast(msg: getTokenDecode['message']);
          msg = getTokenDecode['message'];
          setState(() {
            isRegister = false;
          });
        } else if (getTokenDecode['error'] == 'invalid_request') {
          Fluttertoast.showToast(msg: getTokenDecode['hint']);
          msg = getTokenDecode['hint'];
          setState(() {
            isRegister = false;
          });
        } else if (getTokenDecode['token_type'] == 'Bearer') {
          DataStore()
              .setDataString('access_token', getTokenDecode['access_token']);
          DataStore().setDataString('token_type', getTokenDecode['token_type']);
        }
        dynamic tokenType = getTokenDecode['token_type'];
        dynamic accessToken = getTokenDecode['access_token'];
        requestHeaders['Accept'] = 'application/json';
        requestHeaders['Authorization'] = '$tokenType $accessToken';
        try {
          final getUser =
              await http.get(url("api/user"), headers: requestHeaders);

          if (getUser.statusCode == 200) {
            dynamic datauser = json.decode(getUser.body);

            DataStore store = new DataStore();
            store.setDataString("id", datauser['us_id'].toString());
            store.setDataString("email", datauser['us_email']);
            store.setDataString("name", datauser['us_name']);
            // Navigator.pushReplacementNamed(context, "/dashboard");
            Navigator.of(context)
    .pushNamedAndRemoveUntil('/dashboard', (Route<dynamic> route) => false);
          Fluttertoast.showToast(msg: 'Selamat Datang ${datauser['us_name']}');
            
          } else {
            Fluttertoast.showToast(
                msg: "Request failed with status: ${getUser.statusCode}");
            setState(() {
              isRegister = false;
            });
          }
        } on SocketException catch (_) {
          Fluttertoast.showToast(msg: "Connection Timed Out");
          setState(() {
            isRegister = false;
          });
        } catch (e) {
          print(e);
          setState(() {
            isRegister = false;
          });
        }
      } else if (getToken.statusCode == 401) {
        Fluttertoast.showToast(msg: "Username atau Password salah");
        setState(() {
          isRegister = false;
        });
      } else if (getToken.statusCode == 404) {
        Fluttertoast.showToast(msg: "Terjadi Kesalahan Server");
        setState(() {
          isRegister = false;
        });
      } else {
        Fluttertoast.showToast(
            msg: "Request failed with status: ${getToken.statusCode}");
        setState(() {
          isRegister = false;
        });
      }
    } on SocketException catch (_) {
      Fluttertoast.showToast(msg: "Connection Timed Out");
      setState(() {
        isRegister = false;
      });
    } catch (e) {
      setState(() {
        isRegister = false;
      });
      Fluttertoast.showToast(msg: "Terjadi Kesalahan Server");
    }
  }
  
  void dispose() {
    super.dispose();
  }

  void register() async {
    setState(() {
      isRegister = true;
    });
    formSerialize = Map<String, dynamic>();
    formSerialize['namakelengkap'] = null;
    formSerialize['email'] = null;
    formSerialize['password'] = null;
    formSerialize['namalengkap'] = namalengkap.text;
    formSerialize['email'] = email.text;
    formSerialize['password'] = password.text;

    print(formSerialize);

    Map<String, dynamic> requestHeadersX = requestHeaders;

    requestHeadersX['Content-Type'] = "application/x-www-form-urlencoded";
    try {
      final response = await http.post(
        url('api/user/register'),
        body: {
          'type_platform': 'android',
          'data': jsonEncode(formSerialize),
        },
        encoding: Encoding.getByName("utf-8"),
      );

      if (response.statusCode == 200) {
        dynamic responseJson = jsonDecode(response.body);
        if (responseJson['status'] == 'success') {
         _login();
        } else if (responseJson['status'] == 'emailnotavailable') {
          Fluttertoast.showToast(
              msg: "Email Telah Digunakan, Mohon Gunakan Email Lainnya");
          setState(() {
            isRegister = false;
          });
        }
        print('response decoded $responseJson');
      } else {
        print('${response.body}');
        Fluttertoast.showToast(
            msg: "Gagal Mendaftarkan Akun Silahkan Coba Kembali");
        setState(() {
          isRegister = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(
          msg: "Time Out, Silahkan Coba Kembali");
      setState(() {
        isRegister = false;
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Gagal Mendaftarkan Akun, Silahkan Coba Kembali");
      setState(() {
        isRegister = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final namaField = TextField(
      enabled: isRegister == true ? false : true,
      controller: namalengkap,
      autofocus: true,
      obscureText: false,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        color: Color(0xff25282b),
      ),
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Nama Lengkap",
          hintStyle: TextStyle(
              fontWeight: FontWeight.w300, color: Colors.black, fontSize: 14),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              borderSide: BorderSide(color: Colors.black38)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5.0),
              topRight: Radius.circular(5.0),
              bottomRight: Radius.circular(5.0),
              bottomLeft: Radius.circular(5.0),
            ),
          )),
    );

    final emailField = TextField(
      enabled: isRegister == true ? false : true,
      controller: email,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        color: Color(0xff25282b),
      ),
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Email",
          hintStyle: TextStyle(
              fontWeight: FontWeight.w300, color: Colors.black, fontSize: 14),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              borderSide: BorderSide(color: Colors.black38)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5.0),
              topRight: Radius.circular(5.0),
              bottomRight: Radius.circular(5.0),
              bottomLeft: Radius.circular(5.0),
            ),
          )),
    );

    final passwordField = TextField(
      controller: password,
      obscureText: true,
      enabled: isRegister == true ? false : true,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        color: Color(0xff25282b),
      ),
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Password",
          hintStyle: TextStyle(
              fontWeight: FontWeight.w300, color: Colors.black, fontSize: 14),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              borderSide: BorderSide(color: Colors.black38)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5.0),
              topRight: Radius.circular(5.0),
              bottomRight: Radius.circular(5.0),
              bottomLeft: Radius.circular(5.0),
            ),
          )),
    );
    final loginButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(3.0),
      color: primaryAppBarColor,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: isRegister == true ? null : () async {
          setState(() {
            isLoading = true;
          });
          String emailValid = email.text;
          final bool isValid = EmailValidator.validate(emailValid);

          print('Email is valid? ' + (isValid ? 'yes' : 'no'));
          if (namalengkap.text == null || namalengkap.text == '') {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Nama Lengkap Tidak Boleh Kosong");
          } else if (email.text == null || email.text == '') {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Email Tidak Boleh Kosong");
          } else if (password.text == null || password.text == '') {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Password Tidak Boleh Kosong");
          }else if(!isValid){
            Fluttertoast.showToast(msg: "Masukkan Email Yang Valid");
          } else {
            register();
          }
        },
        child: Text(
          isRegister == true ? "Mohon Tunggu Sebentar" :"Daftar Sekarang",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
            fontSize: 14.0,
          ),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        // child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 27.0, right: 27.0, left: 27.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(bottom: 30.0,top:40.0),
                    child: Text('Tudulis', style: TextStyle(
                      color: Color.fromRGBO(254, 86, 14, 1),
                      fontSize: 42.0,
                    ),),
                  ),
                namaField,
                SizedBox(height: 15.0),
                emailField,
                SizedBox(height: 15.0),
                passwordField,
                SizedBox(
                  height: 15.0,
                ),
                loginButton,
                SizedBox(
                  height: 15.0,
                ),
                Container(
                  margin: EdgeInsets.only(top: 10.0),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              border: BorderDirectional(
                            bottom:
                                BorderSide(width: 1 / 2, color: Colors.grey),
                          )),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: Text(
                            'Sudah Memiliki Akun ?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              border: BorderDirectional(
                            bottom:
                                BorderSide(width: 1 / 2, color: Colors.grey),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 15.0,
                ),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: SizedBox(
                    width: double.infinity,
                    child: RaisedButton(
                      elevation: 1,
                      color: Colors.white,
                      textColor: primaryAppBarColor,
                      disabledColor: Colors.green[400],
                      disabledTextColor: Colors.white,
                      padding: EdgeInsets.all(15.0),
                      splashColor: Colors.blueAccent,
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Login Sekarang',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
       bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Text(
                    'Powered By :',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                Image.asset(
                  "images/logo.png",
                  height: 50.0,
                  width: 50.0,
                ),
              ],
            )),
      ),
      // ),
    );
  }
}
