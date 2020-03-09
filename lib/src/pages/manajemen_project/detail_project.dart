import 'package:intl/intl.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/src/model/Todo.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/model/Member.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:convert';
import 'edit_project.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/pages/todolist/detail_todo.dart';

String tokenType, accessToken;
Map<String, String> requestHeaders = Map();

class ManajemenDetailProjectAll extends StatefulWidget {
  ManajemenDetailProjectAll({Key key, this.idproject, this.namaproject})
      : super(key: key);
  final int idproject;
  final String namaproject;
  @override
  State<StatefulWidget> createState() {
    return _ManajemenDetailProjectAllState();
  }
}

class _ManajemenDetailProjectAllState extends State<ManajemenDetailProjectAll> {
  List<Member> projectMemberdetail = [];
  List<Todo> projectTododetail = [];
  bool isLoading, isError;
  ProgressDialog progressApiAction;
  String projectPercent;
  Map dataProject, dataStatusKita;
  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  @override
  void initState() {
    super.initState();
    getHeaderHTTP();
    projectPercent = '0';
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return detailProject();
  }

  Future<List<List>> detailProject() async {
    setState(() {
      isLoading = true;
    });
    try {
      final getDetailProject = await http
          .post(url('api/detail_project_all'), headers: requestHeaders, body: {
        'project': widget.idproject.toString(),
      });

      if (getDetailProject.statusCode == 200) {
        setState(() {
          projectMemberdetail.clear();
          projectMemberdetail = [];
          projectTododetail.clear();
          projectTododetail = [];
        });
        var getDetailProjectJson = json.decode(getDetailProject.body);
        print(getDetailProjectJson['progressproject']);
        var members = getDetailProjectJson['member'];
        var todos = getDetailProjectJson['todo'];
        Map rawProject = getDetailProjectJson['project'];
        Map rawStatusKita = getDetailProjectJson['statusKita'];
        print(getDetailProjectJson);
        if (mounted) {
          setState(() {
            dataProject = rawProject;
            dataStatusKita = rawStatusKita;
            projectPercent = getDetailProjectJson['progressproject'].toString();
          });
        }

        for (var i in members) {
          Member member = Member(
            iduser: i['mp_user'],
            name: i['us_name'],
            email: i['us_email'],
            roleid: i['mp_role'].toString(),
            rolename: i['r_name'],
            image: i['us_image'],
          );
          projectMemberdetail.add(member);
        }

        for (var i in todos) {
          Todo todo = Todo(
              id: i['tl_id'],
              title: i['tl_title'],
              desc: i['tl_desc'],
              timestart: i['tl_allday'] == '0' || i['tl_allday'] == 0 ? DateFormat("dd MMMM yyyy HH:mm")
                  .format(DateTime.parse(i['tl_planstart'])) : DateFormat("dd MMMM yyyy")
                  .format(DateTime.parse(i['tl_planstart'])),
              timeend: i['tl_allday'] == '0' || i['tl_allday'] == 0 ? DateFormat("dd MMMM yyyy HH:mm")
                  .format(DateTime.parse(i['tl_planend'])) : DateFormat("dd MMMM yyyy")
                  .format(DateTime.parse(i['tl_planend'])),
              progress: i['tl_progress'].toString(),
              status: i['tl_status'],
              statuspinned: i['tli_todolist'].toString());
          projectTododetail.add(todo);
        }
        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getDetailProject.statusCode == 401) {
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
        print(getDetailProject.body);
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
      Fluttertoast.showToast(msg: "error");
      debugPrint('$e');
    }
    return null;
  }

  void _showdetailMemberProject(idMember) async {
    await progressApiAction.show();
    try {
      final detailMemberUrl = await http.post(url('api/detail_member_project'),
          headers: requestHeaders,
          body: {
            'member': idMember.toString(),
            'project': widget.idproject.toString(),
          });
      if (detailMemberUrl.statusCode == 200) {
        var detailMemberjson = json.decode(detailMemberUrl.body);
        var dataMemberProject = detailMemberjson;
        String imageDetailMember = dataMemberProject['us_image'];
        String namaDetailMember = dataMemberProject['us_name'];
        String statusDetailMember = dataMemberProject['mp_role'].toString();
        String addressDetailMember = dataMemberProject['us_address'];
        String phoneDetailMember = dataMemberProject['us_phone'];
        String emailDetailMember = dataMemberProject['us_email'];
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        showModalDetailMember(
            imageDetailMember,
            namaDetailMember,
            statusDetailMember,
            addressDetailMember,
            phoneDetailMember,
            emailDetailMember);
      } else {
        print(detailMemberUrl.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: 'Gagal, Silahkan Coba Kembali');
      }
    } on TimeoutException {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: 'Time Out, Try Again');
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      print(e.toString());
      Fluttertoast.showToast(msg: 'Gagal, Silahkan Coba Kembali');
    }
  }

