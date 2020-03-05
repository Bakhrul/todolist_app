import 'package:todolist_app/src/pages/manajamen_user/edit_photo_profile.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/src/storage/storage.dart';

import 'package:todolist_app/src/pages/dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:checkin_app/pages/profile/image_edit.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';

String tokenType, accessToken;
String validatePasswordLama, validatePasswordBaru, validateConfirmPassword;
Map<String, String> requestHeaders = Map();
File imageProfileEdit;

class ProfileUserEdit extends StatefulWidget {
  ProfileUserEdit({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ProfileUserEdit();
  }
}

class _ProfileUserEdit extends State<ProfileUserEdit> {
  String namaData;
  String emailData;
  String phoneData;
  String locationData;
  File profileImageData;
  String imageData;
  bool load = false;
  var storageApp = new DataStore();
  TextEditingController _controllerNama = new TextEditingController();
  TextEditingController _controllerEmail = new TextEditingController();
  TextEditingController _controllerPhone = new TextEditingController();
  TextEditingController _controllerLocation = new TextEditingController();
  TextEditingController _controllerPasswordLama = new TextEditingController();
  TextEditingController _controllerPasswordBaru = new TextEditingController();
  TextEditingController _controllerConfirmPassword =
      new TextEditingController();

  @override
  void initState() {
    _getUser();
    validatePasswordLama = null;
    validatePasswordBaru = null;
    validateConfirmPassword = null;
    _controllerNama.addListener(nameEdit);
    _controllerEmail.addListener(emailEdit);
    _controllerPhone.addListener(phoneEdit);
    _controllerLocation.addListener(locationEdit);

    getHeaderHTTP();

    super.initState();
  }

  nameEdit() {
    setState(() {
      namaData = _controllerNama.text;
    });
  }

  emailEdit() {
    setState(() {
      emailData = _controllerEmail.text;
    });
  }

  phoneEdit() {
    setState(() {
      phoneData = _controllerPhone.text;
    });
  }

  locationEdit() {
    setState(() {
      locationData = _controllerLocation.text;
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
  }

  _getUser() async {
    DataStore user = new DataStore();
    String namaUser = await user.getDataString('name');
    String emailUser = await user.getDataString('email');
    String phoneUser = await user.getDataString('phone');
    String locationUser = await user.getDataString('location');
    String imageStored = await user.getDataString('photo');

    setState(() {
      namaData = namaUser;
      emailData = emailUser;
      phoneData = phoneUser;
      imageData = imageStored;
      locationData = locationUser;
      _controllerNama.text = namaUser;
      _controllerEmail.text = emailUser;
      _controllerPhone.text = phoneUser;
      _controllerLocation.text = locationUser;
    });
  }

  void _showPasswordModal() {
    setState(() {
      _controllerPasswordLama.text = '';
      _controllerPasswordBaru.text = '';
      _controllerConfirmPassword.text = '';
    });
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
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
          );
        });
  }

