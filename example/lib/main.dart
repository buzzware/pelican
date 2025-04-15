import 'package:example/AppRoutes.dart';
import 'package:flutter/material.dart';
import 'package:pelican/pelican.dart';

import 'AppCommon.dart';

void main() {
  AppCommon.reset();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final routeInformationProvider = PelicanRouter.platformRouteInformationProviderWithInitialPath(AppRoutes.TRIAGE_PATH);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pelican Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerDelegate: AppCommon.router,
      routeInformationParser: AppCommon.router.parser,
      //routeInformationProvider: routeInformationProvider
    );
  }
}
