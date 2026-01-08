<?php
header('Content-Type: application/json; charset=utf-8');

// ===== Config from Environment Variables =====
$dbHost = getenv('DB_HOST') ?: 'mysql';
$dbUser = getenv('DB_USER') ?: 'root';
$dbPass = getenv('DB_PASSWORD') ?: 'thaipbs';
$dbName = getenv('DB_NAME') ?: 'power_real_a_1';

$deviceId = $_GET['device_id'] ?? 'sensor/3phase10';
$ef = isset($_GET['ef']) ? floatval($_GET['ef']) : 0.566; // kgCO2 per kWh

$mysqli = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
$mysqli->set_charset("utf8mb4");
if ($mysqli->connect_error) {
  http_response_code(500);
  echo json_encode(["error" => "DB connect failed: " . $mysqli->connect_error]);
  exit;
}

function queryDailyKwh($mysqli, $deviceId, $start, $end) {
  $sampleSec = isset($_GET['sample_sec']) ? max(1, intval($_GET['sample_sec'])) : 5;

  $sql = "
    SELECT
      COUNT(*) AS rows_count,
      COALESCE(SUM(
        (load_v_r * load_i_r * load_pf_r) +
        (load_v_y * load_i_y * load_pf_y) +
        (load_v_b * load_i_b * load_pf_b)
      ), 0) AS sum_w,
      MIN(time_key) AS first_time,
      MAX(time_key) AS last_time
    FROM full_history
    WHERE device_id = ?
      AND time_key >= ?
      AND time_key <  ?
  ";

  try {
    $stmt = $mysqli->prepare($sql);
    $stmt->bind_param("sss", $deviceId, $start, $end);
    $stmt->execute();
    $res = $stmt->get_result();
    $row = $res->fetch_assoc();
    $stmt->close();

    if (!$row) {
      return [
        "kwh_total" => 0,
        "seconds_covered" => 0,
        "gap_seconds" => 0,
        "max_dt" => 0,
        "first_time" => null,
        "last_time" => null,
        "rows_count" => 0,
        "mode" => "fast",
        "sample_sec" => $sampleSec
      ];
    }

    $rows  = intval($row["rows_count"] ?? 0);
    $sumW  = floatval($row["sum_w"] ?? 0);
    $first = $row["first_time"] ?? null;
    $last  = $row["last_time"] ?? null;

    $kwh = ($sumW * $sampleSec) / 3600000.0;

    $gapSeconds = 0;
    $maxDt = $sampleSec;

    if ($first && $last && $rows > 1) {
      $elapsed = max(0, strtotime($last) - strtotime($first));
      $expected = max(0, ($rows - 1) * $sampleSec);
      $gapSeconds = max(0, $elapsed - $expected);
      $maxDt = max($sampleSec, $gapSeconds + $sampleSec);
    }

    return [
      "kwh_total" => $kwh,
      "seconds_covered" => $rows * $sampleSec,
      "gap_seconds" => $gapSeconds,
      "max_dt" => $maxDt,
      "first_time" => $first,
      "last_time" => $last,
      "rows_count" => $rows,
      "mode" => "fast",
      "sample_sec" => $sampleSec
    ];

  } catch (mysqli_sql_exception $e) {
    return ["kwh_total" => 0, "error" => $e->getMessage(), "mode" => "fast"];
  }
}

function queryLatestKw($mysqli, $deviceId, $start, $end) {
  $sql = "
    SELECT
      time_key,
      (
        (load_v_r * load_i_r * load_pf_r) +
        (load_v_y * load_i_y * load_pf_y) +
        (load_v_b * load_i_b * load_pf_b)
      ) / 1000.0 AS kw_latest
    FROM full_history
    WHERE device_id = ?
      AND time_key >= ?
      AND time_key <  ?
    ORDER BY time_key DESC
    LIMIT 1
  ";

  $stmt = $mysqli->prepare($sql);
  $stmt->bind_param("sss", $deviceId, $start, $end);
  $stmt->execute();
  $res = $stmt->get_result();
  $row = $res->fetch_assoc();
  $stmt->close();

  if (!$row) {
    return ["kw_latest" => 0, "kw_time" => null];
  }
  return [
    "kw_latest" => floatval($row["kw_latest"] ?? 0),
    "kw_time" => $row["time_key"] ?? null
  ];
}

$tz = new DateTimeZone("Asia/Bangkok");
$today = new DateTime("today", $tz);
$yesterday = (clone $today)->modify("-1 day");

$todayStart = $today->format("Y-m-d 00:00:00");
$todayEnd   = (clone $today)->modify("+1 day")->format("Y-m-d 00:00:00");

$yStart = $yesterday->format("Y-m-d 00:00:00");
$yEnd   = (clone $yesterday)->modify("+1 day")->format("Y-m-d 00:00:00");

$t = queryDailyKwh($mysqli, $deviceId, $todayStart, $todayEnd);
$y = queryDailyKwh($mysqli, $deviceId, $yStart, $yEnd);

$tl = queryLatestKw($mysqli, $deviceId, $todayStart, $todayEnd);
$yl = queryLatestKw($mysqli, $deviceId, $yStart, $yEnd);

$todayKwh = floatval($t["kwh_total"] ?? 0);
$yKwh     = floatval($y["kwh_total"] ?? 0);

echo json_encode([
  "device_id" => $deviceId,
  "ef_kgco2_per_kwh" => $ef,
  "today" => [
    "date" => $today->format("Y-m-d"),
    "kwh" => $todayKwh,
    "kgco2" => $todayKwh * $ef,
    "kw_latest" => $tl["kw_latest"],
    "kw_time" => $tl["kw_time"],
    "meta" => $t
  ],
  "yesterday" => [
    "date" => $yesterday->format("Y-m-d"),
    "kwh" => $yKwh,
    "kgco2" => $yKwh * $ef,
    "kw_latest" => $yl["kw_latest"],
    "kw_time" => $yl["kw_time"],
    "meta" => $y
  ]
], JSON_UNESCAPED_UNICODE);

$mysqli->close();
