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
  buildRouter() {
    var table = RouteTable(
        {
          'Menu': RouteSpec((ctx) async => ctx.page(MenuPage()), defaultChild: 'B'),
          'A': RouteSpec((ctx) async => ctx.page(PageA())),
          'B': RouteSpec((ctx) async => ctx.page(PageB())),
          'C': RouteSpec((ctx) async => ctx.page(PageC())),
        }
    );
    var router = PelicanRouter(table);
    return router;
  }

  test('parent & child, no default expansion',() async {
    var router = buildRouter();
    var route = PelicanRoute.fromPath('/Menu@C');
    await router.setInitialRoutePath(route);
    expect(router.currentPage,isA<MenuPage>());

    var subSegment = route.segments.first.getChild();
    var prc = SegmentPageContext(route, subSegment);
    var buildResult = await router.routeTable.executeSegment(prc);
    expect(buildResult.pageWidget,isA<PageC>());
  });

  group('default expansion', () {

    var router = buildRouter();

    test('parent & child',() async {
      var route = PelicanRoute.fromPath('/Menu');
      var expanded = router.routeTable.expand(route);
      expect(expanded.toPath(),'/Menu@B');
    });

    test('parent & child with extra layer',() async {
      expect(router.routeTable.expand(PelicanRoute.fromPath('/Menu/C')).toPath(),'/Menu@B/C');
    });

    test('execute',() async {
      var route = PelicanRoute.fromPath('/Menu');

      await router.setInitialRoutePath(route);
      expect(router.currentPage,isA<MenuPage>());

      var subSegment = router.route!.segments.first.getChild();
      var prc = SegmentPageContext(route, subSegment);
      var buildResult = await router.routeTable.executeSegment(prc);
      expect(buildResult.pageWidget,isA<PageB>());
    });

  });


}
