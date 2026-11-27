import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { sendEmail } from "../_shared/email.ts";
import { createServiceClient, createUserClient } from "../_shared/supabase.ts";
import { handleCreatePatientInvitation } from "./handler.ts";

serve((req) =>
  handleCreatePatientInvitation(req, {
    createUserClient,
    createServiceClient,
    sendEmail,
  })
);
