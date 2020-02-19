import 'package:flutter/material.dart';
import 'package:todolist_app/src/utils/utils.dart';

class Projects extends StatefulWidget {
  @override
  _ProjectsState createState() => _ProjectsState();
}

class _ProjectsState extends State<Projects> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Project ()"),
      ),
      body: _builderBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: Icon(Icons.add),
        backgroundColor: primaryAppBarColor,
      ),
    );
  }

  Widget _builderBody(){
    return Container(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {  },
        
      ),
    );
  }
}