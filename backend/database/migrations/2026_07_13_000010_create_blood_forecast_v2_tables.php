<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('blood_forecast_runs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
            $table->string('status', 20)->default('queued');
            $table->string('trigger', 20)->default('scheduled');
            $table->string('model_version', 50);
            $table->date('data_start_date')->nullable();
            $table->date('data_end_date')->nullable();
            $table->timestamp('generated_at')->nullable();
            $table->foreignId('generated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->json('scenarios')->nullable();
            $table->json('data_quality')->nullable();
            $table->json('metrics')->nullable();
            $table->text('reasoning_summary')->nullable();
            $table->json('recommendations')->nullable();
            $table->string('ai_provider', 50)->nullable();
            $table->text('error_message')->nullable();
            $table->timestamps();

            $table->index(['hospital_id', 'status', 'generated_at']);
            $table->index(['hospital_id', 'trigger', 'created_at']);
        });

        Schema::table('blood_demand_forecasts', function (Blueprint $table) {
            $table->foreignId('forecast_run_id')->nullable()->after('id')->constrained('blood_forecast_runs')->nullOnDelete();
            $table->decimal('predicted_units', 10, 2)->nullable()->after('blood_type');
            $table->decimal('lower_units', 10, 2)->nullable()->after('predicted_volume_ml');
            $table->decimal('upper_units', 10, 2)->nullable()->after('lower_units');
            $table->decimal('actual_units', 10, 2)->nullable()->after('upper_units');
            $table->string('model_version', 50)->nullable()->after('confidence_score');
            $table->index(['forecast_run_id', 'blood_type', 'target_date'], 'forecast_points_run_type_date_index');
        });

        Schema::create('forecast_recommendations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('forecast_run_id')->constrained('blood_forecast_runs')->cascadeOnDelete();
            $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
            $table->string('blood_type', 10)->nullable();
            $table->string('action_type', 40);
            $table->string('status', 30)->default('suggested');
            $table->string('severity', 20)->default('medium');
            $table->string('title');
            $table->text('rationale');
            $table->date('due_date')->nullable();
            $table->decimal('projected_gap_units', 10, 2)->nullable();
            $table->json('payload')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->text('resolution_note')->nullable();
            $table->timestamps();

            $table->index(['hospital_id', 'status', 'severity']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('forecast_recommendations');

        Schema::table('blood_demand_forecasts', function (Blueprint $table) {
            $table->dropIndex('forecast_points_run_type_date_index');
            $table->dropConstrainedForeignId('forecast_run_id');
            $table->dropColumn(['predicted_units', 'lower_units', 'upper_units', 'actual_units', 'model_version']);
        });

        Schema::dropIfExists('blood_forecast_runs');
    }
};
