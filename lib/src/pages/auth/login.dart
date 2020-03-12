import 'package:todolist_app/src/pages/auth/register.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/storage/storage.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:flutter/cupertino.dart';
import 'reset_password.dart';

TextEditingController username = TextEditingController();
TextEditingController password = TextEditingController();
bool loading = false;
bool _isLoading = false;
Map<String, String> requestHeaders = Map();

class LoginPage extends StatefulWidget {
  //   LoginPage({Key key, this.indexIkis, indexIki}) : super(key: key);
  // final String indexIkis;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // String indexIki
  String fcmToken;
  bool validateEmail = false;
  bool validatePassword = false;

  void initState() {
    _isLoading = false;
    username.text = '';
    password.text = '';
    validatePassword = false;
    validateEmail = false;
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  String msg = '';
  _login() async {
    setState(() {
      _isLoading = true;
      validatePassword = false;
      validateEmail = false;
    });

    if (password.text == '' && username.text == '') {
      setState(() {
        validatePassword = true;
        validateEmail = true;
        _isLoading = false;
      });
      return false;
    } else if (username.text == '') {
      setState(() {
        validateEmail = true;
        _isLoading = false;
      });
      return false;
    } else if (password.text == '') {
      setState(() {
        validatePassword = true;
        _isLoading = false;
      });
      return false;
    }
    try {
      final getToken = await http.post(url('oauth/token'), body: {
        'grant_type': grantType,
        'client_id': clientId,
        'client_secret': clientSecret,
        "username": username.text,
        "password": password.text,
      });

      var getTokenDecode = json.decode(getToken.body);
      if (getToken.statusCode == 200) {
        if (getTokenDecode['error'] == 'invalid_credentials') {
          msg = getTokenDecode['message'];
          setState(() {
            _isLoading = false;
          });
        } else if (getTokenDecode['error'] == 'invalid_request') {
          Fluttertoast.showToast(msg: getTokenDecode['hint']);
          msg = getTokenDecode['hint'];
          setState(() {
            _isLoading = false;
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
          // final checkversion =
          // await http.get(url('api/checkversion/${versionNumber.toInt()}'), headers: requestHeaders);
          final getUser =
              await http.get(url("api/user"), headers: requestHeaders);
          
          // print('getUser ' + getUser.body);

          if (getUser.statusCode == 200) {
            dynamic datauser = json.decode(getUser.body);

            DataStore store = new DataStore();
            store.setDataString("id", datauser['us_id'].toString());
            store.setDataString("email", datauser['us_email']);
            store.setDataString("name", datauser['us_name']);
            store.setDataString("phone", datauser['us_phone']);
            store.setDataString("address", datauser['us_address']);
            store.setDataString("photo", datauser['us_image']);
            // store.setDataString("photo", datauser['us_image']);
            // if(checkversion.statusCode == 200){
            //   var version = json.decode(checkversion.body);
            //   if(version == 'Warning'){
            //     showModalVersionWarning(context);
            //   }else if(version == 'Expired'){
            //     showModalVersionDanger(context);
            //   }else{
            // Navigator.pushReplacementNamed(context, "/dashboard");
            //   }
            // }else{
            // }
            Navigator.pushReplacementNamed(context, "/dashboard");

            Fluttertoast.showToast(
                msg: 'Selamat Datang ${datauser['us_name']}');
          } else {
            print(getUser.body);
            Fluttertoast.showToast(
                msg: "Request failed with status: ${getUser.statusCode}");
            setState(() {
              _isLoading = false;
            });
          }
        } on SocketException catch (_) {
          Fluttertoast.showToast(msg: "Connection Timed Out");
          setState(() {
            _isLoading = false;
          });
        } catch (e) {
          print(e);
          setState(() {
            _isLoading = false;
          });
        }
      } else if (getToken.statusCode == 401) {
        Fluttertoast.showToast(msg: "Username Atau Password Salah");
        setState(() {
          _isLoading = false;
        });
      } else if (getToken.statusCode == 404) {
        Fluttertoast.showToast(msg: "Terjadi Kesalahan Server");
        setState(() {
          _isLoading = false;
        });
      } else if (getToken.statusCode == 400) {
        Fluttertoast.showToast(msg: "Username Atau Password Salah");
        setState(() {
          _isLoading = false;
        });
      } else {
        Fluttertoast.showToast(
            msg: "Request failed with status: ${getToken.statusCode}");
        setState(() {
          _isLoading = false;
        });
        print(getToken.body);
      }
    } on SocketException catch (_) {
      Fluttertoast.showToast(msg: "Connection Timed Out");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e.toString());
      Fluttertoast.showToast(msg: "Terjadi Kesalahan Server");
    }
  }

  @override
  Widget build(BuildContext context) {
    final usernameField = TextField(
      controller: username,
      autofocus: true,
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        color: Color(0xff25282b),
      ),
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Alamat Email",
          errorText: validateEmail ? "Email Tidak Boleh Kosong" : null,
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
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        color: Color(0xff25282b),
      ),
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Kata Sandi",
          errorText: validatePassword ? "Password Tidak Boleh Kosong" : null,
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
        onPressed: _isLoading == true
            ? null
            : () async {
                //login();
                _login();
                // Navigator.push(context, MaterialPageRoute(builder: (context) => CobaApps()));
              },
        child: Text(
          _isLoading == true ? "Tunggu Sebentar" : "Masuk",
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
      body: Center(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(top: 27.0, left: 27.0, right: 27.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: 30.0),
                    child: Text(
                      'Todolist',
                      style: TextStyle(
                        color: Color.fromRGBO(254, 86, 14, 1),
                        fontSize: 42.0,
                      ),
                    ),
                  ),

                  usernameField,
                  SizedBox(height: 15.0),

                  passwordField,
                  // SizedBox(
                  //   height: 10.0,
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ButtonTheme(
                        minWidth: 0.0,
                        height: 0.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(5.0),
                          onPressed: () async {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ResetPassword()));
                          },
                          child: Text(
                            'Lupa Password ?',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                          color: Colors.white,
                        ),
                      ),
                      ButtonTheme(
                        minWidth: 0.0,
                        height: 0.0,
                        child: FlatButton(
                          padding: EdgeInsets.all(5.0),
                          onPressed: () async {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Register()));
                          },
                          child: Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                                color: primaryAppBarColor, fontSize: 12),
                          ),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  loginButton,
                ],
              ),
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
    );
  }

   void showModalVersionWarning(BuildContext context) {
    showDialog(
      barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            contentPadding: EdgeInsets.only(top: 0.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 60,
                      decoration: new BoxDecoration(
                          color: Colors.orange,
                          borderRadius: new BorderRadius.only(
                            topLeft: const Radius.circular(8.0),
                            topRight: const Radius.circular(8.0),
                          )),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.info_outline,color: Colors.white , size: 40,),
                            Padding(
                              padding: const EdgeInsets.only(left:8.0),
                              child: Text(
                                "Version Update",
                                style: TextStyle(fontSize: 16.0,color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.only(left:16.0,right:16.0,bottom:8.0),
                      child: Text("Versi Terbaru Telah Tersedia",style: TextStyle(fontSize: 14),)
                      
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Todolist menyarankan anda untuk mengupdate ke versi terbaru. Anda dapat tetap menggunakan aplikasi ini saat mendownload update",style: TextStyle(fontSize: 12,color:Colors.grey,height: 1.5),textAlign: TextAlign.justify,)

                    ),
                    Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () { 
                            Navigator.pushReplacementNamed(context, "/dashboard");
                           },
                          child: Text("CANCEL",style: TextStyle(color:Colors.black54)),
                        ),
                        FlatButton(
                          onPressed: () {  },
                          child: Text("UPDATE",style: TextStyle(color:primaryAppBarColor)),
                        )

                      ],

                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

   void showModalVersionDanger(BuildContext context) {
    showDialog(
      barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            contentPadding: EdgeInsets.only(top: 0.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 60,
                      decoration: new BoxDecoration(
                          color: Colors.red,
                          borderRadius: new BorderRadius.only(
                            topLeft: const Radius.circular(8.0),
                            topRight: const Radius.circular(8.0),
                          )),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.warning,color: Colors.white , size: 40,),
                            Padding(
                              padding: const EdgeInsets.only(left:8.0),
                              child: Text(
                                "Version Update",
                                style: TextStyle(fontSize: 16.0,color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.only(left:16.0,right:16.0,bottom:8.0),
                      child: Text("Versi Terbaru Telah Tersedia",style: TextStyle(fontSize: 14),)
                      
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Todolist menyarankan anda untuk mengupdate ke versi terbaru. Versi yang anda gunakan telah kadaluarsa",style: TextStyle(fontSize: 12,color:Colors.grey,height: 1.5),textAlign: TextAlign.justify,)

                    ),
                    Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () {  },
                          child: Text("UPDATE",style: TextStyle(color:primaryAppBarColor)),
                        )

                      ],

                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

}
