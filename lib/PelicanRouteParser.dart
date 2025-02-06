part of './pelican.dart';

class PelicanRouteParser extends RouteInformationParser<PelicanRoute> {
  PelicanRouter router;

  PelicanRouteParser(this.router);

  // RouteInformation -> PelicanRoute
  @override
  Future<PelicanRoute> parseRouteInformation(RouteInformation routeInformation) async {
    print('parseRouteInformation RouteInformation ${routeInformation.uri}');
    String? path = routeInformation.uri.path;
    path = await router.routeTable.executeRedirects(path);
    if (path==null)
      throw ArgumentError("Redirected to null - cannot route");
    // var route = PelicanRoute.fromPath(routeInformation.uri.toString());
    var route = PelicanRoute.fromPath(path);
    return route;
  }

  // PelicanRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(PelicanRoute route) {
    var path = route.toPath();
    print('restoreRouteInformation route $path');
    var uri = Uri.parse(path);
    print('restoreRouteInformation $uri');
    return RouteInformation(
      uri: uri
    );
  }
}
