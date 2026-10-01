import { createServiceClient } from "./supabase.ts";

export type PushNotification = {
  title: string;
  body: string;
  data?: Record<string, string>;
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

/** Converte um PEM PKCS#8 para DER usando indexOf/slice (suporta formato de linha única ou multilinha). */
function pemToDer(pem: string): Uint8Array {
  const BEGIN = "-----BEGIN PRIVATE KEY-----";
  const END = "-----END PRIVATE KEY-----";
  const raw = String(pem ?? "");
  const start = raw.indexOf(BEGIN);
  const end = raw.indexOf(END);
  let inner = start !== -1 && end > start ? raw.slice(start + BEGIN.length, end) : raw;

  // Remove whitespace char a char (sem regex) — mantém apenas chars base64 visíveis
  let b64 = "";
  for (let i = 0; i < inner.length; i++) {
    const c = inner.charCodeAt(i);
    if (c > 32 && c < 127) b64 += inner[i]; // descarta \n \r \t espaço e controles
  }

  if (!b64) return new Uint8Array(0);

  // Tabela de lookup base64 (inline para evitar dependência de constante de módulo)
  const B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  const lut = new Uint8Array(256).fill(255);
  for (let i = 0; i < B64.length; i++) lut[B64.charCodeAt(i)] = i;

  const pad = b64.endsWith("==") ? 2 : b64.endsWith("=") ? 1 : 0;
  const len = b64.length;
  const out = new Uint8Array(Math.floor((len * 3) / 4) - pad);
  let idx = 0;
  for (let i = 0; i < len; i += 4) {
    const a = lut[b64.charCodeAt(i)];
    const b = lut[b64.charCodeAt(i + 1)];
    const c = b64[i + 2] === "=" ? 0 : lut[b64.charCodeAt(i + 2)];
    const d = b64[i + 3] === "=" ? 0 : lut[b64.charCodeAt(i + 3)];
    if (idx < out.length) out[idx++] = (a << 2) | (b >> 4);
    if (b64[i + 2] !== "=" && idx < out.length) out[idx++] = ((b & 0xf) << 4) | (c >> 2);
    if (b64[i + 3] !== "=" && idx < out.length) out[idx++] = ((c & 0x3) << 6) | d;
  }
  return out;
}

function b64url(s: string): string {
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function uint8ToB64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function fcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const sigInput = `${header}.${payload}`;
  const der = pemToDer(sa.private_key);

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sigBuf = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(sigInput),
  );

  const jwt = `${sigInput}.${uint8ToB64url(new Uint8Array(sigBuf))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!json.access_token) {
    console.error("[push] OAuth failed", JSON.stringify(json));
    throw new Error(`FCM OAuth failed: ${json.error ?? "no access_token"}`);
  }
  return json.access_token as string;
}

/// Envia push para todos os dispositivos registrados de um usuário.
/// Falha silenciosamente — nunca interrompe o fluxo principal.
export async function sendPushToUser(
  serviceClient: ReturnType<typeof createServiceClient>,
  userId: string,
  notification: PushNotification,
): Promise<void> {
  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!saJson) {
    console.error("[push] FIREBASE_SERVICE_ACCOUNT secret not found");
    return;
  }

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(saJson);
  } catch (e) {
    console.error("[push] failed to parse FIREBASE_SERVICE_ACCOUNT", e);
    return;
  }

  const { data: tokens, error: tokensError } = await serviceClient
    .from("device_tokens")
    .select("token")
    .eq("profile_id", userId);

  if (tokensError) {
    console.error("[push] failed to query device_tokens", tokensError);
    return;
  }

  if (!tokens?.length) {
    console.log(`[push] no tokens for userId=${userId}`);
    return;
  }

  let accessToken: string;
  try {
    accessToken = await fcmAccessToken(sa);
  } catch (e) {
    console.error("[push] failed to get FCM access token", e);
    return;
  }

  const results = await Promise.allSettled(
    tokens.map(async (row: { token: string }) => {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: row.token,
              notification: { title: notification.title, body: notification.body },
              data: notification.data ?? {},
              android: {
                priority: "high",
                notification: {
                  icon: "ic_notification",
                  color: "#00B2A9",
                },
              },
              apns: {
                payload: { aps: { sound: "default", badge: 1 } },
              },
            },
          }),
        },
      );
      if (!res.ok) {
        const err = await res.text();
        console.error(`[push] FCM error token=${row.token.slice(0, 20)}...`, err);
      } else {
        console.log(`[push] sent ok to token=${row.token.slice(0, 20)}...`);
      }
      return res;
    }),
  );

  console.log(`[push] total=${tokens.length} settled=${results.length}`);
}
