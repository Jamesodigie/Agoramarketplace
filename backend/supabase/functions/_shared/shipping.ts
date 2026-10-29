import { admin } from "./db.ts";
import * as gig from "./gig.ts";

/** Books the GIG pickup for a paid order. Safe to call twice: it does nothing if already booked. */
export async function bookOrder(orderId: string) {
  const { data: o, error } = await admin.from("orders").select("*, stores(*)").eq("id", orderId).single();
  if (error || !o) throw new Error("Order not found");
  const { data: existing } = await admin.from("shipments").select("*").eq("order_id", orderId).maybeSingle();
  if (existing?.waybill) return existing;

  const s = o.stores;
  const from: gig.Party = { name: s.name, phone: s.pickup_phone ?? "", address: `${s.street}, ${s.area}`, city: s.city, state: s.state };
  const to: gig.Party = { name: o.ship_name, phone: o.ship_phone, address: o.ship_address, city: o.ship_city, state: o.ship_state };
  const items = await itemsFor(o.items);

  const row = existing ?? (await admin.from("shipments").insert({
    order_id: orderId, service: o.delivery_service, price: o.delivery_fee,
    from_name: s.name, from_city: `${s.area}, ${s.city}`, to_name: o.ship_name, to_city: `${o.ship_city}, ${o.ship_state}`, to_phone: o.ship_phone,
  }).select().single()).data;

  try {
    const r = await gig.capture(orderId, from, to, items, o.delivery_service);
    const { data } = await admin.from("shipments").update({ waybill: r.waybill, stage: "booked", last_error: null, updated_at: new Date().toISOString() }).eq("id", row.id).select().single();
    await admin.from("shipment_events").insert({ shipment_id: row.id, stage: "booked", code: "AGORA", title: "Shipment created. GIG rider assigned for pickup", location: `${s.area}, ${s.city}`, at: new Date().toISOString() });
    return data;
  } catch (e) {
    // Leave it for gig-sync to retry, and let admins see the error.
    await admin.from("shipments").update({ last_error: String(e), attempts: (row.attempts ?? 0) + 1 }).eq("id", row.id);
    throw e;
  }
}

/** Pulls the latest scans from GIG and moves the order along. */
export async function refresh(shipmentId: string) {
  const { data: sh } = await admin.from("shipments").select("*").eq("id", shipmentId).single();
  if (!sh?.waybill) return sh;
  const scans = await gig.track(sh.waybill);
  if (scans.length) {
    await admin.from("shipment_events").upsert(
      scans.map((e) => ({ shipment_id: sh.id, stage: gig.stageFrom(e.code, e.title), code: e.code, title: e.title, location: e.location, at: e.at })),
      { onConflict: "shipment_id,code,at", ignoreDuplicates: true },
    );
  }
  const stage = scans.length ? gig.latestStage(scans) : sh.stage;
  const patch: Record<string, unknown> = { stage, updated_at: new Date().toISOString() };

  if (stage === "delivered" && sh.stage !== "delivered") {
    try {
      const pod = await gig.proofOfDelivery(sh.waybill);
      patch.pod_name = pod?.ReceiverName ?? pod?.receiverName ?? null;
      patch.pod_photo = pod?.ImageUrl ?? pod?.PictureUrl ?? null;
    } catch { /* proof of delivery can come later */ }
    await admin.from("orders").update({ status: "delivered", delivered_at: new Date().toISOString() }).eq("id", sh.order_id).in("status", ["held", "dispatched"]);
  } else if (["picked", "transit", "arrived", "out"].includes(stage)) {
    await admin.from("orders").update({ status: "dispatched" }).eq("id", sh.order_id).eq("status", "held");
  }
  const { data } = await admin.from("shipments").update(patch).eq("id", sh.id).select().single();
  return data;
}

/** The shipment with its events, shaped the way the app reads it. */
export async function shipmentJson(where: { id?: string; waybill?: string; order_id?: string }) {
  let q = admin.from("shipments").select("*, shipment_events(*)");
  for (const [k, v] of Object.entries(where)) if (v) q = q.eq(k, v);
  const { data } = await q.single();
  if (!data) return null;
  const events = (data.shipment_events ?? []).sort((a: any, b: any) => a.at.localeCompare(b.at));
  return { ...data, events, shipment_events: undefined };
}

async function itemsFor(items: { product_id: string; name: string; price: number; qty: number }[]): Promise<gig.Item[]> {
  const ids = items.map((i) => i.product_id);
  const { data } = await admin.from("products").select("id, weight_kg").in("id", ids);
  const w = new Map((data ?? []).map((p: any) => [p.id, Number(p.weight_kg) || 1]));
  return items.map((i) => ({ name: i.name, qty: i.qty, weightKg: w.get(i.product_id) ?? 1, value: i.price * i.qty }));
}
