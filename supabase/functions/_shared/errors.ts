export class AppError extends Error {
  code;
  status;
  details;
  constructor(code, message, status = 400, details){
    super(message);
    this.code = code;
    this.status = status;
    this.details = details;
    this.name = "AppError";
  }
}
export function isAppError(error) {
  return error instanceof AppError;
}
