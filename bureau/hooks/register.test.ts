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
function backdrop(
  on: On,
  data: { agents?: AgentInfo[]; handoff?: string; notifyOk?: boolean; profile?: string; profileAt?: 'new' | 'old' | 'v14' | 'both'; claude?: string; home?: string } = {},
) {
  const seen = { status: [] as (string | undefined)[], toasts: [] as string[], notices: [] as string[] }
  mock.store(on)
  mock.env(on, data.home === undefined ? { HOME: '/tmp/faux-home' } : { HOME: data.home })
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
  // Les fichiers lus : le HANDOFF du projet, son CLAUDE.md et le profil (chemin absolu sous HOME).
  on('fs.read', (_$, e) => {
    const content = e.path.endsWith('HANDOFF.md')
      ? data.handoff
      : e.path.endsWith('CLAUDE.md')
        ? data.claude
        : e.path === '/tmp/faux-home/.claude/diapason/profil.md' && data.profileAt !== 'old' && data.profileAt !== 'v14'
          ? data.profile
          : e.path === '/tmp/faux-home/.claude/majordome/profil.md' && data.profileAt === 'v14'
            ? data.profile
            : e.path === '/tmp/faux-home/.claude/maitre-agent/profil.md' && data.profileAt !== undefined && data.profileAt !== 'new' && data.profileAt !== 'v14'
            ? (data.profileAt === 'both' ? '## Réglages\n- seuils : 90 91 92\n' : data.profile)
            : undefined
    return content === undefined ? { deny: 'ENOENT : fichier absent' } : { value: content }
  })
  // Événements du moteur que le test lève lui-même : le fond répond comme le moteur (écho).
  on('session.measure', (_$, e) => ({ changed: e.changed }))
  return seen
}

test('session.measure : ligne d\'état avec projet, agents et quota', async ($, on) => {
  const seen = backdrop(on, { agents: [info('a1', 'dia-chercheur'), info('a2', 'Explore', 'completed')] })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(42), changed: ['rateLimits'] })
  expect(seen.status.at(-1)).toBe('🛎️ projet-factice · 1 agent · 5 h 42 % (reset 18:30) · 7 j 12 %')
})

test('repli propre sans quota', async ($, on) => {
  const seen = backdrop(on)
  await $.session.measure({ context: CONTEXT, rateLimits: [], changed: ['context'] })
  expect(seen.status.at(-1)).toBe('🛎️ projet-factice · 0 agents · quota ?')
  expect(seen.toasts).toEqual([])
})

test('jalon lu dans docs/HANDOFF.md', async ($, on) => {
  const seen = backdrop(on, { handoff: '# HANDOFF\nJalon : J3 bureau\n' })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(5), changed: ['rateLimits'] })
  expect(seen.status.at(-1)).toBe('🛎️ projet-factice · J3 bureau · 0 agents · 5 h 5 % (reset 18:30) · 7 j 12 %')
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
  const seen = backdrop(on, { agents: [info('n1', 'dia-chercheur')] })
  on('agent.spawn', () => ({ model: 'sonnet', agentId: 'n1' }))
  await $.agent.spawn({
    tool_use_id: 't1',
    prompt: 'lire',
    description: 'lecture',
    subagentType: 'dia-chercheur',
  } as never)
  expect(seen.status.at(-1)).toBe('🛎️ projet-factice · 1 agent · quota ?')
})

test('agent.spawn : sans agentId ni type, le lancement passe quand même', async ($, on) => {
  const seen = backdrop(on, { agents: [] })
  on('agent.spawn', () => ({ model: 'sonnet' }))
  const r = await $.agent.spawn({ tool_use_id: 't2', prompt: 'x', description: 'x' } as never)
  expect((r as { model?: string }).model).toBe('sonnet')
  expect(seen.status.length).toBe(0) // rien à compter, rien d'affiché, aucune exception
})

test('fin d\'un sous-agent dia-* : toast avec le statut', async ($, on) => {
  const seen = backdrop(on, { agents: [info('n1', 'diapason:dia-executant')] })
  on('turn.complete', () => ({ text: '' }))
  await $.turn.complete({
    answer: '**TERMINÉ AVEC RÉSERVES**\nle détail est dans le journal',
    durationMs: 1000,
    isAborted: false,
    turnId: 'u1',
    agentId: 'n1',
    reason: 'answer',
  })
  expect(seen.toasts).toEqual(['dia-executant : TERMINÉ AVEC RÉSERVES'])
  expect(seen.status.at(-1)).toBe('🛎️ projet-factice · 0 agents · quota ?')
})

