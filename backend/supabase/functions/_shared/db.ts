import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";

/** Service client: bypasses row-level security. Only used on the server. */
export const admin: SupabaseClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

export const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "content-type": "application/json" } });

/** Who is calling: their user id and role, from the Supabase session token. */
export async function caller(req: Request): Promise<{ id: string; role: string } | null> {
  const jwt = (req.headers.get("authorization") ?? "").replace("Bearer ", "");
  if (!jwt) return null;
  const { data } = await admin.auth.getUser(jwt);
  if (!data?.user) return null;
  const { data: p } = await admin.from("profiles").select("role").eq("id", data.user.id).single();
  return { id: data.user.id, role: p?.role ?? "buyer" };
}

/** True for the service key (cron jobs and webhooks we trust). */
export const isService = (req: Request) =>
  (req.headers.get("authorization") ?? "") === `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`;

/** Can this user see this order? Buyer, store owner or Agora admin. */
export async function canSeeOrder(user: { id: string; role: string }, orderId: string) {
  if (user.role === "admin") return true;
  const { data } = await admin.from("orders").select("buyer_id, stores(owner_id)").eq("id", orderId).single();
  return !!data && (data.buyer_id === user.id || (data as any).stores?.owner_id === user.id);
}
