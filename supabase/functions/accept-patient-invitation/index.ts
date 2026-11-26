import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleAcceptPatientInvitation } from "./handler.ts";
import { sendPushToUser } from "../_shared/push.ts";
import { createServiceClient } from "../_shared/supabase.ts";

serve((req) =>
  handleAcceptPatientInvitation(req, {
    createServiceClient,
    sendPush: sendPushToUser,
  })
);
