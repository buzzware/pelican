import 'package:flutter/cupertino.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:pelican/pelican.dart';

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class MenuPage extends DummyPage {}
class PageA extends DummyPage {}
class PageB extends DummyPage {}
class PageC extends DummyPage {}


void main() {

  test('parent & child',() async {
    var table = RouteTable(
      {
        'Menu': (ctx) async => ctx.parentPage(MenuPage(), defaultChild: 'B'),
        'A': (ctx) async => ctx.page(PageA()),
        'B': (ctx) async => ctx.page(PageB()),
        'C': (ctx) async => ctx.page(PageC()),
      }
    );



    // expect(await table.executeRedirects('/A'),'/A');
    // expect(await table.executeRedirects('/X'),'/A');
    // expect(await table.executeRedirects('/xyz'),'/xyz');
    //
    // expect(await table.executeRedirects('/Y'),'/B');
    //
    // expect(await table.executeRedirects('/Z'),null);
    //
    // expect(await table.executeRedirects('/W'),'/A');
  });
}
