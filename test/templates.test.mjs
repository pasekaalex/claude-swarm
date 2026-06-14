import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { runTemplate } from './harness.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const tpl = (n) => join(ROOT, 'skills/swarm/templates', n);

test('research: fans out finders, verifies, and synthesizes', async () => {
  const { calls } = await runTemplate(tpl('research.js'), {
    args: { question: 'test q', tier: { wide: 'sonnet', judge: 'opus' } },
    agentImpl: (p, o) =>
      o.schema ? { findings: [{ claim: 'c1' }], dry: true, verdict: { real: true } } : 'text',
  });
  assert.ok(calls.agents.length >= 3, 'spawns multiple agents');
  assert.ok(calls.phases.includes('Search'), 'has Search phase');
  assert.ok(calls.phases.includes('Synthesize'), 'has Synthesize phase');
  const judge = calls.agents.find((a) => /consensus|contradiction|blind spot/i.test(a.prompt));
  assert.ok(judge, 'a judge agent uses the structured rubric');
});

test('review: finds by dimension then verifies findings', async () => {
  const { calls } = await runTemplate(tpl('review.js'), {
    args: { target: 'diff', tier: { wide: 'sonnet', judge: 'opus' } },
    agentImpl: (p, o) => (o.schema ? { findings: [{ title: 't', file: 'f', line: 1 }], verdict: { real: true } } : 'text'),
  });
  assert.ok(calls.phases.includes('Review'), 'has Review phase');
  assert.ok(calls.phases.includes('Verify'), 'has Verify phase');
});

test('build: decomposes then implements per unit', async () => {
  const { calls } = await runTemplate(tpl('build.js'), {
    args: { spec: 'do X', tier: { wide: 'sonnet', judge: 'opus' } },
    agentImpl: (p, o) => (o.schema ? { units: [{ name: 'u1', detail: 'd' }] } : 'done'),
  });
  assert.ok(calls.agents.length >= 2, 'decompose + at least one implement');
});

test('ops: maps work items through transform + judge', async () => {
  const { calls } = await runTemplate(tpl('ops.js'), {
    args: { items: [{ id: 'a' }, { id: 'b' }], instruction: 'process', tier: { wide: 'sonnet', judge: 'opus' } },
    agentImpl: (p, o) => (o.schema ? { ok: true } : 'processed'),
  });
  assert.ok(calls.agents.length >= 2, 'one agent per item at least');
});
