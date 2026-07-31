import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertPatientAccess,
  assertUuid,
  getCallerProfile,
  requireStaff,
} from "../_shared/auth.ts";
import { AppError } from "../_shared/errors.ts";
import {
  handleError,
  handleOptions,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import { logger } from "../_shared/logger.ts";
import { createUserClient, getBearerToken } from "../_shared/supabase.ts";

type AssignQuestionnaireBody = {
  patient_id: string;
  questionnaire_id: string;
  message?: string;
};

const FN = "assign-questionnaire";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    const caller = await getCallerProfile(client);

    requireStaff(caller);

    const body = await parseJsonBody<AssignQuestionnaireBody>(req);
    const patientId = assertUuid(body.patient_id, "patient_id");
    const questionnaireId = assertUuid(body.questionnaire_id, "questionnaire_id");

    await assertPatientAccess(client, patientId);

    // Verify questionnaire is active
    const { data: questionnaire, error: qError } = await client
      .from("questionnaires")
      .select("id, code, name, is_active")
      .eq("id", questionnaireId)
      .eq("is_active", true)
      .maybeSingle();

    if (qError) {
      throw new AppError("INTERNAL_ERROR", "Failed to load questionnaire", 500, {
        hint: qError.message,
      });
    }
    if (!questionnaire) {
      throw new AppError("NOT_FOUND", "Questionnaire not found or inactive", 404, {
        questionnaire_id: questionnaireId,
      });
    }

    // Verify psychologist has access to this questionnaire
    const { data: access, error: accessError } = await client
      .from("questionnaire_professional_access")
      .select("id")
      .eq("professional_id", caller.id)
      .eq("questionnaire_id", questionnaireId)
      .eq("is_enabled", true)
      .maybeSingle();

    if (accessError) {
      throw new AppError("INTERNAL_ERROR", "Failed to verify questionnaire access", 500, {
        hint: accessError.message,
      });
    }
    if (!access) {
      throw new AppError(
        "FORBIDDEN",
        "You do not have access to this questionnaire",
        403,
        { questionnaire_id: questionnaireId },
      );
    }

    // Resolve patient row to get clinic_id-scoped patient id
    const { data: patient, error: patientError } = await client
      .from("patients")
      .select("id, clinic_id")
      .eq("id", patientId)
      .maybeSingle();

    if (patientError || !patient) {
      throw new AppError("FORBIDDEN", "Patient not found or access denied", 403);
    }

    const message = body.message?.trim() || null;

    const { data: assignment, error: insertError } = await client
      .from("patient_questionnaire_assignments")
      .insert({
        clinic_id: patient.clinic_id,
        patient_id: patientId,
        questionnaire_id: questionnaireId,
        assigned_by_profile_id: caller.id,
        message,
      })
      .select(
        "id, clinic_id, patient_id, questionnaire_id, assigned_by_profile_id, assigned_at, message, response_id, cancelled_at",
      )
      .single();

    if (insertError) {
      throw new AppError("INTERNAL_ERROR", "Failed to create assignment", 500, {
        hint: insertError.message,
      });
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      assignment_id: assignment.id,
      patient_id: patientId,
      questionnaire_id: questionnaireId,
    });

    return jsonResponse({
      ok: true,
      data: { assignment },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
