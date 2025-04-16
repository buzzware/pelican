part of 'pelican.dart';

abstract interface class IPelicanPage {
  PelicanRoute? get route;
  set route(PelicanRoute? route);

  PelicanRouteSegment? get segment;
  set segment(PelicanRouteSegment? segment);
}
