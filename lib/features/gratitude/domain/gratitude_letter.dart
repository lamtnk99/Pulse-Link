import '../../daily/domain/blood_journey.dart';
import '../../daily/domain/past_donation.dart';
import '../../emergency/domain/emergency_commitment.dart';
import '../../notifications/domain/mobile_notification.dart';
import '../../profile/domain/donor_profile.dart';

enum GratitudeLetterSource {
  regular,
  sosPulseLink,
  sosPatient,
  sosReserve;

  bool get isSos => this != GratitudeLetterSource.regular;
}

class GratitudeLetterMessage {
  const GratitudeLetterMessage({
    required this.sender,
    required this.title,
    required this.body,
    required this.signature,
  });

  factory GratitudeLetterMessage.fromJson(Map<String, dynamic> json) {
    return GratitudeLetterMessage(
      sender: json['sender'] as String? ?? 'PulseLink',
      title: json['title'] as String? ?? 'Thư cảm ơn',
      body: json['body'] as String? ?? '',
      signature: json['signature'] as String? ?? 'PulseLink Team',
    );
  }

  final String sender;
  final String title;
  final String body;
  final String signature;
}

class GratitudeLetter {
  const GratitudeLetter({
    required this.id,
    required this.source,
    required this.style,
    required this.messages,
    this.donorName,
    this.bloodType,
    this.volumeMl,
    this.hospitalName,
    this.donatedAt,
    this.certificateId,
    this.bloodJourneyId,
    this.conversationId,
  });

  factory GratitudeLetter.fromDonation(
    PastDonation donation, {
    DonorProfile? profile,
  }) {
    final journey = donation.bloodJourney;
    if (journey != null) {
      return GratitudeLetter.fromBloodJourney(
        journey,
        profile: profile,
        hospitalName: donation.locationName,
        bloodType: donation.bloodType,
        volumeMl: donation.volumeMl,
        donatedAt: donation.donatedAt,
        certificateId: donation.certificateId,
      );
    }

    final message = (donation.gratitudeMessage ?? '').trim();
    return GratitudeLetter(
      id: 'donation-${donation.id}',
      source: GratitudeLetterSource.regular,
      style: donation.gratitudeStyle ?? 'classic',
      donorName: profile?.name,
      bloodType: donation.bloodType,
      volumeMl: donation.volumeMl,
      hospitalName: donation.locationName,
      donatedAt: donation.donatedAt,
      certificateId: donation.certificateId,
      messages: [
        GratitudeLetterMessage(
          sender: 'PulseLink',
          title: 'Thư cảm ơn từ PulseLink',
          body: message.isNotEmpty
              ? message
              : _regularFallback(
                  donation.volumeMl, donation.bloodType, donation.locationName),
          signature: 'PulseLink Team',
        ),
      ],
    );
  }

  factory GratitudeLetter.fromBloodJourney(
    BloodJourney journey, {
    DonorProfile? profile,
    String? hospitalName,
    String? bloodType,
    int? volumeMl,
    DateTime? donatedAt,
    String? certificateId,
  }) {
    final isReserve = journey.destinationType == 'reserve';
    final expectedSource = isReserve
        ? GratitudeLetterSource.sosReserve
        : GratitudeLetterSource.sosPatient;
    final card = journey.gratitudeCard;
    if (journey.completedAt != null && card != null) {
      final letter = GratitudeLetter.fromCardJson(
        card,
        profile: profile,
        fallbackHospitalName: hospitalName,
        fallbackBloodType: bloodType,
        fallbackVolumeMl: volumeMl,
        fallbackDonatedAt: donatedAt,
        fallbackCertificateId: certificateId,
      );
      if (letter.source == expectedSource) return letter;
    }

    final patientOrHospitalMessage = (journey.finalMessage ?? '').trim();

    return GratitudeLetter(
      id: 'journey-${journey.id}',
      source: expectedSource,
      style: journey.gratitudeStyle ?? (isReserve ? 'botanical' : 'hero_night'),
      donorName: profile?.name,
      bloodType: bloodType,
      volumeMl: volumeMl,
      hospitalName: hospitalName ?? journey.hospitalName,
      donatedAt: donatedAt,
      certificateId: certificateId,
      bloodJourneyId: journey.id,
      messages: [
        GratitudeLetterMessage(
          sender: isReserve ? 'Bệnh viện tiếp nhận' : 'Người nhà bệnh nhân',
          title:
              isReserve ? 'Lời cảm ơn từ bệnh viện' : 'Lời cảm ơn từ người nhà',
          body: patientOrHospitalMessage.isNotEmpty
              ? patientOrHospitalMessage
              : _sosFallback(isReserve),
          signature: isReserve ? 'Đội ngũ y tế' : 'Gia đình người nhận máu',
        ),
      ],
    );
  }

