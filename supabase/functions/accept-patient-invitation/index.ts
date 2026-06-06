import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { AppError } from "../_shared/errors.ts";
import {
  handleError,
  handleOptions,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import {
  hashInvitationToken,
  invalidInvitationError,
} from "../_shared/invitations.ts";
import { logger } from "../_shared/logger.ts";
import { createServiceClient } from "../_shared/supabase.ts";

type AcceptPatientInvitationBody = {
  token: string;
  password: string;
  profile: {
    full_name?: string;
    phone?: string;
    cpf?: string;
    birth_date?: string;
    gender?: string;
    relationship_status?: string;
    education_level?: string;
    occupation?: string;
    birth_country_state?: string;
    country_birth?: string;
    state_birth?: string;
    religious_orientation?: string;
    ethnic_group?: string;
    sexual_orientation?: string;
    has_children?: boolean;
  };
};

const FN = "accept-patient-invitation";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const serviceClient = createServiceClient();
    const body = await parseJsonBody<AcceptPatientInvitationBody>(req);

    if (!body.password || body.password.length < 8) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Senha deve ter pelo menos 8 caracteres.",
        400,
      );
    }

    const tokenHash = await hashInvitationToken(body.token ?? "");

    const { data: invitation, error: invitationError } = await serviceClient
      .from("patient_invitations")
      .select("*")
      .eq("token_hash", tokenHash)
      .maybeSingle();

    if (invitationError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to load invitation",
        500,
        { hint: invitationError.message },
      );
    }

    if (!invitation) {
      throw invalidInvitationError();
    }

    const now = new Date();
    const expiresAt = new Date(invitation.expires_at as string);
    if (invitation.status !== "pending") {
      throw invalidInvitationError();
    }

    if (Number.isNaN(expiresAt.getTime()) || expiresAt <= now) {
      await serviceClient
        .from("patient_invitations")
        .update({ status: "expired" })
        .eq("id", invitation.id)
        .eq("status", "pending");
      throw invalidInvitationError();
    }

    const profileInput = body.profile ?? {};
    const fullName = profileInput.full_name?.trim() ||
      (invitation.full_name as string | null)?.trim();
    if (!fullName) {
      throw new AppError("VALIDATION_ERROR", "Nome completo é obrigatório.", 400);
    }

    const email = String(invitation.email).trim().toLowerCase();
    const phone = profileInput.phone?.trim() ||
      (invitation.phone as string | null)?.trim() ||
      null;

    const { data: authData, error: authError } = await serviceClient.auth.admin
      .createUser({
        email,
        password: body.password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          clinic_id: invitation.clinic_id,
          role: "patient",
          phone,
        },
      });

    if (authError || !authData.user) {
      logger.warn(`${FN}.auth_create_failed`, { message: authError?.message });
      if (authError?.message?.toLowerCase().includes("already")) {
        throw new AppError(
          "CONFLICT",
          "Este e-mail já está em uso.",
          409,
        );
      }
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create auth user",
        500,
        { hint: authError?.message },
      );
    }

    const profileId = authData.user.id;

    const { error: profileError } = await serviceClient.from("profiles").upsert({
      id: profileId,
      clinic_id: invitation.clinic_id,
      role: "patient",
      full_name: fullName,
      email,
      phone,
      is_active: true,
    });

    if (profileError) {
      await serviceClient.auth.admin.deleteUser(profileId);
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to prepare patient profile",
        500,
        { hint: profileError.message },
      );
    }

    const { data: patient, error: patientError } = await serviceClient
      .from("patients")
      .insert({
        clinic_id: invitation.clinic_id,
        profile_id: profileId,
        responsible_psychologist_id: invitation.responsible_psychologist_id,
        full_name: fullName,
        email,
        phone,
        cpf: profileInput.cpf?.trim() || null,
        birth_date: profileInput.birth_date?.trim() || null,
        gender: profileInput.gender?.trim() || null,
        relationship_status: profileInput.relationship_status?.trim() || null,
        education_level: profileInput.education_level?.trim() || null,
        occupation: profileInput.occupation?.trim() || null,
        country_birth: profileInput.country_birth?.trim() ||
          profileInput.birth_country_state?.trim() ||
          null,
        state_birth: profileInput.state_birth?.trim() || null,
        religious_orientation: profileInput.religious_orientation?.trim() || null,
        ethnic_group: profileInput.ethnic_group?.trim() || null,
        sexual_orientation: profileInput.sexual_orientation?.trim() || null,
        has_children: profileInput.has_children ?? null,
      })
      .select("id, full_name, email, clinic_id, profile_id")
      .single();

    if (patientError || !patient) {
      await serviceClient.auth.admin.deleteUser(profileId);
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create patient record",
        500,
        { hint: patientError?.message },
      );
    }

    const { error: updateInvitationError } = await serviceClient
      .from("patient_invitations")
      .update({
        status: "accepted",
        accepted_at: now.toISOString(),
        patient_profile_id: profileId,
        patient_id: patient.id,
      })
      .eq("id", invitation.id)
      .eq("status", "pending");

    if (updateInvitationError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to finalize invitation",
        500,
        { hint: updateInvitationError.message },
      );
    }

    logger.info(`${FN}.success`, {
      invitation_id: invitation.id,
      patient_id: patient.id,
      profile_id: profileId,
      clinic_id: invitation.clinic_id,
    });

    return jsonResponse({
      ok: true,
      data: {
        patient_id: patient.id,
        profile_id: profileId,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
