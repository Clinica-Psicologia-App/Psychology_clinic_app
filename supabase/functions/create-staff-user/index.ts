import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertEmailAvailableInClinic,
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

type StaffRole = "psychologist" | "platform_admin";

type CreateStaffUserBody = {
  email: string;
  password: string;
  full_name: string;
  role: StaffRole;
  clinic_id?: string;
  phone?: string;
  crp?: string;
};

const FN = "create-staff-user";
const STAFF_ROLES: StaffRole[] = ["psychologist", "platform_admin"];

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
        "Only platform administrators can create psychologists",
        403,
      );
    }

    const body = await parseJsonBody<CreateStaffUserBody>(req);
    const email = body.email?.trim().toLowerCase();
    const fullName = body.full_name?.trim();
    const phone = body.phone?.trim() || null;
    const crp = body.crp?.trim() || null;

    if (!email || !body.password || body.password.length < 8) {
      throw new AppError(
        "VALIDATION_ERROR",
        "email and password (min 8 chars) are required",
        400,
      );
    }

    if (!fullName) {
      throw new AppError("VALIDATION_ERROR", "full_name is required", 400);
    }

    if (!STAFF_ROLES.includes(body.role)) {
      throw new AppError(
        "VALIDATION_ERROR",
        "role must be psychologist or platform_admin",
        400,
        { role: body.role },
      );
    }

    const targetClinicId = assertUuid(body.clinic_id ?? "", "clinic_id");

    const { data: clinic, error: clinicError } = await serviceClient
      .from("clinics")
      .select("id")
      .eq("id", targetClinicId)
      .maybeSingle();

    if (clinicError) {
      throw new AppError("INTERNAL_ERROR", "Failed to validate clinic", 500, {
        hint: clinicError.message,
      });
    }

    if (!clinic) {
      throw new AppError("NOT_FOUND", "Clinic not found", 404, {
        clinic_id: targetClinicId,
      });
    }

    await assertEmailAvailableInClinic(userClient, targetClinicId, email);

    const { data: authData, error: authError } = await serviceClient.auth.admin
      .createUser({
        email,
        password: body.password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          clinic_id: targetClinicId,
          role: body.role,
          phone,
        },
      });

    if (authError || !authData.user) {
      logger.warn(`${FN}.auth_create_failed`, { message: authError?.message });
      if (authError?.message?.toLowerCase().includes("already")) {
        throw new AppError("CONFLICT", "Email already registered", 409);
      }
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create auth user",
        500,
        { hint: authError?.message },
      );
    }

    const profileId = authData.user.id;

    const { data: profile, error: profileError } = await serviceClient
      .from("profiles")
      .upsert({
        id: profileId,
        clinic_id: targetClinicId,
        full_name: fullName,
        email,
        phone,
        role: body.role,
        crp,
        is_active: true,
      })
      .select("id, full_name, email, phone, role, crp, is_active, created_at")
      .single();

    if (profileError) {
      logger.error(`${FN}.profile_upsert_failed`, {
        message: profileError.message,
        profile_id: profileId,
      });
      await serviceClient.auth.admin.deleteUser(profileId);
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create staff profile",
        500,
        { hint: profileError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      profile_id: profileId,
      clinic_id: targetClinicId,
      role: body.role,
    });

    return jsonResponse({
      ok: true,
      data: { profile },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
