// GIG Logistics (GIGL) third-party API client.
//
// Credentials come from Supabase secrets, never from the app or the repo:
//   supabase secrets set GIG_BASE_URL=https://dev-thirdpartynode.theagilitysystems.com \
//                        GIG_EMAIL=... GIG_PASSWORD=...
// Production base URL: https://thirdpartynode.theagilitysystems.com
//
// Confirmed from GIG's docs: POST /login {email, password} -> data.data["access-token"].
// Every other path and field below is marked CONFIRM: check it against the matching
// page of the GIG API reference before going live, then delete the marker.

const BASE = Deno.env.get("GIG_BASE_URL") ?? "https://dev-thirdpartynode.theagilitysystems.com";

export const GIG_PATHS = {
  login: "/login",                               // confirmed
  price: "/price",                               // CONFIRM: "Fetch Shipment Price V3"
  capture: "/capture/preshipment",               // CONFIRM: "Capture PreShipment Mobile"
  track: "/track/mobileShipment",                // CONFIRM: "Track Mobile shipment" (GET, waybill in query)
  trackMany: "/track/multipleMobileShipment",    // CONFIRM: "Track multiple mobile shipment" (POST)
  cancel: "/cancel/preshipment",                 // CONFIRM: "Cancel Preshipment"
  pod: "/proofOfDelivery",                       // CONFIRM: "Get Proof of Delivery"
  stations: "/localStations",                    // CONFIRM: "Fetch Local Stations"
  homeDelivery: "/activeHomeDelivery",           // CONFIRM: "Active Home Delivery"
};

let token: { value: string; exp: number } | null = null;

async function login(): Promise<string> {
  if (token && token.exp > Date.now() + 60_000) return token.value;
  const r = await fetch(BASE + GIG_PATHS.login, {
    method: "POST",
    headers: { "content-type": "application/json", accept: "application/json" },
    body: JSON.stringify({ email: Deno.env.get("GIG_EMAIL"), password: Deno.env.get("GIG_PASSWORD") }),
  });
  const j = await r.json();
  const t = j?.data?.data?.["access-token"];
  if (!r.ok || !t) throw new Error(`GIG login failed: ${j?.message ?? r.status}`);
  // The token is a JWT; read its expiry so we log in again only when needed.
  let exp = Date.now() + 6 * 3600_000;
  try { exp = JSON.parse(atob(t.split(".")[1])).exp * 1000; } catch { /* keep default */ }
  token = { value: t, exp };
  return t;
}

