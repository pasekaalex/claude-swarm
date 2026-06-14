import { readFile } from 'node:fs/promises';

// Run a Workflow-dialect template file with mocked globals; capture calls.
export async function runTemplate(file, { args = {}, agentImpl, budgetTotal = null } = {}) {
  let src = await readFile(file, 'utf8');
  // The Workflow runtime extracts `export const meta` and allows top-level return.
  // Emulate: strip the export keyword, wrap the whole body in an async function.
  src = src.replace(/export\s+const\s+meta\s*=/, 'const meta =');
  const calls = { agents: [], phases: [], logs: [] };
  const sandbox = {
    agent: async (prompt, opts = {}) => {
      calls.agents.push({ prompt, opts });
      if (agentImpl) return agentImpl(prompt, opts);
      return opts.schema ? {} : 'mock-answer';
    },
    parallel: (thunks) => Promise.all(thunks.map((t) => t())),
    pipeline: async (items, ...stages) => {
      const out = [];
      for (let i = 0; i < items.length; i++) {
        let v = items[i];
        try { for (const s of stages) v = await s(v, items[i], i); } catch { v = null; }
        out.push(v);
      }
      return out;
    },
    phase: (t) => calls.phases.push(t),
    log: (m) => calls.logs.push(m),
    budget: { total: budgetTotal, spent: () => 0, remaining: () => (budgetTotal == null ? Infinity : budgetTotal) },
    args,
  };
  const fn = new Function(
    ...Object.keys(sandbox),
    `return (async () => {\n${src}\n})();`
  );
  const result = await fn(...Object.values(sandbox));
  return { calls, result, metaName: (src.match(/name:\s*['"]([^'"]+)['"]/) || [])[1] };
}
