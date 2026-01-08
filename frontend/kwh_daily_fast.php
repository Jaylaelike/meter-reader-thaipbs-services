<?php
header('Content-Type: application/json; charset=utf-8');

ini_set('display_errors', 0);
error_reporting(E_ALL);
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// ===== Config from Environment Variables =====
$dbHost = getenv('DB_HOST') ?: 'mysql';
$dbUser = getenv('DB_USER') ?: 'root';
$dbPass = getenv('DB_PASSWORD') ?: 'thaipbs';
$dbName = getenv('DB_NAME') ?: 'power_real_a_1';

$deviceId = $_GET['device_id'] ?? 'sensor/3phase10';
$sampleSec = isset($_GET['sample_sec']) ? (int)$_GET['sample_sec'] : 5;

function iso($dt) { return $dt->format('Y-m-d H:i:s'); }

function kwhFastBySum($mysqli, $deviceId, $start, $end, $sampleSec) {
  $sql = "
    SELECT
      ROUND(
        COALESCE(SUM(
          (load_v_r * load_i_r * load_pf_r) +
          (load_v_y * load_i_y * load_pf_y) +
          (load_v_b * load_i_b * load_pf_b)
        ), 0) * ? / 3600000, 3
      ) AS kwh
    FROM full_history
    WHERE device_id = ?
      AND time_key >= ?
      AND time_key <  ?
  ";

  $stmt = $mysqli->prepare($sql);
  $stmt->bind_param("isss", $sampleSec, $deviceId, $start, $end);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return $row ? (float)$row['kwh'] : 0.0;
}

function latestTimeKey($mysqli, $deviceId) {
  $sql = "SELECT time_key FROM full_history WHERE device_id=? ORDER BY time_key DESC LIMIT 1";
  $stmt = $mysqli->prepare($sql);
  $stmt->bind_param("s", $deviceId);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return $row ? $row['time_key'] : null;
}

try {
  set_time_limit(10);

  $mysqli = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
  $mysqli->set_charset("utf8mb4");

  $now = new DateTime('now');
  $todayStart = (new DateTime('today'))->setTime(0,0,0);
  $todayEnd   = (new DateTime('today'))->modify('+1 day')->setTime(0,0,0);

  $yStart = (new DateTime('today'))->modify('-1 day')->setTime(0,0,0);
  $yEnd   = (new DateTime('today'))->setTime(0,0,0);

  $t0 = microtime(true);
  $kwhToday = kwhFastBySum($mysqli, $deviceId, iso($todayStart), iso($todayEnd), $sampleSec);
  $kwhYest  = kwhFastBySum($mysqli, $deviceId, iso($yStart),     iso($yEnd),     $sampleSec);
  $latest   = latestTimeKey($mysqli, $deviceId);
  $ms = round((microtime(true) - $t0) * 1000, 1);

  echo json_encode([
    "status" => "ok",
    "device_id" => $deviceId,
    "sample_sec" => $sampleSec,
    "kwh_today" => $kwhToday,
    "kwh_yesterday" => $kwhYest,
    "latest_time_key" => $latest,
    "elapsed_ms" => $ms
  ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "status" => "error",
    "message" => $e->getMessage()
  ], JSON_UNESCAPED_UNICODE);
}
