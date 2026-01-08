'use strict';

const mqtt = require('mqtt');
const mysql = require('mysql2/promise');

// =====================
// CONFIG from Environment Variables
// =====================
const MQTT_URL = `mqtt://${process.env.MQTT_HOST || '172.16.202.63'}:${process.env.MQTT_PORT || 1883}`;
const MQTT_OPTIONS = {
  username: process.env.MQTT_USER || 'admin',
  password: process.env.MQTT_PASSWORD || 'public',
  reconnectPeriod: 2000,
  connectTimeout: 10000,
  clean: true,
};

const TOPICS = (process.env.MQTT_TOPICS || 'sensor/3phase10').split(',');

// MySQL Config from Environment
const MYSQL_CONFIG = {
  host: process.env.DB_HOST || 'mysql',
  port: parseInt(process.env.MYSQL_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'thaipbs',
  database: process.env.DB_NAME || 'power_real_a_1',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 30000,
};

const DB_NAME = process.env.DB_NAME || 'power_real_a_1';
const TABLE_NAME = 'full_history';

// =====================
// HELPERS
// =====================
function numOrNull(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function safeArr(a) {
  return Array.isArray(a) ? a : [];
}

function mapPayloadToRow(payload, deviceId) {
  const load = payload?.load ?? {};

  const v = safeArr(load.voltage);
  const v3 = safeArr(load.voltage_3phase);
  const i = safeArr(load.current);
  const pf = safeArr(load.pf);

  return {
    device_id: deviceId,
    load_v_r: numOrNull(v[0]),
    load_v_y: numOrNull(v[1]),
    load_v_b: numOrNull(v[2]),
    load_v3_r: numOrNull(v3[0]),
    load_v3_y: numOrNull(v3[1]),
    load_v3_b: numOrNull(v3[2]),
    load_i_r: numOrNull(i[0]),
    load_i_y: numOrNull(i[1]),
    load_i_b: numOrNull(i[2]),
    load_freq: numOrNull(load.frequency),
    load_pf_t: numOrNull(load.pfT),
    load_pf_r: numOrNull(pf[0]),
    load_pf_y: numOrNull(pf[1]),
    load_pf_b: numOrNull(pf[2]),
  };
}

// Retry connection with exponential backoff
async function connectWithRetry(maxRetries = 10, initialDelay = 2000) {
  let retries = 0;
  let delay = initialDelay;

  while (retries < maxRetries) {
    try {
      const pool = mysql.createPool(MYSQL_CONFIG);
      await pool.query("SELECT 1");
      console.log('[DB] Connection successful');
      return pool;
    } catch (err) {
      retries++;
      console.log(`[DB] Connection attempt ${retries}/${maxRetries} failed: ${err.message}`);
      if (retries >= maxRetries) throw err;
      console.log(`[DB] Retrying in ${delay / 1000}s...`);
      await new Promise(resolve => setTimeout(resolve, delay));
      delay = Math.min(delay * 1.5, 30000);
    }
  }
}

async function main() {
  console.log('[CONFIG] MQTT URL:', MQTT_URL);
  console.log('[CONFIG] Topics:', TOPICS.join(', '));
  console.log('[CONFIG] MySQL Host:', MYSQL_CONFIG.host);
  console.log('[CONFIG] Database:', DB_NAME);

  const pool = await connectWithRetry();

  // Set timezone to Thailand
  await pool.query("SET time_zone = '+07:00'");

  // Debug: confirm DB connection
  const [info] = await pool.query(
    "SELECT @@hostname AS host, @@port AS port, DATABASE() AS db, VERSION() AS ver, @@session.time_zone AS tz, NOW() AS now_th"
  );
  console.log('[DB] Connected to:', info[0]);

  const [tables] = await pool.query('SHOW TABLES');
  console.log('[DB] Tables:', tables.map((r) => Object.values(r)[0]).join(', '));

  // Insert SQL
  const insertSql = `
    INSERT INTO \`${DB_NAME}\`.\`${TABLE_NAME}\`
    (device_id,
     load_v_r, load_v_y, load_v_b,
     load_v3_r, load_v3_y, load_v3_b,
     load_i_r, load_i_y, load_i_b,
     load_freq, load_pf_t,
     load_pf_r, load_pf_y, load_pf_b)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  let insertCount = 0;

  const client = mqtt.connect(MQTT_URL, MQTT_OPTIONS);

  client.on('connect', () => {
    console.log('[MQTT] Connected:', MQTT_URL);

    client.subscribe(TOPICS, { qos: 0 }, (err, granted) => {
      if (err) {
        console.error('[MQTT] Subscribe error:', err.message);
        return;
      }
      console.log('[MQTT] Subscribed:', granted.map((g) => g.topic).join(', '));
    });
  });

  client.on('reconnect', () => console.log('[MQTT] Reconnecting...'));
  client.on('error', (e) => console.error('[MQTT] Error:', e.message));

  client.on('message', async (topic, message) => {
    const deviceId = topic;

    let payload;
    try {
      payload = JSON.parse(message.toString('utf8'));
    } catch {
      console.error('[PARSE] Invalid JSON from topic:', topic);
      return;
    }

    if (!payload?.load) {
      console.warn('[DATA] Missing "load" in payload, topic:', topic);
      return;
    }

    const row = mapPayloadToRow(payload, deviceId);

    const values = [
      row.device_id,
      row.load_v_r, row.load_v_y, row.load_v_b,
      row.load_v3_r, row.load_v3_y, row.load_v3_b,
      row.load_i_r, row.load_i_y, row.load_i_b,
      row.load_freq, row.load_pf_t,
      row.load_pf_r, row.load_pf_y, row.load_pf_b,
    ];

    try {
      const [result] = await pool.execute(insertSql, values);
      insertCount += 1;

      const [t] = await pool.query('SELECT NOW() AS now_th');
      const nowTH = t?.[0]?.now_th;

      console.log(`[DB] Insert OK #${insertCount} | id=${result.insertId} | time=${nowTH} | device=${deviceId}`);
    } catch (e) {
      console.error('[DB] Insert error:', e.message);
    }
  });

  // Graceful shutdown
  const shutdown = async (signal) => {
    console.log(`\n[${signal}] Shutting down...`);
    client.end(true);
    await pool.end();
    process.exit(0);
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});
