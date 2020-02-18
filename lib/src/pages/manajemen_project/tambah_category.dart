import 'package:flutter/material.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'dart:convert';
import 'package:todolist_app/src/model/category.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/routes/env.dart';
import 'package:shimmer/shimmer.dart';
import 'create_project.dart';
import 'package:todolist_app/src/utils/utils.dart';

List<ListKategori> listkategori = [];
bool isLoading, isError, isSame, isCreate;
var datepicker;
String tokenType, accessToken;

Map<String, String> requestHeaders = Map();

class ManajemenCreateCategory extends StatefulWidget {
  ManajemenCreateCategory(
      {Key key, this.title, this.listKategoriadd, this.event})
      : super(key: key);
  final String title, event;
  final listKategoriadd;
  @override
  State<StatefulWidget> createState() {
    return _ManajemeCreateCategoryState();
  }
}

class _ManajemeCreateCategoryState extends State<ManajemenCreateCategory> {
  @override
  void initState() {
    datepicker = FocusNode();
    super.initState();
    isLoading = true;
    isError = false;
    isSame = false;
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
    return listKategoriEvent();
  }

  Future<List<ListKategori>> listKategoriEvent() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      isLoading = true;
    });
    try {
      final getCategory = await http.get(
        url('api/listkategori'),
        headers: requestHeaders,
      );

      if (getCategory.statusCode == 200) {
        var kategorieventJson = json.decode(getCategory.body);
        var kategorievents = kategorieventJson;

        listkategori = [];
        for (var i in kategorievents) {
          ListKategori donex = ListKategori(
            id: i['c_id'].toString(),
            name: i['c_name'],
          );
          listkategori.add(donex);
        }
        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getCategory.statusCode == 401) {
        setState(() {
          isLoading = false;
          isError = true;
        });
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
      } else {
        print(getCategory.body);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: new AppBar(
        backgroundColor: primaryAppBarColor,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: new Text(
          "Tambahkan Kategori Sekarang",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      body: isLoading == true
          ? Container(
              margin: EdgeInsets.only(top: 10.0),
              child: SingleChildScrollView(
                  child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300],
                  highlightColor: Colors.grey[100],
                  child: Column(
                    children: [0, 1, 2, 3, 4, 5, 6]
                        .map((_) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(top: 15.0),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(0)),
                                        ),
                                        width: 35.0,
                                        height: 35.0,
                                      ),
                                      Expanded(
                                        flex: 9,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)),
                                          ),
                                          margin: EdgeInsets.only(left: 15.0),
                                          width: double.infinity,
                                          height: 15.0,
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ))
                        .toList(),
                  ),
                ),
              )))
          : isError == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: RefreshIndicator(
                    onRefresh: () => listKategoriEvent(),
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
                            top: 20.0, left: 15.0, right: 15.0),
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
                              listKategoriEvent();
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
              : Padding(
                  padding:
                      const EdgeInsets.only(top: 10.0, left: 5.0, right: 5.0),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh:listKategoriEvent,
                          child: ListView.builder(             
                            itemCount: listkategori.length,
                            itemBuilder: (BuildContext context, int index) {
                              return InkWell(
                                child: Container(
                                  child: Card(
                                      child: ListTile(
                                    leading: Icon(Icons.category),
                                    title: Text(listkategori[index].name == null
                                        ? 'Unknown Nama'
                                        : listkategori[index].name),
                                  )),
                                ),
                                onTap: isCreate == true
                                    ? null
                                    : () async {
                                        for (int i = 0;
                                            i < listKategoriAdd.length;
                                            i++) {
                                          if (listkategori[index].id ==
                                              listKategoriAdd[i].id) {
                                            setState(() {
                                              isSame = true;
                                            });
                                          }
                                        }
                                        if (isSame == true) {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Kategori Event Tersebut Sudah Ada');
                                          setState(() {
                                            isSame = false;
                                          });
                                        } else {
                                          setState(() {
                                            ListKategoriAdd notax =
                                                ListKategoriAdd(
                                              id: listkategori[index].id.toString(),
                                              name: listkategori[index].name,
                                            );
                                            listKategoriAdd.add(notax);
                                          });

                                          Navigator.pop(context);
                                        }
                                      },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
