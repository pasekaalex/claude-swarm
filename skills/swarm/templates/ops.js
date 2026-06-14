export const meta = {
  name: 'swarm-ops',
  description: 'Sweep a work-list, transform each item in parallel, judge the batch',
  phases: [{ title: 'Process' }, { title: 'Judge' }],
}
// args: { items:[...], instruction, tier:{wide,judge} }
const wide = (args.tier && args.tier.wide) || 'sonnet'
const judgeModel = (args.tier && args.tier.judge) || 'opus'
const items = args.items || []

phase('Process')
const processed = await parallel(items.map((it, i) => () =>
  agent(`${args.instruction}\nItem ${i}: ${JSON.stringify(it)}`,
    { model: wide, phase: 'Process', label: `item:${i}` })
    .then((out) => ({ item: it, out }))))

phase('Judge')
const review = await agent(
  `Review this batch of processed items for consistency and errors. Flag anomalies.\n${JSON.stringify(processed.filter(Boolean), null, 2)}`,
  { model: judgeModel, phase: 'Judge', label: 'judge' })
return { count: items.length, processed: processed.filter(Boolean), review }
