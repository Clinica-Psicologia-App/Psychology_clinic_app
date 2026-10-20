import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const testNamePattern = /\b(teste|test|demo|homologa[çc][aã]o|e2e)\b/i;

class SmokeError extends Error {}

function requireCondition(condition, code) {
  if (!condition) throw new SmokeError(code);
}

// Contrato REST remoto. Não substitui homologação do formulário em dispositivo.
export async function validatePersonalityRemote({ config, credentials, fetchImpl = fetch }) {
  const report = { status: 'failed', checks: [], cleanup: 'not_needed' };
  let token;
  let mutationAttempted = false;
  const assessmentId = randomUUID();
  const marker = `Homologação NEO PI-R ${assessmentId}`;
  let baseUrl;
  let key;

  const request = async (name, path, { method = 'GET', body, anonymous = false, single = false } = {}) => {
    const response = await fetchImpl(new URL(path, baseUrl), {
      method,
      headers: {
        apikey: key,
        ...(token && !anonymous ? { Authorization: `Bearer ${token}` } : {}),
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(single ? { Accept: 'application/vnd.pgrst.object+json', Prefer: 'return=representation' } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
      signal: AbortSignal.timeout(15000),
    });
    let data = null;
    try { data = await response.json(); } catch { /* Respostas 204 não têm JSON. */ }
    report.checks.push({ name, httpStatus: response.status });
    return { status: response.status, ok: response.ok, data };
  };
  const checked = async (...args) => {
    const result = await request(...args);
    requireCondition(result.ok, `${args[0].toUpperCase()}_HTTP_${result.status}`);
    return result.data;
  };

  try {
    baseUrl = new URL(config.SUPABASE_URL);
    requireCondition(baseUrl.protocol === 'https:', 'HTTPS_REQUIRED');
    key = config.SUPABASE_ANON_KEY;
    requireCondition(typeof key === 'string', 'PUBLIC_KEY_REQUIRED');
    if (key.split('.').length === 3) {
      let claims;
      try { claims = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString()); }
      catch { throw new SmokeError('INVALID_PUBLIC_KEY'); }
      requireCondition(claims.role === 'anon', 'ANON_KEY_REQUIRED');
    } else {
      requireCondition(key.startsWith('sb_publishable_'), 'PUBLIC_KEY_REQUIRED');
    }
    requireCondition(typeof credentials.email === 'string' && credentials.email.trim() &&
      typeof credentials.password === 'string' && credentials.password.length > 0,
    'TEST_CREDENTIALS_REQUIRED');
    requireCondition(uuidPattern.test(credentials.patientId ?? ''), 'TEST_PATIENT_ID_REQUIRED');
    requireCondition(typeof credentials.expectedPatientName === 'string' &&
      testNamePattern.test(credentials.expectedPatientName), 'SYNTHETIC_PATIENT_NAME_REQUIRED');

    const auth = await checked('login', '/auth/v1/token?grant_type=password', {
      method: 'POST', body: { email: credentials.email, password: credentials.password },
    });
    token = auth.access_token;
    requireCondition(token && uuidPattern.test(auth.user?.id ?? ''), 'INVALID_AUTH_RESPONSE');
    const profiles = await checked('profile', `/rest/v1/profiles?select=id,clinic_id,role,is_active&id=eq.${auth.user.id}`);
    const profile = profiles?.[0];
    requireCondition(profiles?.length === 1 && profile.id === auth.user.id &&
      profile.role === 'psychologist' && profile.is_active === true && uuidPattern.test(profile.clinic_id),
    'ACTIVE_PSYCHOLOGIST_REQUIRED');
    const patients = await checked('test_patient', `/rest/v1/patients?select=id,clinic_id,full_name,responsible_psychologist_id&id=eq.${credentials.patientId}`);
    const patient = patients?.[0];
    requireCondition(patients?.length === 1 && patient.id === credentials.patientId &&
      patient.full_name === credentials.expectedPatientName &&
      patient.clinic_id === profile.clinic_id && patient.responsible_psychologist_id === profile.id,
    'ASSIGNED_SYNTHETIC_PATIENT_REQUIRED');

    const filter = `id=eq.${assessmentId}&patient_id=eq.${patient.id}&application_form=eq.${encodeURIComponent(marker)}`;
    const select = 'id,clinic_id,patient_id,results,application_form,shared_with_patient';
    const results = { domains: {} };
    mutationAttempted = true; // O ID é conhecido mesmo se a resposta ao INSERT se perder.
    const created = await checked('create', '/rest/v1/personality_assessments?select=id', {
      method: 'POST', single: true, body: {
        id: assessmentId, clinic_id: patient.clinic_id, patient_id: patient.id,
        created_by: profile.id, updated_by: profile.id, instrument: 'NEO_PI_R',
        application_form: marker, results, shared_with_patient: false,
      },
    });
    requireCondition(created?.id === assessmentId, 'CREATE_ID_MISMATCH');
    const steps = [
      ['neuroticism', 29, 'very_low'], ['extraversion', 44, 'low'],
      ['openness', 55, 'medium'], ['agreeableness', 65, 'high'],
      ['conscientiousness', 66, 'very_high'],
    ];
    for (const [domain, score, classification] of steps) {
      results.domains[domain] = { score, classification };
      const updated = await checked(`save_${domain}`, `/rest/v1/personality_assessments?select=id&${filter}`, {
        method: 'PATCH', single: true,
        body: { results, updated_by: profile.id },
      });
      requireCondition(updated?.id === assessmentId, 'UPDATE_ID_MISMATCH');
      const rows = await checked(`reload_${domain}`, `/rest/v1/personality_assessments?select=${select}&${filter}`);
      requireCondition(rows?.length === 1 && rows[0].id === assessmentId &&
        rows[0].patient_id === patient.id && rows[0].clinic_id === patient.clinic_id &&
        rows[0].shared_with_patient === false && isDeepStrictEqual(rows[0].results, results),
      'PERSISTED_RESULTS_MISMATCH');
    }
    const anon = await request('anonymous_read', `/rest/v1/personality_assessments?select=id&id=eq.${assessmentId}`, { anonymous: true });
    requireCondition([401, 403].includes(anon.status) ||
      (anon.ok && Array.isArray(anon.data) && anon.data.length === 0), 'ANONYMOUS_READ_LEAK');
    report.status = 'passed';
  } catch (error) {
    // Nunca incluir respostas, nomes, IDs de pacientes, tokens ou credenciais.
    report.error = error instanceof SmokeError ? error.message : 'REMOTE_REQUEST_FAILED';
  } finally {
    if (mutationAttempted && token) {
      report.cleanup = 'failed';
      try {
        const filter = `id=eq.${assessmentId}&patient_id=eq.${credentials.patientId}&application_form=eq.${encodeURIComponent(marker)}`;
        await checked('cleanup_delete', `/rest/v1/personality_assessments?${filter}`, { method: 'DELETE' });
        const rows = await checked('cleanup_verify', `/rest/v1/personality_assessments?select=id&id=eq.${assessmentId}`);
        requireCondition(Array.isArray(rows) && rows.length === 0, 'CLEANUP_NOT_CONFIRMED');
        report.cleanup = 'passed';
      } catch {
        report.status = 'failed';
        report.cleanupAssessmentId = assessmentId;
      }
    }
    if (token) {
      try {
        const logout = await request('logout_test_session', '/auth/v1/logout?scope=local', { method: 'POST' });
        requireCondition(logout.ok, 'LOGOUT_NOT_CONFIRMED');
      } catch { report.status = 'failed'; report.logout = 'failed'; }
    }
  }
  return report;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const config = JSON.parse(await readFile(process.argv[2] ?? 'mobile/env.production.json', 'utf8'));
    const credentials = JSON.parse(await readFile(process.argv[3] ?? '.env.personality-smoke.local.json', 'utf8'));
    const report = await validatePersonalityRemote({ config, credentials });
    console.log(JSON.stringify(report, null, 2));
    process.exitCode = report.status === 'passed' ? 0 : 1;
  } catch {
    console.error(JSON.stringify({ status: 'blocked', error: 'LOCAL_CONFIG_OR_CREDENTIALS_UNAVAILABLE' }));
    process.exitCode = 1;
  }
}
