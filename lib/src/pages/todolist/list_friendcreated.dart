import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/model/FriendList.dart';
import 'package:todolist_app/src/pages/todolist/adduserfile.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';

bool actionBackAppBar, iconButtonAppbarColor;
List<FriendList> listFriends = [];
bool isLoading,
    isError,
    isFilter,
    isErrorfilter,
    isDelete,
    isCreate,
    isNotFound;
final _debouncer = Debouncer(milliseconds: 500);

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class WidgetFriendList extends StatefulWidget {
  @override
  _WidgetFriendListState createState() => _WidgetFriendListState();
}

class _WidgetFriendListState extends State<WidgetFriendList> {
  final TextEditingController _searchQuery = new TextEditingController();
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return filterDataFriendList('all');
  }

  Future<List<List>> filterDataFriendList(nama) async {
    if (nama == '') {
      nama = 'unknown';
    }
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
      final participant = await http.get(url('api/get_friendlist/filter/$nama'),
          headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var participants = listParticipantToJson;
        listFriends = [];
        if (participants == 'notfound') {
          setState(() {
            isLoading = false;
            isError = false;
            isNotFound = true;
          });
        } else {
          for (var i in participants) {
            FriendList participant = FriendList(
                users: i['user'],
                namafriend: i['name'],
                friend: i['friend'],
                emailfriend: i['email'],
                imageFriend: i['image']);
            listFriends.add(participant);
          }
          setState(() {
            isLoading = false;
            isError = false;
            isNotFound = false;
          });
        }
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
      setState(() {
        isLoading = false;
        isError = true;
      });
      debugPrint('$e');
    }
    return null;
  }

  @override
  void initState() {
    getHeaderHTTP();
    actionBackAppBar = true;
    isLoading = true;
    isNotFound = false;
    isError = false;
    isFilter = false;
    isCreate = false;
    isErrorfilter = false;
    iconButtonAppbarColor = true;
    isDelete = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildBar(context),
      body: isLoading == true
          ? _loadingview()
          : isError == true
              ? Container(
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
                              style: TextStyle(
                                  fontSize: 14.0, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                )
              : isNotFound == true
                  ? RefreshIndicator(
                    onRefresh: getHeaderHTTP,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                          child: Center(
                            child: Column(
                              children: <Widget>[
                                new Container(
                                  margin: EdgeInsets.only(top: 16),
                                  width: 200.0,
                                  height: 200.0,
                                  child: Image.asset("images/icon_person.png"),
                                ),
                                Container(
                                    margin: EdgeInsets.only(top: 16.0),
                                    child: Text(
                                      "Upss... Member Tidak Ditemukan",
                                      style: TextStyle(fontSize: 14),
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ),
                  )
                  : Center(
                      child: RefreshIndicator(
                        onRefresh: getHeaderHTTP,
                        child: ListView.builder(
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: listFriends.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                   
                                    emailMemberFriend = listFriends[index]
                                        .emailfriend
                                        .toString();
                                    nameMemberFriend = listFriends[index]
                                        .namafriend
                                        .toString();
                                  });
                                  Navigator.pop(context);
                                },
                                child: ListTile(
                                  leading: Container(
                                    height: 40.0,
                                    width: 40.0,
                                    child: ClipOval(
                                        child: FadeInImage.assetNetwork(
                                      placeholder: 'images/loading.gif',
                                      image: listFriends[index].imageFriend ==
                                                  null ||
                                              listFriends[index].imageFriend ==
                                                  ''
                                          ? url('assets/images/imgavatar.png')
                                          : url(
                                              'storage/image/profile/${listFriends[index].imageFriend}'),
                                    )),
                                  ),
                                  title: Text(
                                    listFriends[index].namafriend == null
                                        ? 'Member Tidak Diketahui'
                                        : listFriends[index].namafriend,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                  subtitle: Padding(padding: EdgeInsets.only(top:5.0,bottom:10.0), child: Text(  listFriends[index].emailfriend == null
                                        ? 'Member Tidak Diketahui'
                                        : listFriends[index].emailfriend,),),
                                  trailing: Icon(Icons.chevron_right),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _loadingview() {
    return Container(
        color: Colors.white,
        margin: EdgeInsets.only(
          top: 0.0,
        ),
        padding: EdgeInsets.all(15.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3, 4, 5]
                  .map((_) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(bottom: 25.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100.0)),
                                    ),
                                    width: 35.0,
                                    height: 35.0),
                                Expanded(
                                  flex: 9,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(left: 15.0),
                                        width: double.infinity,
                                        height: 10.0,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(
                                            left: 15.0, top: 15.0),
                                        width: 100.0,
                                        height: 10.0,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        )));
  }

  Widget appBarTitle = Text(
    "Daftar Teman",
    style: TextStyle(fontSize: 14),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );

  void _handleSearchEnd() {
    setState(() {
      // ignore: new_with_non_type
      actionBackAppBar = true;
      iconButtonAppbarColor = true;
      this.actionIcon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "Daftar Teman",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      );
      filterDataFriendList('all');
      _debouncer.run(() {
        _searchQuery.clear();
      });
    });
  }

  Widget buildBar(BuildContext context) {
    return PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: appBarTitle,
          titleSpacing: 0.0,
          centerTitle: true,
          backgroundColor: primaryAppBarColor,
          automaticallyImplyLeading: actionBackAppBar,
          actions: <Widget>[
            Container(
              color: iconButtonAppbarColor == true
                  ? primaryAppBarColor
                  : Colors.white,
              child: IconButton(
                icon: actionIcon,
                onPressed: isDelete == true || isCreate == true
                    ? null
                    : () {
                        setState(() {
                          if (this.actionIcon.icon == Icons.search) {
                            actionBackAppBar = false;
                            iconButtonAppbarColor = false;
                            this.actionIcon = new Icon(
                              Icons.close,
                              color: Colors.grey,
                            );
                            this.appBarTitle = Container(
                              height: 50.0,
                              alignment: Alignment.center,
                              padding: EdgeInsets.all(0),
                              margin: EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                              ),
                              child: TextField(
                                autofocus: true,
                                controller: _searchQuery,
                                onChanged: (string) {
                                  if (string != null || string != '') {
                                    _debouncer.run(() {
                                      filterDataFriendList(_searchQuery.text);
                                    });
                                  }
                                },
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: new Icon(Icons.search,
                                      color: Colors.grey),
                                  hintText: "Cari Berdasarkan Nama",
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            _handleSearchEnd();
                          }
                        });
                      },
              ),
            ),
          ],
        ));
  }
}
