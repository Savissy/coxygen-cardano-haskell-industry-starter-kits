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
