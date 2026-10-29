# Agora backend (Supabase)

The server side of Agora: accounts, stores, orders, escrow payments (Bachs) and delivery (GIG Logistics).
The Flutter app talks only to these functions. GIG and Bachs keys never ship inside the app.

```
supabase/
  migrations/0001_agora.sql     tables, row-level security, store links, live tracking
  functions/
    gig/            quotes at checkout, tracking, shipment lists, book / cancel (staff)
    gig-sync/       every 15 min: retry failed bookings, pull tracking for moving parcels
    pay/            starts a Bachs checkout for an order
    bachs-webhook/  payment received -> money held in escrow -> GIG pickup booked
    escrow/         buyer confirms or disputes, staff release or refund, auto-release after 72 h
    _shared/        gig.ts (GIG client), bachs.ts (Bachs client), shipping.ts, db.ts
```

## How an order moves

1. Checkout: the app asks `gig` for prices from the seller's state to the buyer's (home delivery or GIG centre).
2. Pay: `pay` creates a Bachs checkout. The buyer pays, and the money lands in Agora's Bachs balance.
3. `bachs-webhook` marks the order **held** and books the GIG pickup (`Capture PreShipment`). GIG returns a waybill.
4. `gig-sync` pulls GIG scans every 15 minutes. The order becomes **dispatched**, then **delivered**, and proof of delivery is saved.
   Buyers, sellers and staff see every scan live (Supabase realtime on `shipments` and `shipment_events`).
5. The buyer confirms, or 72 hours pass with no dispute: `escrow` pays the seller's bank through a Bachs payout, minus Agora's commission.
   Disputes keep the money held until staff release or refund it.

## Who sees what

| | Buyer | Seller | Agora admin |
|---|---|---|---|
| Their orders and tracking | ✓ | ✓ (their store) | ✓ (all) |
| Book / cancel / rebook GIG | | | ✓ |
| Release or refund escrow | confirm or dispute | | ✓ |

Make someone staff with: `update profiles set role = 'admin' where id = '<user id>';`

## Deploy

```
supabase link --project-ref <project>
supabase db push
cp .env.example supabase/.env      # fill in GIG and Bachs keys (never commit this file)
supabase secrets set --env-file supabase/.env
supabase functions deploy gig gig-sync pay escrow
supabase functions deploy bachs-webhook --no-verify-jwt
```

Then schedule the two background jobs (commands at the bottom of the migration), set the Bachs webhook URL,
and build the app against the project:

```
flutter build apk --dart-define=AGORA_API=https://<project>.supabase.co --dart-define=AGORA_KEY=<anon key>
```

## Before going live

- GIG: every path and field in `functions/_shared/gig.ts` marked `CONFIRM` must be checked against the
  GIG API reference (only `/login` is confirmed). Test in GIG's sandbox with Postman, as GIG asks, then
  ask GIG to enable live access and switch `GIG_BASE_URL` to `https://thirdpartynode.theagilitysystems.com`.
- Bachs: confirm the webhook signature header and the refund call in `functions/_shared/bachs.ts`,
  and ask Bachs to confirm that holding buyer payments until delivery fits their merchant terms.
