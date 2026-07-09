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

        Schema::table($table, function (Blueprint $schema) use ($table, $column, $referencesTable, $uniqueColumns): void {
            if ($uniqueColumns !== null) {
                $schema->dropUnique($uniqueColumns);
            }

            try {
                $schema->dropForeign([$column]);
            } catch (Throwable) {
                // SQLite test databases may not expose Laravel's generated FK name.
            }

            $schema->unsignedBigInteger($column)->nullable()->change();
            $schema->foreign($column)->references('id')->on($referencesTable)->nullOnDelete();

            if ($uniqueColumns !== null) {
                $schema->unique($uniqueColumns);
            }
        });

        if (DB::getDriverName() === 'sqlite') {
            DB::statement('PRAGMA foreign_keys=ON');
        }
    }
};
