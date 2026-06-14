export const meta = {
  name: 'swarm-review',
  description: 'Find issues by dimension, adversarially verify each, report confirmed only',
  phases: [{ title: 'Review' }, { title: 'Verify' }],
}
// args: { target, tier:{wide,judge} }
const wide = (args.tier && args.tier.wide) || 'sonnet'
const judgeModel = (args.tier && args.tier.judge) || 'opus'
const DIMS = [
  { key: 'correctness', prompt: 'logic/correctness bugs' },
  { key: 'security', prompt: 'security vulnerabilities' },
  { key: 'performance', prompt: 'performance problems' },
  { key: 'style', prompt: 'clarity / maintainability issues' },
]
const FINDINGS = { type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['title', 'file', 'line'],
    properties: { title: { type: 'string' }, file: { type: 'string' }, line: { type: 'number' } } } } } }
const VERDICT = { type: 'object', additionalProperties: false, required: ['real', 'why'],
  properties: { real: { type: 'boolean' }, why: { type: 'string' } } }

phase('Review')
const results = await pipeline(
  DIMS,
  (d) => agent(`Review ${args.target} for ${d.prompt}. Report concrete findings with file:line.`,
    { model: wide, phase: 'Review', label: `review:${d.key}`, schema: FINDINGS }),
  (rev) => parallel((rev ? rev.findings : []).map((f) => () =>
    agent(`Adversarially verify this finding in ${args.target}: "${f.title}" at ${f.file}:${f.line}. Try to refute; default real=false if uncertain.`,
      { model: judgeModel, phase: 'Verify', label: `verify:${f.file}:${f.line}`, schema: VERDICT })
      .then((v) => ({ ...f, verdict: v }))))
)
phase('Verify')
const confirmed = results.flat().filter(Boolean).filter((f) => f.verdict && f.verdict.real)
return { target: args.target, confirmed }
