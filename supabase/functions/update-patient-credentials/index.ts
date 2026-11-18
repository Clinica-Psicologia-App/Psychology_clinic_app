import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleUpdatePatientCredentials } from "./handler.ts";
import {
  createServiceClient,
  createUserClient,
} from "../_shared/supabase.ts";

serve((req) =>
  handleUpdatePatientCredentials(req, {
    createUserClient,
    createServiceClient,
  })
);
