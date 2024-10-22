import 'package:example/AppRoutes.dart';
import 'package:pelican/pelican.dart';

class AppCommon {
  static PelicanRouter? _router;
  static PelicanRouter get router => _router!;

  static void reset() {
    _router = AppRoutes.setup();
  }
}
