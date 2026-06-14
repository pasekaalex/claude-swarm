export const meta = {
  name: 'swarm-build',
  description: 'Decompose a spec into units, implement each in isolation, verify',
  phases: [{ title: 'Decompose' }, { title: 'Implement' }, { title: 'Verify' }],
}
// args: { spec, tier:{wide,judge}, isolate=false }
// The Workflow runtime delivers `args` as a JSON string; parse defensively.
const A = (() => { try { return typeof args === 'string' ? JSON.parse(args) : (args || {}); } catch (e) { return {}; } })();
const wide = (A.tier && A.tier.wide) || 'sonnet'
const judgeModel = (A.tier && A.tier.judge) || 'opus'
const UNITS = { type: 'object', additionalProperties: false, required: ['units'],
  properties: { units: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'detail'],
    properties: { name: { type: 'string' }, detail: { type: 'string' } } } } } }

phase('Decompose')
const plan = await agent(`Decompose this build spec into independent, parallelizable units of work:\n${A.spec}`,
  { model: judgeModel, phase: 'Decompose', label: 'decompose', schema: UNITS })

const built = await pipeline(
  (plan && plan.units) || [],
  (u) => agent(`Implement unit "${u.name}": ${u.detail}\nSpec context: ${A.spec}`,
    { model: wide, phase: 'Implement', label: `impl:${u.name}`, ...(A.isolate ? { isolation: 'worktree' } : {}) }),
  (out, u, i) => agent(`Verify the implementation of unit "${(plan.units[i] || {}).name}". Report PASS/FAIL with reasons.\nResult:\n${out}`,
    { model: judgeModel, phase: 'Verify', label: `verify:${i}` })
)
return { spec: A.spec, units: (plan && plan.units) || [], results: built.filter(Boolean) }
