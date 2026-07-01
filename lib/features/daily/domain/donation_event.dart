import '../../../core/location/geo_point.dart';

class DonationEvent {
  const DonationEvent({
    required this.id,
    required this.title,
    required this.organizer,
    required this.startsAt,
    required this.endsAt,
    required this.locationName,
    required this.location,
    required this.distanceKm,
    required this.urgency,
    required this.imageUrl,
    required this.slotsLeft,
    this.booked = false,
    this.description,
    this.province,
    this.ward,
    this.hospital,
    this.appointmentStatus,
    this.capacity,
    this.bookedCount,
  });

  factory DonationEvent.fromJson(Map<String, dynamic> json) {
    return DonationEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      organizer: json['organizer'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      locationName: json['location_name'] as String,
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      distanceKm: (json['distance_km'] as num).toDouble(),
      urgency: EventUrgency.values.byName(json['urgency'] as String),
      imageUrl: json['image_url'] as String? ??
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=900',
      slotsLeft: json['slots_left'] as int,
      booked: json['booked'] as bool? ?? false,
      description: json['description'] as String?,
      province: json['province'] is Map<String, dynamic>
          ? AdministrativeArea.fromJson(json['province'] as Map<String, dynamic>)
          : null,
      ward: json['ward'] is Map<String, dynamic>
          ? AdministrativeArea.fromJson(json['ward'] as Map<String, dynamic>)
          : null,
      hospital: json['hospital'] is Map<String, dynamic>
          ? HospitalSummary.fromJson(json['hospital'] as Map<String, dynamic>)
          : null,
      appointmentStatus: json['appointment_status'] as String?,
      capacity: json['capacity'] as int?,
      bookedCount: json['booked_count'] as int?,
    );
  }

  final String id;
  final String title;
  final String organizer;
  final DateTime startsAt;
  final DateTime endsAt;
  final String locationName;
  final GeoPoint location;
  final double distanceKm;
  final EventUrgency urgency;
  final String imageUrl;
  final int slotsLeft;
  final bool booked;
  final String? description;
  final AdministrativeArea? province;
  final AdministrativeArea? ward;
  final HospitalSummary? hospital;
  final String? appointmentStatus;
  final int? capacity;
  final int? bookedCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organizer': organizer,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'location_name': locationName,
      'location': location.toJson(),
      'distance_km': distanceKm,
      'urgency': urgency.name,
      'image_url': imageUrl,
      'slots_left': slotsLeft,
      'booked': booked,
      'description': description,
      'province': province?.toJson(),
      'ward': ward?.toJson(),
      'hospital': hospital?.toJson(),
      'appointment_status': appointmentStatus,
      'capacity': capacity,
      'booked_count': bookedCount,
    };
  }

  DonationEvent copyWith({
    String? id,
    String? title,
    String? organizer,
    DateTime? startsAt,
    DateTime? endsAt,
    String? locationName,
    GeoPoint? location,
    double? distanceKm,
    EventUrgency? urgency,
    String? imageUrl,
    int? slotsLeft,
    bool? booked,
    String? description,
    AdministrativeArea? province,
    AdministrativeArea? ward,
    HospitalSummary? hospital,
    String? appointmentStatus,
    int? capacity,
    int? bookedCount,
  }) {
    return DonationEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      organizer: organizer ?? this.organizer,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      locationName: locationName ?? this.locationName,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      urgency: urgency ?? this.urgency,
      imageUrl: imageUrl ?? this.imageUrl,
      slotsLeft: slotsLeft ?? this.slotsLeft,
      booked: booked ?? this.booked,
      description: description ?? this.description,
      province: province ?? this.province,
      ward: ward ?? this.ward,
      hospital: hospital ?? this.hospital,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      capacity: capacity ?? this.capacity,
      bookedCount: bookedCount ?? this.bookedCount,
    );
  }
}

enum EventUrgency {
  normal,
  high,
}

class AdministrativeArea {
  const AdministrativeArea({
    required this.code,
    required this.fullName,
    this.name,
  });

  factory AdministrativeArea.fromJson(Map<String, dynamic> json) {
    return AdministrativeArea(
      code: json['code'] as String,
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  final String code;
  final String fullName;
  final String? name;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'full_name': fullName,
      'name': name,
    };
  }
}

class HospitalSummary {
  const HospitalSummary({
    required this.id,
    required this.name,
    this.address,
  });

  factory HospitalSummary.fromJson(Map<String, dynamic> json) {
    return HospitalSummary(
      id: json['id'].toString(),
      name: json['name'] as String,
      address: json['address'] as String?,
    );
  }

  final String id;
  final String name;
  final String? address;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }
}