  factory GratitudeLetter.fromSosDonation(
    EmergencyCommitment commitment, {
    DonorProfile? profile,
    String? hospitalName,
    String? bloodType,
  }) {
    final journey = commitment.bloodJourney;
    final card = journey?.gratitudeCard;
    final cardMessage = _messageBodyFromCard(card, sender: 'PulseLink');
    final pulseLinkMessage =
        (journey?.pulseLinkMessage ?? cardMessage ?? '').trim();

    return GratitudeLetter(
      id: 'sos-donation-${commitment.id}',
      source: GratitudeLetterSource.sosPulseLink,
      style: 'hero_night',
      donorName: profile?.name ?? _stringFromMap(card, 'donor_name'),
      bloodType: bloodType ?? _stringFromMap(card, 'blood_type'),
      volumeMl: commitment.donationVolumeMl ?? _intFromMap(card, 'volume_ml'),
      hospitalName: hospitalName ??
          _stringFromMap(card, 'hospital_name') ??
          journey?.hospitalName,
      donatedAt: commitment.donatedAt ?? _parseDate(card?['donated_at']),
      certificateId: _stringFromMap(card, 'certificate_id'),
      bloodJourneyId: journey?.id ?? _stringFromMap(card, 'blood_journey_id'),
      messages: [
        GratitudeLetterMessage(
          sender: 'PulseLink',
          title: 'Một lá thư từ PulseLink',
          body: pulseLinkMessage.isNotEmpty
              ? pulseLinkMessage
              : _pulseLinkSosFallback(false),
          signature: 'Đội ngũ PulseLink',
        ),
      ],
    );
  }

