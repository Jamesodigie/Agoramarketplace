// POST /functions/v1/gig  { action, ... }
//
// quote  {from_state, to_state, weight, value}  anyone signed in: delivery prices at checkout
// track  {waybill | order_id}                   buyer, seller or admin of that order: latest GIG scans
// list   {stage?}                                seller: their store's shipments, admin: all shipments
// book   {order_id}                              admin (or the server): book the GIG pickup
// cancel {waybill}                               admin: cancel a pickup that has not happened

import { admin, caller, canSeeOrder, cors, isService, json } from "../_shared/db.ts";
import * as gig from "../_shared/gig.ts";
import { bookOrder, refresh, shipmentJson } from "../_shared/shipping.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const body = await req.json();
    const service = isService(req);
    const user = service ? { id: "service", role: "admin" } : await caller(req);
    if (!user) return json({ error: "Please sign in" }, 401);

    switch (body.action) {
      case "quote": {
        const party = (state: string) => ({ name: "Agora", phone: "", address: state, city: state, state });
        const items = [{ name: "Order", qty: 1, weightKg: Number(body.weight) || 1, value: Number(body.value) || 0 }];
        const [home, centre] = await Promise.all([
          gig.price(party(body.from_state), party(body.to_state), items, "home"),
          gig.price(party(body.from_state), party(body.to_state), items, "centre"),
        ]);
        const eta = body.from_state === body.to_state ? "1–2 days" : "2–5 days";
        return json({ quotes: [{ service: "home", price: home.price, eta }, { service: "centre", price: centre.price, eta }] });
      }

      case "track": {
        const sh = await shipmentJson(body.waybill ? { waybill: body.waybill } : { order_id: body.order_id });
        if (!sh) return json({ error: "Shipment not found" }, 404);
        if (!(await canSeeOrder(user, sh.order_id))) return json({ error: "Not your order" }, 403);
        await refresh(sh.id);
        return json({ shipment: await shipmentJson({ id: sh.id }) });
      }

      case "list": {
        let q = admin.from("shipments").select("*, shipment_events(*), orders!inner(store_id, stores!inner(owner_id))").order("updated_at", { ascending: false }).limit(200);
        if (user.role !== "admin") q = q.eq("orders.stores.owner_id", user.id);
        if (body.stage) q = q.eq("stage", body.stage);
        const { data, error } = await q;
        if (error) throw error;
        return json({ shipments: (data ?? []).map((s: any) => ({ ...s, events: (s.shipment_events ?? []).sort((a: any, b: any) => a.at.localeCompare(b.at)) })) });
      }

      case "book": {
        if (user.role !== "admin") return json({ error: "Staff only" }, 403);
        const sh = await bookOrder(body.order_id);
        return json({ shipment: await shipmentJson({ id: sh.id }) });
      }

      case "cancel": {
        if (user.role !== "admin") return json({ error: "Staff only" }, 403);
        await gig.cancel(body.waybill);
        await admin.from("shipments").update({ stage: "cancelled", updated_at: new Date().toISOString() }).eq("waybill", body.waybill);
        return json({ ok: true });
      }

      default:
        return json({ error: `Unknown action ${body.action}` }, 400);
    }
  } catch (e) {
    console.error(e);
    return json({ error: String((e as Error).message ?? e) }, 500);
  }
});
