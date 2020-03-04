import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/storage/storage.dart';

enum PageEnum {
  openGaleri,
  deletePhoto,
}

class EditPhoto extends StatefulWidget {
   final String title;
   final String fileName;
   EditPhoto({Key key, this.title,this.fileName});
   
  @override
  _EditPhotoState createState() => _EditPhotoState();
}

enum AppState {
  free,
  picked,
  cropped,
}

class _EditPhotoState extends State<EditPhoto> {
  AppState state;
  File imageFile;
  String defaultImage;
  Map<String, String> requestHeaders = Map();
  String tokenType, accessToken;
  bool isLoading, isError, isAccess, isFilter, isErrorfilter, isCreate;
  ProgressDialog progressApiAction;

    @override
  void initState() {
    super.initState();
    state = AppState.free;
    defaultImage = widget.fileName;
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
        backgroundColor: Colors.black,
        title: Text("Profile Photo"),
        actions: <Widget>[
          PopupMenuButton<PageEnum>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            
            color: Color.fromRGBO(28, 28, 27, 1),
            onSelected: (PageEnum value){
              switch (value) {
                case PageEnum.openGaleri:
                _pickImage();
                  break;
                case PageEnum.deletePhoto:
                _deleteImage();
                break;
                default:
              }
            },
            itemBuilder: (context) => [  
              PopupMenuItem(
                value: PageEnum.openGaleri,
                child: ListTile(
                  dense:true,
                  contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text("Edit",style: TextStyle( color: Colors.white),)
                ),
                
              ),
              PopupMenuItem(
                value: PageEnum.deletePhoto,
                child: ListTile(
                  dense:true,
                contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                  leading: Icon(Icons.delete, color: Colors.white),
                  title: Text("Hapus",style: TextStyle(color: Colors.white),)
                ),
              )
            ],

          )

          
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: imageFile != null 
          ? Image.file(imageFile) 
          :
          defaultImage != '' 
          ?
          FadeInImage.assetNetwork(
          placeholder:'images/imgavatar.png',
          image: url('storage/profile/'+widget.fileName))
          :
          Image.asset('images/imgavatar.png',
                                fit: BoxFit.fill)
          
          
          // Container()
        ),
      ),
      floatingActionButton: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          state == AppState.cropped ?
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (state == AppState.free)
                  _pickImage();
                else if (state == AppState.picked)
                  _cropImage();
                else if (state == AppState.cropped) 
                _clearImage();
              },
              child: Icon(Icons.clear,color: Colors.deepOrange,),
            ),
          ): Container(),
          state != AppState.free ?
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              backgroundColor: Colors.deepOrange,
              onPressed: () {
                if (state == AppState.free)
                  _pickImage();
                else if (state == AppState.picked)
                  _cropImage();
                else if (state == AppState.cropped) 
                _saveImage();
              },
              child: _buildButtonIcon(),
            ),
          ) : Container(),
        ],
      ),
    );
  }
   Widget _buildButtonIcon() {
    //  print(state);
   if (state == AppState.picked)
      return Icon(Icons.crop);
    else if (state == AppState.cropped)
      return Icon(Icons.check);
    else
      return Container();
  }

    Future<Null> _pickImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    print(imageFile);
    
    if (imageFile != null) {
      setState(() {
        state = AppState.picked;
      });
    }
  }

    Future<Null> _cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      iosUiSettings: IOSUiSettings(
        title: 'Cropper',
      )
    );
    if (croppedFile != null) {
      imageFile = croppedFile;
      setState(() {
        state = AppState.cropped;
      });
    }
  }
    void _clearImage() {
    imageFile = null;
    setState(() {
      state = AppState.free;
    });
  }

   void _saveImage() async {

     var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    await progressApiAction.show();
    try {
    var pathname = imageFile.toString();
    var fileImage = base64Encode(imageFile.readAsBytesSync());
    var filename = imageFile.toString().split('/').last;

      final addpeserta = await http
          .patch(url('api/user/profile/updateimage'), headers: requestHeaders, body: {
        'file64': fileImage.toString(),
        'pathname': pathname,
        'filename': filename
      });
      // print(widget.idTodo.toString());
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          // getHeaderHTTP();
          setState(() {
            // pathname = '';
            storage.setDataString("photo", addpesertaJson['data']);
            state = AppState.free;
            isCreate = false;
          });
          // Navigator.pop(context);
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'owner') {
          Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else if (addpesertaJson['status'] == 'exists') {
          Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Status Tidak Diketahui");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
          setState(() {
            isCreate = false;
          });
        }
      } else {
        print(addpeserta.body);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
        setState(() {
          isCreate = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      print(e);
    }
  }

   void _deleteImage() async {

     var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    await progressApiAction.show();
    try {
    

      final addpeserta = await http
          .patch(url('api/user/profile/deleteimage'), headers: requestHeaders);
      // print(widget.idTodo.toString());
      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          // getHeaderHTTP();
          setState(() {
            // pathname = '';
            storage.setDataString("photo", '');
             defaultImage= '';
            _clearImage();
            state = AppState.free;
            isCreate = false;
          });
          // Navigator.pop(context);
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'owner') {
          Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else if (addpesertaJson['status'] == 'exists') {
          Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Status Tidak Diketahui");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
          setState(() {
            isCreate = false;
          });
        }
      } else {
        print(addpeserta.body);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
        setState(() {
          isCreate = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      print(e);
    }
  }
}