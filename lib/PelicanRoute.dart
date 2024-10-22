part of './pelican.dart';

@immutable
class PelicanRoute {
  late final List<PelicanRouteSegment> _segments;
  List<PelicanRouteSegment> get segments => _segments;
  PelicanRoute(List<PelicanRouteSegment> segments) {
    _segments = List.unmodifiable(segments);
  }

  String toPath() {
    var parts = segments.map<String>((s) => s.toPath()).join('/');
    var result = "/$parts";
    return result;
  }

  PelicanRoute.fromPath(String path) {
    var parts = path.split('/');
    if (parts.isNotEmpty && parts[0].isEmpty)
      parts.removeAt(0);
    _segments = List.unmodifiable(parts.map((p)=>PelicanRouteSegment.fromPathSegment(p)));
  }

  // returns a new instance with the extra segment
  PelicanRoute pushSegment(PelicanRouteSegment segment) {
    return PelicanRoute(segments + [segment]);
  }

  PelicanRoute popSegment() {
    if (segments.isEmpty)
      throw Exception("Can't pop when stack is empty");
    final poppedItem = segments.last;
    return PelicanRoute(segments.sublist(0,segments.length-1));
  }

  bool equals(PelicanRoute other, {bool ignoreOptions = true}) {
    var i = 0;
    return segments.length==other.segments.length && segments.every((s) => s.equals(other.segments[i++],ignoreOptions: ignoreOptions));
  }

  static bool same(PelicanRoute? route1, PelicanRoute? route2, {bool ignoreOptions = true}) {
    return (route1==null && route2==null) ||
        (route1!=null && route2!=null && route1.equals(route2, ignoreOptions: ignoreOptions));
  }
}