test('fin d\'un sous-agent hors dia-* ou du fil principal : pas de toast', async ($, on) => {
  const seen = backdrop(on, { agents: [info('n2', 'Explore')] })
  on('turn.complete', () => ({ text: '' }))
  const base = { answer: 'TERMINÉ', durationMs: 1, isAborted: false, reason: 'answer' as const }
  await $.turn.complete({ ...base, turnId: 'u2', agentId: 'n2' })
  await $.turn.complete({ ...base, turnId: 'u3' })
  expect(seen.toasts).toEqual([])
})

const PROFIL = '# Profil\n\n## Réglages\n- seuils : 60 75 85\n- notifications : agent+quota\n'

test('réglage seuils du profil : alertes à 60 / 75 / 85', async ($, on) => {
  const seen = backdrop(on, { profile: PROFIL })
  for (const p of [50, 60, 61, 70, 75, 80, 85, 99]) {
    await $.session.measure({ context: CONTEXT, rateLimits: limits(p), changed: ['rateLimits'] })
  }
  expect(seen.toasts).toEqual([
    'Quota 5 h : 60 % atteint (60 %), reset 18:30',
    'Quota 5 h : 75 % atteint (75 %), reset 18:30',
    'Quota 5 h : 85 % atteint (85 %), reset 18:30',
  ])
})

test('réglages du projet : le CLAUDE.md surcharge le profil', async ($, on) => {
  const seen = backdrop(on, { profile: PROFIL, claude: '# P\n## Réglages du projet\n- seuils : 50 65 80\n' })
  for (const p of [49, 50, 64, 65]) {
    await $.session.measure({ context: CONTEXT, rateLimits: limits(p), changed: ['rateLimits'] })
  }
  expect(seen.toasts.length).toBe(2)
  expect(seen.toasts[0]).toContain('50 % atteint')
  expect(seen.toasts[1]).toContain('65 % atteint')
})

test('réglage notifications rien : aucun toast ni notification de quota, la ligne d\'état reste', async ($, on) => {
  const seen = backdrop(on, { profile: '## Réglages\n- notifications : rien\n' })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(95), changed: ['rateLimits'] })
  expect(seen.toasts).toEqual([])
  expect(seen.notices).toEqual([])
  expect(seen.status.length).toBe(1)
})

test('réglage notifications quota : pas de toast de fin d\'agent', async ($, on) => {
  const seen = backdrop(on, {
    agents: [info('n1', 'dia-executant')],
    profile: '## Réglages\n- notifications : quota\n',
  })
  on('turn.complete', () => ({ text: '' }))
  await $.turn.complete({ answer: 'TERMINÉ', durationMs: 1, isAborted: false, turnId: 'u1', agentId: 'n1', reason: 'answer' })
  expect(seen.toasts).toEqual([])
  await $.session.measure({ context: CONTEXT, rateLimits: limits(75), changed: ['rateLimits'] })
  expect(seen.toasts.length).toBe(1) // les alertes de quota restent actives
})

test('profil absent, valeur invalide ou HOME inconnu : les défauts 70 / 80 / 90', async ($, on) => {
  const seen = backdrop(on, { profile: '## Réglages\n- seuils : 90 80 70\n- notifications : peut-etre\n' })
  await $.session.measure({ context: CONTEXT, rateLimits: limits(65), changed: ['rateLimits'] })
  expect(seen.toasts).toEqual([])
  await $.session.measure({ context: CONTEXT, rateLimits: limits(71), changed: ['rateLimits'] })
  expect(seen.toasts.length).toBe(1)
  expect(seen.toasts[0]).toContain('70 % atteint')
})

test('profil de la v1.4 dans l\'ancien dossier majordome : lu quand le dossier diapason n\'a pas de profil', async ($, on) => {
  const seen = backdrop(on, { profile: PROFIL, profileAt: 'v14' })
  for (const p of [50, 60, 61]) {
    await $.session.measure({ context: CONTEXT, rateLimits: limits(p), changed: ['rateLimits'] })
  }
  expect(seen.toasts).toEqual(['Quota 5 h : 60 % atteint (60 %), reset 18:30'])
})

test('profil de la v1.3 dans l\'ancien dossier maitre-agent : lu quand le nouveau dossier n\'a pas de profil', async ($, on) => {
  const seen = backdrop(on, { profile: PROFIL, profileAt: 'old' })
  for (const p of [50, 60, 61]) {
    await $.session.measure({ context: CONTEXT, rateLimits: limits(p), changed: ['rateLimits'] })
  }
  expect(seen.toasts).toEqual(['Quota 5 h : 60 % atteint (60 %), reset 18:30'])
})

test('les deux profils présents : celui du dossier diapason gagne', async ($, on) => {
  const seen = backdrop(on, { profile: PROFIL, profileAt: 'both' })
  for (const p of [50, 60, 61]) {
    await $.session.measure({ context: CONTEXT, rateLimits: limits(p), changed: ['rateLimits'] })
  }
  expect(seen.toasts).toEqual(['Quota 5 h : 60 % atteint (60 %), reset 18:30'])
})