async function call(method: "GET" | "POST", path: string, body?: unknown, retried = false): Promise<any> {
  const t = await login();
  const r = await fetch(BASE + path, {
    method,
    headers: {
      "content-type": "application/json",
      accept: "application/json",
      "access-token": t,              // CONFIRM: header name GIG expects (may be Authorization: Bearer)
      authorization: `Bearer ${t}`,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (r.status === 401 && !retried) { token = null; return call(method, path, body, true); }
  const j = await r.json().catch(() => ({}));
  if (!r.ok || j?.success === false) throw new Error(`GIG ${path}: ${j?.message ?? j?.data?.message ?? r.status}`);
  return j?.data?.data ?? j?.data ?? j;
}

/* ---------- What Agora needs from GIG ---------- */

export type Party = { name: string; phone: string; address: string; city: string; state: string; lat?: number; lng?: number };
export type Item = { name: string; qty: number; weightKg: number; value: number };

export async function price(from: Party, to: Party, items: Item[], service: "home" | "centre") {
  const d = await call("POST", GIG_PATHS.price, shipmentBody("quote", from, to, items, service)); // CONFIRM fields
  return { price: Math.round(Number(d?.GrandTotal ?? d?.grandTotal ?? d?.Total ?? d?.price ?? 0)), raw: d };
}

export async function capture(orderId: string, from: Party, to: Party, items: Item[], service: "home" | "centre") {
  const d = await call("POST", GIG_PATHS.capture, shipmentBody(orderId, from, to, items, service)); // CONFIRM fields
  const waybill = d?.waybill ?? d?.Waybill ?? d?.WaybillNumber;
  if (!waybill) throw new Error("GIG did not return a waybill");
  return { waybill: String(waybill), price: Math.round(Number(d?.GrandTotal ?? d?.grandTotal ?? 0)), raw: d };
}

export async function track(waybill: string) {
  const d = await call("GET", `${GIG_PATHS.track}?waybill=${encodeURIComponent(waybill)}`); // CONFIRM
  const list: any[] = d?.MobileShipmentTrackings ?? d?.trackings ?? d?.tracking ?? (Array.isArray(d) ? d : []);
  return list.map((e) => ({
    code: String(e?.Status ?? e?.status ?? e?.ScanStatus?.Code ?? ""),
    title: String(e?.ScanStatus?.Reason ?? e?.Description ?? e?.description ?? e?.Status ?? ""),
    location: String(e?.Location ?? e?.location ?? ""),
    at: new Date(e?.DateTime ?? e?.DateCreated ?? e?.date ?? Date.now()).toISOString(),
  }));
}

export const cancel = (waybill: string) => call("POST", GIG_PATHS.cancel, { waybill }); // CONFIRM
export const proofOfDelivery = (waybill: string) => call("POST", GIG_PATHS.pod, { waybill }); // CONFIRM

function shipmentBody(ref: string, from: Party, to: Party, items: Item[], service: "home" | "centre") {
  // CONFIRM every field name against "Capture PreShipment Mobile" / "Fetch Shipment Price V3".
  return {
    ReceiverName: to.name,
    ReceiverPhoneNumber: to.phone,
    ReceiverAddress: `${to.address}, ${to.city}, ${to.state}`,
    ReceiverStationId: null,
    ReceiverLocation: to.lat ? { Latitude: to.lat, Longitude: to.lng } : undefined,
    SenderName: from.name,
    SenderPhoneNumber: from.phone,
    SenderAddress: `${from.address}, ${from.city}, ${from.state}`,
    SenderLocation: from.lat ? { Latitude: from.lat, Longitude: from.lng } : undefined,
    IsHomeDelivery: service === "home",
    VehicleType: "BIKE",
    CustomerCode: ref,
    PreShipmentItems: items.map((i) => ({
      ItemName: i.name,
      Description: i.name,
      Quantity: i.qty,
      Weight: i.weightKg,
      Value: i.value,
      ShipmentType: 1,
    })),
  };
}

/* ---------- GIG status -> Agora stage (same rules as the app) ---------- */

export function stageFrom(code: string, description: string): string {
  const d = description.toLowerCase();
  const c = code.toUpperCase();
  if (d.includes("cancel")) return "cancelled";
  if (d.includes("fail") || d.includes("unable") || d.includes("return")) return "failed";
  if (d.includes("delivered") || d.includes("collected by") || c === "OKT" || c === "OKC") return "delivered";
  if (d.includes("out for delivery") || d.includes("with courier") || d.includes("dispatched for delivery")) return "out";
  if (d.includes("arrived") || d.includes("ready for pickup") || d.includes("available for collection")) return "arrived";
  if (d.includes("transit") || d.includes("departed") || d.includes("in route") || d.includes("enroute")) return "transit";
  if (d.includes("picked") || d.includes("received") || d.includes("shipment collected")) return "picked";
  return "booked";
}

const ORDER = ["booked", "picked", "transit", "arrived", "out", "delivered"];
/** The furthest stage reached across all events (scans can arrive out of order). */
export function latestStage(events: { code: string; title: string }[]): string {
  let best = "booked";
  for (const e of events) {
    const s = stageFrom(e.code, e.title);
    if (s === "cancelled" || s === "failed") best = s;
    else if (ORDER.indexOf(s) > ORDER.indexOf(best)) best = s;
  }
  return best;
}
