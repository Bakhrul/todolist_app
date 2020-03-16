import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:todolist_app/src/model/Notifications.dart';
import 'dart:core';
import 'package:progress_dialog/progress_dialog.dart';
import '../dashboard/home.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/utils/utils.dart';

String tokenType, accessToken;
List<ListNotifications> listnotifications = [];
bool isLoading, isError;
Map<String, String> requestHeaders = Map();
Map dataUser;
enum PageEnum {
  detailEvent,
  setujuiConfirmation,
  tolakConfirmation,
  deletePesan,
}

class ManajemenNotifications extends StatefulWidget {
  ManajemenNotifications({Key key, this.title}) : super(key: key);
  final String title;
  @override
  State<StatefulWidget> createState() {
    return _NotificationsState();
  }
}

class _NotificationsState extends State<ManajemenNotifications> {
  ProgressDialog progressApiAction;
  @override
  void initState() {
    super.initState();
    isLoading = true;
    isError = false;
    getHeaderHTTP();
  }

  Future<void> getHeaderHTTP() async {
    setState(() {
      jumlahnotifindex = '0';
    });
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    print(requestHeaders);
    return listNotif();
  }

  void deleteNotif(index) async {
    print(listnotifications[index].idnotif);
    try {
      final removeConfirmation = await http.post(
          url('api/deletepesan_notifikasi'),
          headers: requestHeaders,
          body: {
            'idnotif': listnotifications[index].idnotif.toString(),
          });
      print(removeConfirmation);
      if (removeConfirmation.statusCode == 200) {
        var removeConfirmationJson = json.decode(removeConfirmation.body);
        if (removeConfirmationJson['status'] == 'success') {
          setState(() {
            listnotifications.remove(listnotifications[index]);
          });
          String jumlahnotifterbaru =
              removeConfirmationJson['notifbelumbaca'].toString();
          Fluttertoast.showToast(msg: "Berhasil");
        } else if (removeConfirmationJson['status'] == 'Error') {
          Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Lagi");
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Lagi");
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}'");
      print(e);
    }
  }

  Future<List<List>> listNotif() async {
    setState(() {
      isLoading = true;
      isError = false;
      jumlahnotifindex = '0';
    });
    try {
      final notification = await http.get(
        url('api/getnotifications'),
        headers: requestHeaders,
      );

      if (notification.statusCode == 200) {
        var listNotificationJson = json.decode(notification.body);
        var listNotifications = listNotificationJson['notifikasi'];
        listnotifications = [];
        for (var i in listNotifications) {
          ListNotifications willcomex = ListNotifications(
            id: '${i['nt_notifications']}',
            idnotif: i['nt_id'].toString(),
            title: i['n_title'].toString(),
            message: i['n_message'].toString(),
            namato: i['namapenerima'].toString(),
            namafrom: i['namapengirim'],
            status: i['nt_status'],
            idtodo: i['nt_todolist'].toString(),
            namatodo: i['tl_title'],
            namaproject: i['p_name'],
          );
          listnotifications.add(willcomex);
        }
        setState(() {
          isLoading = false;
          isError = false;
          jumlahnotifindex = '0';
        });
      } else if (notification.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token telah kadaluwarsa, silahkan login kembali");
        setState(() {
          isLoading = false;
          isError = true;
        });
      } else {
        print(notification.body);
        setState(() {
          isLoading = false;
          isError = true;
        });
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
      appBar: new AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: new Text(
          "Notifikasi",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: primaryAppBarColor,
      ),
      body: isLoading == true
          ? loadingView()
          : isError == true
              ? RefreshIndicator(
                  onRefresh: () => getHeaderHTTP(),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 20.0),
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
                            "Gagal Memuat Halaman, Tekan Tombol Muat Ulang Halaman Untuk Refresh Halaman",
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
                            top: 20.0, bottom: 20.0, left: 15.0, right: 15.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: RaisedButton(
                            color: Colors.white,
                            textColor: Color.fromRGBO(41, 30, 47, 1),
                            disabledColor: Colors.grey,
                            disabledTextColor: Colors.black,
                            padding: EdgeInsets.all(15.0),
                            splashColor: Colors.blueAccent,
                            onPressed: () async {
                              listNotif();
                            },
                            child: Text(
                              "Muat Ulang Halaman",
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                )
              : listnotifications.length == 0
                  ? RefreshIndicator(
                      onRefresh: () => getHeaderHTTP(),
                      child: Center(
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                new Container(
                                  width: 100.0,
                                  height: 100.0,
                                  child: Image.asset("images/bell.png"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20.0,
                                    left: 15.0,
                                    right: 15.0,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Belum Ada Notifikasi Di Akun Kamu",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ]),
                        ),
                      ))
                  : Padding(
                      padding: const EdgeInsets.only(top:10.0),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Scrollbar(
                              child: RefreshIndicator(
                                onRefresh: () => getHeaderHTTP(),
                                child: ListView.builder(
                                  itemCount: listnotifications.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Dismissible(
                                      background: stackBehindDismiss(),
                                      key: ObjectKey(listnotifications[index]),
                                      onDismissed: (direction) {
                                        deleteNotif(index);
                                      },
                                      child: Card(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  left: BorderSide(
                                            color: listnotifications[index]
                                                            .status ==
                                                        'N' ||
                                                    listnotifications[index]
                                                            .status ==
                                                        null
                                                ? Colors.red
                                                : Colors.grey,
                                            width: 2.0,
                                          ))),
                                          child: ListTile(
                                              leading: Padding(
                                                padding:
                                                    const EdgeInsets.all(0.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100.0),
                                                  child: Container(
                                                    height: 30.0,
                                                    alignment: Alignment.center,
                                                    width: 30.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  100.0) //                 <--- border radius here
                                                              ),
                                                      color: Color.fromRGBO(
                                                          0, 204, 65, 1.0),
                                                    ),
                                                    child: Icon(
                                                      Icons.message,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              title: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5.0),
                                                child: Text(listnotifications[
                                                                    index]
                                                                .title ==
                                                            null ||
                                                        listnotifications[index]
                                                                .title ==
                                                            ''
                                                    ? 'Pesan Tidak Diketahui'
                                                    : listnotifications[index]
                                                        .title),
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5.0),
                                                child: messageEvent(
                                                    listnotifications[index]
                                                        .namatodo,
                                                    listnotifications[index].id,
                                                    listnotifications[index]
                                                        .message,
                                                    listnotifications[index]
                                                        .namato,
                                                    listnotifications[index]
                                                        .namafrom,
                                                    listnotifications[index]
                                                        .namaproject),
                                              )),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
    );
  }

  Widget loadingView() {
    return SingleChildScrollView(
      child: Container(
          margin: EdgeInsets.only(top: 25.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300],
              highlightColor: Colors.grey[100],
              child: Column(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8]
                    .map((_) => Padding(
                          padding: const EdgeInsets.only(bottom: 25.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRect(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.0),
                                    color: Colors.white,
                                  ),
                                  width: 40.0,
                                  height: 40.0,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      width: 100.0,
                                      height: 8.0,
                                      color: Colors.white,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5.0),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          )),
    );
  }

  Widget messageEvent(
      namatodo, id, message, namapenerima, namapengirim, namaproject) {
    if (id == '1' || id == 1 || id == '2' || id == 2) {
      return Padding(
        padding: const EdgeInsets.only(top:5.0,bottom: 10.0),
        child: Text(
          '$namapengirim $message $namatodo',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    } else if (id == '3' || id == 3 || id == '4' || id == 4) {
      return Padding(
       padding: const EdgeInsets.only(top:5.0,bottom: 10.0),
        child: Text(
          '$namatodo $message $namaproject',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    } else if (id == '5' || id == 5 || id == 6 || id == '6') {
      return Padding(
        padding: const EdgeInsets.only(top:5.0,bottom: 10.0),
        child: Text(
          '$namapengirim $message $namaproject',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    } else if (id == '7' ||
        id == 7 ||
        id == '8' ||
        id == 8 ||
        id == 9 ||
        id == '9') {
      return Padding(
        padding: const EdgeInsets.only(top:5.0,bottom: 10.0),
        child: Text(
          '$namatodo $message',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    } else if(id == 10 || id == '10' || id == 11|| id == '11' || id == 12 || id == '12'){
      return Text(
        '$namapengirim $message',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      );
    } else {
      return Text(
        'Pesan Tidak Diketahui',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      );
    }
  }

  Widget stackBehindDismiss() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }
}
