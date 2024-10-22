import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlankPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Container(child: Text("This page left intentionally blank", style: TextStyle(color: Colors.white))),
    );
  }
}
