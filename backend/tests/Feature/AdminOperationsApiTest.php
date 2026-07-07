<?php

namespace Tests\Feature;

use App\Models\CommunityPost;
use App\Models\ChatConversation;
use App\Models\DonationAppointment;
use App\Models\DonationEvent;
use App\Models\DonationHistory;
use App\Models\Hospital;
use App\Models\MobileNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminOperationsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_upload_accepts_images_and_rejects_invalid_files(): void
    {
        Storage::fake('public');
        $this->seed();

        $this->postJson('/api/admin/uploads', [
            'file' => UploadedFile::fake()->image('su-kien.jpg'),
        ])
            ->assertCreated()
            ->assertJsonStructure(['data' => ['path', 'url']]);

        $this->postJson('/api/admin/uploads', [
            'file' => UploadedFile::fake()->create('khong-hop-le.pdf', 32, 'application/pdf'),
        ])->assertUnprocessable();
    }

    public function test_admin_posts_are_paginated_searchable_and_editable(): void
    {
        $this->seed();

        $this->getJson('/api/admin/community-posts?per_page=2&status=published&q=hiến')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonStructure(['data', 'links', 'meta']);

        $post = CommunityPost::query()->where('status', 'published')->firstOrFail();

        $this->putJson("/api/admin/community-posts/{$post->id}", [
            'title' => 'Cập nhật hướng dẫn hiến máu an toàn',
            'excerpt' => 'Bản cập nhật dành cho tình nguyện viên.',
            'content' => 'Nội dung đã được cập nhật để kiểm thử chức năng sửa bài viết.',
            'status' => 'draft',
            'audience_type' => 'all',
        ])
            ->assertOk()
            ->assertJsonPath('data.title', 'Cập nhật hướng dẫn hiến máu an toàn')
            ->assertJsonPath('data.status', 'draft');
    }

    public function test_admin_events_are_paginated_and_lock_sensitive_fields_after_booking(): void
    {
        $this->seed();

        $systemAdmin = User::query()->where('email', 'system@pulselink.test')->firstOrFail();
        $choRayStaff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $bachMai = Hospital::query()->where('code', 'BM-01')->firstOrFail();
        $bachMaiEvent = DonationEvent::query()->where('hospital_id', $bachMai->id)->firstOrFail();

        $this->getJson('/api/admin/donation-events?per_page=2&status=upcoming&q=hiến')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonStructure(['data', 'links', 'meta']);

        $this->getJson("/api/admin/donation-events?admin_user_id={$systemAdmin->id}&hospital_id={$bachMai->id}&province_code={$bachMai->province_code}")
            ->assertOk()
            ->assertJsonFragment(['id' => (string) $bachMaiEvent->id]);

        $this->getJson("/api/admin/donation-events?admin_user_id={$choRayStaff->id}&hospital_id={$bachMai->id}")
            ->assertOk()
            ->assertJsonMissing(['id' => (string) $bachMaiEvent->id]);

        $event = DonationEvent::query()
            ->where('booked_count', '>', 0)
            ->firstOrFail();
        $originalLocation = $event->location_name;
        $originalLatitude = (float) $event->latitude;

        $this->putJson("/api/admin/donation-events/{$event->id}", [
            'title' => 'Sự kiện đã cập nhật tiêu đề',
            'location_name' => 'Địa điểm không được phép đổi',
            'latitude' => 11.1111,
            'capacity' => $event->booked_count + 5,
        ])
            ->assertOk()
            ->assertJsonPath('data.title', 'Sự kiện đã cập nhật tiêu đề')
            ->assertJsonPath('data.location_name', $originalLocation)
            ->assertJsonPath('data.location.latitude', $originalLatitude);

        $this->putJson("/api/admin/donation-events/{$event->id}", [
            'capacity' => $event->booked_count - 1,
        ])->assertUnprocessable();
    }

    public function test_admin_dashboard_and_staff_are_scoped_by_role(): void
    {
        $this->seed();

        $systemAdmin = User::query()->where('email', 'system@pulselink.test')->firstOrFail();
        $hospitalStaff = User::query()->where('email', 'sos.bachmai@pulselink.test')->firstOrFail();

        $this->getJson("/api/admin/dashboard?admin_user_id={$systemAdmin->id}")
            ->assertOk()
            ->assertJsonCount(Hospital::query()->where('is_active', true)->count(), 'data.hospitals')
            ->assertJsonPath('data.current_admin.role', 'system_admin');

        $this->getJson("/api/admin/dashboard?admin_user_id={$hospitalStaff->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data.hospitals')
            ->assertJsonPath('data.hospitals.0.id', $hospitalStaff->hospital_id)
            ->assertJsonPath('data.current_admin.role', 'hospital_staff');

        $this->getJson("/api/admin/staff?admin_user_id={$hospitalStaff->id}")
            ->assertOk()
            ->assertJsonMissing(['email' => 'admin@pulselink.test'])
            ->assertJsonPath('data.0.hospital_id', $hospitalStaff->hospital_id);
    }

    public function test_admin_can_operate_donation_appointment_workflow_and_result_visibility(): void
    {
        $this->seed();

        $staff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->where('blood_type', 'O+')->firstOrFail();
        $event = DonationEvent::query()
            ->where('hospital_id', $staff->hospital_id)
            ->where('ends_at', '>=', now())
            ->firstOrFail();
        $appointment = DonationAppointment::query()->updateOrCreate(
            ['donation_event_id' => $event->id, 'user_id' => $donor->id],
            ['status' => 'booked', 'booked_at' => now()]
        );
        $event->refreshBookedCount();
        app(\App\Services\Donations\DonationRecognitionService::class)->refreshDonorRecognition($donor);
        $donor->refresh();
        $initialDonations = $donor->total_donations;
        $initialPoints = $donor->points;

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$appointment->id}/check-in?admin_user_id={$staff->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'checked_in');

        $this->postJson("/api/mobile/donation-events/{$event->id}/cancel", [
            'user_id' => $donor->id,
        ])->assertUnprocessable();

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$appointment->id}/complete?admin_user_id={$staff->id}", [
            'volume_ml' => 450,
            'blood_type' => $donor->blood_type,
            'screening_status' => 'eligible',
            'screening_notes' => 'Đủ điều kiện sau khám sàng lọc.',
            'result_summary' => 'Kết quả xét nghiệm tổng quát ổn định.',
            'publish_result' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.volume_ml', 450)
            ->assertJsonPath('data.result_published_at', null);

        $this->assertDatabaseHas('donation_histories', [
            'donation_appointment_id' => $appointment->id,
            'user_id' => $donor->id,
            'volume_ml' => 450,
            'certificate_id' => 'PL-EVENT-'.$event->id.'-'.$appointment->id,
        ]);
        $history = DonationHistory::query()
            ->where('donation_appointment_id', $appointment->id)
            ->firstOrFail();
        $this->assertDatabaseHas('chat_conversations', [
            'user_id' => $donor->id,
            'context_type' => ChatConversation::CONTEXT_POST_DONATION_CHECKUP,
        ]);
        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $donor->id,
            'type' => 'post_donation_checkup',
            'title' => 'Hiến máu thành công',
        ]);
        $this->assertTrue(
            MobileNotification::query()
                ->where('user_id', $donor->id)
                ->where('type', 'post_donation_checkup')
                ->get()
                ->contains(fn (MobileNotification $notification): bool => (int) ($notification->payload['donation_history_id'] ?? 0) === (int) $history->id)
        );
        $donor->refresh();
        $this->assertSame($initialDonations + 1, $donor->total_donations);
        $this->assertSame($initialPoints + 450, $donor->points);

        $this->getJson("/api/mobile/me/donations?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonFragment(['certificate_id' => 'PL-EVENT-'.$event->id.'-'.$appointment->id])
            ->assertJsonMissing(['result_summary' => 'Kết quả xét nghiệm tổng quát ổn định.']);

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$appointment->id}/publish-result?admin_user_id={$staff->id}", [
            'publish_result' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.result_summary', 'Kết quả xét nghiệm tổng quát ổn định.');

        $this->getJson("/api/mobile/me/donations?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonFragment(['result_summary' => 'Kết quả xét nghiệm tổng quát ổn định.']);

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$appointment->id}/complete?admin_user_id={$staff->id}", [
            'volume_ml' => 350,
            'screening_status' => 'eligible',
        ])->assertUnprocessable();
        $this->assertSame(1, DonationHistory::query()->where('donation_appointment_id', $appointment->id)->count());
        $this->assertSame($initialDonations + 1, $donor->refresh()->total_donations);

        $secondDonor = User::query()
            ->where('role', 'donor')
            ->where('id', '!=', $donor->id)
            ->firstOrFail();
        $flexibleAppointment = DonationAppointment::query()->updateOrCreate(
            ['donation_event_id' => $event->id, 'user_id' => $secondDonor->id],
            ['status' => 'no_show', 'booked_at' => now(), 'no_show_at' => now()]
        );

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$flexibleAppointment->id}/check-in?admin_user_id={$staff->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'checked_in')
            ->assertJsonPath('data.no_show_at', null);

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$flexibleAppointment->id}/defer?admin_user_id={$staff->id}", [
            'screening_notes' => 'Tạm hoãn để kiểm tra lại huyết áp.',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'deferred');

        $this->postJson("/api/admin/donation-events/{$event->id}/appointments/{$flexibleAppointment->id}/complete?admin_user_id={$staff->id}", [
            'volume_ml' => 350,
            'blood_type' => $secondDonor->blood_type,
            'screening_status' => 'eligible',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.volume_ml', 350);

        $this->deleteJson("/api/admin/donation-events/{$event->id}?admin_user_id={$staff->id}")
            ->assertUnprocessable();
    }

    public function test_admin_can_cancel_event_without_completed_appointments(): void
    {
        $this->seed();

        $staff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $event = DonationEvent::query()->create([
            'hospital_id' => $staff->hospital_id,
            'title' => 'Lịch hiến có thể hủy',
            'organizer' => 'Pulse Link',
            'starts_at' => now()->addDays(3),
            'ends_at' => now()->addDays(3)->addHours(4),
            'location_name' => 'Bệnh viện demo',
            'province_code' => '79',
            'ward_code' => '27301',
            'latitude' => 10.7565,
            'longitude' => 106.6594,
            'urgency' => 'normal',
            'capacity' => 10,
            'booked_count' => 0,
            'is_published' => true,
        ]);
        $donor = User::query()->where('role', 'donor')->firstOrFail();
        $appointment = DonationAppointment::query()->create([
            'donation_event_id' => $event->id,
            'user_id' => $donor->id,
            'status' => 'booked',
            'booked_at' => now(),
        ]);
        $event->refreshBookedCount();

        $this->deleteJson("/api/admin/donation-events/{$event->id}?admin_user_id={$staff->id}", [
            'cancel_reason' => 'Dời lịch tiếp nhận.',
        ])
            ->assertOk()
            ->assertJsonPath('data.cancel_reason', 'Dời lịch tiếp nhận.');

        $this->assertDatabaseHas('donation_events', [
            'id' => $event->id,
            'is_published' => false,
            'cancel_reason' => 'Dời lịch tiếp nhận.',
        ]);
        $this->assertDatabaseHas('donation_appointments', [
            'id' => $appointment->id,
            'status' => 'cancelled',
            'cancel_reason' => 'Dời lịch tiếp nhận.',
        ]);
    }

    public function test_system_admin_can_manage_hospitals(): void
    {
        $this->seed();

        $systemAdmin = User::query()->where('email', 'system@pulselink.test')->firstOrFail();
        $hospitalStaff = User::query()->where('email', 'sos.bachmai@pulselink.test')->firstOrFail();

        $this->getJson('/api/admin/hospitals?per_page=3&q=Bệnh viện')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 3)
            ->assertJsonStructure(['data', 'links', 'meta']);

        $this->postJson("/api/admin/hospitals?admin_user_id={$hospitalStaff->id}", [
            'name' => 'Bệnh viện Demo không được tạo',
            'code' => 'DENY-01',
            'province_code' => '01',
            'ward_code' => '00082',
            'address' => '1 Test, Hà Nội',
            'latitude' => 21.0283,
            'longitude' => 105.8466,
        ])->assertForbidden();

        $created = $this->postJson("/api/admin/hospitals?admin_user_id={$systemAdmin->id}", [
            'name' => 'Bệnh viện Demo Pulse Link',
            'code' => 'PL-DEMO-01',
            'province_code' => '01',
            'ward_code' => '00082',
            'address' => '40 Tràng Thi, Hà Nội',
            'latitude' => 21.0283,
            'longitude' => 105.8466,
            'contact_phone' => '02430000000',
            'contact_email' => 'demo@pulselink.test',
            'is_active' => true,
        ])
            ->assertCreated()
            ->assertJsonPath('data.code', 'PL-DEMO-01');

        $hospitalId = $created->json('data.id');

        $this->putJson("/api/admin/hospitals/{$hospitalId}?admin_user_id={$systemAdmin->id}", [
            'address' => '42 Tràng Thi, Hà Nội',
            'is_active' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.address', '42 Tràng Thi, Hà Nội');

        $this->deleteJson("/api/admin/hospitals/{$hospitalId}?admin_user_id={$systemAdmin->id}")
            ->assertNoContent();

        $this->assertFalse(Hospital::query()->findOrFail($hospitalId)->is_active);
    }
}
