import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertPatientAccess,
  getCallerProfile,
  requireStaff,
} from "../_shared/auth.ts";
import {
  fetchReportData,
  loadPatientForReport,
  reportFilename,
} from "../_shared/clinical-report/fetch_data.ts";
import { buildClinicalReportPdf } from "../_shared/clinical-report/pdf_builder.ts";
import type { GenerateReportBody } from "../_shared/clinical-report/types.ts";
import { parseGenerateReportBody } from "../_shared/clinical-report/validate.ts";
import {
  handleError,
  handleOptions,
  parseJsonBody,
  pdfResponse,
  requirePost,
} from "../_shared/http.ts";
import { logger } from "../_shared/logger.ts";
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

const FN = "generate-clinical-report";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const serviceClient = createServiceClient();

    const caller = await getCallerProfile(userClient);
    requireStaff(caller);

    const body = await parseJsonBody<GenerateReportBody>(req);
    const { patientId, include } = parseGenerateReportBody(body);

    await assertPatientAccess(userClient, patientId);

    const patient = await loadPatientForReport(
      serviceClient,
      patientId,
      caller,
    );
    const reportData = await fetchReportData(serviceClient, patient, include);
    const pdfBytes = await buildClinicalReportPdf(reportData, include);

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      patient_id: patientId,
      clinic_id: caller.clinic_id,
      sections: include,
      bytes: pdfBytes.length,
    });

    return pdfResponse(pdfBytes, reportFilename(patient.full_name));
  } catch (error) {
    return handleError(error, FN);
  }
});
