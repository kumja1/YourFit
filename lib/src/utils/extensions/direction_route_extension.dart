
import 'package:open_route_service/open_route_service.dart';

extension DirectionRouteSegmentStepExtension on DirectionRouteSegmentStep {
   static final Expando<double> manuever = Expando();
  static DirectionRouteSegmentStep fromJson(Map<String, dynamic> json) {
    final step = DirectionRouteSegmentStep.fromJson(json);

  }
}

extension DirectionRouteSegmentExtension on DirectionRouteSegment {
  static DirectionRouteSegment fromJson(Map<String, dynamic> json) {
    final segment = DirectionRouteSegment.fromJson(json);
    for (final step in segment.steps) {
      step
    }
    return segment;
  }
}