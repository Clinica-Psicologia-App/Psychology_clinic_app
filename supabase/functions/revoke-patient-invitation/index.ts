import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleRevokePatientInvitation } from "./handler.ts";
import { createServiceClient, createUserClient } from "../_shared/supabase.ts";

serve((req) =>
  handleRevokePatientInvitation(req, {
    createUserClient,
    createServiceClient,
  })
);
