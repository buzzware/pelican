import 'package:flutter/material.dart';

import 'AppCommon.dart';
import 'AppRoutes.dart';


class EntrancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.red, child:
    Padding(
      padding: const EdgeInsets.only(top: 200),
      child: Column(children: [
        MaterialButton(
          child: Text("One"),
          onPressed: () {
            AppCommon.router.push(AppRoutes.PAGE_ONE);
          },
          shape: Border.all(color: Colors.white),
        ),
        Padding(padding: const EdgeInsets.only(top: 20)),
        MaterialButton(
          child: Text("Two"),
          onPressed: () {
            AppCommon.router.push(AppRoutes.PAGE_TWO);
          },
          shape: Border.all(color: Colors.white),
        )
      ]),
    ));
  }
}
