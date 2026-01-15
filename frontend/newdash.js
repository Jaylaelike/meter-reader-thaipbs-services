// newdash.js

document.addEventListener("DOMContentLoaded", () => {
  // ------------------------------------------------------------
  // Auto UI scale when user toggles Browser Fullscreen (F11)
  // เป้าหมาย: เข้าโหมด Fullscreen แล้ว UI ดู “พอดี” โดยไม่ต้องกด Zoom 110%
  // ปรับเฉพาะตัวแปร CSS --ui-scale (กำหนดไว้ใน newdash.css)
  // ------------------------------------------------------------
  (function initAutoScaleForFullscreen() {
    const SCALE_NORMAL = 1.0;
    const SCALE_FULLSCREEN = 1.10; // ถ้ายังเล็ก/ใหญ่ไป ปรับเลขนี้ได้ เช่น 1.08 หรือ 1.12

    // ตรวจว่าเป็น Browser Fullscreen (F11) หรือ DOM Fullscreen
    function isBrowserFullscreen() {
      const tol = 2; // pixel tolerance
      const byOuter =
        Math.abs(window.outerWidth - screen.width) <= tol &&
        Math.abs(window.outerHeight - screen.height) <= tol;
      const byInner =
        Math.abs(window.innerWidth - screen.width) <= 8 &&
        Math.abs(window.innerHeight - screen.height) <= 80; // toolbar/OS can vary
      return byOuter || byInner;
    }

    let lastScale = null;
    function applyScale() {
      const fullscreen = !!document.fullscreenElement || isBrowserFullscreen();
      const scale = fullscreen ? SCALE_FULLSCREEN : SCALE_NORMAL;
      if (scale === lastScale) return;
      lastScale = scale;
      document.documentElement.style.setProperty("--ui-scale", String(scale));
    }

    // run once
    applyScale();

    // update on resize (F11 triggers resize)
    let raf = 0;
    window.addEventListener(
      "resize",
      () => {
        cancelAnimationFrame(raf);
        raf = requestAnimationFrame(applyScale);
      },
      { passive: true }
    );

    // update on DOM fullscreen change (if used)
    document.addEventListener("fullscreenchange", applyScale);
  })();
  // เก็บเวลา Sunrise / Sunset แบบ Date จาก API ไว้ใช้คำนวณตำแหน่งดวงอาทิตย์
  let sunriseDateObj = null;
  let sunsetDateObj = null;

    // -----------------------------
  // Date / Time (อัปเดตทุก 1 วินาที)
  // -----------------------------
  function pad2(n){ return String(n).padStart(2, "0"); }

  function updateDateTimeCard(){
    const hmEl = document.getElementById("dt-hm");
    const secEl = document.getElementById("dt-sec");
    const weekdayEl = document.getElementById("dt-weekday");
    const dateEl = document.getElementById("dt-date");
    if (!hmEl || !secEl || !weekdayEl || !dateEl) return;

    const now = new Date();

    hmEl.textContent = `${pad2(now.getHours())}:${pad2(now.getMinutes())}`;
    secEl.textContent = `:${pad2(now.getSeconds())}`;

    // วันไทย
    weekdayEl.textContent = new Intl.DateTimeFormat("th-TH", { weekday: "long" }).format(now);

    // วันที่ + ปี พ.ศ.
    dateEl.textContent = new Intl.DateTimeFormat("th-TH-u-ca-buddhist", {
      day: "numeric", month: "long", year: "numeric"
    }).format(now);
  }

  updateDateTimeCard();
  setInterval(updateDateTimeCard, 1000);


  // -----------------------------
  // 1) ตั้งค่า Donut ทุกวง
  // -----------------------------
  const donuts = document.querySelectorAll(".js-donut");

  donuts.forEach((svg) => {
    const percent = parseFloat(svg.getAttribute("data-percent") || "0");
    const ring = svg.querySelector(".donut-ring");
    if (!ring) return;

    const radius = ring.getAttribute("r");
    const circumference = 2 * Math.PI * radius;

    ring.style.strokeDasharray = `${circumference} ${circumference}`;
    const offset = circumference - (percent / 100) * circumference;
    ring.style.strokeDashoffset = offset;
    ring.style.transition = "stroke-dashoffset 1s ease-out";
  });

  // -----------------------------
  // 2) ฟังก์ชันสำหรับ PM2.5 Gauge
  // -----------------------------
  // แทนที่ฟังก์ชันเดิมใน newdash.js ทั้งก้อนนี้
  // === ฟังก์ชันคำนวณมุมของเข็ม PM2.5 แบบสัมพันธ์กับสเกลจริง ===
function getPMAngle(value) {
  const minVal = 0;     // ค่าต่ำสุดของเกจ
  const maxVal = 120;   // ค่าสูงสุดของเกจ
  const minAngle = -90; // มุมซ้ายสุด
  const maxAngle = 90;  // มุมขวาสุด

  // จำกัดค่าที่รับเข้ามาไม่ให้เกินช่วง
  let v = Math.max(minVal, Math.min(value, maxVal));

  // คำนวณมุมแบบเชิงเส้น
  let angle = minAngle + ((v - minVal) / (maxVal - minVal)) * (maxAngle - minAngle);

  return angle;
}

  // เพิ่มฟังก์ชันนี้ไว้ "เหนือ" setPMGauge()
  function getPMColor(value) {
    const v = Number(value);

    // ให้ตรงกับช่วงเกจ: 0–15 ฟ้า, 15–25 เขียว, 25–37.5 เหลือง, 37.5–75 ส้ม, 75–120 แดง
    if (v <= 15)   return "#00c3ff"; // seg-blue
    if (v <= 25)   return "#3cb44a"; // seg-green
    if (v <= 37.5) return "#ffe119"; // seg-yellow
    if (v <= 75)   return "#ffa300"; // seg-orange
    return "#ff0000";                // seg-red
  }

  function setPMGauge(value, pointerId, valueSelector) {
    const pointer = document.getElementById(pointerId);
    if (pointer) {
      const angle = getPMAngle(value);
      pointer.style.transform = `rotate(${angle}deg)`;
      pointer.style.transition = "transform 0.8s ease-out";
    }

    if (valueSelector) {
      const valueEl = document.querySelector(valueSelector);
      if (valueEl) {
        valueEl.textContent = value.toFixed(1);

        // ✅ ทำให้ “ตัวเลขค่า PM2.5” เปลี่ยนสีตามช่วงเกจ
        valueEl.style.color = getPMColor(value);

        // (แนะนำ) เพิ่มเงาเล็กน้อยให้อ่านชัดบนพื้นหลังเข้ม
        valueEl.style.textShadow = "0 2px 6px rgba(0,0,0,0.35)";

        
      }
    }
  }


  // ค่าเริ่มต้นของเกจ (ภายใน / ภายนอก)
  // ภายในอาคารยังใช้ค่าคงที่ไปก่อน
  setPMGauge(0, "pm-pointer-indoor", "#pm-value-indoor");
  // ภายนอกอาคารเริ่มที่ 0 แล้วให้อัปเดตจาก MQTT
  setPMGauge(0, "pm-pointer-outdoor", "#pm-value-outdoor");

  // -----------------------------
  // 2.1 MQTT: รับค่า PM2.5 ภายนอกอาคารจาก MQTT Server
  // -----------------------------
  function initMqttForPM25Outdoor() {
    // ตรวจว่า mqtt.min.js ถูกโหลดแล้วหรือยัง
    if (typeof mqtt === "undefined") {
      console.warn("mqtt.min.js ยังไม่ถูกโหลด – ข้ามการเชื่อมต่อ MQTT");
      return;
    }

    // เชื่อมต่อ MQTT Broker ผ่าน WebSocket
    const client = mqtt.connect("ws://172.16.202.63:8083/mqtt", {
      clientId: "web-dashboard-" + Math.random().toString(16).substr(2, 8),
      // ถ้ามี username/password ให้เพิ่มตรงนี้
      username: "admin",
      password: "public",
    });

    client.on("connect", () => {
      console.log("MQTT connected");

      client.subscribe("sensor/data", (err) => {
        if (err) {
          console.error("MQTT subscribe error:", err);
        } else {
          console.log("Subscribed to sensor/data");
        }
      });
    });

      client.on("message", (topic, message) => {
        // message เป็น Buffer -> แปลงเป็น string แล้ว parse JSON
        try {
          if (topic !== "sensor/data") return;

          const payload = JSON.parse(message.toString());
          // ตัวอย่าง payload:
          // {
          //   "temperature": 25.4,
          //   "humidity": 88.3,
          //   "pm1": 22,
          //   "pm2_5": 39,
          //   "pm10": 39
          // }

          // ----- 1) อัปเดตเกจ PM2.5 ภายนอกอาคาร -----
          if (typeof payload.pm2_5 !== "undefined") {
            const pmValue = parseFloat(payload.pm2_5);
            if (!Number.isNaN(pmValue)) {
              setPMGauge(pmValue, "pm-pointer-outdoor", "#pm-value-outdoor");
            }
          }

          // ----- 2) อัปเดตตัวเลขอุณหภูมิภายนอกอาคาร -----
          if (
            typeof payload.temperature !== "undefined" &&
            typeof payload.humidity !== "undefined"
          ) {
            const temp = parseFloat(payload.temperature);
            const hum  = parseFloat(payload.humidity);

            if (!Number.isNaN(temp) && !Number.isNaN(hum)) {
              // หา element "ภายนอกอาคาร 38°C / 50%"
              const outdoorMain = document.querySelector(
                ".env-block-outdoor .env-main"
              );
              if (outdoorMain) {
                // แสดง temp 1 ตำแหน่งทศนิยม และ humidity เป็นจำนวนเต็ม
                outdoorMain.textContent =
                  `${temp.toFixed(1)}°C / ${hum.toFixed(0)}%`;
              }
            }
          }
        } catch (e) {
          console.error("Error parsing MQTT message:", e);
        }
      });


    client.on("error", (err) => {
      console.error("MQTT error:", err);
    });

    client.on("close", () => {
      console.warn("MQTT connection closed");
      // ถ้าต้องการ reconnect เอง สามารถเพิ่ม logic ตรงนี้ได้
    });
  }

  

// -----------------------------
// 2.1.1 MQTT: รับค่า PM2.5 ภายในอาคารจาก MQTT Server (คนละ Broker กับ Outdoor)
// -----------------------------
function initMqttForPM25Indoor() {
  // ตรวจว่า mqtt.min.js ถูกโหลดแล้วหรือยัง
  if (typeof mqtt === "undefined") {
    console.warn("mqtt.min.js ยังไม่ถูกโหลด – ข้ามการเชื่อมต่อ MQTT (Indoor)");
    return;
  }

  const TOPIC_INDOOR = "sensors/pm25_indoor";

  // เชื่อมต่อ MQTT Broker (Indoor) ผ่าน WebSocket
  const client = mqtt.connect("ws://172.16.116.82:8083/mqtt", {
    clientId: "web-dashboard-indoor-" + Math.random().toString(16).substr(2, 8),
    username: "admin",
    password: "public",
  });

  client.on("connect", () => {
    console.log("MQTT (Indoor) connected");

    client.subscribe(TOPIC_INDOOR, (err) => {
      if (err) {
        console.error("MQTT (Indoor) subscribe error:", err);
      } else {
        console.log("Subscribed to " + TOPIC_INDOOR);
      }
    });
  });

  client.on("message", (topic, message) => {
    try {
      if (topic !== TOPIC_INDOOR) return;

      const raw = message.toString();

      // รองรับทั้งแบบส่งมาเป็นตัวเลขล้วน "35.2"
      // และแบบ JSON เช่น {"pm2_5":35.2} หรือ {"pm25":35.2} หรือ {"value":35.2}
      let payload = null;
      let pmValue = null;

      try {
        payload = JSON.parse(raw);
      } catch (_) {
        payload = null;
      }

      if (payload && typeof payload === "object") {
        const candidate =
          payload.pm2_5 ??
          payload.pm25 ??
          payload.pm2p5 ??
          payload.value ??
          payload.pm ??
          payload.PM2_5 ??
          payload["pm2.5"];

        if (typeof candidate !== "undefined") {
          pmValue = parseFloat(candidate);
        }

        // ถ้ามี temperature/humidity มาด้วย ให้แสดงในบล็อก "ภายในอาคาร" ด้วย (ถ้ามี element)
        if (
          typeof payload.temperature !== "undefined" &&
          typeof payload.humidity !== "undefined"
        ) {
          const temp = parseFloat(payload.temperature);
          const hum = parseFloat(payload.humidity);

          if (!Number.isNaN(temp) && !Number.isNaN(hum)) {
            const indoorMain = document.querySelector(".env-block-indoor .env-main");
            if (indoorMain) {
              indoorMain.textContent = `${temp.toFixed(1)}°C / ${hum.toFixed(0)}%`;
            }
          }
        }
      } else {
        pmValue = parseFloat(raw);
      }

      if (pmValue !== null && !Number.isNaN(pmValue)) {
        setPMGauge(pmValue, "pm-pointer-indoor", "#pm-value-indoor");
      }
    } catch (e) {
      console.error("Error parsing MQTT (Indoor) message:", e);
    }
  });

  client.on("error", (err) => {
    console.error("MQTT (Indoor) error:", err);
  });

  client.on("close", () => {
    console.warn("MQTT (Indoor) connection closed");
  });
}

  // เรียกใช้งาน MQTT เมื่อหน้าโหลดเสร็จ
  initMqttForPM25Outdoor();
  initMqttForPM25Indoor();

    // -----------------------------
  // 2.2 Daily kWh + Carbon footprint (Today / Yesterday)
  // วาง “ใต้” initMqttForPM25Outdoor();
  // วาง “ใต้” initMqttForPM25Outdoor(); และ “เหนือ” Section 3 (ดวงอาทิตย์)
  // -----------------------------
    let energyFetchBusy = false;

  async function updateEnergyAndCarbon() {
    if (energyFetchBusy) return;   // <-- เพิ่ม
    energyFetchBusy = true;        // <-- เพิ่ม

    try {
      const deviceId = "sensor/3phase10";
      const API_URL = `energy_daily.php?device_id=${encodeURIComponent(deviceId)}`;

      const res = await fetch(API_URL, { cache: "no-store" });
      if (!res.ok) throw new Error("HTTP " + res.status);
      const data = await res.json();

      const yKg = Number(data?.yesterday?.kgco2 ?? 0);
      const tKg = Number(data?.today?.kgco2 ?? 0);
      const tKwh = Number(data?.today?.kwh ?? 0);

      // ===== 5) อัปเดต Real-Time Power (kW ล่าสุดของวันนี้) =====
      const tKw = Number(data?.today?.kw_latest ?? 0);

      const WATER_L_PER_KWH = 1.8; // ลิตร ต่อ kWh (ปรับได้)
      const WATER_BOTTLE_L = 1.5;  // ลิตร ต่อขวด

      // อัปเดตตัวเลขกลางวง (kW)
      const kwEl = document.querySelector(".card-power .power-top .donut-value.big");
      if (kwEl) kwEl.textContent = tKw.toFixed(0);

      // อัปเดตวงโดนัท (กำหนด max kW เพื่อแปลงเป็น %)
      const POWER_RING_MAX_KW = 120; // ปรับตามหน้างานจริง
      const pPct = Math.max(0, Math.min(100, (tKw / POWER_RING_MAX_KW) * 100));

      const powerSvg = document.querySelector(".card-power .power-top .js-donut");
      if (powerSvg) {
        powerSvg.setAttribute("data-percent", String(pPct));
        const ringP =
          powerSvg.querySelector(".donut-ring-power") ||
          powerSvg.querySelector(".donut-ring");

        if (ringP) {
          const radius = Number(ringP.getAttribute("r") || 0);
          const circumference = 2 * Math.PI * radius;
          ringP.style.strokeDasharray = `${circumference} ${circumference}`;
          ringP.style.strokeDashoffset = (circumference - (pPct / 100) * circumference);

          // ===== Water equivalent (คำนวณจาก kW ล่าสุด) =====
          const litersPerHour = Math.max(0, tKw) * WATER_L_PER_KWH;
          const bottlesPerHour = litersPerHour / WATER_BOTTLE_L;

          const bottleEl = document.getElementById("water-bottles-per-hour");
          if (bottleEl) bottleEl.textContent = Math.round(bottlesPerHour).toString();

          const litersEl = document.getElementById("water-liters-per-hour");
          if (litersEl) litersEl.textContent = litersPerHour.toFixed(1);
        }
      }

      // 1) อัปเดตตัวเลข Carbon (เมื่อวาน/วันนี้)
      const carbonNums = document.querySelectorAll(".card-carbon .carbon-number");
      if (carbonNums.length >= 2) {
        carbonNums[0].textContent = yKg.toFixed(1);
        carbonNums[1].textContent = tKg.toFixed(1);
      }

      // 2) อัปเดตแท่งกราฟ (เทียบค่าสูงสุดของ 2 วัน)
      const maxKg = Math.max(yKg, tKg, 1);
      const yPct = (yKg / maxKg) * 100;
      const tPct = (tKg / maxKg) * 100;

      const barY = document.querySelector(".card-carbon .bar-yesterday");
      const barT = document.querySelector(".card-carbon .bar-today");
      if (barY) barY.style.height = `${yPct}%`;
      if (barT) barT.style.height = `${tPct}%`;

      // 3) อัปเดตตัวเลข kWh ตรงกลางโดนัท (พลังงานที่ใช้)
      const kwhEl = document.querySelector(".card-carbon .carbon-bottom .donut-value");
      if (kwhEl) kwhEl.textContent = tKwh.toFixed(1);

      // 4) โดนัท “ขยับตามเวลา 24 ชั่วโมง” (00:00 → 24:00)
      const now = new Date();
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
      const endOfDay   = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 0);

      let pct = ((now - startOfDay) / (endOfDay - startOfDay)) * 100;
      pct = Math.max(0, Math.min(100, pct));

      const donutSvg = document.querySelector(".card-carbon .carbon-bottom .js-donut");
      if (donutSvg) {
        donutSvg.setAttribute("data-percent", String(pct));

        const ring = donutSvg.querySelector(".donut-ring");
        if (ring) {
          const radius = Number(ring.getAttribute("r") || 0);
          const circumference = 2 * Math.PI * radius;

          ring.style.strokeDasharray = `${circumference} ${circumference}`;

          // ถ้าใกล้ 100% ให้ “เต็มวง” ชัด ๆ (ลดโอกาสเห็นช่องว่างจากปลายโค้ง)
          if (pct >= 99.9) {
            ring.style.strokeDashoffset = "0";
            ring.style.strokeLinecap = "butt";
          } else {
            ring.style.strokeDashoffset = String(circumference - (pct / 100) * circumference);
            ring.style.strokeLinecap = "round";
          }
        }
      }

    } catch (err) {
      console.error("updateEnergyAndCarbon error:", err);
    } finally {
      energyFetchBusy = false;
    }
  }

  // เรียกครั้งแรก + อัปเดตทุก 60 วินาที
  updateEnergyAndCarbon();
  setInterval(updateEnergyAndCarbon, 5 * 1000);


  // -----------------------------
  // 3) ดวงอาทิตย์วิ่งตามเส้นโค้ง
  // -----------------------------

  // fallback: แปลง "HH:MM" -> นาทีหลังเที่ยงคืน (ใช้กรณี API ใช้ไม่ได้)
  function parseHHMM(text) {
    const [h, m] = text.split(":").map(Number);
    return h * 60 + m;
  }

  // คำนวณ progress 0–1 ของวันนี้
  function getDayProgress() {
    const now = new Date();

    // กรณีมี Date จริงจาก API แล้ว → ใช้แบบละเอียด
    if (sunriseDateObj && sunsetDateObj) {
      const start = sunriseDateObj.getTime();
      const end = sunsetDateObj.getTime();
      const cur = now.getTime();

      if (cur <= start) return 0;
      if (cur >= end) return 1;
      return (cur - start) / (end - start);
    }

    // กรณี API ใช้ไม่ได้ → อ่านจากตัวเลขใน DOM แบบเดิม
    const sunriseEl = document.querySelector(
      ".sun-info-row .sun-info:first-child .sun-time"
    );
    const sunsetEl = document.querySelector(
      ".sun-info-row .sun-info:last-child .sun-time"
    );
    if (!sunriseEl || !sunsetEl) return null;

    const sunrise = parseHHMM(sunriseEl.textContent.trim());
    const sunset = parseHHMM(sunsetEl.textContent.trim());

    const current = now.getHours() * 60 + now.getMinutes();

    if (current <= sunrise) return 0;
    if (current >= sunset) return 1;
    return (current - sunrise) / (sunset - sunrise);
  }

  // จุดบนเส้นโค้ง Bezier: M0 40 C50 2 50 2 100 40
  function getSunPositionOnCurve(t) {
    const P0 = { x: 0, y: 40 };
    const P1 = { x: 50, y: 2 };
    const P2 = { x: 50, y: 2 };
    const P3 = { x: 100, y: 40 };

    const u = 1 - t;
    const x =
      u * u * u * P0.x +
      3 * u * u * t * P1.x +
      3 * u * t * t * P2.x +
      t * t * t * P3.x;

    const y =
      u * u * u * P0.y +
      3 * u * u * t * P1.y +
      3 * u * t * t * P2.y +
      t * t * t * P3.y;

    return { x, y };
  }

  function updateSunPosition() {
    const sunArc = document.querySelector(".sun-arc");
    const sun = document.querySelector(".sun");
    if (!sunArc || !sun) return;

    const progress = getDayProgress();
    if (progress === null) return;

    // จำกัดช่วง 0–1 แล้วเว้น margin ซ้าย/ขวาเล็กน้อย
    const raw = Math.min(1, Math.max(0, progress));
    const t = 0.02 + 0.96 * raw;   // อยากให้ชนขอบเป๊ะใช้ const t = raw;

    const point = getSunPositionOnCurve(t);

    const rect = sunArc.getBoundingClientRect();
    const xPx = (point.x / 100) * rect.width;
    const yPx = (point.y / 40) * rect.height;

    const yOffset = -2;           // ดันดวงอาทิตย์ให้เกาะเส้นพอดี

    sun.style.left = `${xPx}px`;
    sun.style.top = `${yPx + yOffset}px`;
  }
    if (document.querySelector(".sun-arc")) updateSunTimesFromAPI();

  // อัปเดตทุก 1 นาที + ตอนโหลดหน้า
  //updateSunPosition();
  //setInterval(updateSunPosition, 60 * 1000);

  // -----------------------------
  // 4) ดึงเวลา Sunrise / Sunset ของ กทม. จาก API
  // -----------------------------
  async function updateSunTimesFromAPI() {
    const lat = 13.7563;
    const lng = 100.5018;

    const params = new URLSearchParams({
      lat: lat,
      lng: lng,
      date: "today",
      formatted: "0",        // ISO string
      tzid: "Asia/Bangkok"
    });

    const url = `https://api.sunrise-sunset.org/json?${params.toString()}`;

    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error("HTTP " + res.status);

      const data = await res.json();
      if (data.status !== "OK") throw new Error("API status: " + data.status);

      sunriseDateObj = new Date(data.results.sunrise);
      sunsetDateObj = new Date(data.results.sunset);

      const formatter = new Intl.DateTimeFormat("th-TH", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
        timeZone: "Asia/Bangkok"
      });

      const sunriseStr = formatter.format(sunriseDateObj);
      const sunsetStr = formatter.format(sunsetDateObj);

      const sunriseEl = document.querySelector(
        ".sun-info-row .sun-info:first-child .sun-time"
      );
      const sunsetEl = document.querySelector(
        ".sun-info-row .sun-info:last-child .sun-time"
      );

      if (sunriseEl) sunriseEl.textContent = sunriseStr;
      if (sunsetEl) sunsetEl.textContent = sunsetStr;

      // คำนวณตำแหน่งใหม่ด้วยเวลาจริง
      //updateSunPosition();
    } catch (err) {
      console.error("Error updating sunrise/sunset times:", err);
      // ถ้า error ให้ใช้ค่าที่อยู่ใน HTML + fallback เดิม
    }
  }

  //updateSunTimesFromAPI();
});
