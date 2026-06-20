function log(level, event, meta) {
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
  info: (event, meta)=>log("info", event, meta),
  warn: (event, meta)=>log("warn", event, meta),
  error: (event, meta)=>log("error", event, meta)
};
