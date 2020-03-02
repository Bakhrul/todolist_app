import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todolist_app/src/routes/env.dart';

enum PageEnum {
  openGaleri,
  deletePhoto,
 
}

class EditPhoto extends StatefulWidget {
   final String title;
   EditPhoto({Key key, this.title});
   
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

    @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  @override
  Widget build(BuildContext context) {
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
                break;
                default:
              }
            },
            itemBuilder: (context) => [  
              PopupMenuItem(
                value: PageEnum.openGaleri,
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text("Edit",style: TextStyle(color: Colors.white),)
                ),
                
              ),
              PopupMenuItem(
                value: PageEnum.openGaleri,
                child: ListTile(
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
          ? Image.file(imageFile) : Image.network(
            'https://picsum.photos/250?image=9',
          
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () {
          if (state == AppState.free)
            _pickImage();
          else if (state == AppState.picked)
            _cropImage();
          else if (state == AppState.cropped) _clearImage();
        },
        child: _buildButtonIcon(),
      ),
    );
  }
   Widget _buildButtonIcon() {
     print(state);
    if (state == AppState.free)
      return Icon(Icons.add);
    else if (state == AppState.picked)
      return Icon(Icons.crop);
    else if (state == AppState.cropped)
      return Icon(Icons.clear);
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
}