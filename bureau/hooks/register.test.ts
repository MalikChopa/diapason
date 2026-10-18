// Tests du mod avec le moteur : les hooks `on` du test sont le « fond » (ui, session, agents, fichiers),
// ils enregistrent ce que le mod affiche. Rien n'apparaît à l'écran.
import type { AgentInfo, On, SessionRateLimit } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

const RESET = new Date(2026, 9, 18, 18, 30, 0).toISOString()
const CONTEXT = { window: 200000 }

const limits = (five: number, seven = 12): SessionRateLimit[] => [
  { kind: 'five_hour', percentUsed: five, resetsAt: RESET },
  { kind: 'seven_day', percentUsed: seven },
]

const info = (id: string, type: string, status: AgentInfo['status'] = 'running'): AgentInfo => ({
  id,
  type,
  status,
  description: 'tâche factice',
})

/** Pose le fond : enregistre statuts, toasts et notifications ; données factices. */
function backdrop(on: On, data: { agents?: AgentInfo[]; handoff?: string; notifyOk?: boolean } = {}) {
  const seen = { status: [] as (string | undefined)[], toasts: [] as string[], notices: [] as string[] }
  mock.store(on)
  on('ui.status', (_$, e) => {
    seen.status.push(e.text)
    return { value: undefined }
  })
  on('ui.toast', (_$, e) => {
    seen.toasts.push(e.text)
    return { value: undefined }
  })
  on('ui.notify', (_$, e) => {
    seen.notices.push(e.text)
    return {
      value:
        data.notifyOk === false
          ? { isSent: false as const, reason: 'no-channel' as const }
          : { isSent: true as const, channel: 'terminal_bell' as const },
    }
  })
  on('session.cwd', () => ({ value: '/tmp/demo/projet-factice' }))
  on('session.usage', () => ({ value: { startedAt: 0, context: CONTEXT, rateLimits: [] } }))
  on('agent.list', () => ({ value: data.agents ?? [] }))
  on('fs.read', () =>
    data.handoff === undefined ? { deny: 'ENOENT : fichier absent' } : { value: data.handoff },
  )
  // Événements du moteur que le test lève lui-même : le fond répond comme le moteur (écho).
  on('session.measure', (_$, e) => ({ changed: e.changed }))
  return seen
}

test('session.measure : ligne d\'état avec projet, agents et quota', async ($, on) => {
  const seen = backdrop(on, { agents: [info('a1', 'ma-chercheur'), info('a2', 'Explore', 'completed')] })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(42), changed: ['rateLimits'] })
  expect(seen.status.at(-1)).toBe('🧭 projet-factice · 1 agent · 5 h 42 % (reset 18:30) · 7 j 12 %')
})

test('repli propre sans quota', async ($, on) => {
  const seen = backdrop(on)
  await $.session.measure({ context: CONTEXT, rateLimits: [], changed: ['context'] })
  expect(seen.status.at(-1)).toBe('🧭 projet-factice · 0 agents · quota ?')
  expect(seen.toasts).toEqual([])
})

test('jalon lu dans docs/HANDOFF.md', async ($, on) => {
  const seen = backdrop(on, { handoff: '# HANDOFF\nJalon : J3 bureau\n' })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(5), changed: ['rateLimits'] })
  expect(seen.status.at(-1)).toBe('🧭 projet-factice · J3 bureau · 0 agents · 5 h 5 % (reset 18:30) · 7 j 12 %')
})

test('alertes 70 / 80 / 90 : une fois chacune, toast et notification', async ($, on) => {
  const seen = backdrop(on)
  for (const p of [50, 70, 71, 79, 80, 81, 90, 95, 99]) {
    await $.session.measure({ context: CONTEXT, rateLimits: limits(p), changed: ['rateLimits'] })
  }
  expect(seen.toasts).toEqual([
    'Quota 5 h : 70 % atteint (70 %), reset 18:30',
    'Quota 5 h : 80 % atteint (80 %), reset 18:30',
    'Quota 5 h : 90 % atteint (90 %), reset 18:30',
  ])
  expect(seen.notices).toEqual(seen.toasts)
})

test('l\'état des alertes survit : pas de répétition après un nouveau départ du même quota', async ($, on) => {
  const seen = backdrop(on)
  await $.session.measure({ context: CONTEXT, rateLimits: limits(75), changed: ['rateLimits'] })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(76), changed: ['rateLimits'] })
  expect(seen.toasts.length).toBe(1)
})

test('notification impossible : le toast suffit, rien ne casse', async ($, on) => {
  const seen = backdrop(on, { notifyOk: false })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(91), changed: ['rateLimits'] })
  expect(seen.toasts.length).toBe(1)
  expect(seen.status.length).toBe(1)
})

test('agent.spawn : le compteur monte', async ($, on) => {
  const seen = backdrop(on, { agents: [info('n1', 'ma-chercheur')] })
  on('agent.spawn', () => ({ model: 'sonnet', agentId: 'n1' }))
  await $.agent.spawn({
    tool_use_id: 't1',
    prompt: 'lire',
    description: 'lecture',
    subagentType: 'ma-chercheur',
  } as never)
  expect(seen.status.at(-1)).toBe('🧭 projet-factice · 1 agent · quota ?')
})

test('fin d\'un sous-agent ma-* : toast avec le statut', async ($, on) => {
  const seen = backdrop(on, { agents: [info('n1', 'maitre-agent:ma-executant')] })
  on('turn.complete', () => ({ text: '' }))
  await $.turn.complete({
    answer: '**TERMINÉ AVEC RÉSERVES**\nle détail est dans le journal',
    durationMs: 1000,
    isAborted: false,
    turnId: 'u1',
    agentId: 'n1',
    reason: 'answer',
  })
  expect(seen.toasts).toEqual(['ma-executant : TERMINÉ AVEC RÉSERVES'])
  expect(seen.status.at(-1)).toBe('🧭 projet-factice · 0 agents · quota ?')
})

test('fin d\'un sous-agent hors ma-* ou du fil principal : pas de toast', async ($, on) => {
  const seen = backdrop(on, { agents: [info('n2', 'Explore')] })
  on('turn.complete', () => ({ text: '' }))
  const base = { answer: 'TERMINÉ', durationMs: 1, isAborted: false, reason: 'answer' as const }
  await $.turn.complete({ ...base, turnId: 'u2', agentId: 'n2' })
  await $.turn.complete({ ...base, turnId: 'u3' })
  expect(seen.toasts).toEqual([])
})