  editData(password) async {
    if (load) {
      return false;
    }
    Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
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

    setState(() {
      load = true;
    });

    Map body = {
      "name": namaData,
      "ispassword": password,
      'oldpassword': _controllerPasswordLama.text,
      'newpassword': _controllerPasswordBaru.text,
      'confirmpassword': _controllerConfirmPassword.text,
      "email": emailData,
    };

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
        } else if (dataUserToJson['status'] == 'password lama tidak sama') {
          Fluttertoast.showToast(msg: "Password Lama Tidak Sama");
          print(dataUserToJson['msg']);
          setState(() {
            load = false;
          });
        } else if (dataUserToJson['status'] == 'emailnotavailable') {
          Fluttertoast.showToast(msg: "Email Sudah Digunakan");
          setState(() {
            load = false;
          });
        } else if (dataUserToJson['status'] == 'success') {
          storageApp.setDataString("name", body['name']);
          storageApp.setDataString("email", body['email']);
          setState(() {
            usernameprofile = body['name'];
            emailprofile = body['email'];
            namaStore = namaData;
            emailStore = emailData;
            load = false;
          });

          Fluttertoast.showToast(msg: "Berhasil");

          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
          setState(() {
            load = false;
          });
        }
      } else {
        setState(() {
          load = false;
        });
        Fluttertoast.showToast(msg: "Error: Gagal Memperbarui");
      }
    } on TimeoutException catch (_) {
      setState(() {
        load = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } on SocketException catch (_) {
      setState(() {
        load = false;
      });
      Fluttertoast.showToast(msg: "No Internet Connection");
    } catch (e) {
      setState(() {
        load = false;
      });
      Fluttertoast.showToast(msg: "$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Edit Profile'), backgroundColor: primaryAppBarColor),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // background image and bottom contents
          Column(
            children: <Widget>[
              Container(
                height: 150.0,
                color: primaryAppBarColor,
                child: Expanded(
                child: Container(
                  decoration: new BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[300],
                        blurRadius:
                            6.0, // has the effect of softening the shadow
                        spreadRadius:
                            1.0, // has the effect of extending the shadow
                        offset: Offset(
                          1.0, // horizontal, move right 10
                          1.0, // vertical, move down 10
                        ),
                      )
                    ],
                  ),
                  child: Container(
                    decoration: new BoxDecoration(
                        color: Colors.white,
                        borderRadius: new BorderRadius.only(
                          bottomLeft: const Radius.circular(18.0),
                          bottomRight: const Radius.circular(18.0),
                        )),
                    child: Center(
                      child: Text('Content goes here'),
                    ),
                  ),
                ),
              ),
              ),
              
            ],
          ),
          // Profile image
          Positioned(
            top: 100.0, // (background container size) - (circle height / 2)
            child: Container(
              height: 100.0,
              width: 100.0,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.green),
            ),
          )
        ],
      ),
    );

    //   return Scaffold(
    //     backgroundColor: Colors.white,
    //     appBar: AppBar(
    //       iconTheme: IconThemeData(
    //         color: Colors.white,
    //       ),
    //       backgroundColor: primaryAppBarColor,
    //       elevation: 0.0,
    //     ),
    //     body: SingleChildScrollView(
    //         child: Column(
    //       children: <Widget>[
    //         Container(
    //           height: 160,
    //           width: double.infinity,
    //           color: primaryAppBarColor,
    //         ),
    //         Container(
    //             child: Stack(
    //           children: <Widget>[

    //             // Container(
    //             //   margin: EdgeInsets.only(bottom: 5.0, ),
    //             //   child: Text(namaData == null ? 'memuat..' : namaData,
    //             //       style: TextStyle(
    //             //         fontSize: 20.0,
    //             //         color: Colors.white,
    //             //       )),
    //             // ),
    //             Container(
    //               decoration: new BoxDecoration(
    //                 boxShadow: [
    //                   BoxShadow(
    //                     color: Colors.black,
    //                     blurRadius:
    //                         20.0, // has the effect of softening the shadow
    //                     spreadRadius:
    //                         5.0, // has the effect of extending the shadow
    //                     offset: Offset(
    //                       10.0, // horizontal, move right 10
    //                       10.0, // vertical, move down 10
    //                     ),
    //                   )
    //                 ],
    //                 // borderRadius: new BorderRadius.all(...),
    //                 // gradient: new LinearGradient(...),
    //               ),
    //               child: Container(
    //                   decoration: new BoxDecoration(
    //                       color: Colors.white,
    //                       borderRadius: new BorderRadius.only(
    //                         topLeft: const Radius.circular(18.0),
    //                         topRight: const Radius.circular(18.0),
    //                       )),
    //                   width: double.infinity,
    //                   padding: EdgeInsets.only(
    //                     left: 50.0,
    //                     right: 50.0,
    //                     top: 20.0,
    //                   ),
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     children: <Widget>[
    //                       Container(
    //                           child: Text('Nama',
    //                               style: TextStyle(color: Colors.grey))),
    //                       Container(
    //                           margin: EdgeInsets.only(bottom: 20.0),
    //                           child: TextField(
    //                             controller: _controllerNama,
    //                           )),
    //                       Container(
    //                         margin: EdgeInsets.only(bottom: 5.0),
    //                         child: Text('Email',
    //                             style: TextStyle(color: Colors.grey)),
    //                       ),
    //                       Container(
    //                           margin: EdgeInsets.only(bottom: 20.0),
    //                           child: TextField(
    //                             enabled: false,
    //                             controller: _controllerEmail,
    //                             decoration: InputDecoration(
    //                                 suffixIcon: Icon(Icons.lock, size: 20.0)),
    //                           )),
    //                       Container(
    //                         margin: EdgeInsets.only(bottom: 5.0),
    //                         child: Text('Password',
    //                             style: TextStyle(color: Colors.grey)),
    //                       ),
    //                       Row(
    //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                         children: <Widget>[
    //                           Text('********'),
    //                           FlatButton(
    //                             padding: EdgeInsets.all(0),
    //                             child: Padding(
    //                               padding: const EdgeInsets.all(0.0),
    //                               child: Text(
    //                                 'Ganti Password',
    //                                 style: TextStyle(fontSize: 12.0),
    //                               ),
    //                             ),
    //                             onPressed: _showPasswordModal,
    //                           ),
    //                         ],
    //                       ),
    //                     ],
    //                   )),
    //             ),
    //             Align(
    // alignment: Alignment.topCenter,
    //               // top: 20,
    //               child: GestureDetector(
    //                 onTap: () {
    //                   Navigator.push(
    //                       context,
    //                       MaterialPageRoute(
    //                           builder: (context) => EditPhoto(
    //                                 fileName: imageData,
    //                               )));
    //                 },
    //                 child: imageData == null
    //                     ? Container(
    //                         // margin: EdgeInsets.only(top: 20),
    //                         height: 90,
    //                         width: 90,
    //                         child: ClipOval(
    //                             child: Image.asset('images/imgavatar.png',
    //                                 fit: BoxFit.fill)))
    //                     : Container(
    //                         margin: EdgeInsets.only(top: -20),
    //                         height: 90,
    //                         width: 90,
    //                         child: ClipOval(
    //                             child: FadeInImage.assetNetwork(
    //                                 fit: BoxFit.cover,
    //                                 placeholder: 'images/imgavatar.png',
    //                                 image: url('storage/profile/$imageData')))),
    //               ),
    //             ),
    //           ],
    //         )),
    //       ],
    //     )),
    //     bottomNavigationBar: BottomAppBar(
    //       child: Container(
    //           width: double.infinity,
    //           margin: EdgeInsets.only(top: 50.0),
    //           height: 50.0,
    //           child: RaisedButton(
    //               onPressed: load == true
    //                   ? null
    //                   : () {
    //                       editData('N');
    //                     },
    //               color: primaryAppBarColor,
    //               textColor: Colors.white,
    //               disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
    //               disabledTextColor: Colors.white,
    //               splashColor: Colors.blueAccent,
    //               child: load == true
    //                   ? Container(
    //                       height: 25.0,
    //                       width: 25.0,
    //                       child: CircularProgressIndicator(
    //                           valueColor: new AlwaysStoppedAnimation<Color>(
    //                               Colors.white)))
    //                   : Text("Simpan Data",
    //                       style: TextStyle(color: Colors.white)))),
    //     ),
    //   );
  }
}
