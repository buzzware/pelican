part of './pelican.dart';



class SegmentPageResult {
  Widget? pageWidget;

  SegmentPageResult({this.pageWidget});
}

@immutable
class SegmentPageContext {
  final PelicanRoute route;
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

class PelicanRouteParser extends RouteInformationParser<PelicanRouterState> {
  PelicanRouter router;

  PelicanRouteParser(this.router);

  // RouteInformation -> PelicanRoute
  @override
  Future<PelicanRouterState> parseRouteInformation(RouteInformation routeInformation) async {
    print('parseRouteInformation RouteInformation ${routeInformation.uri} -> PelicanRoute');
    // var path = await router.routeTable.executeRedirects(routeInformation.uri.toString());
    // if (path==null)
    //   throw ArgumentError("Redirected to null - cannot route");
    var route = PelicanRoute.fromPath(routeInformation.uri.toString());
    return PelicanRouterState(
        route
    );
  }

  // PelicanRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(PelicanRouterState configuration) {
    if (configuration.route==null) {
      return null;
    }
    var path = configuration.route!.toPath();
    print('restoreRouteInformation PelicanRoute $path -> RouteInformation');
    var uri = Uri.parse(path);
    return RouteInformation(
      uri: uri,
    );
  }
}


class PelicanRouter extends RouterDelegate<PelicanRouterState> with ChangeNotifier, PopNavigatorRouterDelegateMixin<PelicanRouterState> {

  late final PelicanRouteParser parser;
  late PelicanRouterState _state;
  late final RouteTable routeTable;

  @override
  late final GlobalKey<NavigatorState> navigatorKey;

  List<Page>? _cachePages;
  PelicanRoute? _cacheRoute;

  late final List<NavigatorObserver> observers;

  final String _initialPath;
  bool _stateRouteInitialised = false;

  PelicanRouter(
      this._initialPath,
      this.routeTable,
      {this.observers = const []}
      ): super() {
    parser = PelicanRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
    _state = PelicanRouterState(
        PelicanRoute.fromPath(_initialPath)
    );
    _state.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _state.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  PelicanRouterState? get currentConfiguration {
    return _state;
  }

  @override
  Future<void> setRestoredRoutePath(PelicanRouterState routerState) {
    print("setRestoredRoutePath ${routerState.route?.toPath()}");
    return setNewRoutePath(routerState);
  }


  @override
  Future<void> setInitialRoutePath(PelicanRouterState routerState) async {
    print("setInitialRoutePath ${routerState.route?.toPath()}");
    routerState.route = _state.route;
    // var newRoute = configuration.route!=null ? await routeTable.executeRedirectsRoute(configuration.route!) : null;
    // if (!PelicanRoute.same(newRoute,configuration.route)) {
    //   configuration.route = newRoute!;
    //   await setNewRoutePath(configuration);
    // }
  }

  @override
  Future<void> setNewRoutePath(PelicanRouterState routerState) async {
    print("setNewRoutePath ${routerState.route?.toPath()}");
    if (PelicanRoute.same(_state.route,routerState.route)) {
      return;
    }
    _state.route = routerState.route;
  }

  Future<void> initStateRoute() async {
    print('initStateRoute');
    var newPath = await routeTable.executeRedirects(_initialPath);
    if (newPath != null) {
      _state.route = PelicanRoute.fromPath(newPath);
    }
  }

  Page<dynamic> _buildPage(String key, Widget widget) {
    return MaterialPage<dynamic>(
        key: ValueKey(key),
        child: widget
    );
  }

  Future<List<Page<dynamic>>> buildPages(BuildContext context) async {
    print('BEGIN Router.buildPages');
    print("_pages is ${_cachePages==null ? 'not' : ''} set");
    if (!_stateRouteInitialised) {
      _stateRouteInitialised = true;
      await initStateRoute();
    }
    var pages = List<Page<dynamic>>.empty(growable: true);
    var useCached = _cacheRoute!=null;
    for (var i=0; i<_state.route!.segments.length; i++) {
      var segment = _state.route!.segments[i];
      Page page;
      if (useCached && _cacheRoute!.segments.length>i && segment.equals(_cacheRoute!.segments[i])) {
        page = _cachePages![i];
        print("Use cached ${_cacheRoute!.segments[i].toPath()}");
      } else {
        useCached = false;
        var prc = SegmentPageContext(_state.route!, segment);
        var buildResult = await routeTable.executeSegment(prc);
        print("build ${segment.toPath()}");
        page = _buildPage(segment.toPath(),buildResult.pageWidget!);
      }
      pages.add(page);
    }

    _cacheRoute = _state.route;
    // var originalPages = _cachePages;
    // if (originalPages?.isNotEmpty ?? false) {
    //   originalPages!.reversed.forEach((page) {
    //     if (pages.contains(page))
    //       return;
    //     var widget = as<MaterialPage<dynamic>>(page)?.child;
    //     //as<Disposable>(widget)?.onDispose();
    //   });
    // }
    _cachePages = pages;
    print('END Router.buildPages');
    return pages;
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }
    _state.pop();
    notifyListeners();
    return true;
  }

  // build a Navigator
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: buildPages(context),
      initialData: [
        MaterialPage<dynamic>(child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          //child: Text('Please Wait')
        )),
      ],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(child: Text(snapshot.error.toString()));
        } else if (snapshot.hasData) {
          return Navigator(
            key: navigatorKey,
            transitionDelegate: NoAnimationTransitionDelegate(),
            pages: snapshot.data!, // List<Page<dynamic>>.from([BlankPage()]),
            onPopPage: _onPopPage,
            observers: observers,
          );
        } else {
          return const CircularProgressIndicator();
        }
      }
    );
  }

  void push(String segmentPath) {
    _state.push(segmentPath);
  }

  PelicanRouteSegment pop() {
    return _state.pop();
  }

  bool get canPop => (_state.route?.segments.length ?? 0)>1;

  Future<void> goto(String path) async {
    var newPath = await routeTable.executeRedirects(path);
    if (newPath==null) {
      return;
    }
    var route = PelicanRoute.fromPath(newPath);
    if (PelicanRoute.same(route,_state.route)) {
      return;
    }
    _state.route = route;
  }

  void replace(String segmentPath) {
    replaceSegment(PelicanRouteSegment.fromPathSegment(segmentPath));
  }

  void replaceSegment(PelicanRouteSegment segment) {
    var route = _state.route!.popSegment();
    route = route.pushSegment(segment);
    _state.route = route;
  }

  Page? getPage(String segmentName) {
    if (_state.route==null) {
      return null;
    }
    for (var i=_state.route!.segments.length-1; i>=0; i--) {
      if (_cacheRoute!.segments.length > i && _cacheRoute!.segments[i].name==segmentName) {
        return _cachePages![i];
      }
    }
    return null;
  }

  Widget? getPageWidget(String segmentName) {
    return (getPage(segmentName) as MaterialPage?)?.child;
  }

  void replaceParam(String param, String? value) {
    if (_state.route?.segments.isEmpty ?? true) {
      throw Exception("Can't replaceParam on an empty route");
    }
    var leaf = _state.route!.segments.last;
    var params = leaf.params;
    if (params[param]==value) {
      return;
    }

    params = Map.from(leaf.params);
    params[param] = value;
    var segment = leaf.copyWith(params: Map.unmodifiable(params));
    replaceSegment(segment);
  }

}
