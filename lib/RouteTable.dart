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
  String path;
  Future<PathRedirectResult> Function(PathRedirectContext ctx) handler;
  PathRedirect(
      this.path,
      this.handler
      );
  bool matchesPath(String currPath) {
    return currPath==path;
  }

  static fromTo(String fromPath, String toPath) {
    return PathRedirect(fromPath, (ctx) async => ctx.to(toPath));
  }
  static fromToRootPage(String fromPath, String toPage) {
    return PathRedirect(fromPath, (ctx) async => ctx.toRootPage(toPage));
  }
}

typedef SegmentPageBuilder = Future<SegmentPageResult> Function(SegmentPageContext context);
typedef LoadingPageBuilder = Widget Function(BuildContext context);
//typedef PathRedirect = Future<PathRedirectResult> Function(PathRedirectContext string);

@immutable
class SegmentTableEntry {
  final SegmentPageBuilder builder;
  final PelicanRouteSegment segment;
  const SegmentTableEntry(this.segment,this.builder);
}

@immutable
class RouteTable {
  late final List<PathRedirect> redirects;
  late final List<SegmentTableEntry> segments;

  RouteTable(Map<String, SegmentPageBuilder> segments,{List<PathRedirect>? redirects}) {
    this.segments = segments.entries.map<SegmentTableEntry>((e) {
      return SegmentTableEntry(PelicanRouteSegment.fromPathSegment(e.key),e.value);
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

  SegmentPageBuilder? matchRoute(PelicanRouteSegment segment) {
    for (var s in segments) {
      if (s.segment.name==segment.name) {
        return s.builder;
      }
    }
    return null;
  }

  Future<SegmentPageResult> executeSegment(SegmentPageContext context) async {
    print("executeSegment ${context.segment!.toPath()}");
    var builder = matchRoute(context.segment!);
    if (builder==null) {
      throw Exception("Segment route not matched");
    }
    SegmentPageResult buildResult = await builder(context);

    if (buildResult.pageWidget is IPelicanPage) {
      var pelicanPage = buildResult.pageWidget as IPelicanPage;
      pelicanPage.route = context.route;
      pelicanPage.segment = context.segment;
    }
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
