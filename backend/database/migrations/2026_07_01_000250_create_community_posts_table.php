<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('donation_events', function (Blueprint $table) {
            $table->text('description')->nullable();
        });

        Schema::create('community_posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('excerpt')->nullable();
            $table->longText('content');
            $table->string('image_url')->nullable();
            $table->enum('status', ['draft', 'published'])->default('draft')->index();
            $table->timestamp('published_at')->nullable()->index();
            $table->enum('audience_type', ['all', 'blood_type', 'hero_level', 'province'])->default('all')->index();
            $table->string('target_blood_type', 4)->nullable()->index();
            $table->string('target_hero_level')->nullable()->index();
            $table->string('province_code', 2)->nullable()->index();
            $table->string('ward_code', 5)->nullable()->index();
            $table->unsignedInteger('views_count')->default(0);
            $table->unsignedInteger('shares_count')->default(0);
            $table->timestamps();

            $table->foreign('province_code')->references('code')->on('provinces')->nullOnDelete();
            $table->foreign('ward_code')->references('code')->on('wards')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('community_posts');

        Schema::table('donation_events', function (Blueprint $table) {
            $table->dropColumn('description');
        });
    }
};