  void showModalDetailMember(image, name, status, address, phone, email) {
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
                          child: ClipOval(
                            child: FadeInImage.assetNetwork(
                                placeholder: 'images/imgavatar.png',
                                image: image == null || image == ''
                                    ? url('assets/images/imgavatar.png')
                                    : url('storage/image/profile/$image')),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
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
                        Container(
                          margin: EdgeInsets.only(bottom: 15.0),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(right: 3.0),
                                child: Text(
                                  'Status : ',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(
                                    top: 5,
                                    left: 10.0,
                                    bottom: 5.0,
                                    right: 10.0),
                                decoration: BoxDecoration(
                                  color: primaryAppBarColor,
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          5.0) //                 <--- border radius here
                                      ),
                                ),
                                child: Text(
                                  status == '1'
                                      ? 'Owner'
                                      : status == '2'
                                          ? 'Admin'
                                          : status == '3'
                                              ? 'Executor'
                                              : status == '4'
                                                  ? 'Viewer'
                                                  : "Tidak Diketehui",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
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
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 150.0,
              floating: false,
              pinned: true,
              centerTitle: false,
              actions: <Widget>[
                dataStatusKita == null
                    ? Container()
                    : dataStatusKita['mp_role'] == 3 ||
                            dataStatusKita['mp_role'] == 4
                        ? Container()
                        : IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                            tooltip: 'Edit Data Project',
                            onPressed: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DetailProject(
                                          idproject: widget.idproject,
                                          namaproject: widget.namaproject)));
                            },
                          ),
              ],
              // automaticallyImplyLeading: false,
              backgroundColor: primaryAppBarColor,
              flexibleSpace: FlexibleSpaceBar(

                  // titlePadding: EdgeInsets.only(left: 15.0,bottom: 10.0,top:20.0,right: 15.0),
                  centerTitle: true,
                  // titlePadding: EdgeInsets.only(left:40.0,right:40.0),
                  title: Container(
                    margin:
                        EdgeInsets.only(left: 50.0, right: 50.0, bottom: 0.0),
                    padding: EdgeInsets.only(
                        left: 15.0, bottom: 5.0, top: 5.0, right: 15.0),
                    child: Text("${widget.namaproject}",
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                        )),
                  ),
                  background: Image.asset(
                    "images/manajemen_project.png",
                    fit: BoxFit.cover,
                  )),
            ),
          ];
        },
        body: isLoading == true
            ? loadingPage(context)
            : isError == true
                ? errorSystem(context)
                : RefreshIndicator(
                    onRefresh: getHeaderHTTP,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            dataProject == null
                                ? Text('Belum Ada Keterangan Tanggal')
                                : Column(
                                    children: <Widget>[
                                      Text(
                                        DateFormat('dd MMM yyyy').format(
                                                DateTime.parse(dataProject[
                                                    'p_timestart'])) +
                                            ' - ' +
                                            DateFormat('dd MMM yyyy')
                                                .format(DateTime.parse(
                                                    dataProject['p_timeend'])),
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                            Padding(
                              padding: const EdgeInsets.only(top:10.0),
                              child: Text(
                                dataProject == null
                                    ? 'Belum ada deskripsi project'
                                    : dataProject['p_desc'] == null ||
                                            dataProject['p_desc'] == '' ||
                                            dataProject['p_desc'] == 'null'
                                        ? 'Belum ada deskripsi project'
                                        : dataProject['p_desc'],
                                style: TextStyle(height: 2),
                              ),
                            ),
                            // Container(
                            //   margin: EdgeInsets.only(top: 25.0, bottom: 15.0),
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     children: <Widget>[
                            //       InkWell(
                            //         onTap: () async {
                            //           Fluttertoast.showToast(
                            //               msg: 'Fitur ini masih dikerjakan');
                            //         },
                            //         child: Container(
                            //           margin: EdgeInsets.only(right: 3),
                            //           padding: EdgeInsets.only(
                            //               top: 10.0,
                            //               left: 5,
                            //               bottom: 10.0,
                            //               right: 5),
                            //           decoration: BoxDecoration(
                            //             border: Border.all(
                            //                 color: Colors.grey[300],
                            //                 width: 1.0),
                            //             borderRadius:
                            //                 BorderRadius.circular(10.0),
                            //           ),
                            //           child: Row(
                            //             children: <Widget>[
                            //               Icon(
                            //                 Icons.insert_drive_file,
                            //                 size: 13,
                            //                 color: Colors.red,
                            //               ),
                            //               Padding(
                            //                 padding: const EdgeInsets.only(
                            //                     left: 5.0),
                            //                 child: Text(
                            //                   'Proposal Project',
                            //                   style: TextStyle(
                            //                       color: Colors.black,
                            //                       fontSize: 12),
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //       ),
                            //       InkWell(
                            //         onTap: () async {
                            //           Fluttertoast.showToast(
                            //               msg: 'Fitur ini masih dikerjakan');
                            //         },
                            //         child: Container(
                            //           margin: EdgeInsets.only(left: 3),
                            //           padding: EdgeInsets.only(
                            //               top: 10.0,
                            //               left: 5,
                            //               bottom: 10.0,
                            //               right: 5),
                            //           decoration: BoxDecoration(
                            //             border: Border.all(
                            //                 color: Colors.grey[300],
                            //                 width: 1.0),
                            //             borderRadius:
                            //                 BorderRadius.circular(10.0),
                            //           ),
                            //           child: Row(
                            //             children: <Widget>[
                            //               Icon(
                            //                 Icons.insert_drive_file,
                            //                 size: 13,
                            //                 color: Colors.red,
                            //               ),
                            //               Padding(
                            //                 padding: const EdgeInsets.only(
                            //                     left: 5.0),
                            //                 child: Text(
                            //                   'Ruang Lingkup',
                            //                   style: TextStyle(
                            //                       color: Colors.black,
                            //                       fontSize: 12),
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Container(
                                margin: EdgeInsets.only(bottom: 15.0),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child: Text(
                                    'Project Progress',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )),
                            Container(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  CircularPercentIndicator(
                                    radius: 80.0,
                                    lineWidth: 5.0,
                                    animation: true,
                                    percent: double.parse(projectPercent) / 100,
                                    center: new Text(
                                      "$projectPercent%",
                                      style: new TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.0),
                                    ),
                                    circularStrokeCap: CircularStrokeCap.round,
                                    progressColor: Colors.green,
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 15.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                            padding: EdgeInsets.only(top: 15.0),
                                            child: Row(
                                              children: <Widget>[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100.0),
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                        right: 3.0),
                                                    height: 10.0,
                                                    alignment: Alignment.center,
                                                    width: 10.0,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Color.fromRGBO(
                                                              0, 204, 65, 1.0),
                                                          width: 1.0),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  100.0) //                 <--- border radius here
                                                              ),
                                                      color: Color.fromRGBO(
                                                          0, 204, 65, 1.0),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 5.0),
                                                  child: Text(
                                                    'Sudah Selesai',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )),
                                        Padding(
                                            padding: EdgeInsets.only(top: 10.0),
                                            child: Row(
                                              children: <Widget>[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100.0),
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                        right: 3.0),
                                                    height: 10.0,
                                                    alignment: Alignment.center,
                                                    width: 10.0,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Color.fromRGBO(
                                                              0, 204, 65, 1.0),
                                                          width: 1.0),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  100.0) //                 <--- border radius here
                                                              ),
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 5.0),
                                                  child: Text(
                                                    'Belum Selesai',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                                margin:
                                    EdgeInsets.only(bottom: 15.0, top: 15.0),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child: Text(
                                    'Team Member',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )),
                            Container(
                              color: Colors.white,
                              margin: EdgeInsets.only(
                                top: 0.0,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: projectMemberdetail
                                        .map((Member item) => InkWell(
                                              onTap: () async {
                                                _showdetailMemberProject(
                                                    item.iduser);
                                              },
                                              child: Container(
                                                width: 40.0,
                                                height: 40.0,
                                                margin:
                                                    EdgeInsets.only(right: 5.0),
                                                child: ClipOval(
                                                  child:
                                                      FadeInImage.assetNetwork(
                                                    placeholder:
                                                        'images/loading.gif',
                                                    image: item.image == null ||
                                                            item.image == '' ||
                                                            item.image == 'null'
                                                        ? url(
                                                            'assets/images/imgavatar.png')
                                                        : url(
                                                            'storage/image/profile/${item.image}'),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                                margin:
                                    EdgeInsets.only(bottom: 10.0, top: 15.0),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child: Text(
                                    'To Do',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )),
                            projectTododetail.length == 0
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 25.0),
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
                                            "${widget.namaproject} Tidak Memiliki To Do Sama Sekali",
                                            style: TextStyle(
                                              fontSize: 16,
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    ]))
                                : Container(
                                    color: Colors.white,
                                    margin: EdgeInsets.only(
                                      top: 0.0,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: projectTododetail
                                              .map((Todo item) => InkWell(
                                                  onTap: () async {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ManajemenDetailTodo(
                                                                  idtodo:
                                                                      item.id,
                                                                  namatodo: item
                                                                      .title,
                                                                )));
                                                  },
                                                  child: Card(
                                                      elevation: 0.5,
                                                      margin: EdgeInsets.only(
                                                          top: 5.0,
                                                          bottom: 5.0,
                                                          left: 5.0,
                                                          right: 5.0),
                                                      child: ListTile(
                                                        title: Row(
                                                          children: <Widget>[
                                                            Expanded(
                                                              child: Text(
                                                                  item.title ==
                                                                              '' ||
                                                                          item.title ==
                                                                              null
                                                                      ? 'Nama To Do Tidak Diketahui'
                                                                      : item
                                                                          .title,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  softWrap:
                                                                      true,
                                                                  maxLines: 1,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500)),
                                                            ),
                                                            ButtonTheme(
                                                              minWidth: 0.0,
                                                              height: 0,
                                                              child: FlatButton(
                                                                  onPressed:
                                                                      () async {
                                                                    try {
                                                                      final actionPinnedTodo = await http.post(
                                                                          url(
                                                                              'api/actionpinned_todo'),
                                                                          headers:
                                                                              requestHeaders,
                                                                          body: {
                                                                            'todolist':
                                                                                item.id.toString(),
                                                                          });

                                                                      if (actionPinnedTodo
                                                                              .statusCode ==
                                                                          200) {
                                                                        var actionPinnedTodoJson =
                                                                            json.decode(actionPinnedTodo.body);
                                                                        if (actionPinnedTodoJson['status'] ==
                                                                            'tambah') {
                                                                          setState(
                                                                              () {
                                                                            item.statuspinned =
                                                                                item.id.toString();
                                                                          });
                                                                        } else if (actionPinnedTodoJson['status'] ==
                                                                            'hapus') {
                                                                          setState(
                                                                              () {
                                                                            item.statuspinned =
                                                                                null;
                                                                          });
                                                                        }
                                                                      } else {
                                                                        print(actionPinnedTodo
                                                                            .body);
                                                                      }
                                                                    } on TimeoutException catch (_) {
                                                                      Fluttertoast
                                                                          .showToast(
                                                                              msg: "Timed out, Try again");
                                                                    } catch (e) {
                                                                      print(e);
                                                                    }
                                                                  },
                                                                  color: Colors
                                                                      .white,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              0),
                                                                  child: Icon(
                                                                    Icons
                                                                        .star_border,
                                                                    color: item.statuspinned == null ||
                                                                            item.statuspinned ==
                                                                                'null' ||
                                                                            item.statuspinned ==
                                                                                ''
                                                                        ? Colors
                                                                            .grey
                                                                        : Colors
                                                                            .orange,
                                                                  )),
                                                            ),
                                                          ],
                                                        ),
                                                        subtitle: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      top: 0,
                                                                      bottom:
                                                                          10.0),
                                                              child: Text(
                                                                  '${item.timestart} - ${item.timeend}'),
                                                            ),
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          10.0),
                                                              child:
                                                                  LinearPercentIndicator(
                                                                      lineHeight:
                                                                          8.0,
                                                                      percent:
                                                                          double.parse(item.progress) /
                                                                              100,
                                                                      trailing:
                                                                          new Text(
                                                                        "${item.progress}%",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontWeight: FontWeight.w500),
                                                                      ),
                                                                      progressColor:
                                                                          Colors
                                                                              .green),
                                                            ),
                                                          ],
                                                        ),
                                                      ))))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: bottomvaigation(),
    );
  }

  Widget bottomvaigation() {
    if (dataProject == null) {
      return null;
    } else if (dataProject['p_status'] == 'Open') {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(0),
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: dataStatusKita == null
                              ? null
                              : dataStatusKita['mp_role'] == 4
                                  ? null
                                  : () async {
                                      actionmulaimengerjakan(
                                          'baru mengerjakan');
                                    },
                          child: Text(
                            "Mulai Mengerjakan",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    } else if (dataProject['p_status'] == 'Working') {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 3.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: Colors.grey,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(0),
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: dataStatusKita == null
                              ? null
                              : dataStatusKita['mp_role'] == 4
                                  ? null
                                  : () async {
                                      actionmulaimengerjakan(
                                          'pending mengerjakan');
                                    },
                          child: Text(
                            "Pending",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 3, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: Colors.green,
                          padding: EdgeInsets.all(0),
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: dataStatusKita == null
                              ? null
                              : dataStatusKita['mp_role'] == 4
                                  ? null
                                  : () async {
                                      actionmulaimengerjakan(
                                          'selesai mengerjakan');
                                    },
                          child: Text(
                            "Selesai",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    } else if (dataProject['p_status'] == 'Pending') {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          padding: EdgeInsets.all(0),
                          color: primaryAppBarColor,
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: dataStatusKita == null
                              ? null
                              : dataStatusKita['mp_role'] == 4
                                  ? null
                                  : () async {
                                      actionmulaimengerjakan(
                                          'mulai mengerjakan lagi');
                                    },
                          child: Text(
                            "Mulai Mengerjakan Lagi",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    } else if (dataProject['p_status'] == 'Finish') {
      return BottomAppBar(
          child: Container(
              width: double.infinity,
              height: 55.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(),
                      margin: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: ButtonTheme(
                        child: RaisedButton(
                          color: primaryAppBarColor,
                          padding: EdgeInsets.all(0),
                          textColor: Colors.white,
                          disabledColor: Color.fromRGBO(254, 86, 14, 0.8),
                          disabledTextColor: Colors.white,
                          splashColor: Colors.blueAccent,
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0),
                          ),
                          onPressed: null,
                          child: Text(
                            "Project Sudah Selesai",
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )));
    }
    return null;
  }

  void actionmulaimengerjakan(type) async {
    await progressApiAction.show();
    try {
      final addpeserta = await http.post(url('api/project/started-project'),
          headers: requestHeaders,
          body: {
            'project': widget.idproject.toString(),
            'type': type,
          });
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
          getHeaderHTTP();
        }
      } else {
        print(addpeserta.body);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});

      print(e);
    }
  }

  Widget errorSystem(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
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
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget loadingPage(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
            child: SingleChildScrollView(
                child: Container(
          margin: EdgeInsets.only(top: 15.0),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3]
                  .map((_) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                        margin: EdgeInsets.only(right: 15.0, top: 10.0),
                        width: double.infinity,
                        height: 10.0,
                      ))
                  .toList(),
            ),
          ),
        ))),
        Container(
            child: SingleChildScrollView(
                child: Container(
          margin: EdgeInsets.only(top: 15.0),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                0,
              ]
                  .map((_) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                        margin: EdgeInsets.only(right: 15.0, top: 10.0),
                        width: 120.0,
                        height: 10.0,
                      ))
                  .toList(),
            ),
          ),
        ))),
        Container(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  margin: EdgeInsets.only(top: 15.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 0.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300],
                    highlightColor: Colors.grey[100],
                    child: Row(
                      children: [0, 1, 2, 3, 4, 5, 6]
                          .map((_) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(100.0)),
                                ),
                                margin: EdgeInsets.only(right: 15.0, top: 10.0),
                                width: 40.0,
                                height: 40.0,
                              ))
                          .toList(),
                    ),
                  ),
                ))),
        Container(
            margin: EdgeInsets.only(top: 20.0),
            child: SingleChildScrollView(
                child: Container(
              margin: EdgeInsets.only(top: 15.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300],
                highlightColor: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    0,
                  ]
                      .map((_) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            margin: EdgeInsets.only(right: 15.0, top: 10.0),
                            width: 120.0,
                            height: 10.0,
                          ))
                      .toList(),
                ),
              ),
            ))),
        Container(
            color: Colors.white,
            margin: EdgeInsets.only(
              top: 15.0,
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
                                      height: 35.0,
                                    ),
                                    Expanded(
                                      flex: 9,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
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
            ))),
      ],
    ));
  }
}
