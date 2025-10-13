enum MapLayerType {
  openStreetMap,
  openTopoMap,
  esriWorldImagery,
}

class MapLayer {
  final MapLayerType type;
  final String name;
  final String urlTemplate;
  final String attribution;
  final int maxZoom;

  const MapLayer({
    required this.type,
    required this.name,
    required this.urlTemplate,
    required this.attribution,
    required this.maxZoom,
  });

  static const openStreetMap = MapLayer(
    type: MapLayerType.openStreetMap,
    name: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  );

  static const openTopoMap = MapLayer(
    type: MapLayerType.openTopoMap,
    name: 'OpenTopoMap',
    urlTemplate: 'https://a.tile.opentopomap.org/{z}/{x}/{y}.png',
    attribution: '© OpenTopoMap (CC-BY-SA)',
    maxZoom: 17,
  );

  static const esriWorldImagery = MapLayer(
    type: MapLayerType.esriWorldImagery,
    name: 'ESRI Satellite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri',
    maxZoom: 19,
  );

  static const List<MapLayer> allLayers = [
    openStreetMap,
    openTopoMap,
    esriWorldImagery,
  ];

  static MapLayer fromType(MapLayerType type) {
    return allLayers.firstWhere((layer) => layer.type == type);
  }
}
