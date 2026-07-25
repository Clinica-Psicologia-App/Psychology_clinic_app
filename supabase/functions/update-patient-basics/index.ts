import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertPatientAccess,
  assertUuid,
  getCallerProfile,
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
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

/**
 * Bloco 1 do fluxo "Conhecer" (Conhecendo Você).
 *
 * Existe porque a policy `patients_update_staff` só deixa staff atualizar
 * `patients` — o paciente consegue LER a própria linha, mas não escrever.
 * Esta função valida o chamador e grava com service role apenas as colunas
 * da lista branca abaixo, sem afrouxar a RLS da tabela.
 */
type UpdatePatientBasicsBody = {
  patient_id: string;
  preferred_name?: string | null;
  birth_date?: string | null;
  occupation?: string | null;
  lives_with?: string | null;
  has_children?: boolean | null;
  uses_medication?: boolean | null;
  medication_notes?: string | null;
  psychiatric_followup?: boolean | null;
  psychiatrist_notes?: string | null;
  important_to_know?: string | null;
};

const FN = "update-patient-basics";

/** Colunas que o paciente pode escrever sobre si. Identidade e vínculo
 * clínico (full_name, email, cpf, responsible_psychologist_id, is_active…)
 * ficam de fora de propósito. */
const TEXT_FIELDS = [
  "preferred_name",
  "occupation",
  "lives_with",
  "medication_notes",
  "psychiatrist_notes",
  "important_to_know",
] as const;

const BOOL_FIELDS = [
  "has_children",
  "uses_medication",
  "psychiatric_followup",
] as const;

const RETURN_COLUMNS =
  "id, preferred_name, birth_date, occupation, lives_with, has_children, " +
  "uses_medication, medication_notes, psychiatric_followup, psychiatrist_notes, " +
  "important_to_know";

const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function normalizeText(value: unknown): string | null {
  if (value === null) return null;
  if (typeof value !== "string") {
    throw new AppError("VALIDATION_ERROR", "Expected a text value", 400);
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function normalizeBool(value: unknown): boolean | null {
  if (value === null) return null;
  if (typeof value !== "boolean") {
    throw new AppError("VALIDATION_ERROR", "Expected a boolean value", 400);
  }
  return value;
}

function normalizeBirthDate(value: unknown): string | null {
  if (value === null) return null;
  if (typeof value !== "string" || !ISO_DATE_RE.test(value.trim())) {
    throw new AppError(
      "VALIDATION_ERROR",
      "birth_date must be an ISO date (YYYY-MM-DD)",
      400,
      { field: "birth_date" },
    );
  }
  return value.trim();
}

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    const caller = await getCallerProfile(client);

    const body = await parseJsonBody<UpdatePatientBasicsBody>(req);
    const patientId = assertUuid(body.patient_id, "patient_id");

    // O paciente só pode editar a si mesmo; staff precisa ter acesso ao
    // paciente (validado pela RLS através do client do usuário).
    if (caller.role === "patient") {
      const { data: ownPatient } = await client
        .from("patients")
        .select("id")
        .eq("profile_id", caller.id)
        .maybeSingle();

      if (!ownPatient || ownPatient.id !== patientId) {
        throw new AppError(
          "FORBIDDEN",
          "Patient can only update their own basic information",
          403,
        );
      }
    } else {
      await assertPatientAccess(client, patientId);
    }

    // Monta o payload apenas com os campos enviados (update parcial).
    const payload: Record<string, unknown> = {};
    for (const field of TEXT_FIELDS) {
      if (body[field] !== undefined) payload[field] = normalizeText(body[field]);
    }
    for (const field of BOOL_FIELDS) {
      if (body[field] !== undefined) payload[field] = normalizeBool(body[field]);
    }
    if (body.birth_date !== undefined) {
      payload.birth_date = normalizeBirthDate(body.birth_date);
    }

    if (Object.keys(payload).length === 0) {
      throw new AppError("VALIDATION_ERROR", "No fields to update", 400);
    }

    // Service role: a escrita já foi autorizada acima.
    const serviceClient = createServiceClient();
    const { data: updated, error: updateError } = await serviceClient
      .from("patients")
      .update(payload)
      .eq("id", patientId)
      .select(RETURN_COLUMNS)
      .single();

    if (updateError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to update patient basic information",
        500,
        { hint: updateError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      caller_role: caller.role,
      patient_id: patientId,
      fields: Object.keys(payload),
    });

    return jsonResponse({ ok: true, data: { patient: updated } });
  } catch (error) {
    return handleError(error, FN);
  }
});
