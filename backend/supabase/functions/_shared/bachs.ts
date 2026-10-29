// Bachs (bachs.io) payments client. Escrow on Bachs works like this:
//   1. The buyer pays Agora (platform checkout). The money sits in Agora's Bachs balance.
//   2. GIG delivers. The buyer confirms, or 72 hours pass with no dispute.
//   3. Agora pays the seller's bank account with a Bachs payout (POST /v1/payouts).
// Refunds before release come out of Agora's balance (POST refund, see docs/guides/refunds).
//
// Secrets: supabase secrets set BACHS_API_KEY=sk_sandbox_... BACHS_BASE_URL=https://sandbox-api.bachs.io BACHS_WEBHOOK_SECRET=...
// Live: BACHS_BASE_URL=https://api.bachs.io with an sk_live_ key.

const BASE = Deno.env.get("BACHS_BASE_URL") ?? "https://sandbox-api.bachs.io";

async function call(method: string, path: string, body?: unknown, idempotencyKey?: string) {
  const r = await fetch(BASE + path, {
    method,
    headers: {
      authorization: `Bearer ${Deno.env.get("BACHS_API_KEY")}`,
      "content-type": "application/json",
      ...(idempotencyKey ? { "Idempotency-Key": idempotencyKey } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(`Bachs ${path}: ${j?.error?.message ?? j?.message ?? r.status}`);
  return j;
}

const money = (naira: number) => naira.toFixed(2);

/** A hosted checkout for one order. Returns the URL the buyer pays on. */
export async function checkout(order: { id: string; total: number; buyerEmail: string }, successUrl: string, cancelUrl: string) {
  // Each order is priced on the fly as a one-off product. CONFIRM: Bachs may allow inline
  // pricing on product_cart, which would skip creating a product.
  const product = await call("POST", "/v1/products", { name: `Agora order ${order.id}`, description: "Held in escrow until delivery", price: { currency: "NGN", amount: money(order.total) } }, `product-${order.id}`);
  const s = await call("POST", "/v1/checkout-sessions", {
    product_cart: [{ product_id: product.id, quantity: 1 }],
    customer: { email: order.buyerEmail },
    metadata: { order_id: order.id },   // CONFIRM: metadata support
    success_url: successUrl,
    cancel_url: cancelUrl,
  }, `checkout-${order.id}`);
  return { id: s.id as string, url: (s.checkout_url ?? s.url) as string };
}

export const getCheckout = (id: string) => call("GET", `/v1/checkout-sessions/${id}`);

/** Registers a seller's bank account. The bank returns the real account name. */
export async function payoutDestination(bankCode: string, accountNumber: string) {
  const d = await call("POST", "/v1/payouts/destinations", { currency: "NGN", account_number: accountNumber, bank_code: bankCode });
  return { id: d.id as string, accountName: d.account_name as string, bankName: d.bank_name as string, usable: !!d.is_usable };
}

/** Pays the seller. The idempotency key makes a retry safe: it never pays twice. */
export const payout = (destinationId: string, naira: number, orderId: string) =>
  call("POST", "/v1/payouts", { destination: destinationId, amount: money(naira), reference: `agora-${orderId}` }, `release-${orderId}`);

/** Refunds the buyer in full. CONFIRM path against docs/guides/refunds. */
export const refund = (chargeId: string, orderId: string) => call("POST", "/v1/refunds", { charge: chargeId }, `refund-${orderId}`);

export const banks = () => call("GET", "/v1/reference/banks?country=NG");

/** Checks a webhook really came from Bachs. CONFIRM the header name and scheme in the webhook docs. */
export async function verifyWebhook(req: Request, raw: string) {
  const secret = Deno.env.get("BACHS_WEBHOOK_SECRET");
  const sig = req.headers.get("bachs-signature") ?? req.headers.get("x-bachs-signature") ?? "";
  if (!secret || !sig) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(raw));
  const hex = [...new Uint8Array(mac)].map((b) => b.toString(16).padStart(2, "0")).join("");
  return sig.split(",").some((p) => p.trim().endsWith(hex));
}

/** Agora's commission, kept from each order before paying the seller. */
export const commission = (subtotal: number) => Math.round(subtotal * Number(Deno.env.get("AGORA_COMMISSION") ?? "0.05"));
