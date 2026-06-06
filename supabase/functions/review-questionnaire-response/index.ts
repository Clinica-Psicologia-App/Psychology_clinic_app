import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
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

type ReviewQuestionnaireResponseBody = {
  response_id: string;
  reviewed: boolean;
  review_notes?: string | null;
};

const FN = "review-questionnaire-response";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    const caller = await getCallerProfile(client);
    requireStaff(caller);

    const body = await parseJsonBody<ReviewQuestionnaireResponseBody>(req);
    const responseId = assertUuid(body.response_id, "response_id");
    const reviewed = body.reviewed === true;
    const notes = normalizeNotes(body.review_notes);

    const { data: response, error: loadError } = await client
      .from("questionnaire_responses")
      .select("id")
      .eq("id", responseId)
      .eq("clinic_id", caller.clinic_id)
      .maybeSingle();

    if (loadError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to load questionnaire response",
        500,
        { hint: loadError.message },
      );
    }

    if (!response) {
      throw new AppError(
        "FORBIDDEN",
        "Questionnaire response not found or access denied",
        403,
        { response_id: responseId },
      );
    }

    const now = new Date().toISOString();
    const payload = reviewed
      ? {
        reviewed_at: now,
        reviewed_by_profile_id: caller.id,
        review_notes: notes,
      }
      : {
        reviewed_at: null,
        reviewed_by_profile_id: null,
        review_notes: null,
      };

    const { data: updated, error: updateError } = await client
      .from("questionnaire_responses")
      .update(payload)
      .eq("id", responseId)
      .select("id, reviewed_at, review_notes")
      .single();

    if (updateError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to update questionnaire review state",
        500,
        { hint: updateError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      response_id: responseId,
      reviewed,
    });

    return jsonResponse({ ok: true, data: { response: updated } });
  } catch (error) {
    return handleError(error, FN);
  }
});

function normalizeNotes(value?: string | null): string | null {
  const trimmed = value?.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, 1000);
}
