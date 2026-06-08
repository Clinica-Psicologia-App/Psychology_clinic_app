import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertEmailAvailableInClinic,
  assertProfileInClinic,
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
import {
  buildInviteUrl,
  generateInvitationToken,
  hashInvitationToken,
  invitationExpiresAt,
} from "../_shared/invitations.ts";
import { logger } from "../_shared/logger.ts";
import {
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

type CreatePatientInvitationBody = {
  email: string;
  full_name?: string;
  phone?: string;
  responsible_psychologist_id: string;
};

const FN = "create-patient-invitation";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);

    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const caller = await getCallerProfile(userClient);
    requireStaff(caller);

    const body = await parseJsonBody<CreatePatientInvitationBody>(req);
    const email = body.email?.trim().toLowerCase();
    const fullName = body.full_name?.trim();
    const phone = body.phone?.trim();

    if (!email || !email.includes("@")) {
      throw new AppError("VALIDATION_ERROR", "Email inválido.", 400);
    }

    const psychologistId = assertUuid(
      body.responsible_psychologist_id,
      "responsible_psychologist_id",
    );

    if (caller.role === "psychologist" && psychologistId !== caller.id) {
      throw new AppError(
        "FORBIDDEN",
        "Psychologist can only assign themselves as responsible",
        403,
      );
    }

    await assertProfileInClinic(
      userClient,
      psychologistId,
      caller.clinic_id,
      "responsible_psychologist_id",
      ["admin", "psychologist"],
    );
    await assertEmailAvailableInClinic(
      userClient,
      caller.clinic_id,
      email,
    );

    const pendingInvitation = await userClient
      .from("patient_invitations")
      .select("id")
      .eq("clinic_id", caller.clinic_id)
      .ilike("email", email)
      .eq("status", "pending")
      .maybeSingle();

    if (pendingInvitation.error) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to validate pending invitations",
        500,
        { hint: pendingInvitation.error.message },
      );
    }

    if (pendingInvitation.data != null) {
      throw new AppError(
        "CONFLICT",
        "Já existe um convite pendente para este e-mail.",
        409,
      );
    }

    const token = generateInvitationToken();
    const tokenHash = await hashInvitationToken(token);
    const expiresAt = invitationExpiresAt();

    const { data: invitation, error: invitationError } = await userClient
      .from("patient_invitations")
      .insert({
        clinic_id: caller.clinic_id,
        invited_by: caller.id,
        responsible_psychologist_id: psychologistId,
        email,
        full_name: fullName ?? null,
        phone: phone ?? null,
        token_hash: tokenHash,
        expires_at: expiresAt,
      })
      .select(
        "id, clinic_id, email, full_name, phone, status, expires_at, created_at, invited_by, responsible_psychologist_id",
      )
      .single();

    if (invitationError) {
      logger.error(`${FN}.insert_failed`, {
        message: invitationError.message,
        clinic_id: caller.clinic_id,
      });
      throw new AppError(
        invitationError.code === "23505" ? "CONFLICT" : "INTERNAL_ERROR",
        invitationError.code === "23505"
          ? "Já existe um convite pendente para este e-mail."
          : "Failed to create patient invitation",
        invitationError.code === "23505" ? 409 : 500,
        { hint: invitationError.message },
      );
    }

    const inviteUrl = buildInviteUrl(token);

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      invitation_id: invitation.id,
      clinic_id: caller.clinic_id,
    });

    return jsonResponse({
      ok: true,
      data: {
        invitation,
        invite_url: inviteUrl,
        expires_at: expiresAt,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
