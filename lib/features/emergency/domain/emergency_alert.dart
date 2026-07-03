import '../../../core/location/geo_point.dart';

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.hospitalProvinceCode,
    required this.hospitalLocation,
    required this.requiredBloodType,
    required this.level,
    required this.unitsNeeded,
    required this.createdAt,
    required this.expiresAt,
    required this.message,
    this.active = true,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    final hospital = json['hospital'] is Map<String, dynamic>
        ? json['hospital'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final location = json['hospital_location'] is Map<String, dynamic>
        ? json['hospital_location'] as Map<String, dynamic>
        : <String, dynamic>{
            'latitude': hospital['latitude'],
            'longitude': hospital['longitude'],
          };

    return EmergencyAlert(
      id: json['id'] as String,
      hospitalName: json['hospital_name'] as String? ??
          hospital['name'] as String? ??
          'Bệnh viện',
      hospitalAddress: json['hospital_address'] as String? ??
          hospital['address'] as String? ??
          'Chưa có địa chỉ',
      hospitalProvinceCode: json['hospital_province_code'] as String? ??
          hospital['province_code'] as String? ??
          '',
      hospitalLocation: GeoPoint.fromJson(location),
      requiredBloodType: json['required_blood_type'] as String,
      level: EmergencyLevel.values.byName(json['level'] as String),
      unitsNeeded: json['units_needed'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      message: json['message'] as String,
      active: json['active'] as bool? ??
          (json.containsKey('status') ? json['status'] == 'active' : true),
    );
  }

  final String id;
  final String hospitalName;
  final String hospitalAddress;
  final String hospitalProvinceCode;
  final GeoPoint hospitalLocation;
  final String requiredBloodType;
  final EmergencyLevel level;
  final int unitsNeeded;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String message;
  final bool active;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

enum EmergencyLevel {
  level1,
  level2,
  level3,
}

extension EmergencyLevelDisplay on EmergencyLevel {
  String get label {
    return switch (this) {
      EmergencyLevel.level1 => 'Cấp độ 1',
      EmergencyLevel.level2 => 'Cấp độ 2',
      EmergencyLevel.level3 => 'Cấp độ 3',
    };
  }

  double get targetRadiusKm {
    return switch (this) {
      EmergencyLevel.level1 => 15,
      EmergencyLevel.level2 => 30,
      EmergencyLevel.level3 => 120,
    };
  }

  String get dispatchDescription {
    return switch (this) {
      EmergencyLevel.level1 => 'Quét tình nguyện viên trong bán kính 15 km',
      EmergencyLevel.level2 => 'Mở rộng toàn tỉnh trong bán kính 30 km',
      EmergencyLevel.level3 => 'Chi viện liên tỉnh, bán kính trên 50 km',
    };
  }
}
