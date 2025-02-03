part of './pelican.dart';

class PelicanRouter extends RouterDelegate<PelicanRoute> with ChangeNotifier, PopNavigatorRouterDelegateMixin<PelicanRoute> {

  late final PelicanRouteParser parser;
  PelicanRoute? _state;
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
  PelicanRoute? get currentConfiguration {
    return _state;
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
    if (PelicanRoute.same(_state,route)) {
      return;
    }
    _state = route;
    _pages = await buildPages();
    notifyListeners();
  }

  Page<dynamic> _buildPage(String key, Widget widget) {
    return MaterialPage<dynamic>(
        key: ValueKey(key),
        name: key,
        child: widget
    );
  }

  Future<(SegmentPageResult,Page<dynamic>)> _buildPageFromSegment(segment) async {
    var prc = SegmentPageContext(_state!, segment);
    var buildResult = await routeTable.executeSegment(prc);
    var page = _buildPage(segment.toPath(), buildResult.pageWidget!);
    return (buildResult,page);
  }

  Future<List<Page<dynamic>>> buildPages() async {
    print('BEGIN Router.buildPages');
    print("_cachePages is ${_cachePages==null ? 'not' : ''} set");
    var pages = List<Page<dynamic>>.empty(growable: true);
    var useCached = _cacheRoute!=null;
    for (var i=0; i<_state!.segments.length; i++) {
      var segment = _state!.segments[i];
      Page page;
      // this approach isn't complete because any childSegments will mean  _cachePages is longer than _cacheRoute
      // Another approach is to store the child page on the parent page using IParentPage that must be implemented
      if (useCached && _cacheRoute!.segments.length>i && segment.equals(_cacheRoute!.segments[i])) {
        page = _cachePages![i];
        print("Use cached ${_cacheRoute!.segments[i].toPath()}");
        pages.add(page);
      } else {
        useCached = false;
        SegmentPageResult buildResult;
        (buildResult,page) = await _buildPageFromSegment(segment);
        pages.add(page);
        if (buildResult.isParent) {
          var childSegment = PelicanRouteSegment.fromPathSegment(buildResult.defaultChild!);
          // SegmentPageResult buildResult2;
          // Page<dynamic> childPage;
          var (buildResult2,childPage) = await _buildPageFromSegment(childSegment);
          pages.add(childPage);
        }
      }
    }

    _cacheRoute = _state;
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

  // returns actual page widget
  childPageFor(Widget parentWidget) async {
    // return Builder configured to find parentWidget in _cachePages and return the child widget
    var iParent = _cachePages?.indexWhere((p) => (p as MaterialPage?)?.child == parentWidget) ?? -1;
    var childPage = iParent >= 0 ? _cachePages!.elementAtOrNull(iParent+1) : null;
    if (childPage!=null)
      return (childPage as MaterialPage?)?.child;   // existing page widget
    var childSegment = iParent>=0 ? _cacheRoute?.segments.elementAtOrNull(iParent+1) : null;
    if (childSegment==null)
      throw StateError("Failed to get child page. Missing child segment");
    SegmentPageResult buildResult;
    (buildResult,childPage) = await _buildPageFromSegment(childSegment);
    _cachePages!.add(childPage);
    return (childPage as MaterialPage?)?.child;     // new page widget
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
    if (_state == null || ((_pages?.length ?? 0) == 0)) {
      return List<Page<dynamic>>.from([_buildPage("LoadingPage", loadingPageBuilder!=null ? loadingPageBuilder!(context) : DefaultLoadingPage())]);
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
    setNewRoutePath(_state!.pushSegment(PelicanRouteSegment.fromPathSegment(segmentPath)));
  }

  PelicanRouteSegment pop() {
    if (_state?.segments.isEmpty ?? true) {
      throw Exception("Can't pop when stack is empty");
    }
    final poppedItem = _state!.segments.isNotEmpty ? _state!.segments.last : null;
    print("pop ${poppedItem!.toPath()}");
    setNewRoutePath(_state!.popSegment());
    return poppedItem;
  }

  void _onDidRemovePage(Page<Object?> page) {
    if (page.name!=null)
      setNewRoutePath(_state!.remove(page.name!));
  }

  bool get canPop => (_state?.segments.length ?? 0)>1;

  Future<void> goto(String path) async {
    var newPath = await routeTable.executeRedirects(path);
    if (newPath==null) {
      return;
    }
    var route = PelicanRoute.fromPath(newPath);
    if (PelicanRoute.same(route,_state)) {
      return;
    }
    setNewRoutePath(route);
  }

  void replace(String segmentPath) {
    replaceSegment(PelicanRouteSegment.fromPathSegment(segmentPath));
  }

  void replaceSegment(PelicanRouteSegment segment) {
    var route = _state!.popSegment();
    route = route.pushSegment(segment);
    setNewRoutePath(route);
  }

  Page? getPage(String segmentName) {
    if (_state==null) {
      return null;
    }
    for (var i=_state!.segments.length-1; i>=0; i--) {
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
    if (_state?.segments.isEmpty ?? true) {
      throw Exception("Can't replaceParam on an empty route");
    }
    var leaf = _state!.segments.last;
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