  factory GratitudeLetter.fromCardJson(
    Map<String, dynamic> json, {
    DonorProfile? profile,
    String? fallbackHospitalName,
    String? fallbackBloodType,
    int? fallbackVolumeMl,
    DateTime? fallbackDonatedAt,
    String? fallbackCertificateId,
  }) {
    final source = _sourceFromJson(json['source'] as String?);
    final rawMessages = json['messages'];
    final messages = rawMessages is List<dynamic>
        ? rawMessages
            .whereType<Map<String, dynamic>>()
            .map(GratitudeLetterMessage.fromJson)
            .where((message) => message.body.trim().isNotEmpty)
            .toList(growable: false)
        : const <GratitudeLetterMessage>[];

    return GratitudeLetter(
      id: json['id'] as String? ??
          json['blood_journey_id'] as String? ??
          json['certificate_id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      source: source,
      style: json['style'] as String? ?? _defaultStyleFor(source),
      donorName: json['donor_name'] as String? ?? profile?.name,
      bloodType: json['blood_type'] as String? ?? fallbackBloodType,
      volumeMl: (json['volume_ml'] as num?)?.toInt() ?? fallbackVolumeMl,
      hospitalName: json['hospital_name'] as String? ?? fallbackHospitalName,
      donatedAt: _parseDate(json['donated_at']) ?? fallbackDonatedAt,
      certificateId: json['certificate_id'] as String? ?? fallbackCertificateId,
      bloodJourneyId: json['blood_journey_id'] as String?,
      conversationId: json['conversation_id']?.toString(),
      messages: messages.isNotEmpty ? messages : [_fallbackMessageFor(source)],
    );
  }

  static GratitudeLetter? maybeFromNotification(
    MobileNotification notification, {
    DonorProfile? profile,
  }) {
    final card = notification.payload['gratitude_card'];
    if (card is Map<String, dynamic>) {
      return GratitudeLetter.fromCardJson(card, profile: profile);
    }

    if (notification.type == 'post_donation_checkup') {
      return GratitudeLetter(
        id: 'notification-${notification.id}',
        source: GratitudeLetterSource.regular,
        style: 'classic',
        donorName: profile?.name,
        bloodType: notification.payload['blood_type'] as String?,
        volumeMl: (notification.payload['volume_ml'] as num?)?.toInt(),
        certificateId: notification.payload['certificate_id'] as String?,
        conversationId: notification.payload['conversation_id']?.toString(),
        messages: [
          GratitudeLetterMessage(
            sender: 'PulseLink',
            title: 'Thư cảm ơn từ PulseLink',
            body: notification.body,
            signature: 'PulseLink Team',
          ),
        ],
      );
    }

    if (notification.type == 'blood_journey_completed') {
      final source = notification.payload['destination_type'] == 'reserve'
          ? GratitudeLetterSource.sosReserve
          : GratitudeLetterSource.sosPatient;
      return GratitudeLetter(
        id: 'notification-${notification.id}',
        source: source,
        style: _defaultStyleFor(source),
        donorName: profile?.name,
        bloodJourneyId: notification.payload['blood_journey_id'] as String?,
        messages: [
          GratitudeLetterMessage(
            sender: source == GratitudeLetterSource.sosReserve
                ? 'Bệnh viện tiếp nhận'
                : 'Người nhà bệnh nhân',
            title: source == GratitudeLetterSource.sosReserve
                ? 'Lời cảm ơn từ bệnh viện'
                : 'Lời cảm ơn từ người nhà',
            body: notification.body,
            signature: source == GratitudeLetterSource.sosReserve
                ? 'Đội ngũ y tế'
                : 'Gia đình người nhận máu',
          ),
        ],
      );
    }

    return null;
  }

  final String id;
  final GratitudeLetterSource source;
  final String style;
  final List<GratitudeLetterMessage> messages;
  final String? donorName;
  final String? bloodType;
  final int? volumeMl;
  final String? hospitalName;
  final DateTime? donatedAt;
  final String? certificateId;
  final String? bloodJourneyId;
  final String? conversationId;

  bool get isSos => source.isSos;
  bool get hasCareConversation =>
      conversationId != null && conversationId!.isNotEmpty;

  String get heroTitle {
    if (source == GratitudeLetterSource.regular) {
      return 'Cảm ơn bạn, hiệp sĩ sẻ chia!';
    }
    if (source == GratitudeLetterSource.sosPulseLink) {
      return 'PulseLink gửi bạn một lá thư';
    }
    return 'Cảm ơn bạn, hiệp sĩ cứu người!';
  }

  String get heroSubtitle {
    if (source == GratitudeLetterSource.sosPulseLink) {
      return 'Bệnh viện đã ghi nhận nghĩa cử của bạn. Trước khi hành trình giọt máu tiếp tục, đội ngũ PulseLink muốn gửi lời cảm ơn đầu tiên tới bạn.';
    }
    if (source == GratitudeLetterSource.sosPatient) {
      return 'Giọt máu bạn trao đi đã đi qua một hành trình cấp bách và chạm tới một gia đình đang chờ hy vọng.';
    }
    if (source == GratitudeLetterSource.sosReserve) {
      return 'Giọt máu bạn trao đi đã được lưu giữ an toàn để sẵn sàng cứu người ở khoảnh khắc tiếp theo.';
    }
    return 'Mỗi giọt máu bạn hiến tặng là một cơ hội sống được trao đi.';
  }

  GratitudeLetter copyWithStyle(String value) {
    return GratitudeLetter(
      id: id,
      source: source,
      style: value,
      messages: messages,
      donorName: donorName,
      bloodType: bloodType,
      volumeMl: volumeMl,
      hospitalName: hospitalName,
      donatedAt: donatedAt,
      certificateId: certificateId,
      bloodJourneyId: bloodJourneyId,
      conversationId: conversationId,
    );
  }
}

GratitudeLetterSource _sourceFromJson(String? value) {
  return switch (value) {
    'sos_pulselink' => GratitudeLetterSource.sosPulseLink,
    'sos_patient' => GratitudeLetterSource.sosPatient,
    'sos_reserve' => GratitudeLetterSource.sosReserve,
    _ => GratitudeLetterSource.regular,
  };
}

String _defaultStyleFor(GratitudeLetterSource source) {
  return switch (source) {
    GratitudeLetterSource.regular => 'classic',
    GratitudeLetterSource.sosPulseLink => 'hero_night',
    GratitudeLetterSource.sosPatient => 'hero_night',
    GratitudeLetterSource.sosReserve => 'botanical',
  };
}

GratitudeLetterMessage _fallbackMessageFor(GratitudeLetterSource source) {
  return GratitudeLetterMessage(
    sender: source == GratitudeLetterSource.regular ||
            source == GratitudeLetterSource.sosPulseLink
        ? 'PulseLink'
        : source == GratitudeLetterSource.sosReserve
            ? 'Bệnh viện tiếp nhận'
            : 'Người nhà bệnh nhân',
    title: source == GratitudeLetterSource.regular ||
            source == GratitudeLetterSource.sosPulseLink
        ? 'Thư cảm ơn từ PulseLink'
        : source == GratitudeLetterSource.sosReserve
            ? 'Lời cảm ơn từ bệnh viện'
            : 'Lời cảm ơn từ người nhà',
    body: source == GratitudeLetterSource.regular
        ? _regularFallback(null, null, null)
        : source == GratitudeLetterSource.sosPulseLink
            ? _pulseLinkSosFallback(false)
            : _sosFallback(source == GratitudeLetterSource.sosReserve),
    signature: source == GratitudeLetterSource.regular ||
            source == GratitudeLetterSource.sosPulseLink
        ? 'Đội ngũ PulseLink'
        : source == GratitudeLetterSource.sosReserve
            ? 'Đội ngũ y tế'
            : 'Gia đình người nhận máu',
  );
}

String _regularFallback(
    int? volumeMl, String? bloodType, String? hospitalName) {
  final volume = volumeMl == null ? 'một đơn vị' : '${volumeMl}ml';
  final blood = bloodType == null ? '' : ' nhóm $bloodType';
  final place = hospitalName == null ? '' : ' tại $hospitalName';
  return 'Cảm ơn bạn đã trao đi $volume máu$blood$place. Món quà thầm lặng này giúp ngân hàng máu có thêm hy vọng cho những ca điều trị tiếp theo.';
}

String _sosFallback(bool isReserve) {
  if (isReserve) {
    return 'Bệnh viện xin cảm ơn bạn vì đã có mặt đúng lúc. Đơn vị máu của bạn đã được lưu giữ an toàn, sẵn sàng tiếp sức cho những bệnh nhân cần máu khẩn cấp.';
  }
  return 'Gia đình chúng tôi xin gửi lời cảm ơn chân thành nhất. Sự có mặt của bạn trong thời khắc cấp bách đã trao thêm hy vọng cho người thân của chúng tôi.';
}

String _pulseLinkSosFallback(bool isReserve) {
  if (isReserve) {
    return 'PulseLink cảm ơn bạn vì nghĩa cử bình tĩnh và đầy trách nhiệm. Giọt máu của bạn đang nằm trong tuyến dự phòng quý giá để sẵn sàng cứu người.';
  }
  return 'PulseLink cảm ơn bạn vì đã đáp lại lời gọi SOS. Trong những phút cấp bách nhất, bạn đã biến lòng tốt thành một cơ hội sống thật sự.';
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _stringFromMap(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is String && value.trim().isNotEmpty ? value : null;
}

int? _intFromMap(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is num ? value.toInt() : null;
}

String? _messageBodyFromCard(
  Map<String, dynamic>? json, {
  required String sender,
}) {
  final messages = json?['messages'];
  if (messages is! List<dynamic>) return null;

  for (final item in messages.whereType<Map<String, dynamic>>()) {
    if (item['sender'] != sender) continue;
    final body = item['body'];
    if (body is String && body.trim().isNotEmpty) return body;
  }

  return null;
}
