<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // SQLite applies DDL immediately. If a prior run stopped at the
        // unique index below, the ledger table already exists although this
        // migration is still marked as pending.
        if (! Schema::hasTable('blood_stock_movements')) {
            Schema::create('blood_stock_movements', function (Blueprint $table) {
                $table->id();
                $table->foreignId('hospital_id')->constrained('hospitals')->cascadeOnDelete();
                $table->foreignId('blood_stock_id')->nullable()->constrained('blood_stocks')->nullOnDelete();
                $table->foreignId('donation_history_id')->nullable()->constrained('donation_histories')->nullOnDelete();
                $table->string('blood_type', 10);
                $table->string('movement_type', 50);
                $table->string('from_status', 30)->nullable();
                $table->string('to_status', 30)->nullable();
                $table->integer('quantity_units')->default(1);
                $table->integer('volume_ml')->default(350);
                $table->integer('available_delta')->default(0);
                $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('source_type', 100)->nullable();
                $table->unsignedBigInteger('source_id')->nullable();
                $table->string('idempotency_key')->unique();
                $table->boolean('is_synthetic')->default(false);
                $table->string('notes', 1000)->nullable();
                $table->json('metadata')->nullable();
                $table->timestamp('occurred_at');
                $table->timestamps();

                $table->index(['hospital_id', 'blood_type', 'occurred_at']);
                $table->index(['blood_stock_id', 'occurred_at']);
                $table->index(['movement_type', 'occurred_at']);
            });
        }

        // Legacy seed and operational data may contain multiple blood-stock
        // rows for the same donation. Keep the earliest stock linked to the
        // donor record and preserve the remaining units as unlinked legacy
        // inventory; no physical stock is deleted by this migration.
        $duplicates = DB::table('blood_stocks')
            ->whereNotNull('donation_history_id')
            ->select('donation_history_id', DB::raw('MIN(id) as kept_stock_id'))
            ->groupBy('donation_history_id')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        foreach ($duplicates as $duplicate) {
            DB::table('blood_stocks')
                ->where('donation_history_id', $duplicate->donation_history_id)
                ->where('id', '!=', $duplicate->kept_stock_id)
                ->update([
                    'donation_history_id' => null,
                    'updated_at' => now(),
                ]);
        }

        Schema::table('blood_stocks', function (Blueprint $table) {
            $table->unique('donation_history_id', 'blood_stocks_donation_history_unique');
        });
    }

    public function down(): void
    {
        Schema::table('blood_stocks', function (Blueprint $table) {
            $table->dropUnique('blood_stocks_donation_history_unique');
        });

        Schema::dropIfExists('blood_stock_movements');
    }
};
