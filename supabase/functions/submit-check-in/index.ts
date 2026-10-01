import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { getCallerProfile } from "../_shared/auth.ts";
import { AppError } from "../_shared/errors.ts";
import {
  handleError,
  handleOptions,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import { logger } from "../_shared/logger.ts";
import { sendPushToUser } from "../_shared/push.ts";
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

type SubmitCheckInBody = {
  mood_score?: number | null;
  mood_emotions?: string[];
  anxiety_score?: number | null;
  energy_score?: number | null;
  sleep_score?: number | null;
  stress_score?: number | null;
  selected_modes?: string[] | null;
  notes?: string | null;
};

const FN = "submit-check-in";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const caller = await getCallerProfile(userClient);

    if (caller.role !== "patient") {
      throw new AppError("FORBIDDEN", "Apenas pacientes podem registrar check-ins.", 403);
    }

    const body = await parseJsonBody<SubmitCheckInBody>(req);

    const { data: patient, error: patientError } = await userClient
      .from("patients")
      .select("id, clinic_id, full_name, responsible_psychologist_id")
      .eq("profile_id", caller.id)
      .maybeSingle();

    if (patientError || !patient) {
      throw new AppError("NOT_FOUND", "Cadastro de paciente não encontrado.", 404);
    }

    const { data: checkIn, error: insertError } = await userClient
      .from("patient_check_ins")
      .insert({
        clinic_id: patient.clinic_id,
        patient_id: patient.id,
        created_by: caller.id,
        mood_score: body.mood_score ?? null,
        mood_emotions: body.mood_emotions ?? [],
        anxiety_score: body.anxiety_score ?? null,
        energy_score: body.energy_score ?? null,
        sleep_score: body.sleep_score ?? null,
        stress_score: body.stress_score ?? null,
        selected_modes: body.selected_modes ?? null,
        notes: body.notes?.trim() || null,
      })
      .select(
        "id, clinic_id, patient_id, created_by, mood_score, mood_emotions, anxiety_score, energy_score, sleep_score, stress_score, selected_modes, selected_mode, notes, checked_in_at, created_at, updated_at",
      )
      .single();

    if (insertError || !checkIn) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Falha ao registrar check-in.",
        500,
        { hint: insertError?.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      patient_id: patient.id,
      check_in_id: checkIn.id,
    });

    // Notifica o psicólogo responsável.
    if (patient.responsible_psychologist_id) {
      const serviceClient = createServiceClient();
      try {
        await sendPushToUser(serviceClient, patient.responsible_psychologist_id as string, {
          title: "Novo check-in",
          body: `${patient.full_name} registrou um check-in diário.`,
          data: { type: "check_in_submitted", check_in_id: checkIn.id, patient_id: patient.id },
        });
      } catch (e) {
        console.error("[submit-check-in] push failed", e);
      }
    }

    return jsonResponse({ ok: true, data: { check_in: checkIn } });
  } catch (error) {
    return handleError(error, FN);
  }
});
