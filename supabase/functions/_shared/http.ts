import { corsHeaders } from "./cors.ts";
import { AppError, isAppError } from "./errors.ts";
import { logger } from "./logger.ts";
export function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json"
    }
  });
}
export function pdfResponse(bytes, filename = "relatorio-clinico.pdf") {
  return new Response(bytes, {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="${filename}"`
    }
  });
}
export function handleOptions(req) {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }
  return null;
}
export function requirePost(req) {
  if (req.method !== "POST") {
    throw new AppError("VALIDATION_ERROR", "Method not allowed", 405);
  }
}
export async function parseJsonBody(req) {
  try {
    return await req.json();
  } catch  {
    throw new AppError("VALIDATION_ERROR", "Invalid JSON body", 400);
  }
}
export function handleError(error, functionName) {
  if (isAppError(error)) {
    logger.warn(`${functionName}.app_error`, {
      code: error.code,
      message: error.message,
      details: error.details
    });
    return jsonResponse({
      ok: false,
      error: {
        code: error.code,
        message: error.message,
        details: error.details
      }
    }, error.status);
  }
  logger.error(`${functionName}.unhandled`, {
    message: error instanceof Error ? error.message : String(error)
  });
  return jsonResponse({
    ok: false,
    error: {
      code: "INTERNAL_ERROR",
      message: "Internal server error"
    }
  }, 500);
}
