part of './pelican.dart';



bool linkedMapsEqual(Map<String, String?> map1, Map<String, String?> map2) {
  return map1.length==map2.length && (
      map1.isEmpty || map1.entries.every((e) {
        return map2.containsKey(e.key) && map2[e.key]==e.value;
      })
  );
}

@immutable
class PelicanRouteSegment {
  late final String name;
  late final Map<String,String?> params;
  late final Map<String,String?> options;
  late final PelicanRouteSegment? child;

  PelicanRouteSegment(
      this.name,
      [
        Map<String,String?>? params,
        Map<String,String?>? options,
        this.child
      ]
  ) {
    this.params = Map.unmodifiable(params ?? {});
    this.options = Map.unmodifiable(options ?? {});
  }

  copyWith({
    String? name,
    Map<String,String?>? params,
    Map<String,String?>? options,
    PelicanRouteSegment? child
  }) {
    return PelicanRouteSegment(
      name ?? this.name,
      params ?? this.params,
      options ?? this.options,
      child ?? this.child
    );
  }


  PelicanRouteSegment? getChild([int index = 0]) {
    PelicanRouteSegment? curr = this;
    for (var i=0; i<=index;i++) {
      curr = curr!.child;
      if (curr==null)
        break;
    }
    return curr;
  }

  // includes self
  Iterable<PelicanRouteSegment> get subSegments {
    var result = List<PelicanRouteSegment>.empty(growable: true);
    PelicanRouteSegment? curr = this;
    do {
      result.add(curr!);
      curr = curr.child;
    } while (curr != null);
    return result;
  }

  static Map<String,String> mapFromValues(String values) {
    return Map<String,String>.fromIterable(values.isEmpty ? [] : values.split(';'),key: (i) => i.split('=')[0],value: (i) {
    var parts = i.split('=');
    return parts.length>1 ? parts[1] : '';
    });
  }

  static String getName(String segment) {
    var parts = segment.split(';');
    if (parts.isEmpty) {
      throw Exception('segment is empty');
    }
    return parts[0];
  }

  PelicanRouteSegment.fromPathSegmentSub(String path, [PelicanRouteSegment? child]) {
    if (path.contains('@'))
      throw ArgumentError('incoming path should never contain @ - use fromPathSegment');
    var parts = path.split('+');
    var nameAndParams = parts[0];
    var optionsStr = parts.length > 1 ? parts[1] : '';
    List<String> nameAndParamsParts = nameAndParams.isNotEmpty ? nameAndParams.split(';') : [];
    name = nameAndParamsParts.isNotEmpty ? nameAndParamsParts.removeAt(0) : '';
    params = mapFromValues(nameAndParamsParts.join(';'));
    options = mapFromValues(optionsStr);
    this.child = child;
  }

  static PelicanRouteSegment fromPathSegment(String path) {
    PelicanRouteSegment? child;
    for (var p in path.split('@').reversed) {
      child = PelicanRouteSegment.fromPathSegmentSub(p,child);
    }
    return child!;
  }

  String toPath() {
    PelicanRouteSegment? curr = this;
    var parts = [];
    do {
      parts.add(curr!.toPathSingle());
      curr = curr.child;
    } while (curr != null);
    return parts.join('@');
  }

  String toPathSingle({PelicanRouteSegment? definition}) {
    if (definition!=null && definition.name != name) {
      throw Exception('definition name must match path name');
    }

    var nameAndPars = [name];
    var ops = List<String>.empty(growable: true);
    if (definition!=null) {
      if (params.isNotEmpty) {
        for (var p in definition.params.keys) {
          if (params.containsKey(p)) {
            nameAndPars.add([p, params[p]].join('='));
          }
        }
      }
      if (options.isNotEmpty) {
        for (var op in definition.options.keys) {
          if (options.containsKey(op)) {
            ops.add([op, options[op]].join('='));
          }
        }
      }
    } else {
      List<String> keys = params.keys.toList()..sort((a, b) => a.compareTo(b));
      for (var p in keys) {
        nameAndPars.add([p, params[p]].join('='));
      }
      keys = options.keys.toList()..sort((a, b) => a.compareTo(b));
      for (var op in keys) {
        ops.add([op, options[op]].join('='));
      }
    }
    return [nameAndPars.join(';'), ops.join(';')].where((s) => s.isNotEmpty).join('+');
  }

  bool equals(PelicanRouteSegment other, {bool ignoreOptions = true}) {
    return name == other.name && linkedMapsEqual(params,other.params) && (ignoreOptions || linkedMapsEqual(options,other.options));
  }

}

