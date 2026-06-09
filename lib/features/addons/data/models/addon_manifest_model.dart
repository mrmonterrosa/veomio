class StremioAddon {
  final String id;
  final String name;
  final String version;
  final String? description;
  final String? logo;
  final List<String> resources;
  final List<String> types;
  final List<AddonCatalog> catalogs;
  final String manifestUrl;

  StremioAddon({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    this.logo,
    required this.resources,
    required this.types,
    required this.catalogs,
    required this.manifestUrl,
  });

  factory StremioAddon.fromJson(Map<String, dynamic> json, String manifestUrl) {
    // Parse resources
    List<String> resList = [];
    if (json['resources'] is List) {
      for (var r in json['resources']) {
        if (r is String) {
          resList.add(r);
        } else if (r is Map && r.containsKey('name')) {
          resList.add(r['name'] as String);
        }
      }
    }

    // Parse types
    List<String> typeList = [];
    if (json['types'] is List) {
      typeList = List<String>.from(json['types']);
    }

    // Parse catalogs
    List<AddonCatalog> catList = [];
    if (json['catalogs'] is List) {
      for (var c in json['catalogs']) {
        if (c is Map<String, dynamic>) {
          catList.add(AddonCatalog.fromJson(c));
        }
      }
    }

    return StremioAddon(
      id: json['id'] as String? ?? 'unknown_addon',
      name: json['name'] as String? ?? 'Unnamed Addon',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      resources: resList,
      types: typeList,
      catalogs: catList,
      manifestUrl: manifestUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'logo': logo,
      'resources': resources,
      'types': types,
      'catalogs': catalogs.map((c) => c.toJson()).toList(),
      'manifestUrl': manifestUrl,
    };
  }
}

class AddonCatalog {
  final String id;
  final String type;
  final String name;

  AddonCatalog({
    required this.id,
    required this.type,
    required this.name,
  });

  factory AddonCatalog.fromJson(Map<String, dynamic> json) {
    return AddonCatalog(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      name: json['name'] as String? ?? 'Catalog',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
    };
  }
}
