part of './pelican.dart';

class SegmentPageResult {
  Widget? pageWidget;

  SegmentPageResult({this.pageWidget});
}

@immutable
class SegmentPageContext {
  final PelicanRoute? route;
  final PelicanRouteSegment? segment;

  const SegmentPageContext(this.route,this.segment);

  SegmentPageResult page(Widget pageWidget) {
    return SegmentPageResult(pageWidget: pageWidget);
  }

  // SegmentPageResult parentPage(Widget pageWidget, {required String defaultChild}) {
  //   return SegmentPageResult(pageWidget: pageWidget, isParent: true, defaultChild: defaultChild);
  // }
}

class PathRedirectResult {
  String? path;
  late bool cancel;
  late bool pass;
  PathRedirectResult({
    this.path,
    bool? cancel,
    bool? pass
  }) {
    this.cancel = cancel ?? false;
    this.pass = pass ?? false;
  }
}

@immutable
class PathRedirectContext {
  final String path;

  const PathRedirectContext(
      this.path
      );

  PathRedirectResult to(String path) {
    return PathRedirectResult(path: path);
  }

  PathRedirectResult toRootPage(String pageName) {
    return PathRedirectResult(path: '/$pageName');
  }

  PathRedirectResult cancel() {
    return PathRedirectResult(cancel: true);
  }

  PathRedirectResult pass() {
    return PathRedirectResult(pass: true);
  }
}

class PathRedirect {
  String? path;
  Future<PathRedirectResult> Function(PathRedirectContext ctx) handler;
  RegExp? pattern;
  PathRedirect(
    this.path,
    this.handler,
    {this.pattern}
  );
  bool matchesPath(String currPath) {
    if (pattern!=null) {
      return pattern!.hasMatch(currPath);
    } else if (path!=null) {
      return currPath == path;
    }
    return false;
  }

  static fromTo(String fromPath, String toPath) {
    return PathRedirect(fromPath, (ctx) async => ctx.to(toPath));
  }
  static fromToRootPage(String fromPath, String toPage) {
    return PathRedirect(fromPath, (ctx) async => ctx.toRootPage(toPage));
  }
  static fromPattern(RegExp pattern, Future<PathRedirectResult> Function(PathRedirectContext ctx) handler) {
    return PathRedirect(null, handler, pattern: pattern);
  }
}

typedef SegmentPageBuilder = Future<SegmentPageResult> Function(SegmentPageContext context);
typedef LoadingPageBuilder = Widget Function(BuildContext context);
//typedef PathRedirect = Future<PathRedirectResult> Function(PathRedirectContext string);

@immutable
class RouteSpec {
  final SegmentPageBuilder builder;
  final String? defaultChild;
  const RouteSpec(this.builder,{this.defaultChild});
}

@immutable
class RouteTableEntry {
  final SegmentPageBuilder builder;
  final PelicanRouteSegment segment;
  final String? defaultChild;
  const RouteTableEntry(this.segment,this.builder,{this.defaultChild});
}

@immutable
class RouteTable {
  late final List<PathRedirect> redirects;
  late final List<RouteTableEntry> entries;

  RouteTable(Map<String, RouteSpec> entrySpecs,{List<PathRedirect>? redirects}) {
    this.entries = entrySpecs.entries.map<RouteTableEntry>((e) {
      return RouteTableEntry(PelicanRouteSegment.fromPathSegment(e.key),e.value.builder,defaultChild: e.value.defaultChild);
    }).toList();
    this.redirects = redirects ?? List<PathRedirect>.empty(growable: true);
  }

  // Future<PelicanRouteResult> segmentNotFound(PelicanRouteContext context) async {
  //   if (_routeNotFound != null) {
  //     return await _routeNotFound(context.route!.toPath());
  //   } else {
  //     return PelicanRouteResult(pageWidget: ErrorPage(text: "${context.path} doesn't exist"));
  //   }
  // }

  PelicanRoute expand(PelicanRoute route) {
    var segments = List<PelicanRouteSegment>.from(route.segments);
    var segmentChanged = false;
    for (int i = 0; i < segments.length; i++) {
      var routeSeg = segments[i];
      var newSubs = List<PelicanRouteSegment>.empty(growable: true);
      var subChanged = false;
      PelicanRouteSegment? sub = routeSeg;
      var parts = [];
      do {
        var tableEntry = matchEntry(sub!); //   entries.firstOrNull(e => e.segment.name == s.name
        if (tableEntry==null)
          throw ErrorDescription("Failed to match ${sub.toPath()}");
        newSubs.add(sub);
        // has a default and no child
        if (tableEntry.defaultChild!=null && sub.child==null) {
          newSubs.add(PelicanRouteSegment.fromPathSegment(tableEntry.defaultChild!));
          subChanged = true;
          segmentChanged = true;
        }
        sub = sub.child;
      } while (sub != null);
      if (subChanged) {
        PelicanRouteSegment? child;
        for (var sub in newSubs.reversed) {
          var curr = sub;
          if (sub.child!=child)
            curr = sub.copyWith(child: child);
          child = curr;
        }
        segments[i] = child!;
      }
    }
    return segmentChanged ? route.copyWith(segments: segments) : route;
  }

  RouteTableEntry? matchEntry(PelicanRouteSegment segment) {
    for (var e in entries) {
      if (e.segment.name==segment.name) {
        return e;
      }
    }
    return null;
  }

  // SegmentPageBuilder? matchRoute(PelicanRouteSegment segment) {
  //   for (var s in entries) {
  //     if (s.segment.name==segment.name) {
  //       return s.builder;
  //     }
  //   }
  //   return null;
  // }

  Future<SegmentPageResult> executeSegment(SegmentPageContext context) async {
    print("executeSegment ${context.segment!.toPath()}");
    var entry = matchEntry(context.segment!);
    if (entry==null) {
      throw Exception("Segment route not matched");
    }
    SegmentPageResult buildResult = await entry.builder(context);
    return buildResult;
  }

  Future<String?> executeRedirects(String path) async {
    print("executeRedirects $path");
    String currPath = path;
    do {
      PathRedirectResult? result;
      for (var r in redirects) {
        if (!r.matchesPath(currPath)) {
          continue;
        }
        print("executeRedirects: BEFORE handler ${r.path}");
        result = await r.handler(PathRedirectContext(currPath));
        if (result.cancel) {
          print("executeRedirects: Cancelled Path ${r.path}");
          return null;
        }
        if (result.pass) {
          print("executeRedirects: Passed Path ${r.path}");
          continue;
        }
        if (result.path==null) {
          print("executeRedirects: Nulled Path ${r.path}");
          return null;
        }
        break;
      }
      if (result==null) {
        print("executeRedirects: Returning Path $currPath as is");
        return currPath;
      }
      currPath = result.path!;
    } while (true);
  }

  Future<PelicanRoute?> executeRedirectsRoute(PelicanRoute route) async {
    var path = route.toPath();
    var redirected = await executeRedirects(path);
    if (redirected==null) {
      return null;
    }
    if (redirected == path) {
      return route;
    } else {
      return PelicanRoute.fromPath(redirected);
    }
  }

}
