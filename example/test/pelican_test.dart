// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pelican/pelican.dart';

const testRouteUrl = 'auth_email+auth_link=aHR0cHM6Ly9saW5rcy5odWV5LmNvLz9saW5rPWh0dHBzOi8vbGlua3MuaHVleS5jby9fXy9hdXRoL2FjdGlvbj9hcGlLZXklM0RBSXphU3lBSC0wLUMydDhpbkctZnBHb2FaZmxKS0FXbEpFTVJFdm8lMjZtb2RlJTNEc2lnbkluJTI2b29iQ29kZSUzRFNMaktwNEV3dnM3VzJjNXNnZ20xemJ5b1Q5bm00SWd6WERoMlc0b2JIYWtBQUFGOFdRZk1udyUyNmNvbnRpbnVlVXJsJTNEaHR0cHM6Ly9saW5rcy5odWV5LmNvL2gyby9hY3Rpb25zL2NvbmZpcm1fZW1haWw_ZW1haWwlMjUzREdhcnklMjUyQjZAaHVleS5jbyUyNmxhbmclM0RlbiZhcG49Y28uaHVleS5hbmRyb2lkLmgybyZhbXY9MTImaWJpPWNvLmh1ZXkuaW9zLmgybyZpZmw9aHR0cHM6Ly9saW5rcy5odWV5LmNvL19fL2F1dGgvYWN0aW9uP2FwaUtleSUzREFJemFTeUFILTAtQzJ0OGluRy1mcEdvYVpmbEpLQVdsSkVNUkV2byUyNm1vZGUlM0RzaWduSW4lMjZvb2JDb2RlJTNEU0xqS3A0RXd2czdXMmM1c2dnbTF6YnlvVDlubTRJZ3pYRGgyVzRvYkhha0FBQUY4V1FmTW53JTI2Y29udGludWVVcmwlM0RodHRwczovL2xpbmtzLmh1ZXkuY28vaDJvL2FjdGlvbnMvY29uZmlybV9lbWFpbD9lbWFpbCUyNTNER2FyeSUyNTJCNkBodWV5LmNvJTI2bGFuZyUzRGVu';

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class PageA extends DummyPage {}
class PageB extends DummyPage {}
class PageC extends DummyPage {}


void main() {
  // initializeJsonMapper();
  // SetupModels.call();


  test('PelicanRoute.fromPath',(){
    var route = PelicanRoute.fromPath(testRouteUrl);
    expect(route.segments.length,1);
    expect(route.segments[0].name,'auth_email');
    expect(route.segments[0].options.length,1);
    expect(route.segments[0].options['auth_link']!.isNotEmpty,true);
  });


  test('redirects',() async {
    var table = RouteTable(
      {
        'A': (ctx) async => ctx.page(PageA()),
        'B': (ctx) async => ctx.page(PageB()),
        'C': (ctx) async => ctx.page(PageC()),
      },
      redirects: [
        PathRedirect('/X',(ctx) async => ctx.toRootPage('A')),

        PathRedirect('/Y',(ctx) async => ctx.pass()),
        PathRedirect('/Y',(ctx) async => ctx.toRootPage('B')),

        PathRedirect('/Z',(ctx) async => ctx.cancel()),
        PathRedirect('/Z',(ctx) async => ctx.toRootPage('C')),

        PathRedirect('/W',(ctx) async => ctx.to('/X')),
      ]
    );

    expect(await table.executeRedirects('/A'),'/A');
    expect(await table.executeRedirects('/X'),'/A');
    expect(await table.executeRedirects('/xyz'),'/xyz');

    expect(await table.executeRedirects('/Y'),'/B');

    expect(await table.executeRedirects('/Z'),null);

    expect(await table.executeRedirects('/W'),'/A');
  });
}
