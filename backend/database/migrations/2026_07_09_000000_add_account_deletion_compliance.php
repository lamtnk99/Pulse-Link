<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('account_deletion_logs', function (Blueprint $table): void {
            $table->id();
            $table->string('user_hash', 64)->index();
            $table->string('email_hash', 64)->nullable()->index();
            $table->string('role', 32)->nullable();
            $table->string('status', 32)->default('completed')->index();
            $table->text('reason')->nullable();
            $table->timestamp('deleted_at')->index();
        });

        $this->makeNullableUserReference('donation_appointments', 'user_id', 'users', ['donation_event_id', 'user_id']);
        $this->makeNullableUserReference('donation_histories', 'user_id', 'users');
        $this->makeNullableUserReference('emergency_commitments', 'donor_id', 'users', ['emergency_alert_id', 'donor_id']);
        $this->makeNullableUserReference('blood_journeys', 'donor_id', 'users');
    }

    public function down(): void
    {
        Schema::dropIfExists('account_deletion_logs');
    }

    private function makeNullableUserReference(
        string $table,
        string $column,
        string $referencesTable,
        ?array $uniqueColumns = null,
    ): void {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, $column)) {
            return;
        }

        if (DB::getDriverName() === 'sqlite') {
            DB::statement('PRAGMA foreign_keys=OFF');
        }

        // MySQL may use the leftmost column of the composite unique key to
        // enforce another foreign key. Keep an explicit index before removing
        // that unique key.
        if ($uniqueColumns !== null && ! Schema::hasIndex($table, [$uniqueColumns[0]])) {
            Schema::table($table, function (Blueprint $schema) use ($uniqueColumns): void {
                $schema->index($uniqueColumns[0]);
            });
        }

        Schema::table($table, function (Blueprint $schema) use ($column): void {
            try {
                $schema->dropForeign([$column]);
            } catch (Throwable) {
                // SQLite test databases may not expose Laravel's generated FK name.
            }
        });

        if ($uniqueColumns !== null && Schema::hasIndex($table, $uniqueColumns, 'unique')) {
            Schema::table($table, function (Blueprint $schema) use ($uniqueColumns): void {
                $schema->dropUnique($uniqueColumns);
            });
        }

        Schema::table($table, function (Blueprint $schema) use ($column): void {
            $schema->unsignedBigInteger($column)->nullable()->change();
        });

        Schema::table($table, function (Blueprint $schema) use ($table, $column, $referencesTable, $uniqueColumns): void {
            $schema->foreign($column)->references('id')->on($referencesTable)->nullOnDelete();

            if ($uniqueColumns !== null && ! Schema::hasIndex($table, $uniqueColumns, 'unique')) {
                $schema->unique($uniqueColumns);
            }
        });

        if (DB::getDriverName() === 'sqlite') {
            DB::statement('PRAGMA foreign_keys=ON');
        }
    }
};
