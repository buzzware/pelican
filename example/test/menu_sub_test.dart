import 'package:example/AppRoutes.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:pelican/pelican.dart';

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

void main() {

  test('menu sub test',() async {
    var table = AppRoutes.define();
    var route = PelicanRoute.fromPath('/Menu');
    var segment = route.segments.first;
    var context = SegmentPageContext(route, segment);
    var result = await table.executeSegment(context);
  });
}
