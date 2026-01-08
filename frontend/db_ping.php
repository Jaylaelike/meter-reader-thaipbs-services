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

$deviceId = isset($_GET["device_id"]) ? trim($_GET["device_id"]) : "";

try {
  set_time_limit(5);

  $mysqli = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
  $mysqli->set_charset("utf8mb4");

  if ($deviceId !== "") {
    $sql = "SELECT time_key FROM full_history WHERE device_id = ? ORDER BY time_key DESC LIMIT 1";
    $stmt = $mysqli->prepare($sql);
    $stmt->bind_param("s", $deviceId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
  } else {
    $sql = "SELECT time_key FROM full_history ORDER BY time_key DESC LIMIT 1";
    $row = $mysqli->query($sql)->fetch_assoc();
  }

  echo json_encode([
    "status" => "ok",
    "db" => $dbName,
    "table" => "full_history",
    "device_id" => $deviceId,
    "latest_time_key" => $row ? $row["time_key"] : null
  ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    "status" => "error",
    "message" => $e->getMessage()
  ], JSON_UNESCAPED_UNICODE);
}
