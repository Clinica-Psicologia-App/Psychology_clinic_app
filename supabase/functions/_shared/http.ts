import { corsHeaders } from "./cors.ts";
import { AppError, isAppError } from "./errors.ts";
import { logger } from "./logger.ts";
export function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json"
    }
  });
}
export function pdfResponse(bytes: Uint8Array, filename = "relatorio-clinico.pdf") {
  return new Response(bytes as BodyInit, {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="${filename}"`
    }
  });
}
export function handleOptions(req: Request) {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }
  return null;
}
export function requirePost(req: Request) {
  if (req.method !== "POST") {
    throw new AppError("VALIDATION_ERROR", "Method not allowed", 405);
  }
}
export async function parseJsonBody<T = any>(req: Request): Promise<T> {
  try {
    return await req.json();
  } catch  {
    throw new AppError("VALIDATION_ERROR", "Invalid JSON body", 400);
  }
}
/**
 * Erro para função chamada por anônimo: resposta e log sem `details`, hint ou
 * mensagem de exceção/banco. Mensagens de AppError abaixo de 500 são textos
 * fixos para o usuário; de 500 para cima, mensagem genérica.
 */
export function handlePublicError(error: unknown, functionName: string) {
  const appError = isAppError(error) ? error as AppError : null;
  const code = appError?.code ?? "INTERNAL_ERROR";
  const status = appError?.status ?? 500;
  if (appError) {
    logger.warn(`${functionName}.app_error`, { code, status });
  } else {
    logger.error(`${functionName}.unhandled`, {
      error_name: error instanceof Error ? error.name : typeof error
    });
  }
  const message = appError && status < 500 ? appError.message : "Internal server error";
  return jsonResponse({
    ok: false,
    error: {
      code,
      message
    }
  }, status);
}
export function handleError(error: unknown, functionName: string) {
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
