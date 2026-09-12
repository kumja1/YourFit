import 'package:geolocator/geolocator.dart';

extension PositionExtension on Position {
  static final Expando<double> _distanceMap = Expando();

  double get distance => _distanceMap[this] ?? 0;

  set distance(double value) => _distanceMap[this] = value;

  Map<String, dynamic> asJson() => {...toJson(), "distance": distance};
}
