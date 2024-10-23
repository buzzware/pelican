import 'package:flutter/material.dart';

import 'AppCommon.dart';
import 'AppRoutes.dart';

class EntrancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.red, child: Row(children: [
      MaterialButton(
        child: Text("One"),
        onPressed: () {
          AppCommon.router.push(AppRoutes.PAGE_ONE);
        }
      ),
      MaterialButton(
        child: Text("Two"),
        onPressed: () {
          AppCommon.router.push(AppRoutes.PAGE_TWO);
        }
      )
    ]));
  }
}
