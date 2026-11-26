import type { SupabaseClient } from "@supabase/supabase-js";
import {
  assertUuid,
  type CallerProfile,
  getCallerProfile,
  requireStaff,
} from "../_shared/auth.ts";
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
 * Cancela um convite de paciente pendente (status = 'revoked', sem apagar a
 * linha). "Reenviar" é o app chamar esta função e depois
 * create-patient-invitation; se a segunda falhar, o convite antigo já está
 * cancelado e basta criar de novo.
 *
 * Quem pode: psicóloga da clínica do convite que seja a responsável ou quem
 * convidou; platform_admin em qualquer clínica.
 *
 * A autorização está nos filtros do próprio UPDATE (um só comando). Convite
 * inexistente ou fora do alcance de quem chama recebe a mesma resposta.
 *
 * Privacidade: só ids em log, auditoria e resposta; nunca e-mail, nome, token
 * ou mensagem vinda do banco.
 */
export type Deps = {
  createUserClient: (authHeader: string) => SupabaseClient;
  createServiceClient: () => SupabaseClient;
};

const FN = "revoke-patient-invitation";
const AUDIT_ACTION = "patient_invitation_revoked";
const NOT_FOUND_MSG = "Convite não encontrado.";
const RETRY_MSG = "Não foi possível cancelar o convite. Tente novamente.";
const STATE_MSG: Record<string, string> = {
  accepted: "Este convite já foi aceito.",
  expired: "Este convite já expirou.",
  revoked: "Este convite já foi cancelado.",
};

/** Mesmo alcance na escrita e na releitura. Só platform_admin é global. */
// `any`: tipar o builder do supabase-js genericamente estoura o checker (TS2589).
// deno-lint-ignore no-explicit-any
function withinScope(query: any, caller: CallerProfile): any {
  if (caller.role === "platform_admin") return query;
  return query
    .eq("clinic_id", caller.clinic_id)
    .or(
      `responsible_psychologist_id.eq.${caller.id},invited_by.eq.${caller.id}`,
    );
}

function internalError() {
  return new AppError("INTERNAL_ERROR", RETRY_MSG, 500);
}

export async function handleRevokePatientInvitation(
  req: Request,
  deps: Deps,
): Promise<Response> {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const caller = await getCallerProfile(deps.createUserClient(authHeader));
    requireStaff(caller);

    const body = await parseJsonBody<Record<string, unknown>>(req);
    if (
      !body || typeof body !== "object" || Array.isArray(body) ||
      Object.keys(body).some((key) => key !== "invitation_id") ||
      typeof body.invitation_id !== "string"
    ) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Body must contain only invitation_id",
        400,
      );
    }
    const invitationId = assertUuid(body.invitation_id, "invitation_id");
    const service = deps.createServiceClient();
    const ids = { invitation_id: invitationId, caller_id: caller.id };

    const { data: revoked, error: updateError } = await withinScope(
      service
        .from("patient_invitations")
        .update({ status: "revoked" })
        .eq("id", invitationId)
        .eq("status", "pending"),
      caller,
    ).select("id, clinic_id");

    if (updateError) {
      logger.error(`${FN}.update_failed`, {
        ...ids,
        db_code: updateError.code,
      });
      throw internalError();
    }

    if (!revoked || revoked.length !== 1) {
      // Nada mudou: relê (com o mesmo alcance) só para explicar o motivo.
      const { data: current, error: readError } = await withinScope(
        service
          .from("patient_invitations")
          .select("status")
          .eq("id", invitationId),
        caller,
      ).maybeSingle();
      if (readError) {
        logger.error(`${FN}.read_failed`, {
          ...ids,
          db_code: readError.code,
        });
        throw internalError();
      }
      if (!current) throw new AppError("NOT_FOUND", NOT_FOUND_MSG, 404);
      throw new AppError(
        "CONFLICT",
        STATE_MSG[String(current.status)] ?? RETRY_MSG,
        409,
      );
    }

    const clinicId = revoked[0].clinic_id as string;
    // O cancelamento já aconteceu: falha na auditoria não vira erro (repetir
    // só diria "já cancelado"). Uma nova tentativa; se falhar, log com os ids
    // para reparo (docs/produto/REPARO_CONVITES.md, na pasta da Fábrica).
    const insertAudit = async () => {
      try {
        const { error } = await service.from("audit_events").insert({
          clinic_id: clinicId,
          actor_profile_id: caller.id,
          action: AUDIT_ACTION,
          entity_type: "patient_invitation",
          entity_id: invitationId,
          metadata: {},
        });
        return error ? { dbCode: error.code } : null;
      } catch {
        return { dbCode: undefined };
      }
    };
    let auditFailure = await insertAudit();
    if (auditFailure) auditFailure = await insertAudit();
    if (auditFailure) {
      logger.error("revoke_audit_failed", {
        ...ids,
        clinic_id: clinicId,
        db_code: auditFailure.dbCode,
      });
    }

    logger.info(`${FN}.revoke_success`, { ...ids, clinic_id: clinicId });
    return jsonResponse({
      ok: true,
      data: { id: invitationId, status: "revoked" },
    });
  } catch (error) {
    if (isAppError(error)) {
      // Sem `details` (log e resposta): podem carregar mensagem do banco.
      const e = error as AppError;
      logger.warn(`${FN}.app_error`, { code: e.code, status: e.status });
      return jsonResponse(
        { ok: false, error: { code: e.code, message: e.message } },
        e.status,
      );
    }
    logger.error(`${FN}.unhandled`, {
      error_name: error instanceof Error ? error.name : typeof error,
    });
    return jsonResponse(
      {
        ok: false,
        error: { code: "INTERNAL_ERROR", message: "Internal server error" },
      },
      500,
    );
  }
}
