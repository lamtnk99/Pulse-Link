<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreEmergencyAlertRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'hospital_id' => ['required', 'integer', 'exists:hospitals,id'],
            'required_blood_type' => ['required', 'in:O-,O+,A-,A+,B-,B+,AB-,AB+'],
            'compatibility_mode' => ['nullable', 'in:exact,compatible'],
            'level' => ['required', 'in:level1,level2,level3'],
            'units_needed' => ['required', 'integer', 'min:1', 'max:99'],
            'message' => ['required', 'string', 'max:1000'],
            'expires_at' => ['required', 'date', 'after:now'],
            'created_by' => ['nullable', 'integer', 'exists:users,id'],
        ];
    }
}
