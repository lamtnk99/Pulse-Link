<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Str;

class AppSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
    ];

    public static function get(string $key, $default = null)
    {
        $setting = self::where('key', $key)->first();
        if (!$setting) {
            return $default;
        }

        $value = $setting->value;
        if (empty($value)) {
            return $value;
        }

        // Auto decrypt if it is an API key
        if (Str::endsWith($key, '_api_key')) {
            try {
                return Crypt::decryptString($value);
            } catch (\Exception $e) {
                return $value; // Fallback to raw if not encrypted yet
            }
        }

        return $value;
    }

    public static function set(string $key, $value): self
    {
        $setting = self::firstOrNew(['key' => $key]);

        if (!empty($value) && Str::endsWith($key, '_api_key')) {
            // Mask raw input if it was already masked (prevent double encrypting mask)
            if (Str::startsWith($value, 'sk-') && Str::contains($value, '***')) {
                // Do not update the key if it was just the masked string sent back
                return $setting;
            }
            $setting->value = Crypt::encryptString($value);
        } else {
            $setting->value = $value;
        }

        $setting->save();
        return $setting;
    }
}
