import 'package:flutter/material.dart';

class PageOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page One'),
        automaticallyImplyLeading: true,  // automatic back button
      ),
      body: Container(
          color: Colors.blue,
          child: Center(child: Text('Page Content'))
      )
    );
  }
}
