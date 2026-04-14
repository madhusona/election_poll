import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 50,
  duration: "30s",
};

function extractCsrfToken(html) {
  const match = html.match(/<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"/i);
  return match ? match[1] : null;
}

// tiny valid-looking base64 jpeg placeholder
const dummySelfie =
  "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxAQEBAQEBAVFRUVFRUVFRUVFRUVFRUVFRUWFhUVFRUYHSggGBolGxUVITEhJSkrLi4uFx8zODMsNygtLisBCgoKDg0OFQ8QFS0dHR0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIAAEAAgMBIgACEQEDEQH/xAAXAAADAQAAAAAAAAAAAAAAAAAAAQID/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEAMQAAAB6A//xAAVEAEBAAAAAAAAAAAAAAAAAAABEP/aAAgBAQABBQJf/8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAEP/aAAgBAQAGPwJf/8QAFBABAAAAAAAAAAAAAAAAAAAAEP/aAAgBAQABPyF//9k=";

export default function () {
  const jar = http.cookieJar();

  const votePageUrl =
    "http://localhost:4000/poll/firstt/vote?constituency_id=3&booth_id=2&booth_name=B&gender=Female&age_group=40-60";

  // Step 1: load page and get CSRF + session cookie
  const pageRes = http.get(votePageUrl, { jar });
  const csrf = extractCsrfToken(pageRes.body);

  check(pageRes, {
    "vote page loaded": (r) => r.status === 200,
    "csrf found": () => csrf !== null,
  });

  if (!csrf) {
    console.log("CSRF token not found");
    return;
  }

  // Step 2: simulate final posted form after browser JS filled hidden fields
  const payload = {
    _csrf_token: csrf,
    "response[constituency_id]": "3",
    "response[booth_name]": "B",
    "response[booth_id]": "2",
    "response[gender]": "Female",
    "response[age_group]": "40-60",
    "response[latitude]": "12.9716",
    "response[longitude]": "77.5946",
    "response[selfie_base64]": dummySelfie,
    "response[candidate_id]": "4",
  };

  const postRes = http.post(
    "http://localhost:4000/poll/firstt/submit",
    payload,
    {
      jar,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      redirects: 0,
    }
  );

  check(postRes, {
    "submit accepted": (r) => r.status === 200 || r.status === 302,
    "success redirect": (r) =>
      r.status === 302 &&
      r.headers.Location &&
      r.headers.Location.includes("/success"),
  });

  if (postRes.status !== 200 && postRes.status !== 302) {
    console.log("POST STATUS: " + postRes.status);
    console.log("POST HEADERS: " + JSON.stringify(postRes.headers));
    console.log("POST BODY: " + postRes.body.substring(0, 1000));
  }

  sleep(1);
}
