abstract interface class EmergencyAudioService {
  Future<void> startHeartbeat({
    required double intensity,
  });

  Future<void> updateIntensity(double intensity);

  Future<void> confirmedPulse();

  Future<void> stop();

  Future<void> dispose();
}
