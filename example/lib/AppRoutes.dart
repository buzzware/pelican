
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pelican/pelican.dart';

import 'EntrancePage.dart';
import 'LoadingPage.dart';
import 'PageOne.dart';
import 'PageTwo.dart';

class AppRoutes {

  static const ROOT_PATH = '/';
  static const TRIAGE_PATH = '/TRIAGE';
  static const RANDOM_PAGE_PATH = '/RANDOM_PAGE';

  static const LOADING_PAGE = 'loading';
  static const ENTRANCE_PAGE = 'entrance';
  static const PAGE_ONE = 'page_one';
  static const PAGE_TWO = 'page_two';

  static PelicanRouter setup() {
    return PelicanRouter(
      define(),
      loadingPageBuilder: (ctx) => LoadingPage(),
      observers: [
        //BotToastNavigatorObserver()
        //FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)
      ]
    );
  }

  static RouteTable define() {
    return RouteTable(
        {
          LOADING_PAGE: (ctx) async => ctx.page(LoadingPage()),
          ENTRANCE_PAGE: (ctx) async => ctx.page(EntrancePage()),
          PAGE_ONE: (ctx) async => ctx.page(PageOne()),
          PAGE_TWO: (ctx) async => ctx.page(PageTwo()),
        },
        redirects: [
          PathRedirect.fromTo(ROOT_PATH,TRIAGE_PATH),
          PathRedirect(TRIAGE_PATH, (ctx) async {
            return ctx.toRootPage(ENTRANCE_PAGE);
          }),
          PathRedirect(RANDOM_PAGE_PATH, (ctx) async {
            if (Random().nextInt(2)==0)
              return ctx.toRootPage(PAGE_ONE);
            else
              return ctx.toRootPage(PAGE_TWO);
          }),
        ]
    );
  }
}
