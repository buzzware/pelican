part of './pelican.dart';

/// A [RouteInformationProvider] that provides a default route
/// if the app is opened at the root path ("/") or with no path at all.
/// Otherwise, it uses the browser's or deep link's current route.
// class DefaultRouteInformationProvider extends PlatformRouteInformationProvider {
//   DefaultRouteInformationProvider({
//     required String defaultRoute,
//     RouteInformation? restoredRouteInformation,
//   }) : super(
//     // If the current URL is "/" or empty, use [defaultRoute] as the initial route.
//     initialRouteInformation: _getInitialRouteInformation(defaultRoute),
//     res
//     restoredRouteInformation: restoredRouteInformation,
//   );
//
//   /// Returns a [RouteInformation] based on the browser's URL.
//   /// If the URL is "/" or empty, returns a [RouteInformation] with the [defaultRoute].
//   static RouteInformation _getInitialRouteInformation(String defaultRoute) {
//     final String path = Uri.base.path;
//     if (path == '/' || path.isEmpty) {
//       return RouteInformation(location: defaultRoute);
//     }
//     return RouteInformation(location: path);
//   }
// }

class PelicanRouter extends RouterDelegate<PelicanRoute> with ChangeNotifier, PopNavigatorRouterDelegateMixin<PelicanRoute> {

  late final PelicanRouteParser parser;
  PelicanRoute? _route;
  List<Page>? _pages;
  late final RouteTable routeTable;

  @override
  late final GlobalKey<NavigatorState> navigatorKey;

  List<Page>? _cachePages;
  PelicanRoute? _cacheRoute;

  late final List<NavigatorObserver> observers;

  LoadingPageBuilder? loadingPageBuilder;

