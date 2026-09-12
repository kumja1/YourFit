import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourfit/src/utils/extensions/position_extension.dart';
import 'package:yourfit/src/utils/index.dart';

class DeviceService() {
  final OpenRouteService locationClient = OpenRouteService(
    apiKey: Env.openRouteKey,
  );

  final FlutterTts speech = FlutterTts();
  late final SharedPreferences preferences;

  Future<void> initPreferences() async =>
      preferences = await SharedPreferences.getInstance();

  Future<void> setDevicePreference<T>(
    String key,
    T value, {
    String Function(T)? converter,
  }) async {
    try {
      converter ??= (value) => value.toString();
      await (value is int
          ? preferences.setInt(key, value)
          : value is double
          ? preferences.setDouble(key, value)
          : value is bool
          ? preferences.setBool(key, value)
          : preferences.setString(key, converter(value)));
    } on Error catch (e) {
      logger.severe("Error in setDevicePreference", e);
    }
  }

  T? getDevicePreference<T>(String key, {T? Function(String)? converter}) {
    try {
      if (!preferences.containsKey(key)) {
        return null;
      }

      converter ??= (value) => value as T;
      return T is int
          ? preferences.getInt(key) as T
          : T is double
          ? preferences.getDouble(key) as T
          : T is bool
          ? preferences.getBool(key) as T
          : converter(preferences.getString(key)!);
    } on Error catch (e) {
      logger.severe("Error in getDevicePreference", e);
      return null;
    }
  }

  Future<bool> _requestDeviceLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      if (preferences.containsKey("location_enabled")) {
        return true;
      }

      final permission = await Geolocator.requestPermission();
      final denied =
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine;

      if (!denied) {
        setDevicePreference("location_enabled", true);
      }

      return !denied;
    } on Error catch (e) {
      logger.severe("Error in _requestDeviceLocationPermission", e);
      return false;
    }
  }

  Stream<Position>? getDevicePositionStream({
    LocationSettings? locationSettings,
  }) {
    try {
      return Geolocator.getPositionStream(locationSettings: locationSettings);
    } on Error catch (e) {
      logger.severe("Error in getDevicePositionStream", e);
      return null;
    }
  }

  Future<List<Position>> getPositionsNearDevice({int amount = 5}) async {
    try {
      Position position = await getDevicePosition();
      if (position.latitude == 0 && position.longitude == 0) {
        return [];
      }

      PoisData response = await locationClient.poisDataPost(request: "pois");
      return response.features.map((e) {
        ORSCoordinate coords = e.geometry.coordinates.first.first;
        return Position(
          longitude: coords.longitude,
          latitude: coords.latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: coords.altitude ?? 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        )..distance = e.properties["distance"] as double;
      }).toList();
    } on Error catch (e) {
      logger.severe("Error in getPositionsNearDevice", e);
      return [];
    }
  }

  Future<Position> getDevicePosition() async {
    if (!await _requestDeviceLocationPermission()) {
      return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Position?> getDeviceLastPosition() async {
    if (!(await _requestDeviceLocationPermission())) {
      return null;
    }

    return await Geolocator.getLastKnownPosition();
  }

  Future<
    ({
      Position start,
      Map<String, dynamic> segmentJson,
      DirectionRouteSegment segment,
      GeoJsonFeatureGeometry geometry,
    })?
  >
  getRouteFromDevicePosition({
    required double targetLongitude,
    required double targetLatitude,
    ORSProfile? profile,
  }) async {
    try {
      Position position = await getDevicePosition();
      if (position.longitude == 0 && position.latitude == 0) {
        return null;
      }

      final route = (await locationClient.directionsMultiRouteGeoJsonPost(
        coordinates: [
          ORSCoordinate(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          ORSCoordinate(latitude: targetLatitude, longitude: targetLongitude),
        ],
        maneuvers: true,
        profileOverride: profile,
        geometrySimplify: true,

      )).features.first;

      final List<Map<String, dynamic>> segments =
          (route.properties["segments"] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

      if (segments.isEmpty) {
        return null;
      }

      final segment = segments.first;
      if (segments.length >= 2) {
        for (final seg in segments.skip(1)) {
          (segment["steps"] as List<Map<String, dynamic>>).addAll(seg["steps"]);
        }
      }

      return (
        start: position,
        segmentJson: segment,
        segment: DirectionRouteSegment.fromJson(segment),
        geometry: route.geometry,
      );
    } on Error catch (e) {
      logger.severe("Error in getRouteFromDevicePosition", e);
      return null;
    }
  }

  Future<void> speak(
    String text, {
    bool isNavigation = false,
    double? pitch,
    double? rate,
    double? volume,
    String? language,
    String? voice,
  }) async {
    try {
      if (language != null) {
        await speech.setLanguage(language);
      }

      if (pitch != null) {
        await speech.setPitch(pitch);
      }

      if (rate != null) {
        await speech.setSpeechRate(rate);
      }

      if (volume != null) {
        await speech.setVolume(volume);
      }

      if (voice != null) {
        await speech.setVoice({"name": voice, "locale": language ?? ""});
      }

      if (isNavigation && !kIsWeb) {
        await speech.setAudioAttributesForNavigation();
      }

      await speech.stop();
      await speech.speak(text);
    } on Error catch (e) {
      logger.severe("Error in speak", e);
    }
  }
}
