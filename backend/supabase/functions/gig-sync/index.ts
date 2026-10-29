// Runs every 15 minutes (pg_cron, see the migration).
// 1. Retries GIG bookings that failed.
// 2. Pulls tracking for every parcel that is still moving.

import { admin, isService, json } from "../_shared/db.ts";
import { bookOrder, refresh } from "../_shared/shipping.ts";

Deno.serve(async (req) => {
  if (!isService(req)) return json({ error: "Service only" }, 401);
  const out = { booked: 0, refreshed: 0, errors: [] as string[] };

  const { data: unbooked } = await admin.from("shipments").select("order_id, attempts").is("waybill", null).lt("attempts", 10);
  for (const s of unbooked ?? []) {
    try { await bookOrder(s.order_id); out.booked++; } catch (e) { out.errors.push(`${s.order_id}: ${e}`); }
  }

  const { data: moving } = await admin.from("shipments").select("id").not("waybill", "is", null).not("stage", "in", "(delivered,cancelled)");
  for (const s of moving ?? []) {
    try { await refresh(s.id); out.refreshed++; } catch (e) { out.errors.push(`${s.id}: ${e}`); }
  }
  return json(out);
});
