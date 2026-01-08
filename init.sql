-- Database initialization for power_real_a_1
-- This file is executed automatically by MySQL Docker on first startup

SET time_zone = '+07:00';

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS `power_real_a_1` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `power_real_a_1`;

-- Main history table for raw sensor data
CREATE TABLE IF NOT EXISTS `full_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `load_v_r` DECIMAL(8,2) NULL,
  `load_v_y` DECIMAL(8,2) NULL,
  `load_v_b` DECIMAL(8,2) NULL,
  `load_v3_r` DECIMAL(8,2) NULL,
  `load_v3_y` DECIMAL(8,2) NULL,
  `load_v3_b` DECIMAL(8,2) NULL,
  `load_i_r` DECIMAL(10,2) NULL,
  `load_i_y` DECIMAL(10,2) NULL,
  `load_i_b` DECIMAL(10,2) NULL,
  `load_freq` DECIMAL(6,2) NULL,
  `load_pf_t` DECIMAL(6,3) NULL,
  `load_pf_r` DECIMAL(6,3) NULL,
  `load_pf_y` DECIMAL(6,3) NULL,
  `load_pf_b` DECIMAL(6,3) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_device_time` (`device_id`, `time_key`),
  KEY `idx_time_key` (`time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Summary tables for aggregated data
CREATE TABLE IF NOT EXISTS `summary_minute` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATETIME NOT NULL,
  `avg_kw` DECIMAL(12,4) DEFAULT 0,
  `total_kwh` DECIMAL(12,6) DEFAULT 0,
  `counter` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`),
  KEY `idx_time_key` (`time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `summary_hourly` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATETIME NOT NULL,
  `avg_kw` DECIMAL(12,4) DEFAULT 0,
  `total_kwh` DECIMAL(12,6) DEFAULT 0,
  `counter` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`),
  KEY `idx_time_key` (`time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `summary_daily` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATE NOT NULL,
  `avg_kw` DECIMAL(12,4) DEFAULT 0,
  `total_kwh` DECIMAL(12,6) DEFAULT 0,
  `counter` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`),
  KEY `idx_time_key` (`time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `summary_monthly` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATE NOT NULL,
  `avg_kw` DECIMAL(12,4) DEFAULT 0,
  `total_kwh` DECIMAL(12,6) DEFAULT 0,
  `counter` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`),
  KEY `idx_time_key` (`time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `summary_yearly` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATE NOT NULL,
  `avg_kw` DECIMAL(12,4) DEFAULT 0,
  `total_kwh` DECIMAL(12,6) DEFAULT 0,
  `counter` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`),
  KEY `idx_time_key` (`time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Event summary tables
CREATE TABLE IF NOT EXISTS `event_summary_daily` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATE NOT NULL,
  `grid_failures` INT UNSIGNED DEFAULT 0,
  `gen_starts` INT UNSIGNED DEFAULT 0,
  `load_failures` INT UNSIGNED DEFAULT 0,
  `last_failure_time` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_summary_monthly` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATE NOT NULL,
  `grid_failures` INT UNSIGNED DEFAULT 0,
  `gen_starts` INT UNSIGNED DEFAULT 0,
  `load_failures` INT UNSIGNED DEFAULT 0,
  `last_failure_time` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_summary_yearly` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `time_key` DATE NOT NULL,
  `grid_failures` INT UNSIGNED DEFAULT 0,
  `gen_starts` INT UNSIGNED DEFAULT 0,
  `load_failures` INT UNSIGNED DEFAULT 0,
  `last_failure_time` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_time` (`device_id`, `time_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Event timeline for detailed event logging
CREATE TABLE IF NOT EXISTS `event_timeline` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `event_time` DATETIME NOT NULL,
  `event_type` VARCHAR(50) NOT NULL,
  `voltage_r` DECIMAL(8,2) NULL,
  `voltage_y` DECIMAL(8,2) NULL,
  `voltage_b` DECIMAL(8,2) NULL,
  `voltage_3ph_r` DECIMAL(8,2) NULL,
  `voltage_3ph_y` DECIMAL(8,2) NULL,
  `voltage_3ph_b` DECIMAL(8,2) NULL,
  `frequency` DECIMAL(6,2) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_device_time` (`device_id`, `event_time`),
  KEY `idx_event_type` (`event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Summary history table for hourly snapshots
CREATE TABLE IF NOT EXISTS `summary_history_table` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(64) NOT NULL,
  `datetime` DATETIME NOT NULL,
  `main_voltage_r` DECIMAL(8,2) NULL,
  `main_voltage_y` DECIMAL(8,2) NULL,
  `main_voltage_b` DECIMAL(8,2) NULL,
  `main_voltage_3ph_r` DECIMAL(8,2) NULL,
  `main_voltage_3ph_y` DECIMAL(8,2) NULL,
  `main_voltage_3ph_b` DECIMAL(8,2) NULL,
  `gen_voltage_r` DECIMAL(8,2) NULL,
  `gen_voltage_y` DECIMAL(8,2) NULL,
  `gen_voltage_b` DECIMAL(8,2) NULL,
  `gen_voltage_3ph_r` DECIMAL(8,2) NULL,
  `gen_voltage_3ph_y` DECIMAL(8,2) NULL,
  `gen_voltage_3ph_b` DECIMAL(8,2) NULL,
  `load_voltage_r` DECIMAL(8,2) NULL,
  `load_voltage_y` DECIMAL(8,2) NULL,
  `load_voltage_b` DECIMAL(8,2) NULL,
  `load_voltage_3ph_r` DECIMAL(8,2) NULL,
  `load_voltage_3ph_y` DECIMAL(8,2) NULL,
  `load_voltage_3ph_b` DECIMAL(8,2) NULL,
  `load_current_r` DECIMAL(10,2) NULL,
  `load_current_y` DECIMAL(10,2) NULL,
  `load_current_b` DECIMAL(10,2) NULL,
  `load_freq` DECIMAL(6,2) NULL,
  `grid_freq` DECIMAL(6,2) NULL,
  `gen_freq` DECIMAL(6,2) NULL,
  `status` VARCHAR(20) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_device_datetime` (`device_id`, `datetime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
