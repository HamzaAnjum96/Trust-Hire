import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/formatters.dart';
import '../../core/map_theme.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import '../../l10n/app_localizations.dart';

/// Choosing roughly where the work is.
///
/// The pin stays fixed at the centre and the map moves under it — one-handed
/// and impossible to get wrong, unlike dragging a small target. The radius
/// circle makes it obvious that an area is being chosen, not an address, which
/// is what the product promises.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.location,
    required this.radiusMetres,
    required this.onLocationChanged,
    this.tileProvider,
    this.height = 260,
  });

  final JobLocation location;
  final double radiusMetres;
  final ValueChanged<JobLocation> onLocationChanged;
  final TileProvider? tileProvider;
  final double height;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapTheme = MapTheme.of(context);
    final centre = LatLng(widget.location.latitude, widget.location.longitude);

    return ClipRRect(
      borderRadius: BrandRadius.largeAll,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: centre,
                initialZoom: 15,
                minZoom: 8,
                maxZoom: 18,
                backgroundColor: mapTheme.backgroundColour,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
                onPositionChanged: (position, hasGesture) {
                  if (!hasGesture) return;
                  widget.onLocationChanged(
                    JobLocation(
                      latitude: position.center.latitude,
                      longitude: position.center.longitude,
                    ),
                  );
                },
              ),
              children: [
                mapTheme.tileLayer(context, provider: widget.tileProvider),
                mapTheme.tintLayer(),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: centre,
                      radius: widget.radiusMetres,
                      useRadiusInMeter: true,
                      color: BrandColours.jobRadiusFill,
                      borderColor: BrandColours.jobRadiusBorder,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              ],
            ),

            // The fixed pin. Ignoring pointers keeps it from stealing the
            // drag that moves the map beneath it.
            IgnorePointer(
              child: Padding(
                // Lift it so the point, not the middle, marks the centre.
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.place,
                  size: 44,
                  color: theme.colorScheme.primary,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 6)],
                ),
              ),
            ),

            Positioned(
              left: BrandSizing.spaceSm,
              right: BrandSizing.spaceSm,
              bottom: BrandSizing.spaceSm,
              child: _AreaChip(radiusMetres: widget.radiusMetres),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.radiusMetres});

  final double radiusMetres;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSizing.spaceMd,
        vertical: BrandSizing.spaceSm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BrandRadius.mediumAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.my_location,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BrandSizing.spaceSm),
          Expanded(
            child: Text(
              '${strings.moveMapToChooseArea} · '
              '${Format.radius(strings, radiusMetres)}',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
