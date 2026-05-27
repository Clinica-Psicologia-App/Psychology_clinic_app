import { corsHeaders } from "./cors.ts";
import { AppError, isAppError } from "./errors.ts";
import { logger } from "./logger.ts";

export type ApiSuccess<T> = {
  ok: true;
  data: T;
};

export type ApiFailure = {
  ok: false;
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
};

export function jsonResponse(
  body: ApiSuccess<unknown> | ApiFailure,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function handleOptions(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  return null;
}

export function requirePost(req: Request): void {
  if (req.method !== "POST") {
    throw new AppError("VALIDATION_ERROR", "Method not allowed", 405);
  }
}

export async function parseJsonBody<T>(req: Request): Promise<T> {
  try {
    return (await req.json()) as T;
  } catch {
    throw new AppError("VALIDATION_ERROR", "Invalid JSON body", 400);
  }
}

export function handleError(error: unknown, functionName: string): Response {
  if (isAppError(error)) {
    logger.warn(`${functionName}.app_error`, {
      code: error.code,
      message: error.message,
      details: error.details,
    });
    return jsonResponse(
      {
        ok: false,
        error: {
          code: error.code,
          message: error.message,
          details: error.details,
        },
      },
      error.status,
    );
  }

  logger.error(`${functionName}.unhandled`, {
    message: error instanceof Error ? error.message : String(error),
  });

  return jsonResponse(
    {
      ok: false,
      error: {
        code: "INTERNAL_ERROR",
        message: "Internal server error",
      },
    },
    500,
  );
}
