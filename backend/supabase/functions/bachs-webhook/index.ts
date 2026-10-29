// Bachs calls this when money moves. Set the webhook URL in the Bachs dashboard to
// https://<project>.supabase.co/functions/v1/bachs-webhook (deploy with --no-verify-jwt).
//
// checkout.completed -> order is paid: mark it "held" (escrow) and book the GIG pickup.
// payout.paid        -> the seller got their money: mark the order "released".
// payout.failed      -> flag it for Agora staff.

import { admin, json } from "../_shared/db.ts";
import * as bachs from "../_shared/bachs.ts";
import { bookOrder } from "../_shared/shipping.ts";

Deno.serve(async (req) => {
  const raw = await req.text();
  const signed = await bachs.verifyWebhook(req, raw);
  const evt = JSON.parse(raw);
  const type: string = evt.type ?? evt.event;
  const data = evt.data ?? {};

  try {
    if (type === "checkout.completed") {
      // Never trust the payload alone: read the checkout back from Bachs.
      const c = await bachs.getCheckout(data.id);
      if (!signed && c.status !== "completed") return json({ error: "unverified" }, 401);
      if (c.payment_status !== "paid" && c.data?.payment_status !== "paid") return json({ ok: true, ignored: "not paid" });
      const { data: o } = await admin.from("orders").select("id, status").eq("bachs_checkout_id", c.id).single();
      if (o && o.status === "awaiting_payment") {
        await admin.from("orders").update({ status: "held", paid_at: new Date().toISOString(), bachs_charge_id: c.charge?.id ?? data.charge?.id ?? null }).eq("id", o.id);
        await bookOrder(o.id).catch((e) => console.error("GIG booking will retry", e));
      }
    } else if (signed && type === "payout.paid") {
      await admin.from("orders").update({ status: "released", released_at: new Date().toISOString() }).eq("bachs_payout_id", data.id);
    } else if (signed && type === "payout.failed") {
      console.error("Payout failed", data.id, data.failure_reason);
    }
    return json({ ok: true });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500); // Bachs retries on errors
  }
});