  static PlatformRouteInformationProvider platformRouteInformationProviderWithInitialPath(String path) {
    return PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
            uri: WidgetsBinding.instance.platformDispatcher.defaultRouteName != '/'
                ? Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName)
                : Uri.parse(path)
        )
    );
  }

  static PlatformRouteInformationProvider platformRouteInformationProviderWithInitialPath2({String? defaultPath, String? initialPath}) {
    Uri uri;
    Uri initialUri;
    if (kIsWeb)
      initialUri = (initialPath ?? '') == '' ? Uri.base : Uri.parse(initialPath!);
    else
      initialUri = (initialPath ?? '') == '' ? Uri.parse('/') : Uri.parse(initialPath!);
    var defaultUri = (defaultPath ?? '')=='' ? Uri.parse('/') : Uri.parse(defaultPath!);
    uri = initialUri.path == '/' ? defaultUri : initialUri;
    print("platformRouteInformationProviderWithInitialPath2: ${uri}");
    return PlatformRouteInformationProvider(initialRouteInformation: RouteInformation(uri: uri));
  }

  PelicanRouter(
      this.routeTable,
      {
        this.observers = const [],
        this.loadingPageBuilder
      }
  ): super() {
    parser = PelicanRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  PelicanRoute? get route {
    return _route;
  }

  Widget? get currentPage {
    return (_cachePages?.lastOrNull as MaterialPage?)?.child;
  }

  @override
  Future<void> setRestoredRoutePath(PelicanRoute route) {
    print("setRestoredRoutePath ${route.toPath()}");
    return setNewRoutePath(route);
  }

  @override
  Future<void> setInitialRoutePath(PelicanRoute route) async {
    print("setInitialRoutePath ${route.toPath()}");
    await setNewRoutePath(route);
  }

  @override
  Future<void> setNewRoutePath(PelicanRoute route) async {
    print("setNewRoutePath ${route.toPath()}");
    route = routeTable.expand(route);
    // if (PelicanRoute.same(_route,route)) {
    //   print("setNewRoutePath exiting because route has not changed");
    //   return;
    // }
    print("setNewRoutePath setting ${route.toPath()}");
    _route = route;
    _pages = await buildPages();
    notifyListeners();
  }

  Page<dynamic> _buildPage(String key, Widget widget) {
    print("_buildPage ${key}");
    return MaterialPage<dynamic>(
        key: ValueKey(key),
        name: key,
        child: widget,

    );
  }

  Future<(SegmentPageResult,Page<dynamic>)> _buildPageFromSegment(segment,{PelicanRoute? route}) async {
    var prc = SegmentPageContext(segment);
    var buildResult = await routeTable.executeSegment(prc);
    var path = route?.toPath() ?? '/'+segment.toPath();
    var page = _buildPage(path, buildResult.pageWidget!);
    return (buildResult,page);
  }

  Future<List<Page<dynamic>>> buildPages() async {
    print('BEGIN Router.buildPages ${_route?.toPath()}');
    print("_cachePages is ${_cachePages==null ? 'not' : ''} set");
    var pages = List<Page<dynamic>>.empty(growable: true);
    var useCached = _cacheRoute!=null;
    for (var i=0; i<_route!.segments.length; i++) {
      var segment = _route!.segments[i];
      Page page;
      if (useCached && _cacheRoute!.segments.length>i && segment.equals(_cacheRoute!.segments[i])) {
        page = _cachePages![i];
        print("Use cached ${_cacheRoute!.segments[i].toPath()}");
      } else {
        useCached = false;
        SegmentPageResult buildResult;
        var route = PelicanRoute(_route!.segments.getRange(0,i+1).toList());
        (buildResult,page) = await _buildPageFromSegment(segment,route: route);
      }
      pages.add(page);
    }
    _cacheRoute = _route;
    _cachePages = pages;
    print('END Router.buildPages');
    return pages;
  }

  // returns actual page widget
  Widget childPageFor(Widget parentWidget, [int index = 0]) {
    // return Builder configured to find parentWidget in _cachePages and return the child widget
    var iParentPage = _cachePages?.indexWhere((p) => (p as MaterialPage?)?.child == parentWidget) ?? -1;
    var parentSegment = _cacheRoute!.segments[iParentPage];
    var subSegment = parentSegment.getChild(index);

    var prc = SegmentPageContext(subSegment);
    var buildResultPromise = routeTable.executeSegment(prc);
    return FutureBuilder(future: buildResultPromise, builder: (context, snapshot) {
      return snapshot.data?.pageWidget ?? Container();
    });
  }

  // bool _onPopPage(Route<dynamic> route, dynamic result) {
  //   if (!route.didPop(result)) {
  //     return false;
  //   }
  //   _state.pop();
  //   notifyListeners();
  //   return true;
  // }

  List<Page> servePages(BuildContext context) {
    if (_route == null || ((_pages?.length ?? 0) == 0)) {
      return List<Page<dynamic>>.from([_buildPage("/LoadingPage", loadingPageBuilder!=null ? loadingPageBuilder!(context) : DefaultLoadingPage())]);
    } else {
      return _pages!;
    }
  }

  // build a Navigator
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      transitionDelegate: NoAnimationTransitionDelegate(),
      pages: servePages(context),   //snapshot.data!, // List<Page<dynamic>>.from([BlankPage()]),
      onDidRemovePage: _onDidRemovePage,
      observers: observers,
      // onDidRemovePage: (Page<dynamic> page) {
      //   // Check if it's the book details page being removed
      //   if (page.key == ValueKey('bookDetails') ||
      //       (page is MaterialPage && page.child is BookDetailsScreen)) {
      //     _selectedBook = null;
      //     show404 = false;
      //     notifyListeners();
      //   }
      // }
    );
  }

  void push(String segmentPath) {
    setNewRoutePath(_route!.pushSegment(PelicanRouteSegment.fromPathSegment(segmentPath)));
  }

  PelicanRouteSegment pop() {
    if (_route?.segments.isEmpty ?? true) {
      throw Exception("Can't pop when stack is empty");
    }
    final poppedItem = _route!.segments.isNotEmpty ? _route!.segments.last : null;
    print("pop ${poppedItem!.toPath()}");
    setNewRoutePath(_route!.popSegment());
    return poppedItem;
  }

  void _onDidRemovePage(Page<Object?> page) {
    if (page.name!=null)
      setNewRoutePath(_route!.remove(page.name!));
  }

  bool get canPop => (_route?.segments.length ?? 0)>1;

  Future<void> goto(String path) async {
    var newPath = await routeTable.executeRedirects(path);
    if (newPath==null) {
      return;
    }
    var route = PelicanRoute.fromPath(newPath);
    if (PelicanRoute.same(route,_route)) {
      return;
    }
    setNewRoutePath(route);
  }

  void replace(String segmentPath) {
    replaceSegment(PelicanRouteSegment.fromPathSegment(segmentPath));
  }

  void replaceSegment(PelicanRouteSegment segment) {
    var route = _route!.popSegment();
    route = route.pushSegment(segment);
    setNewRoutePath(route);
  }

  Page? getPage(String segmentName) {
    if (_route==null) {
      return null;
    }
    for (var i=_route!.segments.length-1; i>=0; i--) {
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
    if (_route?.segments.isEmpty ?? true) {
      throw Exception("Can't replaceParam on an empty route");
    }
    var leaf = _route!.segments.last;
    var params = leaf.params;
    if (params[param]==value) {
      return;
    }

    params = Map.from(leaf.params);
    params[param] = value;
    var segment = leaf.copyWith(params: Map.unmodifiable(params));
    replaceSegment(segment);
  }

  void appendPathRedirect(PathRedirect redirect) {
    routeTable.redirects.add(redirect);
  }

  void prependPathRedirect(PathRedirect redirect) {
    routeTable.redirects.insert(0,redirect);
  }

  void removePathRedirect(PathRedirect redirect) {
    routeTable.redirects.remove(redirect);
  }
}
