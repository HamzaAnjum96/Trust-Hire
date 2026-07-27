import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map_theme.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';
import 'job_marker.dart';
import 'marker_cluster.dart';
import '../../l10n/app_localizations.dart';

/// The map itself — tiles, job radii, markers and the user's position.
///
/// Kept free of app state so it can be reused by the create and edit flows in
/// later sprints: it takes jobs and a selection, and reports taps back.
class JobMap extends StatefulWidget {
  const JobMap({
    super.key,
    required this.jobs,
    required this.centre,
    required this.onJobTapped,
    required this.onMapTapped,
    this.selectedJobId,
    this.userLocation,
    this.controller,
    this.initialZoom = 13,
    this.tileProvider,
    this.onTilesUnavailable,
    this.onClusterTapped,
  });

  final List<Job> jobs;
  final JobLocation centre;
  final String? selectedJobId;
  final JobLocation? userLocation;
  final ValueChanged<Job> onJobTapped;
  final VoidCallback onMapTapped;
  final MapController? controller;
  final double initialZoom;

  /// Overrides where map tiles come from. Left null in the app, which uses
  /// flutter_map's network provider; tests pass an offline provider so they
  /// do not depend on tile servers.
  final TileProvider? tileProvider;

  /// Called once if map tiles cannot be fetched. The map keeps working —
  /// markers stay correctly positioned over the plain background — so the
  /// owner decides how to explain it.
  final VoidCallback? onTilesUnavailable;

  /// Called when a group of overlapping jobs is tapped. The map zooms to it so
  /// the individual pins separate.
  final void Function(JobCluster cluster)? onClusterTapped;

  @override
  State<JobMap> createState() => _JobMapState();
}

class _JobMapState extends State<JobMap> {
  bool _reportedTileFailure = false;

  void _onTileError() {
    if (_reportedTileFailure || !mounted) return;
    _reportedTileFailure = true;
    widget.onTilesUnavailable?.call();
  }

  Job? get _selectedJob {
    final id = widget.selectedJobId;
    if (id == null) return null;
    for (final job in widget.jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final mapTheme = MapTheme.of(context);
    final selected = _selectedJob;

    return Stack(
      children: [
        // The map is one large tappable surface with no text of its own, so
        // it needs an explicit label — otherwise a screen reader announces an
        // unnamed button covering the screen.
        Semantics(
          label: strings.mapLabel,
          child: FlutterMap(
            mapController: widget.controller,
            options: MapOptions(
              initialCenter: LatLng(
                widget.centre.latitude,
                widget.centre.longitude,
              ),
              initialZoom: widget.initialZoom,
              minZoom: 4,
              maxZoom: 18,
              backgroundColor: mapTheme.backgroundColour,
              onTap: (_, _) => widget.onMapTapped(),
              interactionOptions: const InteractionOptions(
                // Rotation adds nothing here and makes one-handed panning
                // fiddly, so it is off.
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
              ),
            ),
            children: [
              mapTheme.tileLayer(
                context,
                provider: widget.tileProvider,
                onTileError: _onTileError,
              ),

              // A whisper of brand colour over the basemap, under everything
              // else, so markers and work areas stay untinted.
              IgnorePointer(
                child: ColoredBox(
                  color: mapTheme.tint.withValues(alpha: mapTheme.tintOpacity),
                  child: const SizedBox.expand(),
                ),
              ),

              // The approximate work area of the selected job. Only the
              // selected one is drawn — every radius at once turns the map into
              // noise, which section 15 warns against.
              if (selected != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        selected.location.latitude,
                        selected.location.longitude,
                      ),
                      radius: selected.radiusMetres,
                      useRadiusInMeter: true,
                      color: BrandColours.jobRadiusFill,
                      borderColor: BrandColours.jobRadiusBorder,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              if (widget.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        widget.userLocation!.latitude,
                        widget.userLocation!.longitude,
                      ),
                      width: UserLocationMarker.size,
                      height: UserLocationMarker.size,
                      child: const UserLocationMarker(),
                    ),
                  ],
                ),

              // Clustering needs the camera, which only exists inside the map.
              Builder(
                builder: (context) {
                  final clusters = const MarkerClusterer().cluster(
                    widget.jobs,
                    camera: MapCamera.of(context),
                  );

                  return MarkerLayer(
                    markers: [
                      for (final cluster in clusters)
                        if (cluster.isSingle)
                          Marker(
                            point: LatLng(
                              cluster.only.location.latitude,
                              cluster.only.location.longitude,
                            ),
                            width: JobMarker.selectedSize,
                            height: JobMarker.selectedSize,
                            // Anchor the pin's point at the coordinate rather
                            // than its centre, so it marks the right spot.
                            alignment: Alignment.topCenter,
                            child: JobMarker(
                              job: cluster.only,
                              isSelected:
                                  cluster.only.id == widget.selectedJobId,
                              onTap: () => widget.onJobTapped(cluster.only),
                            ),
                          )
                        else
                          Marker(
                            point: LatLng(
                              cluster.centre.latitude,
                              cluster.centre.longitude,
                            ),
                            width: ClusterMarker.size,
                            height: ClusterMarker.size,
                            child: ClusterMarker(
                              count: cluster.count,
                              icon: cluster.isUniform
                                  ? cluster.jobs.first.icon
                                  : null,
                              onTap: () =>
                                  widget.onClusterTapped?.call(cluster),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // OpenStreetMap requires visible attribution.
        Positioned(
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BrandRadius.small),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                mapTheme.attribution,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
