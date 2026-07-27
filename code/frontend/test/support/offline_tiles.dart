import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// A tile provider that serves a 1×1 transparent PNG from memory.
///
/// The map's real provider fetches from a tile server, which a widget test
/// cannot reach — the pending requests keep the frame scheduler busy and
/// `pumpAndSettle` never returns. Tests pass this instead so the map settles.
class OfflineTileProvider extends TileProvider {
  OfflineTileProvider();

  static final Uint8List _transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    return MemoryImage(_transparentPixel);
  }
}
