export const meta = {
  name: 'swarm-research',
  description: 'Search fan-out across angles, adversarial verification, cited synthesis',
  phases: [{ title: 'Search' }, { title: 'Verify' }, { title: 'Synthesize' }],
}

// args: { question, tier:{wide,judge}, dryRounds=2, maxRounds=4 }
const Q = args.question
const wide = (args.tier && args.tier.wide) || 'sonnet'
const judgeModel = (args.tier && args.tier.judge) || 'opus'
const ANGLES = ['primary sources & docs', 'by-entity / who-is-involved', 'contrarian / what-could-be-wrong', 'recent / time-sensitive']

const FINDINGS = {
  type: 'object', additionalProperties: false,
  required: ['findings', 'dry'],
  properties: {
    findings: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['claim', 'source'], properties: { claim: { type: 'string' }, source: { type: 'string' } } } },
    dry: { type: 'boolean', description: 'true if this angle found nothing new' },
  },
}
const VERDICT = {
  type: 'object', additionalProperties: false, required: ['real', 'why'],
  properties: { real: { type: 'boolean' }, why: { type: 'string' } },
}

phase('Search')
const seen = new Set(); const all = []
let dry = 0; let round = 0
const maxRounds = args.maxRounds || 4; const dryStop = args.dryRounds || 2
while (dry < dryStop && round < maxRounds) {
  round++
  const batch = await parallel(ANGLES.map((angle, i) => () =>
    agent(`Research question: "${Q}". Angle: ${angle}. Round ${round}. Use web search/fetch. Return only NEW findings not already covered; set dry=true if you found nothing new.`,
      { model: wide, phase: 'Search', label: `find:r${round}:${i}`, schema: FINDINGS })))
  const fresh = batch.filter(Boolean).flatMap((b) => b.findings).filter((f) => !seen.has(f.claim))
  if (!fresh.length) { dry++; log(`round ${round}: dry (${dry}/${dryStop})`); continue }
  dry = 0; fresh.forEach((f) => seen.add(f.claim)); all.push(...fresh)
  log(`round ${round}: +${fresh.length} findings (${all.length} total)`)
}

phase('Verify')
const verified = await parallel(all.map((f, i) => () =>
  agent(`Adversarially verify this claim for question "${Q}": "${f.claim}" (source: ${f.source}). Try to REFUTE it; default real=false if uncertain.`,
    { model: judgeModel, phase: 'Verify', label: `verify:${i}`, schema: VERDICT })
    .then((v) => ({ ...f, verdict: v }))))
const confirmed = verified.filter(Boolean).filter((f) => f.verdict && f.verdict.real)

phase('Synthesize')
const final = await agent(
  `Synthesize a cited answer to "${Q}" from these verified findings:\n${JSON.stringify(confirmed, null, 2)}\n` +
  `Structure your analysis as: consensus, contradictions, partial coverage, unique insights, blind spots — then write the grounded final answer with inline source citations.`,
  { model: judgeModel, phase: 'Synthesize', label: 'judge' })

return { question: Q, confirmed, rounds: round, answer: final }
