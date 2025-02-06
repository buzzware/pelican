import 'package:flutter/material.dart';

class PageTwo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return
      // Scaffold(
      //   appBar: AppBar(
      //     title: Text('Page Two'),
      //     automaticallyImplyLeading: true,  // automatic back button
      //   ),
      //   body:
        Container(
            color: Colors.purple,
            child: Center(child: Text('Page Two'))
        );
    // );
  }
}
