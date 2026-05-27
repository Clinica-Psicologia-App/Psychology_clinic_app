import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "./errors.ts";

export type Database = Record<string, unknown>;

function getEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new AppError("INTERNAL_ERROR", `Missing env: ${name}`, 500);
  }
  return value;
}

export function createUserClient(authHeader: string): SupabaseClient {
  return createClient(
    getEnv("SUPABASE_URL"),
    getEnv("SUPABASE_ANON_KEY"),
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}

export function createServiceClient(): SupabaseClient {
  return createClient(
    getEnv("SUPABASE_URL"),
    getEnv("SUPABASE_SERVICE_ROLE_KEY"),
    {
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}

export function getBearerToken(req: Request): string {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    throw new AppError("UNAUTHORIZED", "Missing Bearer token", 401);
  }
  return authHeader;
}
