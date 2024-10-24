import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pelican/pelican.dart';

void main() {
  test('PelicanRouteSegment serialise', () async {
    expect(PelicanRouteSegment('page',const {'a': '1', 'b': '2'}).toPath(),'page;a=1;b=2');
    expect(PelicanRouteSegment('page',const {'a': '1', 'b': '2'}, const {'x': '9'}).toPath(),'page;a=1;b=2+x=9');
    expect(PelicanRouteSegment('page',const {'b': '1', 'a': '2'}, const {'y': '10', 'x': '9'}).toPath(),'page;a=2;b=1+x=9;y=10');  // sorted order
  });
  test('PelicanRouteSegment deserialise', () async {
    expect(PelicanRouteSegment.fromPathSegment('page;b=2;a=1+y=9;x=10').toPath(),'page;a=1;b=2+x=10;y=9');
  });
}
