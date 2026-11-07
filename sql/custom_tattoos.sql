-- Non-destructive beta-3 migration. Character-specific ownership.
CREATE TABLE IF NOT EXISTS `dtgrid_custom_tattoos` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(80) NOT NULL,
    `kind` VARCHAR(8) NOT NULL,
    `label` VARCHAR(64) NOT NULL,
    `image_png` MEDIUMTEXT NOT NULL,
    `thumbnail_png` TEXT NOT NULL,
    `transform_json` JSON NOT NULL,
    `collection` VARCHAR(64) DEFAULT NULL,
    `hash_male` VARCHAR(96) DEFAULT NULL,
    `hash_female` VARCHAR(96) DEFAULT NULL,
    `render_status` ENUM('pending', 'ready') NOT NULL DEFAULT 'pending',
    `paid` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_dtgrid_custom_tattoos_owner` (`citizenid`, `paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
