import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/models/todo.dart';
import 'package:todolist_app/src/pages/auth/login.dart';
import 'package:todolist_app/src/pages/manajamen_user/change_password.dart';
import 'package:todolist_app/src/pages/manajamen_user/edit_photo_profile.dart';
import 'package:todolist_app/src/pages/manajemen_project/detail_project.dart';
import 'package:todolist_app/src/pages/todolist/detail_todo.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/model/Project.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:todolist_app/src/model/FriendList.dart';
import 'confirmation_friend.dart';

enum PageEnum {
  editProfile,
  permintaanTeman,
  gantiPassword,
}
String validatePasswordLama, validatePasswordBaru, validateConfirmPassword;

class ManajemenUser extends StatefulWidget {
  @override
  _ManajemenUserState createState() => _ManajemenUserState();
}

class _ManajemenUserState extends State<ManajemenUser>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  String tokenType, accessToken;

  TextEditingController _emailPenggunaController = TextEditingController();
  String nameUser = '';
  Map<String, String> requestHeaders = Map();
  List<Project> listProject = [];
  List<Todo> listHistory = [];
  List<FriendList> listFriend = [];
  bool isLoading = true;
  bool isError = true;
  ProgressDialog progressApiAction;
  String imageData;
  bool load = false;

  String namaData;
  String emailData;
  String phoneData;
  String locationData;
  File profileImageData;

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
    super.initState();
    _getUser();
    getHeaderHTTP();

    validatePasswordLama = null;
    validatePasswordBaru = null;
    validateConfirmPassword = null;
    _controllerNama.addListener(nameEdit);
    _controllerEmail.addListener(emailEdit);
    _controllerPhone.addListener(phoneEdit);
    _controllerLocation.addListener(locationEdit);
    isLoading = true;
    isError = false;
    _tabController =
        TabController(length: 3, vsync: _ManajemenUserState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
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

  _getUser() async {
    DataStore user = new DataStore();
    String namaUser = await user.getDataString('name');
    String emailUser = await user.getDataString('email');
    String phoneUser = await user.getDataString('phone');
    String locationUser = await user.getDataString('address');
    String imageStored = await user.getDataString('photo');

    print(emailUser);
    print(locationUser);

    setState(() {
      namaData = namaUser;
      emailData = emailUser;
      phoneData = phoneUser;
      imageData = imageStored;
      locationData = locationUser;
      _controllerNama.text = namaUser;
      _controllerEmail.text = emailUser == 'Tidak ditemukan' ? '' : emailUser;
      _controllerPhone.text = phoneUser == 'Tidak ditemukan' ? '' : phoneUser;
      _controllerLocation.text =
          locationUser == 'Tidak ditemukan' ? '' : locationUser;
    });
  }

  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  void _handleTabIndex() {
    if (_tabController.index == 0) {
      setState(() {
        getDataProject();
      });
    } else if (_tabController.index == 1) {
      setState(() {
        getDataHistory();
      });
    } else {
      setState(() {
        getDataFriend();
      });
    }
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
      "name": namaData,
      "ispassword": password,
      'oldpassword': _controllerPasswordLama.text,
      'newpassword': _controllerPasswordBaru.text,
      'confirmpassword': _controllerConfirmPassword.text,
      "email": emailData,
      "address": locationData,
      "phone": phoneData
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

  Future<Null> _pickImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    print(imageFile);

    if (imageFile != null) {
      setState(() {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditPhoto(filePath: imageFile)));
        // state = AppState.picked;
      });
    }
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');
    var nameStorage = await storage.getDataString('name');
    String imageStore = await storage.getDataString('photo');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    nameUser = nameStorage;
    imageData = imageStore;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataProject();
  }

  Future<List<List>> getDataProject() async {
    setState(() {
      listProject.clear();
      listProject = [];
      isLoading = true;
    });
    try {
      await new Future.delayed(const Duration(seconds: 1));
      final participant =
          await http.get(url('api/dashboard'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson['project'];
        listProject.clear();
        listProject = [];
        print(project);

        for (var i in project) {
          Project participant = Project(
              id: i['id'],
              title: i['title'].toString(),
              start: i['created_date'].toString(),
              end: i['finish_date'].toString(),
              colored: i['status'] == 'compleshed'
                  ? Colors.green
                  : i['status'] == 'overdue'
                      ? Colors.red
                      : i['status'] == 'pending' ? Colors.grey : Colors.white);
          listProject.add(participant);
        }
        await new Future.delayed(const Duration(seconds: 1));

        setState(() {
          isLoading = false;
          isError = false;
        });

        print(listProject.length);
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
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> getDataHistory() async {
    setState(() {
      listHistory.clear();
      listHistory = [];
      isLoading = true;
    });
    try {
      await new Future.delayed(const Duration(seconds: 1));
      final participant =
          await http.get(url('api/history'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;
        listHistory.clear();
        listHistory = [];

        for (var i in project) {
          Todo participant = Todo(
            id: i['id'],
            title: i['title'].toString(),
            start: i['start'].toString(),
            end: i['end'].toString(),
            status: i['status'].toString(),
            allday: i['allday'],
          );
          listHistory.add(participant);
        }
        await new Future.delayed(const Duration(seconds: 1));

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
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> getDataFriend() async {
    setState(() {
      listFriend.clear();
      listFriend = [];
      isLoading = true;
    });
    try {
      await new Future.delayed(const Duration(seconds: 1));

      final participant =
          await http.get(url('api/get_friendlist'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson;
        listFriend.clear();
        listFriend = [];

        for (var i in project) {
          FriendList participant = FriendList(
            users: i['fl_users'],
            friend: i['fl_friend'],
            namafriend: i['us_name'],
            waktutambah: i['fl_added'],
            waktuditolak: i['fl_denied'],
            waktuditerima: i['fl_approved'],
            imageFriend: i['us_image'],
          );
          listFriend.add(participant);
        }
        await new Future.delayed(const Duration(seconds: 1));

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
      debugPrint('$e');
    }
    return null;
  }

  @override
  void dispose() {
    listHistory.clear();
    listFriend.clear();
    listProject.clear();
    super.dispose();
  }

  void _tambahteman() async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addadminevent = await http
          .post(url('api/tambah_teman'), headers: requestHeaders, body: {
        'email': _emailPenggunaController.text,
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        Fluttertoast.showToast(msg: addpesertaJson['message']);
        setState(() {
          _emailPenggunaController.text = '';
        });
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        getDataFriend();
      } else {
        setState(() {
          _emailPenggunaController.text = '';
        });
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      setState(() {
        _emailPenggunaController.text = '';
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        _emailPenggunaController.text = '';
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  void _deleteteman(friend) async {
    await progressApiAction.show();
    try {
      final deleteTemanUrl = await http
          .post(url('api/hapus_teman'), headers: requestHeaders, body: {
        'friend': friend.toString(),
      });

      if (deleteTemanUrl.statusCode == 200) {
        var deleteTemanUrJson = json.decode(deleteTemanUrl.body);
        if (deleteTemanUrJson['status'] == 'success') {
          Fluttertoast.showToast(msg: 'Berhasil!');
        }
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        getDataFriend();
      } else {
        print(deleteTemanUrl.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
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
      backgroundColor: Colors.white,
      body: new ListView(
        children: <Widget>[
          new Container(
            // color: Colors.white,
            height: 290.0,
            margin: new EdgeInsets.only(bottom: 8.0),
            decoration: new BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[300],
                  blurRadius: 6.0, // has the effect of softening the shadow
                  spreadRadius: 1.0, // has the effect of extending the shadow
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
              // color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                      // margin: EdgeInsets.all(8),
                      child: PopupMenuButton<PageEnum>(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0)),
                          onSelected: (PageEnum value) {
                            switch (value) {
                              case PageEnum.editProfile:
                                _editProfile();
                                break;
                              case PageEnum.gantiPassword:
                                // Navigator.push(context,CupertinoPageRoute(builder: (context) => ChangePassword() ));
                                _showPasswordModal();
                                break;
                              case PageEnum.permintaanTeman:
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ConfirmationFriend()));
                                break;
                              default:
                            }
                          },
                          itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: PageEnum.editProfile,
                                  child: Row(children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "Edit Data Akun",
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 14),
                                    ),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: PageEnum.gantiPassword,
                                  child: Row(children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Icon(
                                        Icons.lock,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "Ganti Password",
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 14),
                                    ),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: PageEnum.permintaanTeman,
                                  child: Row(children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.people,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      "Permintaan Teman",
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 14),
                                    ),
                                  ]),
                                )
                              ])),
                  Center(
                      child: Stack(
                    children: <Widget>[
                      GestureDetector(
                        // child: Hero(
                        // tag: 'imageHero',
                        child: Container(
                          height: 90,
                          width: 90,
                          child: ClipOval(
                              child: FadeInImage.assetNetwork(
                                  fit: BoxFit.cover,
                                  placeholder: 'images/imgavatar.png',
                                  image: imageData == null ||
                                          imageData == '' ||
                                          imageData == 'Tidak ditemukan'
                                      ? url('assets/images/imgavatar.png')
                                      : url(
                                          'storage/image/profile/$imageData'))),
                          // )
                        ),
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) {
                            return DetailScreen(
                                tag: 'imageHero',
                                url: url('storage/image/profile/$imageData'));
                          }));
                        },
                      ),
                      Positioned(
                        right: 1,
                        top: 1,
                        child: InkWell(
                            onTap: () {
                              _pickImage();
                            },
                            child: Container(
                                child: Icon(
                              Icons.camera_alt,
                              color: Colors.black54,
                              size: 32.0,
                            ))),
                      ),
                    ],
                  )),
                  Center(
                    child: Container(
                        child: Padding(
                      padding:
                          const EdgeInsets.only(top: 8, left: 24, right: 24),
                      child: Text(
                        "$nameUser",
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ),
                  Center(
                      child: Container(
                    margin: EdgeInsets.only(top: 8, bottom: 16),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(18.0),
                      ),
                      color: primaryAppBarColor,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text('Peringatan!'),
                            content: Text('Apa anda yakin ingin logout?'),
                            actions: <Widget>[
                              FlatButton(
                                child: Text(
                                  'Tidak',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              FlatButton(
                                child: Text(
                                  'Ya',
                                  style: TextStyle(color: Colors.cyan),
                                ),
                                onPressed: () {
                                  removeSharedPrefs();
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              LoginPage()));
                                },
                              )
                            ],
                          ),
                        );
                      },
                      child: Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )),
                  Expanded(
                    child: TabBar(
                      labelColor: Colors.black,
                      controller: _tabController,
                      indicatorColor: primaryAppBarColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        new Tab(
                          text: 'Project',
                        ),
                        new Tab(
                          text: 'Riwayat',
                        ),
                        new Tab(
                          text: 'Teman',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              height: MediaQuery.of(context).size.height / 2,
              child: new TabBarView(
                controller: _tabController,
                children: <Widget>[
                  isLoading == true
                      ? listLoadingTodo()
                      : isError == true
                          ? errorSystemFilter(context)
                          : listProject.length == 0
                              ? RefreshIndicator(
                                  onRefresh: getHeaderHTTP,
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
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
                                              "Project Yang Anda Cari Tidak Ditemukan",
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: getHeaderHTTP,
                                  child: SingleChildScrollView(
                                      physics: AlwaysScrollableScrollPhysics(),
                                      child: Column(
                                        children: listProject
                                            .map(
                                              (Project item) => InkWell(
                                                onTap: () async {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              ManajemenDetailProjectAll(
                                                                  idproject:
                                                                      item.id,
                                                                  namaproject: item
                                                                      .title)));
                                                },
                                                child: Container(
                                                  child: Card(
                                                      elevation: 0.5,
                                                      margin: EdgeInsets.only(
                                                          top: 5.0,
                                                          bottom: 5.0,
                                                          left: 0.0,
                                                          right: 0.0),
                                                      child: ClipPath(
                                                        clipper: ShapeBorderClipper(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            3))),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              border: Border(
                                                                  right: BorderSide(
                                                                      color: item
                                                                          .colored,
                                                                      width:
                                                                          5))),
                                                          child: ListTile(
                                                            leading: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(0.0),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            0.0),
                                                                child:
                                                                    Container(
                                                                        height:
                                                                            40.0,
                                                                        alignment:
                                                                            Alignment
                                                                                .center,
                                                                        width:
                                                                            40.0,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border: Border.all(
                                                                              color: Colors.white,
                                                                              width: 2.0),
                                                                          color:
                                                                              primaryAppBarColor,
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          '${item.title[0].toUpperCase()}',
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: 18,
                                                                              fontWeight: FontWeight.bold),
                                                                        )),
                                                              ),
                                                            ),
                                                            title: Text(
                                                                item.title ==
                                                                            '' ||
                                                                        item.title ==
                                                                            null
                                                                    ? 'ToDo Tidak Diketahui'
                                                                    : item
                                                                        .title,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: true,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500)),
                                                            subtitle: Text(
                                                                DateFormat('d MMM y')
                                                                        .format(DateTime.parse(
                                                                            "${item.start}"))
                                                                        .toString() +
                                                                    ' - ' +
                                                                    DateFormat(
                                                                            'd MMM y')
                                                                        .format(DateTime.parse(
                                                                            "${item.end}"))
                                                                        .toString(),
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1),
                                                          ),
                                                        ),
                                                      )),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      )),
                                ),
                  // LIST HISTORY
                  isLoading == true
                      ? listLoadingTodo()
                      : isError == true
                          ? errorSystemFilter(context)
                          : listHistory.length == 0
                              ? RefreshIndicator(
                                  onRefresh: getDataHistory,
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
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
                                              "ToDo Yang Anda Cari Tidak Ditemukan",
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: getDataHistory,
                                  child: SingleChildScrollView(
                                      physics: AlwaysScrollableScrollPhysics(),
                                      child: Column(
                                        children: listHistory
                                            .map(
                                              (Todo item) => InkWell(
                                                onTap: () async {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              ManajemenDetailTodo(
                                                                  idtodo:
                                                                      item.id,
                                                                  namatodo: item
                                                                      .title)));
                                                },
                                                child: Container(
                                                  child: Card(
                                                      elevation: 0.5,
                                                      margin: EdgeInsets.only(
                                                          top: 5.0,
                                                          bottom: 5.0,
                                                          left: 0.0,
                                                          right: 0.0),
                                                      child: ClipPath(
                                                        clipper: ShapeBorderClipper(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            3))),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              border: Border(
                                                                  right: BorderSide(
                                                                      color: Colors
                                                                          .green,
                                                                      width:
                                                                          5))),
                                                          child: ListTile(
                                                            leading: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(0.0),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            100.0),
                                                                child:
                                                                    Container(
                                                                        height:
                                                                            40.0,
                                                                        alignment:
                                                                            Alignment
                                                                                .center,
                                                                        width:
                                                                            40.0,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border: Border.all(
                                                                              color: Colors.white,
                                                                              width: 2.0),
                                                                          borderRadius: BorderRadius.all(
                                                                              Radius.circular(100.0) //                 <--- border radius here
                                                                              ),
                                                                          color:
                                                                              primaryAppBarColor,
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          '${item.title[0].toUpperCase()}',
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.bold),
                                                                        )),
                                                              ),
                                                            ),
                                                            title: Text(
                                                                item.title ==
                                                                            '' ||
                                                                        item.title ==
                                                                            null
                                                                    ? 'ToDo Tidak Diketahui'
                                                                    : item
                                                                        .title,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: true,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500)),
                                                            subtitle: Text(
                                                                DateFormat(item.allday >
                                                                                0
                                                                            ? 'd MMM y'
                                                                            : 'd MMM y HH:mm')
                                                                        .format(DateTime.parse(
                                                                            "${item.start}"))
                                                                        .toString() +
                                                                    ' - ' +
                                                                    DateFormat(item.allday >
                                                                                0
                                                                            ? 'd MMM y'
                                                                            : 'd MMM y HH:mm')
                                                                        .format(DateTime.parse(
                                                                            "${item.end}"))
                                                                        .toString(),
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1),
                                                          ),
                                                        ),
                                                      )),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      )),
                                ),
                  isLoading == true
                      ? listLoadingTodo()
                      : isError == true
                          ? errorSystemFilter(context)
                          : listFriend.length == 0
                              ? RefreshIndicator(
                                  onRefresh: getDataFriend,
                                  child: SingleChildScrollView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Column(children: <Widget>[
                                        new Container(
                                          width: 140.0,
                                          height: 140.0,
                                          child: Image.asset(
                                              "images/icon_person.png"),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 20.0,
                                              left: 25.0,
                                              right: 25.0,
                                              bottom: 35.0),
                                          child: Center(
                                            child: Text(
                                              "Anda Belum Memiliki Daftar Teman",
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: getDataFriend,
                                  child: SingleChildScrollView(
                                      physics: AlwaysScrollableScrollPhysics(),
                                      child: Column(
                                        children: listFriend
                                            .map(
                                              (FriendList item) => InkWell(
                                                onTap: () async {},
                                                child: Container(
                                                  child: Card(
                                                      elevation: 0.5,
                                                      margin: EdgeInsets.only(
                                                          top: 5.0,
                                                          bottom: 5.0,
                                                          left: 0.0,
                                                          right: 0.0),
                                                      child: ClipPath(
                                                        clipper: ShapeBorderClipper(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            3))),
                                                        child: Container(
                                                          child: ListTile(
                                                            leading: Container(
                                                              height: 40.0,
                                                              width: 40.0,
                                                              child: ClipOval(
                                                                  child: FadeInImage
                                                                      .assetNetwork(
                                                                placeholder:
                                                                    'images/loading.gif',
                                                                image: item.imageFriend ==
                                                                            null ||
                                                                        item.imageFriend ==
                                                                            ''
                                                                    ? url(
                                                                        'assets/images/imgavatar.png')
                                                                    : url(
                                                                        'storage/image/profile/${item.imageFriend}'),
                                                              )),
                                                            ),
                                                            trailing: buttonFriend(
                                                                item.waktuditerima,
                                                                item.friend),
                                                            title: Text(
                                                                item.namafriend ==
                                                                            '' ||
                                                                        item.namafriend ==
                                                                            null
                                                                    ? 'Teman Tidak Diketahui'
                                                                    : item
                                                                        .namafriend,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: true,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500)),
                                                            subtitle: statusFriend(
                                                                item.waktuditerima,
                                                                item.waktuditolak),
                                                          ),
                                                        ),
                                                      )),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      )),
                                ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _bottomButtons(),
    );
  }

  Widget statusFriend(terima, tolak) {
    String textStatus;
    Color statusColor;
    if (terima == null && tolak == null) {
      textStatus = 'Belum Dikonfirmasi';
      statusColor = Colors.grey;
    } else if (terima != null) {
      textStatus = 'Terdaftar Sebagai Teman';
      statusColor = Colors.green;
    } else if (tolak != null) {
      textStatus = 'Pertemanan Ditolak';
      statusColor = Colors.red;
    } else {
      textStatus = 'Status Tidak Diketahui';
      statusColor = Colors.grey;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      child: Text(textStatus,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
    );
  }

  Widget buttonFriend(terima, friend) {
    if (terima != null) {
      return ButtonTheme(
          minWidth: 0,
          height: 0,
          child: RaisedButton(
            elevation: 0,
            padding: EdgeInsets.all(0),
            color: Colors.white,
            child: Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('Peringatan!'),
                  content: Text('Apakah Anda Ingin Menghapus Teman Ini ? '),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Tidak'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    FlatButton(
                      textColor: Colors.green,
                      child: Text('Ya'),
                      onPressed: () async {
                        Navigator.pop(context);
                        _deleteteman(friend);
                      },
                    )
                  ],
                ),
              );
            },
          ));
    } else {
      return null;
    }
  }

  void _showmodalcreatefriend() {
    setState(() {
      _emailPenggunaController.text = '';
    });
    showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            contentPadding: EdgeInsets.only(top: 10.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          "Tambah Teman",
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _emailPenggunaController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          border: OutlineInputBorder(),
                          hintText: 'Email Pengguna',
                          hintStyle:
                              TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        String emailValid = _emailPenggunaController.text;
                        final bool isValid =
                            EmailValidator.validate(emailValid);
                        if (_emailPenggunaController.text == '') {
                          Fluttertoast.showToast(
                              msg: 'Email Tidak Boleh Kosong');
                        } else if (!isValid) {
                          Fluttertoast.showToast(msg: 'Email Harus Valid');
                        } else {
                          _tambahteman();
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.all(10.0),
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: primaryAppBarColor,
                        ),
                        child: Text(
                          "Tambahkan",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _bottomButtons() {
    return _tabController.index == 2
        ? DraggableFab(
            child: FloatingActionButton(
                shape: StadiumBorder(),
                onPressed: () async {
                  _showmodalcreatefriend();
                },
                backgroundColor: Color.fromRGBO(254, 86, 14, 1),
                child: Icon(
                  Icons.add,
                  size: 20.0,
                )))
        : null;
  }

  Widget listLoadingTodo() {
    return Container(
        margin: EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3, 4]
                  .map((_) => Padding(
                        padding: const EdgeInsets.only(bottom: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40.0,
                                  height: 40.0,
                                  color: Colors.white,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                      ),
                                      Container(
                                        width: 40.0,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        )));
  }

  Widget errorSystemFilter(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
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
                // getHeaderHTTP();
                _tabController.index == 0
                    ? getHeaderHTTP()
                    : _tabController.index == 1
                        ? getDataHistory()
                        : getDataFriend();
              },
              child: Text(
                "Muat Ulang Halaman",
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ]),
    ));
  }

  void _editProfile() {
    showModalBottomSheet(
        context: context,
        builder: (context) => Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300],
                      width: 1.0,
                    ),
                  )),

              height: 350.0 + MediaQuery.of(context).viewInsets.bottom,
              padding: EdgeInsets.only(
                bottom: 25.0 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // child: Form(

                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Material(
                          child: InkWell(
                            child: Text(
                              "Batal",
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        title: Center(child: Text("Edit Profile")),
                        trailing: Material(
                          child: InkWell(
                              child: Text("Simpan",
                                  style: TextStyle(color: Colors.blue)),
                              onTap: () {
                                editData('N');
                              }),
                        ),
                      ),
                      Divider(),
                      Container(
                        margin: EdgeInsets.only(bottom: 6),
                        child: Theme(
                          data: new ThemeData(
                            primaryColor: Colors.blue,
                            primaryColorDark: Colors.blue,
                          ),
                          child: new TextField(
                            controller: _controllerNama,
                            decoration: new InputDecoration(
                              border: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: primaryAppBarColor)),
                              hintText: 'Nama',
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.deepOrange,
                              ),
                              prefixText: ' ',
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 6),
                        child: Theme(
                          data: new ThemeData(
                            primaryColor: Colors.blue,
                            primaryColorDark: Colors.blue,
                          ),
                          child: new TextField(
                            enabled: false,
                            enableInteractiveSelection: false,
                            controller: _controllerEmail,
                            decoration: new InputDecoration(
                              border: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: primaryAppBarColor)),
                              hintText: 'Email',
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.deepOrange,
                              ),
                              suffixIcon: const Icon(Icons.lock_outline),
                              prefixText: ' ',
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 6),
                        child: Theme(
                          data: new ThemeData(
                            primaryColor: Colors.blue,
                            primaryColorDark: Colors.blue,
                          ),
                          child: new TextField(
                            keyboardType: TextInputType.phone,
                            controller: _controllerPhone,
                            decoration: new InputDecoration(
                              border: new OutlineInputBorder(
                                  borderSide:
                                      new BorderSide(color: Colors.blue)),
                              hintText: 'No telp',
                              prefixIcon: const Icon(
                                Icons.phone,
                                color: Colors.deepOrange,
                              ),
                              prefixText: ' ',
                            ),
                          ),
                        ),
                      ),
                      Container(
                          // height: 5 * 18.0,
                          child: TextField(
                        controller: _controllerLocation,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: new OutlineInputBorder(
                              borderSide: new BorderSide(color: Colors.blue)),
                          hintText: "Alamat",
                          // labelText: 'Alamat',
                          // fillColor: Colors.grey[300],
                          // filled: true,
                        ),
                      ))
                    ],
                  ),
                ),
              ),
              // ),
            ));
  }
}

class DetailScreen extends StatefulWidget {
  final String tag;
  final String url;

  DetailScreen({Key key, @required this.tag, @required this.url})
      : assert(tag != null),
        assert(url != null),
        super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
  }

  @override
  void dispose() {
    //SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        child: Center(
          child: Hero(
            tag: widget.tag,
            child: FadeInImage.assetNetwork(
              placeholder: 'images/imgavatar.png',
              image: widget.url,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
