import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/models/custom_map_config.dart';

void main() {
  test('displayBounds stays within valid LatLng limits for tall images', () {
    const config = CustomMapConfig(
      filePath: '/tmp/map.png',
      displayName: 'Tall Map',
      mapId: 'map-id',
      imageWidth: 2400,
      imageHeight: 3213,
    );

    expect(config.displayBounds.north, lessThanOrEqualTo(90));
    expect(config.displayBounds.south, greaterThanOrEqualTo(-90));
    expect(config.displayBounds.east, lessThanOrEqualTo(180));
    expect(config.displayBounds.west, greaterThanOrEqualTo(-180));
  });

  test('display point conversion preserves stored coordinates', () {
    const config = CustomMapConfig(
      filePath: '/tmp/map.png',
      displayName: 'Tall Map',
      mapId: 'map-id',
      imageWidth: 2400,
      imageHeight: 3213,
    );
    const storedPoint = LatLng(1600, 1200);

    final displayPoint = config.toDisplayPoint(storedPoint);
    final roundTrip = config.fromDisplayPoint(displayPoint);

    expect(roundTrip.latitude, closeTo(storedPoint.latitude, 0.001));
    expect(roundTrip.longitude, closeTo(storedPoint.longitude, 0.001));
  });
}
