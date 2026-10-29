// POST /functions/v1/escrow { action, ... }
//
// confirm      {order_id, photo?}  buyer: the order arrived as described -> pay the seller
// dispute      {order_id, reason}  buyer: something is wrong -> money stays held, staff review
// release      {order_id}          admin: pay the seller after a dispute is resolved
// refund       {order_id}          admin: give the buyer their money back
// auto_release                     cron: pay sellers 72 hours after delivery with no dispute
// bank         {bank_code, account_number}  seller: register payout account, returns the bank's account name

import { admin, caller, cors, isService, json } from "../_shared/db.ts";
import * as bachs from "../_shared/bachs.ts";

async function release(orderId: string) {
  const { data: o } = await admin.from("orders").select("id, status, subtotal, stores(bachs_destination_id, name)").eq("id", orderId).single();
  if (!o) throw new Error("Order not found");
  if (!["delivered", "disputed"].includes(o.status)) throw new Error(`Cannot release an order that is ${o.status}`);
  const dest = (o as any).stores?.bachs_destination_id;
  if (!dest) throw new Error("The seller has no verified payout account yet");
  const amount = o.subtotal - bachs.commission(o.subtotal); // delivery fee went to GIG
  const p = await bachs.payout(dest, amount, o.id);
  await admin.from("orders").update({ bachs_payout_id: p.id, confirmed_at: new Date().toISOString() }).eq("id", o.id);
  return p;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const body = await req.json();
    if (body.action === "auto_release") {
      if (!isService(req)) return json({ error: "Service only" }, 401);
      const cutoff = new Date(Date.now() - 72 * 3600_000).toISOString();
      const { data } = await admin.from("orders").select("id").eq("status", "delivered").is("bachs_payout_id", null).lt("delivered_at", cutoff);
      const done: string[] = [];
      for (const o of data ?? []) { try { await release(o.id); done.push(o.id); } catch (e) { console.error(o.id, e); } }
      return json({ released: done });
    }

    const user = await caller(req);
    if (!user) return json({ error: "Please sign in" }, 401);

    if (body.action === "bank") {
      const d = await bachs.payoutDestination(body.bank_code, body.account_number);
      await admin.from("stores").update({ bank_code: body.bank_code, account_number: body.account_number, account_name: d.accountName, bachs_destination_id: d.id }).eq("owner_id", user.id);
      return json({ account_name: d.accountName, bank_name: d.bankName, usable: d.usable });
    }

    const { data: o } = await admin.from("orders").select("id, buyer_id, status, bachs_charge_id").eq("id", body.order_id).single();
    if (!o) return json({ error: "Order not found" }, 404);
    const isBuyer = o.buyer_id === user.id, isAdmin = user.role === "admin";

    switch (body.action) {
      case "confirm":
        if (!isBuyer) return json({ error: "Only the buyer can confirm" }, 403);
        if (body.photo) await admin.from("orders").update({ confirm_photo: body.photo }).eq("id", o.id);
        return json({ payout: await release(o.id) });
      case "dispute":
        if (!isBuyer) return json({ error: "Only the buyer can open a dispute" }, 403);
        await admin.from("orders").update({ status: "disputed" }).eq("id", o.id).in("status", ["held", "dispatched", "delivered"]);
        return json({ ok: true });
      case "release":
        if (!isAdmin) return json({ error: "Staff only" }, 403);
        return json({ payout: await release(o.id) });
      case "refund":
        if (!isAdmin) return json({ error: "Staff only" }, 403);
        if (!o.bachs_charge_id) return json({ error: "No payment to refund" }, 409);
        await bachs.refund(o.bachs_charge_id, o.id);
        await admin.from("orders").update({ status: "refunded" }).eq("id", o.id);
        return json({ ok: true });
    }
    return json({ error: `Unknown action ${body.action}` }, 400);
  } catch (e) {
    console.error(e);
    return json({ error: String((e as Error).message ?? e) }, 500);
  }
});
