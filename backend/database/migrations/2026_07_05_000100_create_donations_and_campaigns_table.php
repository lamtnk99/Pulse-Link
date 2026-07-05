<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donation_campaigns', function (Blueprint $table) {
            $table->id();
            $table->string('public_id')->unique();
            $table->string('title');
            $table->text('description');
            $table->string('image_url')->nullable();
            $table->enum('type', ['financial', 'points', 'both'])->default('both');
            $table->decimal('target_amount', 15, 2)->default(0);
            $table->decimal('current_amount', 15, 2)->default(0);
            $table->integer('target_points')->default(0);
            $table->integer('current_points')->default(0);
            $table->enum('status', ['active', 'completed', 'cancelled'])->default('active');
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('campaign_donations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('donation_campaign_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('amount', 15, 2)->default(0);
            $table->integer('points')->default(0);
            $table->string('payment_method'); // 'momo', 'vnpay', 'bank_transfer', 'points'
            $table->enum('payment_status', ['pending', 'success', 'failed'])->default('pending');
            $table->string('transaction_id')->unique()->nullable();
            $table->string('donor_name')->default('Hiệp sĩ ẩn danh');
            $table->string('message')->nullable();
            $table->boolean('is_anonymous')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('campaign_donations');
        Schema::dropIfExists('donation_campaigns');
    }
};
