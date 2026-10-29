// POST /functions/v1/pay { order_id }  -> { url }
// The buyer's app opens the Bachs checkout URL. Payment lands in Agora's balance (escrow).

import { admin, caller, cors, json } from "../_shared/db.ts";
import * as bachs from "../_shared/bachs.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const user = await caller(req);
    if (!user) return json({ error: "Please sign in" }, 401);
    const { order_id } = await req.json();
    const { data: o } = await admin.from("orders").select("id, buyer_id, total, status").eq("id", order_id).single();
    if (!o || o.buyer_id !== user.id) return json({ error: "Order not found" }, 404);
    if (o.status !== "awaiting_payment") return json({ error: "This order is already paid" }, 409);

    const { data: u } = await admin.auth.admin.getUserById(user.id);
    const site = Deno.env.get("SITE_URL") ?? "https://agoramarket.ng";
    const c = await bachs.checkout({ id: o.id, total: o.total, buyerEmail: u.user?.email ?? "" }, `${site}/orders/${o.id}?paid=1`, `${site}/orders/${o.id}?cancelled=1`);
    await admin.from("orders").update({ bachs_checkout_id: c.id }).eq("id", o.id);
    return json({ url: c.url });
  } catch (e) {
    console.error(e);
    return json({ error: String((e as Error).message ?? e) }, 500);
  }
});
