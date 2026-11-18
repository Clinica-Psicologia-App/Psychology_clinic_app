import type { SupabaseClient } from "@supabase/supabase-js";
import { assertUuid, getCallerProfile } from "../_shared/auth.ts";
import { AppError, isAppError } from "../_shared/errors.ts";
import {
  handleOptions,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import { logger } from "../_shared/logger.ts";
import { getBearerToken } from "../_shared/supabase.ts";

/**
 * Equipe da clínica edita o e-mail de login e/ou define nova senha de um
 * paciente que já tem conta. O e-mail é o login (Auth). Paciente nunca chama.
 *
 * Desenho convergente (sem compensação):
 *  1. auditoria ANTES (fail-closed: se não gravar, nada muda);
 *  2. Auth é a fonte da verdade; `profiles.email` vem do gatilho
 *     `on_auth_user_email_updated` (handle_user_email_updated), na mesma
 *     transação do Auth;
 *  3. `patients.email` sempre acompanha o login (se difere do novo e-mail) depois do Auth; se
 *     falhar, 500 claro e REPETIR o mesmo pedido conclui.
 *
 * Residual aceito: dois pedidos simultâneos no mesmo paciente; repetir converge.
 * Residual aceito: a troca de senha/e-mail não encerra as sessões ativas do
 * paciente (signOut admin exige o JWT dele); valem até expirar.
 *
 * Privacidade: e-mail e senha NUNCA vão para log, `details` de erro, retorno
 * ou auditoria; só ids e nomes de campo.
 */
export type Deps = {
  createUserClient: (authHeader: string) => SupabaseClient;
  createServiceClient: () => SupabaseClient;
};

type Body = { patient_id: string; email?: string; password?: string };

const FN = "update-patient-credentials";
const ALLOWED_ROLES = ["platform_admin", "admin", "psychologist"];
// Papéis que atuam entre clínicas (igual a create-patient: platform_admin).
// Pendente decisão do Bruno; para retirar, esvaziar esta lista (1 linha).
const CROSS_CLINIC_ROLES = ["platform_admin"];
const AUDIT_REQUESTED = "patient_credentials_update_requested";
const AUDIT_COMPLETED = "patient_credentials_update_completed";
// Recusa `*` (curinga do PostgREST) e `,`.
const EMAIL_RE = /^[^\s@*,]+@[^\s@*,]+\.[^\s@*,]+$/;
const MIN_PASSWORD = 8;
const MAX_PASSWORD = 72; // limite do bcrypt usado pelo Auth

const PASSWORD_MSG =
  "Senha inválida: use de 8 a 72 caracteres e evite senhas comuns ou vazadas.";
const EMAIL_UNAVAILABLE_MSG = "Este e-mail não pode ser usado.";
const PATIENT_PENDING_MSG =
  "O login já foi alterado, mas a ficha do paciente não foi atualizada. Repita o pedido para concluir.";

function authMsg(error: { message?: string } | null | undefined) {
  return error?.message?.toLowerCase() ?? "";
}

/** Escapa curingas do LIKE (\, % e _) para comparação exata sem caixa. */
export function escapeLike(value: string) {
  return value.replace(/[\\%_]/g, (c) => `\\${c}`);
}

const norm = (v: unknown) => String(v ?? "").trim().toLowerCase();

export async function handleUpdatePatientCredentials(
  req: Request,
  deps: Deps,
): Promise<Response> {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = deps.createUserClient(authHeader);
    const service = deps.createServiceClient();
    const caller = await getCallerProfile(userClient);

    if (!ALLOWED_ROLES.includes(caller.role)) {
      throw new AppError(
        "FORBIDDEN",
        "Only clinic staff can change patient credentials",
        403,
      );
    }

    const body = await parseJsonBody<Body>(req);
    if (!body || typeof body !== "object") {
      throw new AppError("VALIDATION_ERROR", "Invalid JSON body", 400);
    }
    const patientId = assertUuid(String(body.patient_id ?? ""), "patient_id");

    if (body.email !== undefined && typeof body.email !== "string") {
      throw new AppError("VALIDATION_ERROR", "email must be text", 400);
    }
    if (body.password !== undefined && typeof body.password !== "string") {
      throw new AppError("VALIDATION_ERROR", "password must be text", 400);
    }
    if (body.email === undefined && body.password === undefined) {
      throw new AppError(
        "VALIDATION_ERROR",
        "email or password is required",
        400,
      );
    }

    let newEmail: string | undefined;
    if (body.email !== undefined) {
      newEmail = body.email.trim().toLowerCase();
      if (newEmail.length > 254 || !EMAIL_RE.test(newEmail)) {
        throw new AppError("VALIDATION_ERROR", "Invalid email format", 400, {
          field: "email",
        });
      }
    }
    const newPassword = body.password;
    if (
      newPassword !== undefined &&
      (newPassword.length < MIN_PASSWORD || newPassword.length > MAX_PASSWORD)
    ) {
      throw new AppError("VALIDATION_ERROR", PASSWORD_MSG, 400, {
        field: "password",
      });
    }

    // --- Autorização explícita (service role; não depende da RLS do admin) ---
    const { data: patient, error: patientErr } = await service
      .from("patients")
      .select("id, clinic_id, profile_id, responsible_psychologist_id, email")
      .eq("id", patientId)
      .maybeSingle();
    if (patientErr) {
      throw new AppError("INTERNAL_ERROR", "Failed to load patient", 500);
    }
    const sameClinic = !!patient &&
      (CROSS_CLINIC_ROLES.includes(caller.role) ||
        patient.clinic_id === caller.clinic_id);
    const allowed = sameClinic &&
      (caller.role !== "psychologist" ||
        patient!.responsible_psychologist_id === caller.id);
    if (!patient || !allowed) {
      throw new AppError(
        "FORBIDDEN",
        "Patient not found or access denied",
        403,
      );
    }

    if (!patient.profile_id) {
      throw new AppError(
        "CONFLICT",
        "Este paciente ainda não aceitou o convite e não tem conta. Reenvie o convite com o e-mail correto.",
        409,
      );
    }
    const profileId = patient.profile_id as string;
    const clinicId = patient.clinic_id as string;

    const { data: profile, error: profileErr } = await service
      .from("profiles")
      .select("id, clinic_id, role, email")
      .eq("id", profileId)
      .maybeSingle();
    if (profileErr) {
      throw new AppError("INTERNAL_ERROR", "Failed to load patient profile", 500);
    }
    if (!profile || profile.role !== "patient" || profile.clinic_id !== clinicId) {
      throw new AppError(
        "FORBIDDEN",
        "Patient not found or access denied",
        403,
      );
    }

    const { data: authLookup, error: lookupErr } = await service.auth.admin
      .getUserById(profileId);
    if (lookupErr || !authLookup?.user) {
      throw new AppError("INTERNAL_ERROR", "Failed to load patient account", 500);
    }
    const authEmail = norm(authLookup.user.email);
    const patientEmail = norm(patient.email);

    // --- O que falta fazer, calculado contra Auth e patients (convergência) ---
    const authEmailChange = newEmail !== undefined && newEmail !== authEmail;

    // patients.email sempre acompanha o login: pendente quando difere do novo
    // e-mail (sem caixa). Repetir o pedido converge após falha parcial.
    const patientEmailChange = newEmail !== undefined && patientEmail !== newEmail;

    const changed: string[] = [];
    if (authEmailChange) changed.push("email");
    if (newPassword !== undefined) changed.push("password");
    if (patientEmailChange) changed.push("patient_email");
    if (changed.length === 0) {
      throw new AppError("VALIDATION_ERROR", "No changes to apply", 400);
    }

    // --- E-mail livre na clínica (ilike com curingas escapados) ---
    if (authEmailChange) {
      const pattern = escapeLike(newEmail!);
      const { data: clash, error: clashErr } = await service
        .from("profiles")
        .select("id")
        .eq("clinic_id", clinicId)
        .ilike("email", pattern)
        .neq("id", profileId)
        .limit(1);
      if (clashErr) {
        throw new AppError("INTERNAL_ERROR", "Failed to check email", 500);
      }
      if (clash && clash.length > 0) {
        throw new AppError("CONFLICT", EMAIL_UNAVAILABLE_MSG, 409);
      }
      const { data: pending, error: pendingErr } = await service
        .from("patient_invitations")
        .select("id")
        .eq("clinic_id", clinicId)
        .ilike("email", pattern)
        .eq("status", "pending")
        .limit(1);
      if (pendingErr) {
        throw new AppError("INTERNAL_ERROR", "Failed to check invitations", 500);
      }
      if (pending && pending.length > 0) {
        throw new AppError("CONFLICT", EMAIL_UNAVAILABLE_MSG, 409);
      }
    }

    // --- 1) Auditoria "solicitado" ANTES (fail-closed), só nomes de campo ---
    const { error: auditErr } = await service.from("audit_events").insert({
      clinic_id: clinicId,
      actor_profile_id: caller.id,
      action: AUDIT_REQUESTED,
      entity_type: "profile",
      entity_id: profileId,
      patient_id: patientId,
      metadata: { changed },
    });
    if (auditErr) {
      logger.error(`${FN}.audit_failed`, { patient_id: patientId });
      throw new AppError("INTERNAL_ERROR", "Failed to record audit; nothing was changed", 500);
    }

    // --- 2) Auth (gatilho sincroniza profiles.email) ---
    if (authEmailChange || newPassword !== undefined) {
      const authPatch: Record<string, unknown> = {};
      if (authEmailChange) {
        authPatch.email = newEmail;
        authPatch.email_confirm = true;
      }
      if (newPassword !== undefined) authPatch.password = newPassword;

      const { error: authError } = await service.auth.admin.updateUserById(
        profileId,
        authPatch,
      );
      if (authError) {
        const m = authMsg(authError);
        logger.warn(`${FN}.auth_update_failed`, {
          patient_id: patientId,
          profile_id: profileId,
        });
        if (m.includes("already") || m.includes("exists") || m.includes("registered")) {
          throw new AppError("CONFLICT", EMAIL_UNAVAILABLE_MSG, 409);
        }
        if (
          m.includes("password") || m.includes("weak") || m.includes("breach") ||
          m.includes("leaked") || m.includes("hibp")
        ) {
          throw new AppError("VALIDATION_ERROR", PASSWORD_MSG, 400);
        }
        throw new AppError("INTERNAL_ERROR", "Failed to update patient account", 500);
      }
    }

    // --- 3) patients.email (sempre acompanha o login) ---
    if (patientEmailChange) {
      const { error: tErr } = await service
        .from("patients")
        .update({ email: newEmail })
        .eq("id", patientId);
      if (tErr) {
        logger.error(`${FN}.patient_update_failed`, {
          patient_id: patientId,
          profile_id: profileId,
          auth_changed: authEmailChange || newPassword !== undefined,
        });
        throw new AppError("INTERNAL_ERROR", PATIENT_PENDING_MSG, 500);
      }
    }

    // Auditoria "concluído": falha só loga ids (a troca já aconteceu).
    const { error: doneErr } = await service.from("audit_events").insert({
      clinic_id: clinicId,
      actor_profile_id: caller.id,
      action: AUDIT_COMPLETED,
      entity_type: "profile",
      entity_id: profileId,
      patient_id: patientId,
      metadata: { changed },
    });
    if (doneErr) {
      logger.error(`${FN}.audit_completed_failed`, {
        patient_id: patientId,
        profile_id: profileId,
      });
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      caller_role: caller.role,
      patient_id: patientId,
      profile_id: profileId,
      changed,
    });

    return jsonResponse({ ok: true, data: { patient_id: patientId, changed } });
  } catch (error) {
    if (isAppError(error)) {
      // Sem `details` (log e resposta): podem carregar hint com e-mail/PII.
      const e = error as AppError;
      logger.warn(`${FN}.app_error`, { code: e.code, message: e.message });
      return jsonResponse(
        { ok: false, error: { code: e.code, message: e.message } },
        e.status,
      );
    }
    // Nunca repassar a mensagem original: pode conter e-mail/senha.
    logger.error(`${FN}.unhandled`, {
      error_name: error instanceof Error ? error.name : typeof error,
    });
    return jsonResponse(
      { ok: false, error: { code: "INTERNAL_ERROR", message: "Internal server error" } },
      500,
    );
  }
}
