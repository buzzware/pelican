part of 'pelican.dart';

abstract interface class IPelicanPage {
  PelicanRoute? get route;
  set route(PelicanRoute? route);

  PelicanRouteSegment? get segment;
  set segment(PelicanRouteSegment? segment);

  Map<String,String?>? get params;
  set params(Map<String,String?>? params);

  Map<String,String?>? get options;
  set options(Map<String,String?>? options);
}
