import test from 'node:test';
import assert from 'node:assert/strict';
import { validatePersonalityRemote } from './validate-personality-remote.mjs';

const userId = '11111111-1111-1111-1111-111111111103';
const clinicId = '11111111-1111-1111-1111-111111111101';
const config = { SUPABASE_URL: 'https://smoke.example.test', SUPABASE_ANON_KEY: 'sb_publishable_test_only' };
const credentials = {
  email: 'smoke@example.test', password: 'synthetic-test-password',
  patientId: '11111111-1111-1111-1111-111111111201', expectedPatientName: 'Paciente TESTE NEO',
};

function fixture(options = {}) {
  let row = null;
  const requests = [];
  const json = (body, status = 200) => new Response(JSON.stringify(body), { status });
  const fetchImpl = async (url, init) => {
    const body = init.body ? JSON.parse(init.body) : undefined;
    requests.push({ url, method: init.method, body });
    if (url.pathname === '/auth/v1/token') {
      return json({ access_token: 'synthetic-session-token', user: { id: userId } });
    }
    if (url.pathname === '/auth/v1/logout') return new Response(null, { status: 204 });
    if (url.pathname === '/rest/v1/profiles') {
      return json([{ id: userId, clinic_id: clinicId, role: options.role ?? 'psychologist', is_active: true }]);
    }
    if (url.pathname === '/rest/v1/patients') {
      return json([{ id: credentials.patientId, clinic_id: clinicId,
        full_name: options.patientName ?? credentials.expectedPatientName,
        responsible_psychologist_id: userId }]);
    }
    assert.equal(url.pathname, '/rest/v1/personality_assessments');
    if (init.method === 'POST') {
      row = structuredClone(body);
      if (options.lostInsertResponse) throw new Error('SIMULATED_RESPONSE_LOSS');
      return json({ id: row.id }, 201);
    }
    if (init.method === 'PATCH') {
      assert.equal(url.searchParams.get('id'), `eq.${row.id}`);
      if (options.failUpdate) return json({ message: 'Do not log this body' }, 500);
      row.results = structuredClone(body.results);
      return json({ id: row.id });
    }
    if (init.method === 'DELETE') {
      assert.equal(url.searchParams.get('id'), `eq.${row.id}`);
      assert.equal(url.searchParams.get('patient_id'), `eq.${credentials.patientId}`);
      assert.equal(url.searchParams.get('application_form'), `eq.${row.application_form}`);
      if (options.failCleanup) return json({}, 500);
      row = null;
      return new Response(null, { status: 204 });
    }
    if (!init.headers.Authorization) return json(options.anonymousLeak ? [{ id: row.id }] : []);
    return json(row ? [structuredClone(row)] : []);
  };
  return { fetchImpl, requests, get row() { return row; } };
}

test('cria um registro, salva cinco domínios, relê, verifica anon e remove', async () => {
  const server = fixture();
  const report = await validatePersonalityRemote({ config, credentials, fetchImpl: server.fetchImpl });
  assert.equal(report.status, 'passed');
  assert.equal(report.cleanup, 'passed');
  assert.equal(server.row, null);
  assert.equal(server.requests.filter(r => r.method === 'POST' && r.url.pathname.includes('personality')).length, 1);
  assert.equal(server.requests.filter(r => r.method === 'PATCH').length, 5);
  assert.equal(report.checks.filter(c => c.name.startsWith('reload_')).length, 5);
  assert.equal(server.requests.at(-1).url.searchParams.get('scope'), 'local');
  for (const secret of [credentials.password, credentials.patientId, credentials.expectedPatientName, 'synthetic-session-token']) {
    assert.ok(!JSON.stringify(report).includes(secret));
  }
});

test('bloqueia conta administrativa e paciente diferente antes de gravar', async () => {
  for (const options of [{ role: 'platform_admin' }, { patientName: 'Pessoa real' }]) {
    const server = fixture(options);
    const report = await validatePersonalityRemote({ config, credentials, fetchImpl: server.fetchImpl });
    assert.equal(report.status, 'failed');
    assert.equal(report.cleanup, 'not_needed');
    assert.equal(server.requests.filter(r => ['PATCH', 'DELETE'].includes(r.method) || r.url.pathname.includes('personality')).length, 0);
    assert.equal(server.requests.at(-1).url.pathname, '/auth/v1/logout');
  }
});

test('credenciais ausentes, nome não sintético e service_role não iniciam rede', async () => {
  const serviceKey = `header.${Buffer.from(JSON.stringify({ role: 'service_role' })).toString('base64url')}.signature`;
  for (const overrides of [
    { credentials: { ...credentials, password: '' } },
    { credentials: { ...credentials, expectedPatientName: 'Pessoa real' } },
    { config: { ...config, SUPABASE_ANON_KEY: serviceKey } },
  ]) {
    const server = fixture();
    const report = await validatePersonalityRemote({ config, credentials, ...overrides, fetchImpl: server.fetchImpl });
    assert.equal(report.status, 'failed');
    assert.equal(server.requests.length, 0);
  }
});

test('falha de atualização interrompe etapas e limpa somente o registro criado', async () => {
  const server = fixture({ failUpdate: true });
  const report = await validatePersonalityRemote({ config, credentials, fetchImpl: server.fetchImpl });
  assert.equal(report.status, 'failed');
  assert.equal(report.error, 'SAVE_NEUROTICISM_HTTP_500');
  assert.equal(report.cleanup, 'passed');
  assert.equal(server.row, null);
  assert.equal(server.requests.filter(r => r.method === 'PATCH').length, 1);
});

test('perda da resposta ao INSERT permite cleanup pelo ID pré-alocado', async () => {
  const server = fixture({ lostInsertResponse: true });
  const report = await validatePersonalityRemote({ config, credentials, fetchImpl: server.fetchImpl });
  assert.equal(report.status, 'failed');
  assert.equal(report.cleanup, 'passed');
  assert.equal(server.row, null);
});

test('vazamento para anon falha e ainda remove o registro sintético', async () => {
  const server = fixture({ anonymousLeak: true });
  const report = await validatePersonalityRemote({ config, credentials, fetchImpl: server.fetchImpl });
  assert.equal(report.error, 'ANONYMOUS_READ_LEAK');
  assert.equal(report.status, 'failed');
  assert.equal(report.cleanup, 'passed');
});

test('cleanup não confirmado impede sucesso e informa apenas o ID sintético', async () => {
  const server = fixture({ failCleanup: true });
  const report = await validatePersonalityRemote({ config, credentials, fetchImpl: server.fetchImpl });
  assert.equal(report.status, 'failed');
  assert.equal(report.cleanup, 'failed');
  assert.equal(report.cleanupAssessmentId, server.row.id);
  assert.ok(!JSON.stringify(report).includes(credentials.patientId));
});

test('exceções externas não expõem mensagem potencialmente sensível', async () => {
  const report = await validatePersonalityRemote({ config, credentials,
    fetchImpl: async () => { throw new Error('SENSITIVE_EXTERNAL_MESSAGE'); },
  });
  assert.equal(report.error, 'REMOTE_REQUEST_FAILED');
  assert.ok(!JSON.stringify(report).includes('SENSITIVE_EXTERNAL_MESSAGE'));
});
