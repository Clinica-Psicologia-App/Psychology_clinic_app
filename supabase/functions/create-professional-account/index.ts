import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { AppError } from "../_shared/errors.ts";
import {
  handleError,
  handleOptions,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import { logger } from "../_shared/logger.ts";
import { createServiceClient } from "../_shared/supabase.ts";

type CreateProfessionalAccountBody = {
  email: string;
  password: string;
  full_name: string;
  phone?: string;
  crp?: string;
  mode: "solo" | "clinic";
  clinic?: {
    name?: string;
    phone?: string;
    email?: string;
  };
};

const FN = "create-professional-account";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const serviceClient = createServiceClient();
    const body = await parseJsonBody<CreateProfessionalAccountBody>(req);

    const email = body.email?.trim().toLowerCase();
    const password = body.password;
    const fullName = body.full_name?.trim();
    const phone = body.phone?.trim() || null;
    const crp = body.crp?.trim() || null;
    const mode = body.mode;

    if (!email || !email.includes("@")) {
      throw new AppError("VALIDATION_ERROR", "Email inválido.", 400);
    }

    if (!password || password.length < 8) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Senha deve ter pelo menos 8 caracteres.",
        400,
      );
    }

    if (!fullName) {
      throw new AppError("VALIDATION_ERROR", "Nome completo é obrigatório.", 400);
    }

    if (mode !== "solo" && mode !== "clinic") {
      throw new AppError("VALIDATION_ERROR", "Modo de cadastro inválido.", 400);
    }

    const clinicName = mode === "solo"
      ? `Clínica pessoal — ${fullName}`
      : body.clinic?.name?.trim();

    if (!clinicName) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Nome da clínica é obrigatório para modo clínica/equipe.",
        400,
      );
    }

    const clinicEmail = body.clinic?.email?.trim().toLowerCase() || null;
    if (clinicEmail != null && !clinicEmail.includes("@")) {
      throw new AppError("VALIDATION_ERROR", "E-mail da clínica inválido.", 400);
    }

    const { data: existingAuthUsers, error: listUsersError } = await serviceClient
      .auth.admin.listUsers({
        page: 1,
        perPage: 1000,
      });

    if (listUsersError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to verify professional email",
        500,
        { hint: listUsersError.message },
      );
    }

    const emailAlreadyUsed = existingAuthUsers.users.some(
      (user) => user.email?.toLowerCase() === email,
    );
    if (emailAlreadyUsed) {
      throw new AppError("CONFLICT", "Este e-mail já está em uso.", 409);
    }

    const { data: clinic, error: clinicError } = await serviceClient
      .from("clinics")
      .insert({
        name: clinicName,
        phone: mode === "clinic" ? body.clinic?.phone?.trim() || null : phone,
        email: mode === "clinic" ? clinicEmail : email,
        clinic_type: mode === "solo" ? "personal" : "clinic",
      })
      .select("id, name")
      .single();

    if (clinicError || !clinic) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create clinic",
        500,
        { hint: clinicError?.message },
      );
    }

    const { data: authData, error: authError } = await serviceClient.auth.admin
      .createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          clinic_id: clinic.id,
          role: "admin",
          full_name: fullName,
          phone,
        },
      });

    if (authError || !authData.user) {
      await serviceClient.from("clinics").delete().eq("id", clinic.id);
      if (authError?.message?.toLowerCase().includes("already")) {
        throw new AppError("CONFLICT", "Este e-mail já está em uso.", 409);
      }
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create professional auth user",
        500,
        { hint: authError?.message },
      );
    }

    const profileId = authData.user.id;

    const { error: profileError } = await serviceClient
      .from("profiles")
      .update({
        clinic_id: clinic.id,
        full_name: fullName,
        email,
        phone,
        role: "admin",
        crp,
      })
      .eq("id", profileId);

    if (profileError) {
      await serviceClient.auth.admin.deleteUser(profileId);
      await serviceClient.from("clinics").delete().eq("id", clinic.id);
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to configure professional profile",
        500,
        { hint: profileError.message },
      );
    }

    const { error: ownerError } = await serviceClient
      .from("clinics")
      .update({ owner_profile_id: profileId })
      .eq("id", clinic.id);

    if (ownerError) {
      await serviceClient.auth.admin.deleteUser(profileId);
      await serviceClient.from("clinics").delete().eq("id", clinic.id);
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to finalize clinic ownership",
        500,
        { hint: ownerError.message },
      );
    }

    logger.info(`${FN}.success`, {
      clinic_id: clinic.id,
      profile_id: profileId,
      clinic_type: mode === "solo" ? "personal" : "clinic",
    });

    return jsonResponse({
      ok: true,
      data: {
        profile_id: profileId,
        clinic_id: clinic.id,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
