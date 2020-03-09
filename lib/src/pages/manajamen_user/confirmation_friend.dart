import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/model/FriendList.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'dart:async';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';

class ConfirmationFriend extends StatefulWidget {
  @override
  ConfirmationFriendState createState() => ConfirmationFriendState();
}

class ConfirmationFriendState extends State<ConfirmationFriend> {
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  List<FriendList> listFriend = [];
  bool isLoading, isError;
  ProgressDialog progressApiAction;

  @override
  void initState() {
    super.initState();
    getHeaderHTTP();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataProject();
  }

  Future<List<List>> getDataProject() async {
    listFriend.clear();
    listFriend = [];
    setState(() {
      isLoading = true;
      listFriend.clear();
      listFriend = [];
    });
    try {
      final getFriendUrl = await http.get(url('api/get_confirmation_friend'),
          headers: requestHeaders);

      if (getFriendUrl.statusCode == 200) {
        var getFriendJson = json.decode(getFriendUrl.body);
        var friends = getFriendJson;
        print(friends);

        for (var i in friends) {
          FriendList participant = FriendList(
            users: i['fl_friend'],
            friend: i['fl_users'],
            namafriend: i['us_name'],
            waktutambah: i['fl_added'] == null || i['fl_added'] == ''
                ? null
                : DateFormat('dd MMM yyyy HH:mm')
                    .format(DateTime.parse(i['fl_added'])),
            waktuditerima: i['fl_approved'],
            waktuditolak: i['fl_denied'],
            imageFriend: i['us_image'],
          );
          listFriend.add(participant);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getFriendUrl.statusCode == 401) {
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
        print(getFriendUrl.body);
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

  void _gantistatusfriend(friend, type) async {
    print(friend);
    await progressApiAction.show();
    try {
      final gantiStatusTemanUrl = await http
          .post(url('api/konfirmasiTeman'), headers: requestHeaders, body: {
        'friend': friend.toString(),
        'type_confirmation': type,
      });

      if (gantiStatusTemanUrl.statusCode == 200) {
        var gantiStatusTemanJson = json.decode(gantiStatusTemanUrl.body);
        if (gantiStatusTemanJson['status'] == 'success') {
          Fluttertoast.showToast(msg: 'Berhasil!');
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          getHeaderHTTP();
        }
      } else {
        print(gantiStatusTemanUrl.body);
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
        appBar: AppBar(
          title: Text(
            "Permintaan Teman",
            style: TextStyle(fontSize: 14),
          ),
          backgroundColor: primaryAppBarColor,
        ),
        body: isLoading != false
            ? listLoadingTodo()
            : isError == true
                ? errorSystem(context)
                : Container(
                    child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Scrollbar(
                      child: RefreshIndicator(
                          onRefresh: getHeaderHTTP,
                          child: ListView.builder(
                            itemCount: listFriend.length,
                            itemBuilder: (BuildContext context, int index) {
                              return InkWell(
                                onTap: () async {
                                  detailUser(listFriend[index].friend);
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
                                                    BorderRadius.circular(3))),
                                        child: Container(
                                          child: ListTile(
                                            leading: Container(
                                              height: 40.0,
                                              width: 40.0,
                                              child: ClipOval(
                                                  child:
                                                      FadeInImage.assetNetwork(
                                                placeholder:
                                                    'images/loading.gif',
                                                image: listFriend[index]
                                                                .imageFriend ==
                                                            null ||
                                                        listFriend[index]
                                                                .imageFriend ==
                                                            ''
                                                    ? url(
                                                        'assets/images/imgavatar.png')
                                                    : url(
                                                        'storage/image/profile/${listFriend[index].imageFriend}'),
                                              )),
                                            ),
                                            title: Text(
                                                listFriend[index].namafriend ==
                                                            '' ||
                                                        listFriend[index]
                                                                .namafriend ==
                                                            null
                                                    ? 'Teman Tidak Diketahui'
                                                    : listFriend[index]
                                                        .namafriend,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                                maxLines: 1,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            trailing: PopupMenuButton<String>(
                                              onSelected: (String value) {
                                                switch (value) {
                                                  case 'Terima':
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                        title:
                                                            Text('Peringatan!'),
                                                        content: Text(
                                                            'Apakah Anda Ingin Menerima Pertemanan?'),
                                                        actions: <Widget>[
                                                          FlatButton(
                                                            child:
                                                                Text('Tidak'),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          FlatButton(
                                                            textColor:
                                                                Colors.green,
                                                            child: Text('Ya'),
                                                            onPressed:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                              _gantistatusfriend(
                                                                  listFriend[
                                                                          index]
                                                                      .friend,
                                                                  'terima');
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    );

                                                    break;
                                                  case 'Tolak':
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                        title:
                                                            Text('Peringatan!'),
                                                        content: Text(
                                                            'Apakah Anda Ingin Menolak Pertemanan?'),
                                                        actions: <Widget>[
                                                          FlatButton(
                                                            child:
                                                                Text('Tidak'),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          FlatButton(
                                                            textColor:
                                                                Colors.green,
                                                            child: Text('Ya'),
                                                            onPressed:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                              _gantistatusfriend(
                                                                  listFriend[
                                                                          index]
                                                                      .friend,
                                                                  'tolak');
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                    break;

                                                  default:
                                                    break;
                                                }
                                              },
                                              icon: Icon(Icons.more_vert),
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'Terima',
                                                  child: Text("Terima"),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Tolak',
                                                  child: Text("Tolak"),
                                                ),
                                              ],
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 5.0, bottom: 10.0),
                                              child: Text(listFriend[index]
                                                          .waktutambah ==
                                                      null
                                                  ? 'Waktu Permintaan Tidak Diketahui'
                                                  : listFriend[index]
                                                      .waktutambah),
                                            ),
                                          ),
                                        ),
                                      )),
                                ),
                              );
                            },
                          )),
                    ),
                  )));
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
                                        width: 100.0,
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
  void detailUser(friend) async{
    print(friend);
    await progressApiAction.show();
    try {
      final detailUserUrl = await http
          .get(url('api/userdetail/$friend'), headers: requestHeaders,);

      if (detailUserUrl.statusCode == 200) {
        var detailUserJson = json.decode(detailUserUrl.body);
        String nama = detailUserJson['us_name'];
        String image = detailUserJson['us_image'];
        String telp = detailUserJson['us_phone'];
        String address = detailUserJson['us_address'];
        String email = detailUserJson['us_email'];
          progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
        showModalDetailMember(image,nama,address,telp,email);
      } else {
        print(detailUserUrl.body);
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

   void showModalDetailMember(image, name, address, phone, email) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
              height: 370.0 + MediaQuery.of(context).viewInsets.bottom,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  right: 15.0,
                  left: 15.0,
                  top: 15.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(
                            top: 10.0,
                          ),
                          height: 60.0,
                          width: 60.0,
                          child: GestureDetector(
                            child: Hero(
                                tag: 'imageDetail',
                                child: ClipOval(
                                    child: FadeInImage.assetNetwork(
                                        fit: BoxFit.cover,
                                        placeholder: 'images/imgavatar.png',
                                        image: image == null ||
                                                image == '' ||
                                                image == 'Tidak ditemukan'
                                            ? url('assets/images/imgavatar.png')
                                            : url(
                                                'storage/image/profile/$image')))),
                            onTap: () {                            
                            },
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 15.0, bottom: 25.0),
                            child: Text(
                              name == null || name == '' || name == 'null'
                                  ? 'Member Tidak Diketahui'
                                  : name,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )),                    
                        ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 0, bottom: 0, left: 10.0, right: 10.0),
                          leading: Icon(
                            Icons.location_on,
                            color: primaryAppBarColor,
                          ),
                          title: Text(
                            address == null || address == ''
                                ? 'Alamat belum ditambahkan'
                                : address,
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                        Container(height: 5.0, child: Divider()),
                        ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 0, bottom: 0, left: 10.0, right: 10.0),
                          leading: Icon(
                            Icons.phone,
                            color: primaryAppBarColor,
                          ),
                          title: Text(
                            phone == null || phone == ''
                                ? 'Nomor telepon belum ditambahkan'
                                : phone,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Container(height: 5.0, child: Divider()),
                        ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 0, bottom: 0, left: 10.0, right: 10.0),
                          leading: Icon(
                            Icons.email,
                            color: primaryAppBarColor,
                          ),
                          title: Text(
                            email == null || email == ''
                                ? 'Email belum ditambahkan'
                                : email,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ));
        });
  }


  Widget errorSystem(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: RefreshIndicator(
        onRefresh: () => getHeaderHTTP(),
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
                  getHeaderHTTP();
                },
                child: Text(
                  "Muat Ulang Halaman",
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
