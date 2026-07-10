import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/location/geo_point.dart';
import '../../services/emergency_audio_service.dart';
import '../../services/location_service.dart';

class DeviceLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw StateError('Quyền truy cập vị trí đã bị từ chối.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class JustAudioEmergencyAudioService implements EmergencyAudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPrepared = false;
  // Bản web chưa đóng gói âm thanh nhịp tim; tránh gọi asset gây lỗi 404.
  bool _isAvailable = !kIsWeb;

  @override
  Future<void> startHeartbeat({
    required double intensity,
  }) async {
    if (!_isAvailable) return;
    if (!_isPrepared) {
      try {
        await _player.setAsset('assets/audio/heartbeat_loop.mp3');
      } on Object {
        _isAvailable = false;
        return;
      }
      await _player.setLoopMode(LoopMode.one);
      _isPrepared = true;
    }
    await updateIntensity(intensity);
    await _player.play();
  }

  @override
  Future<void> updateIntensity(double intensity) async {
    if (!_isAvailable) return;
    final clamped = intensity.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(0.35 + clamped * 0.65);
    await _player.setSpeed(0.85 + clamped * 0.45);
  }

  @override
  Future<void> confirmedPulse() async {
    if (!_isAvailable) return;
    await updateIntensity(1);
  }

  @override
  Future<void> stop() async {
    if (!_isAvailable) return;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
