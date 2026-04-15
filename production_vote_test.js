import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
    thresholds: {
      http_req_failed: ["rate<0.01"],
      http_req_duration: ["p(95)<1000"],
    },
    scenarios: {
      ramp_test: {
        executor: "ramping-vus",
        startVUs: 1,
        stages: [
          { duration: "30s", target: 10 },
          { duration: "30s", target: 25 },
          { duration: "30s", target: 50 },
          { duration: "30s", target: 75 },
          { duration: "30s", target: 100 },
        ],
        gracefulRampDown: "10s",
      },
    },
  };
const BASE_URL = "https://votegrid.in";
const SLUG = "tn47";

function extractCsrfToken(html) {
  const match = html.match(/<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"/i);
  return match ? match[1] : null;
}

const dummySelfie =
  "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxAQEBAQEBAVFRUVFRUVFRUVFRUVFRUVFRUWFhUVFRUYHSggGBolGxUVITEhJSkrLi4uFx8zODMsNygtLisBCgoKDg0OFQ8QFS0dHR0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIAAEAAgMBIgACEQEDEQH/xAAXAAADAQAAAAAAAAAAAAAAAAAAAQID/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEAMQAAAB6A//xAAVEAEBAAAAAAAAAAAAAAAAAAABEP/aAAgBAQABBQJf/8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAEP/aAAgBAQAGPwJf/8QAFBABAAAAAAAAAAAAAAAAAAAAEP/aAAgBAQABPyF//9k=";

function fakeFingerprint() {
  return "k6-test-device-fingerprint-001";
}

export default function () {
  const jar = http.cookieJar();

  const constituencyId = "1";
  const boothId = "1";
  const boothName = "Panchayat union Middle School, Facing East";
  const gender = "Female";
  const ageGroup = "40-60";
  const candidateId = "1"; // use a valid candidate id from production

  const votePageUrl =
    `${BASE_URL}/poll/${SLUG}/vote` +
    `?constituency_id=${encodeURIComponent(constituencyId)}` +
    `&booth_id=${encodeURIComponent(boothId)}` +
    `&booth_name=${encodeURIComponent(boothName)}` +
    `&gender=${encodeURIComponent(gender)}` +
    `&age_group=${encodeURIComponent(ageGroup)}`;

  const pageRes = http.get(votePageUrl, {
    jar,
    headers: {
      "User-Agent": "k6-load-test",
    },
  });

  const csrf = extractCsrfToken(pageRes.body);

  check(pageRes, {
    "vote page loaded": (r) => r.status === 200 || r.status === 302,
    "csrf found": () => csrf !== null,
  });

  if (!csrf) {
    console.log("CSRF token not found");
    console.log(pageRes.body.substring(0, 1000));
    return;
  }

  const payload = {
    _csrf_token: csrf,
    "response[constituency_id]": constituencyId,
    "response[booth_id]": boothId,
    "response[booth_name]": boothName,
    "response[gender]": gender,
    "response[age_group]": ageGroup,
    "response[latitude]": "12.9716",
    "response[longitude]": "77.5946",
    "response[selfie_base64]": dummySelfie,
    "response[voted_at]": new Date().toISOString(),
    "response[device_fingerprint]": fakeFingerprint(),
    "response[candidate_id]": candidateId,
  };

  const postRes = http.post(
    `${BASE_URL}/poll/${SLUG}/submit_ajax`,
    payload,
    {
      jar,
      headers: {
        "X-CSRF-Token": csrf,
        "X-Requested-With": "XMLHttpRequest",
        "User-Agent": "k6-load-test",
      },
    }
  );

  check(postRes, {
    "ajax submit success http": (r) => r.status === 200,
    "ajax returned json": (r) =>
      (r.headers["Content-Type"] || "").includes("application/json"),
  });

  let body = null;
  try {
    body = postRes.json();
  } catch (e) {
    console.log("Non-JSON response: " + postRes.body.substring(0, 1000));
  }

  if (body) {
    check(body, {
      "result ok": (b) => b.ok === true,
      "vote id returned": (b) => !!b.vote_id,
      "redirect url returned": (b) => !!b.redirect_url,
    });
  }

  if (postRes.status !== 200 || !body || body.ok !== true) {
    console.log("POST STATUS: " + postRes.status);
    console.log("POST HEADERS: " + JSON.stringify(postRes.headers));
    console.log("POST BODY: " + postRes.body.substring(0, 2000));
  }

  sleep(1);
}