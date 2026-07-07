<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Bảng quản lý kho túi máu
        Schema::create('blood_stocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
            $table->string('blood_type', 10);
            $table->integer('volume_ml')->default(350);
            $table->date('received_date');
            $table->date('expiry_date');
            $table->string('status', 30)->default('available'); // available, used, expired, allocated
            $table->foreignId('donation_history_id')->nullable()->constrained('donation_histories')->nullOnDelete();
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->index(['hospital_id', 'blood_type', 'status']);
            $table->index('expiry_date');
        });

        // 2. Bảng cấu hình ngưỡng an toàn cho từng nhóm máu tại bệnh viện
        Schema::create('blood_safety_thresholds', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
            $table->string('blood_type', 10);
            $table->integer('min_units')->default(15); // Ngưỡng an toàn tối thiểu (theo đơn vị túi máu)
            $table->timestamps();

            $table->unique(['hospital_id', 'blood_type']);
        });

        // 3. Bảng lưu trữ lịch sử dự báo nhu cầu của AI
        Schema::create('blood_demand_forecasts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
            $table->date('forecast_date'); // Ngày chạy phân tích dự báo
            $table->date('target_date');   // Ngày cần dự báo nhu cầu
            $table->string('blood_type', 10);
            $table->integer('predicted_volume_ml'); // Thể tích dự đoán cần dùng (ml)
            $table->double('confidence_score', 8, 2)->default(0.8); // Độ tin cậy (0.0 đến 1.0)
            $table->text('explanation')->nullable(); // Giải thích từ AI
            $table->timestamps();

            $table->index(['hospital_id', 'forecast_date']);
        });

        // 4. Bảng ghi nhận cảnh báo thông minh tự động
        Schema::create('smart_alerts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
            $table->string('blood_type', 10);
            $table->integer('current_units');
            $table->integer('threshold_units');
            $table->string('status', 30)->default('active'); // active, resolved, mobilized
            $table->timestamp('triggered_at');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->index(['hospital_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('smart_alerts');
        Schema::dropIfExists('blood_demand_forecasts');
        Schema::dropIfExists('blood_safety_thresholds');
        Schema::dropIfExists('blood_stocks');
    }
};
