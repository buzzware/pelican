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


  //String loadingPageName;

  LoadingPageBuilder? loadingPageBuilder;

  late RouteInformationProvider routeProvider;
  //final String _initialPath;
  //bool _stateRouteInitialised = false;

  // bool validateInitialPath(String initialPath) {
  //   if (initialPath=='/')
  //     return true;
  //   try {
  //     var route = PelicanRoute.fromPath(initialPath);
  //     if (route.segments.any((s) => routeTable.matchRoute(s)==null))
  //       return false;
  //   } catch(e) {
  //     return false;
  //   }
  //   return true;
  // }

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
      String initialPath,
      this.routeTable,
      {
        this.observers = const [],
        this.loadingPageBuilder
      }
  ): super() {
    parser = PelicanRouteParser(this);
    navigatorKey = GlobalKey<NavigatorState>();
    //routeProvider = platformRouteInformationProviderWithInitialPath(initialPath);
    // if (!validateInitialPath(_initialPath)) {
    //   throw ArgumentError("$_initialPath must match page(s)");
    // }
    //_state = PelicanRoute.fromPath('/');
  }

  @override
  void dispose() {
    //_state.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  PelicanRoute? get currentConfiguration {
    //return null;  // disable state restoration
    return _state;
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
    //routerState.route = _state.route;
    // var newRoute = configuration.route!=null ? await routeTable.executeRedirectsRoute(configuration.route!) : null;
    // if (!PelicanRoute.same(newRoute,configuration.route)) {
    //   configuration.route = newRoute!;
    //   await setNewRoutePath(configuration);
    // }
  }

  @override
  Future<void> setNewRoutePath(PelicanRoute route) async {
    print("setNewRoutePath ${route.toPath()}");
    if (PelicanRoute.same(_state,route)) {
      return;
    }
    _state = route;
    _pages = await buildPages();
    //notifyListeners();
  }

  // Future<void> initStateRoute() async {
  //   print('initStateRoute');
  //   var newPath = await routeTable.executeRedirects(_initialPath);
  //   if (newPath != null) {
  //     _state.route = PelicanRoute.fromPath(newPath);
  //   }
  // }

  Page<dynamic> _buildPage(String key, Widget widget) {
    return MaterialPage<dynamic>(
        key: ValueKey(key),
        name: key,
        child: widget
    );
  }

  Future<List<Page<dynamic>>> buildPages() async {
    print('BEGIN Router.buildPages');
    print("_cachePages is ${_cachePages==null ? 'not' : ''} set");
    // if (!_stateRouteInitialised) {
    //   _stateRouteInitialised = true;
    //   await initStateRoute();
    // }
    var pages = List<Page<dynamic>>.empty(growable: true);
    var useCached = _cacheRoute!=null;
    for (var i=0; i<_state!.segments.length; i++) {
      var segment = _state!.segments[i];
      Page page;
      if (useCached && _cacheRoute!.segments.length>i && segment.equals(_cacheRoute!.segments[i])) {
        page = _cachePages![i];
        print("Use cached ${_cacheRoute!.segments[i].toPath()}");
      } else {
        useCached = false;
        var prc = SegmentPageContext(_state!, segment);
        var buildResult = await routeTable.executeSegment(prc);
        print("build ${segment.toPath()}");
        page = _buildPage(segment.toPath(),buildResult.pageWidget!);
      }
      pages.add(page);
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
    // return FutureBuilder(
    //   future: buildPages(context),
    //   initialData: [
    //     MaterialPage<dynamic>(child: SizedBox(
    //       width: double.infinity,
    //       height: double.infinity,
    //       //child: Text('Please Wait')
    //     )),
    //   ],
    //   builder: (context, snapshot) {
    //     if (snapshot.hasError) {
    //       return Container(child: Text(snapshot.error.toString()));
    //     } else if (snapshot.hasData) {
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
        // } else {
        //   return const CircularProgressIndicator();
        // }

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
}
