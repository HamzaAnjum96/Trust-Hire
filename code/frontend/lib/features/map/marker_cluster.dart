import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/job.dart';

/// A group of jobs close enough together to draw as one pin.
@immutable
class JobCluster {
  const JobCluster({required this.jobs, required this.centre});

  final List<Job> jobs;
  final JobLocation centre;

  bool get isSingle => jobs.length == 1;
  Job get only => jobs.first;
  int get count => jobs.length;

  /// True when every job in the group is the same kind of work — then the
  /// cluster can keep that kind's glyph instead of falling back to a generic
  /// one, which keeps the map informative when it is zoomed out.
  bool get isUniform {
    if (isSingle) return true;
    final first = jobs.first.type;
    if (first == null) return false;
    return jobs.every((job) => job.type == first);
  }
}

/// Groups markers that would otherwise overlap.
///
/// Deferred as optional in Sprint 1 and needed now: the seed data spans
/// Islamabad to Muzaffarabad, so at any zoom that shows the whole picture the
/// twin-cities pins pile on top of each other and neither can be tapped.
///
/// Grid-based rather than distance-based, and the grid is in *screen* space
/// rather than degrees. Clustering by degrees would group differently at the
/// equator than at 34° north, and the thing being avoided is pins overlapping
/// on screen — which is a pixel problem, not a geography one.
class MarkerClusterer {
  const MarkerClusterer({this.cellSizePixels = 72});

  /// Roughly one marker wide, so two jobs merge only once their pins would
  /// actually collide.
  final double cellSizePixels;

  List<JobCluster> cluster(List<Job> jobs, {required MapCamera camera}) {
    if (jobs.isEmpty) return const <JobCluster>[];

    final buckets = <({int x, int y}), List<Job>>{};

    for (final job in jobs) {
      final point = camera.projectAtZoom(
        LatLng(job.location.latitude, job.location.longitude),
      );

      final key = (
        x: (point.dx / cellSizePixels).floor(),
        y: (point.dy / cellSizePixels).floor(),
      );
      buckets.putIfAbsent(key, () => <Job>[]).add(job);
    }

    return buckets.values
        .map((group) => JobCluster(jobs: group, centre: _centreOf(group)))
        .toList(growable: false);
  }

  /// The mean position of a group. Fine at the scale a cluster covers — a
  /// cell is under a hundred pixels, so the great-circle correction is far
  /// below the size of the pin drawn on top of it.
  JobLocation _centreOf(List<Job> jobs) {
    if (jobs.length == 1) return jobs.first.location;

    var latitude = 0.0;
    var longitude = 0.0;
    for (final job in jobs) {
      latitude += job.location.latitude;
      longitude += job.location.longitude;
    }

    return JobLocation(
      latitude: latitude / jobs.length,
      longitude: longitude / jobs.length,
    );
  }
}

/// The bounds that contain every job, with a little breathing room.
///
/// Used to open the map on all of the work rather than on an arbitrary point,
/// so a job in Kashmir is not stranded off-screen with no hint it exists.
LatLngBounds? boundsOf(List<Job> jobs, {double paddingDegrees = 0.02}) {
  if (jobs.isEmpty) return null;

  var minLat = jobs.first.location.latitude;
  var maxLat = minLat;
  var minLng = jobs.first.location.longitude;
  var maxLng = minLng;

  for (final job in jobs) {
    minLat = math.min(minLat, job.location.latitude);
    maxLat = math.max(maxLat, job.location.latitude);
    minLng = math.min(minLng, job.location.longitude);
    maxLng = math.max(maxLng, job.location.longitude);
  }

  return LatLngBounds(
    LatLng(minLat - paddingDegrees, minLng - paddingDegrees),
    LatLng(maxLat + paddingDegrees, maxLng + paddingDegrees),
  );
}
