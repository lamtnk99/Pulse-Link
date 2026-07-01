# Pulse Link Backend

Laravel 11 backend for Pulse Link.

## Setup

```bash
composer install
copy .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve
php artisan reverb:start
```

## Implemented

- Database schema for users, hospitals, donation events, appointments, histories, emergency alerts, recipients, commitments, and audit logs.
- Clean architecture split:
  - `app/Domain`
  - `app/Repositories`
  - `app/Services`
  - `app/Http`
- Inter-provincial wave dispatch:
  - `local5km`
  - `province30km`
  - `inter_province`
- Reverb broadcasting events:
  - `emergency.alert.activated`
  - `emergency.commitment.updated`
- FCM gateway abstraction via HTTP v1.

## Useful Commands

```bash
php artisan route:list --path=api
php artisan channel:list
php artisan test
```
