part of './pelican.dart';

class PelicanRouteParser extends RouteInformationParser<PelicanRoute> {
  PelicanRouter router;

  PelicanRouteParser(this.router);

  // RouteInformation -> PelicanRoute
  @override
  Future<PelicanRoute> parseRouteInformation(RouteInformation routeInformation) async {
    print('parseRouteInformation RouteInformation ${routeInformation.uri}');
    // var path = await router.routeTable.executeRedirects(routeInformation.uri.toString());
    // if (path==null)
    //   throw ArgumentError("Redirected to null - cannot route");
    var route = PelicanRoute.fromPath(routeInformation.uri.toString());
    return route;
  }

  // PelicanRoute -> RouteInformation
  @override
  RouteInformation? restoreRouteInformation(PelicanRoute route) {
    print('restoreRouteInformation');
    var path = route.toPath();
    print('restoreRouteInformation $path');
    return RouteInformation(
      uri: Uri.parse(path),
    );
  }
}
