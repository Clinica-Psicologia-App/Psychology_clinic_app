import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { assertUuid, getCallerProfile } from "../_shared/auth.ts";
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

type DeleteClinicBody = {
  clinic_id: string;
  confirmation_name?: string;
};

type DependencyCheck = {
  table: string;
  label: string;
};

const FN = "delete-clinic";

const BLOCKING_DEPENDENCIES: DependencyCheck[] = [
  { table: "profiles", label: "usuários" },
  { table: "patients", label: "pacientes" },
  { table: "therapy_resources", label: "recursos terapêuticos" },
  { table: "daily_monitors", label: "monitores diários" },
  { table: "questionnaire_responses", label: "respostas de questionários" },
  { table: "questionnaire_response_contexts", label: "contextos de respostas" },
  { table: "questionnaire_professional_access", label: "acessos a questionários" },
  { table: "patient_invitations", label: "convites de pacientes" },
  { table: "legal_consents", label: "consentimentos legais" },
  { table: "therapy_goals", label: "metas terapêuticas" },
  { table: "patient_problems", label: "problemas clínicos" },
  { table: "patient_check_ins", label: "check-ins" },
  { table: "patient_timeline_events", label: "linha do tempo" },
  { table: "genogram_people", label: "genograma" },
  { table: "genogram_relationships", label: "relações do genograma" },
];

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const serviceClient = createServiceClient();
    const caller = await getCallerProfile(userClient);

    if (caller.role !== "platform_admin") {
      throw new AppError(
        "FORBIDDEN",
        "Apenas administradores da plataforma podem excluir clínicas",
        403,
      );
    }

    const body = await parseJsonBody<DeleteClinicBody>(req);
    const clinicId = assertUuid(body.clinic_id, "clinic_id");
    const confirmationName = body.confirmation_name?.trim() ?? "";

    const { data: clinic, error: clinicError } = await userClient
      .from("clinics")
      .select("id, name, clinic_type")
      .eq("id", clinicId)
      .maybeSingle();

    if (clinicError) {
      throw new AppError("INTERNAL_ERROR", "Falha ao carregar clínica", 500, {
        hint: clinicError.message,
      });
    }

    if (!clinic) {
      throw new AppError("NOT_FOUND", "Clínica não encontrada", 404);
    }

    if (confirmationName !== clinic.name) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Digite exatamente o nome da clínica para confirmar a exclusão",
        400,
        { field: "confirmation_name" },
      );
    }

    const blockers = await findBlockingDependencies(serviceClient, clinicId);
    if (blockers.length > 0) {
      throw new AppError(
        "INVALID_STATE",
        "Esta clínica possui vínculos e não pode ser excluída. Inative a clínica ou remova os vínculos antes.",
        400,
        { blockers },
      );
    }

    const { error: deleteError } = await serviceClient
      .from("clinics")
      .delete()
      .eq("id", clinicId);

    if (deleteError) {
      logger.error(`${FN}.delete_failed`, {
        clinic_id: clinicId,
        message: deleteError.message,
      });
      throw new AppError("INTERNAL_ERROR", "Falha ao excluir clínica", 500, {
        hint: deleteError.message,
      });
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      clinic_id: clinicId,
      clinic_type: clinic.clinic_type,
    });

    return jsonResponse({
      ok: true,
      data: {
        deleted_clinic_id: clinicId,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});

async function findBlockingDependencies(
  serviceClient: ReturnType<typeof createServiceClient>,
  clinicId: string,
) {
  const blockers: Array<{ table: string; label: string; count: number }> = [];

  for (const dependency of BLOCKING_DEPENDENCIES) {
    const { count, error } = await serviceClient
      .from(dependency.table)
      .select("id", { count: "exact", head: true })
      .eq("clinic_id", clinicId);

    if (error) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Falha ao validar vínculos da clínica",
        500,
        {
          table: dependency.table,
          hint: error.message,
        },
      );
    }

    if ((count ?? 0) > 0) {
      blockers.push({
        table: dependency.table,
        label: dependency.label,
        count: count ?? 0,
      });
    }
  }

  return blockers;
}
