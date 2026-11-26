import type { SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "../_shared/errors.ts";
import {
  handleOptions,
  handlePublicError,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import {
  hashInvitationToken,
  invalidInvitationError,
} from "../_shared/invitations.ts";
import { logger } from "../_shared/logger.ts";
import type { sendPushToUser } from "../_shared/push.ts";

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
  legal_consent?: {
    terms_version?: string;
    privacy_version?: string;
  };
};

export type Deps = {
  createServiceClient: () => SupabaseClient;
  sendPush: typeof sendPushToUser;
};

const FN = "accept-patient-invitation";
const UNAVAILABLE_MSG = "Convite não está mais disponível.";
const RELEASE_FAILED_MSG =
  "Não foi possível concluir o cadastro. Peça um novo convite à clínica.";
const ACCOUNT_STUCK_MSG =
  "Não foi possível concluir o cadastro. Fale com a clínica.";

/** Apaga o usuário criado neste aceite; `false` se não der (erro conferido). */
async function deleteCreatedUser(
  serviceClient: SupabaseClient,
  userId: string,
) {
  try {
    const { error } = await serviceClient.auth.admin.deleteUser(userId);
    return !error;
  } catch {
    return false;
  }
}

/** Grava no convite os ids criados. Nunca lança: a conta já existe. */
async function linkInvitation(
  serviceClient: SupabaseClient,
  invitationId: string,
  profileId: string,
  patientId: string,
): Promise<{ ok: boolean; dbCode?: string }> {
  try {
    const { data, error } = await serviceClient
      .from("patient_invitations")
      .update({ patient_profile_id: profileId, patient_id: patientId })
      .eq("id", invitationId)
      .eq("status", "accepted")
      .select("id");
    return { ok: !error && data?.length === 1, dbCode: error?.code };
  } catch {
    return { ok: false };
  }
}

/**
 * Devolve a `pending` um convite reservado cuja conta não foi criada. Pode
 * falhar (venceu no meio, ou já existe outro pendente para o e-mail): nesse
 * caso ele fica `accepted` sem paciente e a saída é um novo convite. O mesmo
 * vale se a função morrer entre a reserva e o fim.
 */
async function releaseReservation(
  serviceClient: SupabaseClient,
  invitationId: string,
) {
  let dbCode: string | undefined;
  try {
    const { data, error } = await serviceClient
      .from("patient_invitations")
      .update({ status: "pending", accepted_at: null })
      .eq("id", invitationId)
      .eq("status", "accepted")
      .is("patient_id", null)
      .select("id");
    if (!error && data?.length === 1) return true;
    dbCode = error?.code;
  } catch {
    // Mesmo tratamento abaixo; a mensagem original não vai para o log.
  }
  logger.error(`${FN}.release_failed`, {
    invitation_id: invitationId,
    db_code: dbCode,
  });
  return false;
}

export async function handleAcceptPatientInvitation(
  req: Request,
  deps: Deps,
): Promise<Response> {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const serviceClient = deps.createServiceClient();
    const body = await parseJsonBody<AcceptPatientInvitationBody>(req);

    if (!body.password || body.password.length < 8) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Senha deve ter pelo menos 8 caracteres.",
        400,
      );
    }

    const termsVersion = body.legal_consent?.terms_version?.trim();
    const privacyVersion = body.legal_consent?.privacy_version?.trim();
    if (!termsVersion || !privacyVersion) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Aceite dos Termos de Uso e da Política de Privacidade é obrigatório.",
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
      logger.error(`${FN}.load_failed`, { db_code: invitationError.code });
      throw new AppError("INTERNAL_ERROR", "Failed to load invitation", 500);
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
      throw new AppError(
        "VALIDATION_ERROR",
        "Nome completo é obrigatório.",
        400,
      );
    }

    const email = String(invitation.email).trim().toLowerCase();
    const phone = profileInput.phone?.trim() ||
      (invitation.phone as string | null)?.trim() ||
      null;

    // Reserva ANTES de criar qualquer coisa: só a requisição que fizer
    // pending -> accepted segue. Cancelado, aceito ou vencido no meio do
    // caminho = 0 linhas, nada criado.
    const { data: reserved, error: reserveError } = await serviceClient
      .from("patient_invitations")
      .update({ status: "accepted", accepted_at: now.toISOString() })
      .eq("id", invitation.id)
      .eq("status", "pending")
      .gt("expires_at", new Date().toISOString())
      .select("id");

    if (reserveError) {
      logger.error(`${FN}.reserve_failed`, {
        invitation_id: invitation.id,
        db_code: reserveError.code,
      });
      throw new AppError("INTERNAL_ERROR", "Failed to reserve invitation", 500);
    }
    if (reserved?.length !== 1) {
      throw new AppError("CONFLICT", UNAVAILABLE_MSG, 409);
    }

    let orphanAccount = false;
    const createAccount = async () => {
      const { data: authData, error: authError } = await serviceClient.auth
        .admin
        .createUser({
          email,
          password: body.password,
          email_confirm: true,
          user_metadata: {
            full_name: fullName,
            phone,
          },
        });

      if (authError || !authData.user) {
        // Só código e status: a mensagem do Auth pode trazer o e-mail.
        logger.warn(`${FN}.auth_create_failed`, {
          invitation_id: invitation.id,
          auth_code: authError?.code,
          auth_status: authError?.status,
        });
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
        );
      }

      const profileId = authData.user.id;
      const stepFailed = (step: string, dbCode: string | undefined) => {
        logger.error(`${FN}.create_failed`, {
          invitation_id: invitation.id,
          step,
          db_code: dbCode,
        });
        return new AppError(
          "INTERNAL_ERROR",
          "Failed to create patient account",
          500,
        );
      };

      try {
        const { error: profileError } = await serviceClient.from("profiles")
          .upsert({
            id: profileId,
            clinic_id: invitation.clinic_id,
            role: "patient",
            full_name: fullName,
            email,
            phone,
            is_active: true,
          });

        if (profileError) throw stepFailed("profile", profileError.code);

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
            relationship_status: profileInput.relationship_status?.trim() ||
              null,
            education_level: profileInput.education_level?.trim() || null,
            occupation: profileInput.occupation?.trim() || null,
            country_birth: profileInput.country_birth?.trim() ||
              profileInput.birth_country_state?.trim() ||
              null,
            state_birth: profileInput.state_birth?.trim() || null,
            religious_orientation: profileInput.religious_orientation?.trim() ||
              null,
            ethnic_group: profileInput.ethnic_group?.trim() || null,
            sexual_orientation: profileInput.sexual_orientation?.trim() || null,
            has_children: profileInput.has_children ?? null,
          })
          .select("id, full_name, email, clinic_id, profile_id")
          .single();

        if (patientError || !patient) {
          throw stepFailed("patient", patientError?.code);
        }

        const { error: consentError } = await serviceClient
          .from("legal_consents")
          .insert([
            {
              clinic_id: invitation.clinic_id,
              profile_id: profileId,
              document_type: "terms",
              document_version: termsVersion,
              source: "patient-invitation",
            },
            {
              clinic_id: invitation.clinic_id,
              profile_id: profileId,
              document_type: "privacy",
              document_version: privacyVersion,
              source: "patient-invitation",
            },
          ]);

        if (consentError) throw stepFailed("consent", consentError.code);

        return { profileId, patientId: patient.id as string };
      } catch (error) {
        // Qualquer falha depois de criar o usuário (erro ou exceção) desfaz.
        if (!await deleteCreatedUser(serviceClient, profileId)) {
          orphanAccount = true;
          logger.error("accept_compensation_failed", {
            invitation_id: invitation.id,
            clinic_id: invitation.clinic_id,
            profile_id: profileId,
          });
        }
        throw error;
      }
    };

    let account: { profileId: string; patientId: string };
    try {
      account = await createAccount();
    } catch (error) {
      // Conta que não deu para apagar: voltar a `pending` daria um convite que
      // nunca funciona. Fica `accepted` até o reparo manual
      // (docs/produto/REPARO_CONVITES.md, na pasta da Fábrica).
      if (orphanAccount) {
        throw new AppError("CONFLICT", ACCOUNT_STUCK_MSG, 409);
      }
      if (!await releaseReservation(serviceClient, invitation.id)) {
        throw new AppError("CONFLICT", RELEASE_FAILED_MSG, 409);
      }
      throw error;
    }
    const { profileId, patientId } = account;

    // A conta já existe e o convite já está `accepted`: falha em vincular os
    // ids não pode virar erro para o paciente (repetir daria "indisponível").
    const link = await linkInvitation(
      serviceClient,
      invitation.id,
      profileId,
      patientId,
    );
    if (!link.ok) {
      logger.error("accept_link_failed", {
        invitation_id: invitation.id,
        clinic_id: invitation.clinic_id,
        patient_id: patientId,
        profile_id: profileId,
        db_code: link.dbCode,
      });
    }

    logger.info(`${FN}.success`, {
      invitation_id: invitation.id,
      patient_id: patientId,
      profile_id: profileId,
      clinic_id: invitation.clinic_id,
    });

    // Notifica o psicólogo responsável.
    if (invitation.responsible_psychologist_id) {
      try {
        await deps.sendPush(
          serviceClient,
          invitation.responsible_psychologist_id as string,
          {
            title: "Paciente cadastrado",
            body: `${fullName} aceitou o convite e criou sua conta.`,
            data: { type: "invitation_accepted", patient_id: patientId },
          },
        );
      } catch (e) {
        logger.warn(`${FN}.push_failed`, {
          invitation_id: invitation.id,
          error_name: e instanceof Error ? e.name : typeof e,
        });
      }
    }

    return jsonResponse({
      ok: true,
      data: {
        patient_id: patientId,
        profile_id: profileId,
      },
    });
  } catch (error) {
    // Chamador anônimo: sem details, hint ou mensagem de exceção.
    return handlePublicError(error, FN);
  }
}
