# Pulse Link Backend Contract

This document is the first API contract between the Flutter app and the Laravel/Vue admin backend.

## Architecture

- Laravel owns users, hero passes, donation events, booking appointments, donation history, hospital users, and SOS alert records.
- Vue Admin calls Laravel APIs to manage events and trigger emergency alerts from hospital staff screens.
- Firebase/FCM is the realtime fan-out channel for SOS delivery. Laravel writes or mirrors active SOS alerts to Firebase and sends push notifications.
- Flutter reads daily data from Laravel REST APIs and listens to Firebase for realtime SOS mode activation.

## Mobile REST Endpoints

All endpoints are expected to return JSON. Wrapped responses may use `{ "data": ... }`.

### Hero Pass

`GET /api/mobile/me/hero-pass`

```json
{
  "data": {
    "id": "donor-8890",
    "name": "Minh Tri",
    "blood_type": "O+",
    "hero_level": "Silver Badge",
    "badge_title": "Hiep Si Bac",
    "total_donations": 5,
    "last_donation_date": "2026-04-15T00:00:00.000",
    "points": 1250,
    "province_code": "79",
    "province": {
      "code": "79",
      "name": "Hồ Chí Minh",
      "full_name": "Thành phố Hồ Chí Minh"
    },
    "ward_code": "27301",
    "hero_pass_code": "PL-8890-MINHTRI"
  }
}
```

`POST /api/mobile/me/hero-pass`

Updates local profile fields accepted by the backend.

### Donation Events

`GET /api/mobile/donation-events`

```json
{
  "data": [
    {
      "id": "ev-1",
      "title": "Chu Nhat Do - FPT Polytechnic",
      "organizer": "Hoi Chu Thap Do TP.HCM",
      "starts_at": "2026-07-05T07:30:00.000",
      "ends_at": "2026-07-05T11:30:00.000",
      "location_name": "Cong vien phan mem Quang Trung, Quan 12",
      "province_code": "79",
      "province": {
        "code": "79",
        "name": "Hồ Chí Minh",
        "full_name": "Thành phố Hồ Chí Minh"
      },
      "ward_code": "27004",
      "location": { "latitude": 10.8521, "longitude": 106.6297 },
      "distance_km": 1.2,
      "urgency": "high",
      "image_url": "https://example.com/event.jpg",
      "slots_left": 42,
      "booked": false
    }
  ]
}
```

`POST /api/mobile/donation-events/{eventId}/book`

Books an appointment and returns the updated event.

`POST /api/mobile/donation-events/{eventId}/cancel`

Cancels the appointment and returns the updated event.

### Donation History

`GET /api/mobile/me/donations`

`POST /api/mobile/me/donations`

```json
{
  "donated_at": "2026-07-01T00:00:00.000",
  "location_name": "Benh vien Cho Ray",
  "volume_ml": 350,
  "blood_type": "O+",
  "notes": "Health indicators stable"
}
```

## Firebase SOS Document

Collection: `sos_alerts`

Flutter currently expects documents shaped like this:

```json
{
  "id": "sos-001",
  "active": true,
  "blood_types": ["O+", "O-"],
  "hospital_name": "Benh vien Cho Ray",
  "hospital_address": "201B Nguyen Chi Thanh, Quan 5, TP.HCM",
  "hospital_province_code": "79",
  "hospital_location": { "latitude": 10.7565, "longitude": 106.6594 },
  "required_blood_type": "O+",
  "level": "level1",
  "units_needed": 6,
  "created_at": "2026-07-01T13:00:00.000",
  "expires_at": "2026-07-01T13:40:00.000",
  "message": "Bao dong do thieu nhom mau O+ cho ca phau thuat cap cuu."
}
```

Valid `level` values:

- `level1`: radius 5 km
- `level2`: radius 30 km, same province
- `level3`: inter-province support, currently accepted up to 100 km in the app policy

Commitments are written under:

`sos_alerts/{alertId}/commits`

Laravel should also expose this durable commitment endpoint, because Firestore subcollection writes are best treated as realtime signal data rather than the final medical audit log:

`POST /api/mobile/sos-alerts/{alertId}/commit`

Recommended request body:

```json
{
  "donor_id": 2,
  "latitude": 10.7727,
  "longitude": 106.6663,
  "eta_minutes": 12
}
```

## Location Master Data

`GET /api/locations/provinces`

Returns the current 34 province-level administrative units.

`GET /api/locations/provinces/{provinceCode}/wards`

Returns wards for the province code, for example `79`.

`POST /api/locations/normalize`

Maps legacy/common names such as `HCM` or `TP.HCM` to official province codes.

## Route Planning

`POST /api/mobile/routes/plan`

The Flutter app can ask Laravel to calculate the fastest route. This keeps Google Directions or other map provider keys on the server.

Request:

```json
{
  "origin": { "latitude": 10.7727, "longitude": 106.6663 },
  "destination": { "latitude": 10.7565, "longitude": 106.6594 },
  "preferred_distance_km": 2.1
}
```

Response:

```json
{
  "data": {
    "polyline": [
      { "latitude": 10.7727, "longitude": 106.6663 },
      { "latitude": 10.7646, "longitude": 106.6629 },
      { "latitude": 10.7565, "longitude": 106.6594 }
    ],
    "distance_km": 2.1,
    "estimated_minutes": 8,
    "summary": "Priority route via Nguyen Tri Phuong"
  }
}
```
