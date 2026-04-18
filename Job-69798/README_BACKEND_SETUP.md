# Insurance Finance Backend Setup (PHP + MySQL + Sessions + CSRF + SMTP)

## 1) Windows + XAMPP + phpMyAdmin Checklist

1. Install XAMPP (PHP 8.1+ recommended) and start **Apache** + **MySQL**.
2. Copy this repo into `C:\xampp\htdocs\Defi-Insurance`.
3. Open phpMyAdmin (`http://localhost/phpmyadmin`), create DB: `insurance_finance`.
4. Import SQL schema (section below) into `insurance_finance`.
5. In repo root run Composer:
   - `composer require phpmailer/phpmailer`
6. Update `config.php`:
   - `app.url`
   - DB credentials
   - SMTP credentials
   - admin email allowlist
   - `dev_bypass_email_verification` for local dev only
7. Ensure upload directory exists and is writable:
   - `storage/kyc_uploads`
8. Open app:
   - Landing: `http://localhost/Defi-Insurance/index.html`
   - Launch routing: `http://localhost/Defi-Insurance/launch.php`

## 2) SQL Schema

```sql
CREATE TABLE `admins` (
  `id` int(10) UNSIGNED NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','reviewer') NOT NULL DEFAULT 'reviewer',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `admin_claim_reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `asset_unit` varchar(255) NOT NULL,
  `status` enum('pending','rejected','executed') NOT NULL DEFAULT 'pending',
  `reason` text DEFAULT NULL,
  `tx_hash` varchar(64) DEFAULT NULL,
  `acted_by_admin_id` int(10) UNSIGNED DEFAULT NULL,
  `acted_by_role` enum('admin','reviewer') DEFAULT NULL,
  `acted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `claim_descriptions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `asset_unit` varchar(255) DEFAULT NULL,
  `wallet_address` varchar(255) DEFAULT NULL,
  `description` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `claim_documents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `actor_wallet_address` varchar(255) DEFAULT NULL,
  `file_hash_hex` char(64) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `mime_type` varchar(150) NOT NULL,
  `file_size` int(10) UNSIGNED NOT NULL,
  `file_blob` longblob NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `asset_unit` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `document_url` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `cover_purchases` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `wallet_address` varchar(255) NOT NULL,
  `protocol_name` varchar(100) NOT NULL,
  `coverage_amount_ada` decimal(18,2) NOT NULL,
  `premium_amount_ada` decimal(18,2) NOT NULL,
  `duration_days` int(11) NOT NULL,
  `start_date` datetime NOT NULL DEFAULT current_timestamp(),
  `end_date` datetime NOT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'active',
  `tx_hash` varchar(128) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `email_verifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `insurance_transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `tx_hash` varchar(64) NOT NULL,
  `action_type` enum('deposit_pool','withdraw_shares','submit_claim','vote_claim','execute_claim','mint_membership_sbt') NOT NULL,
  `reference_id` varchar(255) DEFAULT NULL,
  `actor_wallet_address` varchar(255) NOT NULL,
  `counterparty_wallet_address` varchar(255) DEFAULT NULL,
  `amount_lovelace` bigint(20) UNSIGNED DEFAULT NULL,
  `asset_unit` varchar(255) NOT NULL DEFAULT 'lovelace',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `status` enum('submitted','confirmed','failed') NOT NULL DEFAULT 'submitted',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `kyc_submissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `phone_number` varchar(50) NOT NULL,
  `country` varchar(100) NOT NULL,
  `business_name` varchar(255) DEFAULT NULL,
  `id_document_path` varchar(255) DEFAULT NULL,
  `id_document_mime` varchar(100) DEFAULT NULL,
  `id_document_size` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_by_admin_id` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `review_note` text DEFAULT NULL,
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `wallet_address` varchar(255) DEFAULT NULL,
  `wallet_address_hash` char(64) DEFAULT NULL,
  `wallet_verified_at` datetime DEFAULT NULL,
  `role` enum('user','admin') NOT NULL DEFAULT 'user',
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `user_wallets` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(11) NOT NULL,
  `wallet_address` varchar(255) NOT NULL,
  `wallet_address_hash` char(64) NOT NULL,
  `status` enum('pending','verified','revoked') NOT NULL DEFAULT 'pending',
  `verified_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `last_connected` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

```

> Admin approach used: allowlist emails in `config.php` (`security.admin_email_allowlist`) and/or set `users.role='admin'`.

## 3) Route Flow Implemented

- `index.html` Launch buttons route to `launch.php`.
- `launch.php` gates by:
  - not logged in -> `/login.php`
  - unverified -> `/verify_notice.php` (unless dev bypass)
  - KYC not approved -> `/kyc_status.php`
  - verified + approved -> `/main.html`

## 4) Frontend Wiring Notes

Already wired in code:
- `main.html` stats placeholders + recent transactions table + wallet lookup section.
- `app.js`:
  - `ensureRegisteredWalletOrFail(address)` via `wallet_status.php`
  - `bindWalletToAccount()` via `wallet_challenge.php` + `wallet_bind.php`
  - logs all tx actions to `log_tx.php`
  - loads `stats.php` and `recent_transactions.php`
  - wallet lookup via `tx_history.php`
- `mint.js` logs `mint_membership_sbt`

## 5) Security Measures Implemented

- PDO prepared statements everywhere
- `password_hash`/`password_verify`
- `session_regenerate_id(true)` on login/verify
- CSRF on all POST forms
- verification token stored as sha256 hash
- upload validation MIME + max 5MB + random filename
- no raw stack traces to client; errors logged via `error_log`

## 6) End-to-End Test Plan

1. Register new user (`/register.php`).
2. Verify received email link (`/verify.php?token=...`) or dev bypass in config.
3. Submit KYC (`/kyc.php`) with PDF/JPG/PNG.
4. Login as admin (`/admin/login.php`), approve in dashboard.
5. User reaches `main.html`.
6. Connect wallet; first connect signs bind challenge and stores wallet.
7. Try different wallet for same account -> blocked by wallet status enforcement.
8. Run dApp actions: mint membership, deposit, withdraw, submit claim, vote, execute.
9. Confirm `stats.php` values update and recent tx table updates.
10. Test wallet history lookup with `tx_history.php?address=...`.
