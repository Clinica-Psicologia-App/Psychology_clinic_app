type LogLevel = "info" | "warn" | "error";
type LogMeta = Record<string, unknown>;
function log(level: LogLevel, event: string, meta?: LogMeta) {
  const payload = {
    ts: new Date().toISOString(),
    level,
    event,
    ...meta
  };
  const line = JSON.stringify(payload);
  if (level === "error") console.error(line);
  else if (level === "warn") console.warn(line);
  else console.log(line);
}
export const logger = {
  info: (event: string, meta?: LogMeta)=>log("info", event, meta),
  warn: (event: string, meta?: LogMeta)=>log("warn", event, meta),
  error: (event: string, meta?: LogMeta)=>log("error", event, meta)
};
