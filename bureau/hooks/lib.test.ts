import { describe, expect, test } from 'claude-code/testing'

import {
  agentDoneText,
  alertText,
  decideAlerts,
  firstLine,
  formatReset,
  formatStatus,
  isMaAgent,
  levelOf,
  parseMilestone,
  parseNotifications,
  parseThresholds,
  projectName,
  readSection,
  resolveSettings,
  truncate,
  wantsAgentDone,
  wantsQuotaAlerts,
} from './lib'
import type { AlertState, Window } from './lib'

// Une date locale 18:30 (le test ne dépend pas du fuseau de la machine).
const at1830 = (day: number) => new Date(2026, 9, day, 18, 30, 0).toISOString()

describe('ligne d\'état', () => {
  test('quota complet', async () => {
    const line = formatStatus({
      project: 'demo',
      agents: 2,
      rateLimits: [
        { kind: 'five_hour', percentUsed: 41.6, resetsAt: at1830(18) },
        { kind: 'seven_day', percentUsed: 12 },
      ],
    })
    expect(line).toBe('🛎️ demo · 2 agents · 5 h 42 % (reset 18:30) · 7 j 12 %')
  })

  test('singulier, jalon et quota absent', async () => {
    expect(formatStatus({ project: 'demo', agents: 1, rateLimits: [], milestone: 'J2' })).toBe(
      '🛎️ demo · J2 · 1 agent · quota ?',
    )
    expect(formatStatus({ project: '', agents: 0, rateLimits: undefined })).toBe('🛎️ session · 0 agents · quota ?')
  })

  test('une seule fenêtre connue', async () => {
    expect(formatStatus({ project: 'p', agents: 0, rateLimits: [{ kind: 'five_hour', percentUsed: 5 }] })).toBe(
      '🛎️ p · 0 agents · 5 h 5 % · 7 j ?',
    )
  })

  test('nom du projet et heure de reset', async () => {
    expect(projectName('/tmp/demo/mon-projet/')).toBe('mon-projet')
    expect(projectName('C:\\Users\\demo\\jeu')).toBe('jeu')
    expect(projectName(undefined)).toBe('')
    expect(formatReset(at1830(18))).toBe('18:30')
    expect(formatReset('pas une date')).toBe(undefined)
    expect(formatReset(undefined)).toBe(undefined)
  })
})

describe('alertes de quota', () => {
  const w = (percentUsed: number, resetsAt = at1830(18), kind = 'five_hour'): Window[] => [
    { kind, percentUsed, resetsAt },
  ]

  test('niveaux', async () => {
    expect([0, 69.9, 70, 79, 80, 89.9, 90, 100].map(p => levelOf(p))).toEqual([0, 0, 70, 70, 80, 80, 90, 90])
  })

  test('une seule fois par seuil et par fenêtre', async () => {
    let state: AlertState | undefined
    const seen: number[] = []
    for (const p of [10, 69, 70, 71, 75, 80, 85, 90, 95, 99]) {
      const r = decideAlerts(state, w(p))
      state = r.state
      seen.push(...r.alerts.map(a => a.threshold))
    }
    expect(seen).toEqual([70, 80, 90])
  })

  test('un saut franchit plusieurs seuils : une seule alerte, la plus haute', async () => {
    const r = decideAlerts(undefined, w(85))
    expect(r.alerts.length).toBe(1)
    expect(r.alerts[0]?.threshold).toBe(80)
  })

  test('nouvelle fenêtre : on repart de zéro', async () => {
    const first = decideAlerts(undefined, w(92, at1830(18)))
    expect(first.alerts[0]?.threshold).toBe(90)
    const sameWindow = decideAlerts(first.state, w(93, at1830(18)))
    expect(sameWindow.alerts).toEqual([])
    const nextWindow = decideAlerts(first.state, w(71, at1830(19)))
    expect(nextWindow.alerts[0]?.threshold).toBe(70)
  })

  test('pourcentage retombé sans date de reset : on repart de zéro', async () => {
    const first = decideAlerts(undefined, [{ kind: 'five_hour', percentUsed: 91 }])
    const after = decideAlerts(first.state, [{ kind: 'five_hour', percentUsed: 3 }])
    expect(after.alerts).toEqual([])
    const again = decideAlerts(after.state, [{ kind: 'five_hour', percentUsed: 72 }])
    expect(again.alerts[0]?.threshold).toBe(70)
  })

  test('fenêtres indépendantes', async () => {
    const r = decideAlerts(undefined, [
      { kind: 'five_hour', percentUsed: 71, resetsAt: at1830(18) },
      { kind: 'seven_day', percentUsed: 91 },
    ])
    expect(r.alerts.map(a => `${a.kind}:${a.threshold}`)).toEqual(['five_hour:70', 'seven_day:90'])
  })

  test('le seuil se compare à la valeur affichée (69,6 s\'affiche 70 %)', async () => {
    expect(decideAlerts(undefined, w(69.6)).alerts.map(a => a.threshold)).toEqual([70])
    expect(decideAlerts(undefined, w(69.4)).alerts).toEqual([])
    expect(decideAlerts(undefined, w(79.5)).alerts.map(a => a.threshold)).toEqual([80])
  })

  test('texte', async () => {
    expect(alertText({ kind: 'five_hour', threshold: 80, percent: 81.4, resetsAt: at1830(18) })).toBe(
      'Quota 5 h : 80 % atteint (81 %), reset 18:30',
    )
    expect(alertText({ kind: 'seven_day', threshold: 70, percent: 70 })).toBe('Quota 7 j : 70 % atteint (70 %)')
  })
})

describe('sous-agents ma-*', () => {
  test('reconnaissance du type', async () => {
    expect(isMaAgent('ma-chercheur')).toBe(true)
    expect(isMaAgent('majordome:ma-executant')).toBe(true)
    expect(isMaAgent('maitre-agent:ma-executant')).toBe(true) // ancien préfixe du plugin (v1.3)
    expect(isMaAgent('general-purpose')).toBe(false)
    expect(isMaAgent('autre:ma-x')).toBe(false)
    expect(isMaAgent('maman')).toBe(false)
    expect(isMaAgent(undefined)).toBe(false)
  })

  test('première ligne du rapport', async () => {
    expect(firstLine('\n\n## **TERMINÉ AVEC RÉSERVES**\nle reste')).toBe('TERMINÉ AVEC RÉSERVES')
    expect(firstLine('- `BLOQUÉ` : pas de réseau')).toBe('BLOQUÉ : pas de réseau')
    expect(firstLine('   ')).toBe('')
  })

  test('texte du toast : 80 caractères au plus', async () => {
    expect(agentDoneText('majordome:ma-chercheur', 'TERMINÉ\nsuite')).toBe('ma-chercheur : TERMINÉ')
    const long = agentDoneText('ma-executant', 'TERMINÉ ' + 'x'.repeat(200))
    expect(Array.from(long).length).toBe(80)
    expect(long.endsWith('…')).toBe(true)
    expect(agentDoneText('ma-auditeur', '', 'aborted')).toBe('ma-auditeur : interrompu')
    expect(truncate('court', 80)).toBe('court')
  })
})

describe('jalon', () => {
  test('ligne « Jalon : »', async () => {
    expect(parseMilestone('# HANDOFF\nJalon : J2 plugin\n')).toBe('J2 plugin')
    expect(parseMilestone('- **Jalon** : livraison')).toBe('livraison')
    expect(parseMilestone('Jalon actuel: ' + 'y'.repeat(100))?.length).toBe(40)
  })

  test('pas de jalon', async () => {
    expect(parseMilestone('# HANDOFF\nrien ici')).toBe(undefined)
    expect(parseMilestone('Jalon :   ')).toBe(undefined)
    expect(parseMilestone(undefined)).toBe(undefined)
  })

  test('gabarit non rempli : pas de jalon', async () => {
    expect(parseMilestone('Jalon : <jalon ou étape en cours, en quelques mots> (lu par la barre d\'état)')).toBe(undefined)
    expect(parseMilestone('Jalon : <x>\nJalon : J3 tests')).toBe('J3 tests')
  })
})

describe('réglages', () => {
  test('readSection : rubrique exacte, clé insensible à la casse, commentaire entre parenthèses retiré', async () => {
    const md = '# P\n## Réglages du projet\n- seuils : 1 2 3\n## Réglages\n- Seuils : 60 75 85 (économe)\n* **barre** : projet\n### Sous\n- ton : tutoiement\n## Autre\n- seuils : 9 9 9\n'
    expect(readSection(md, 'Réglages')).toEqual({ seuils: '60 75 85', barre: 'projet', ton: 'tutoiement' })
    expect(readSection(md, 'Réglages du projet')).toEqual({ seuils: '1 2 3' })
    expect(readSection(undefined, 'Réglages')).toEqual({})
  })

  test('parseThresholds : trois entiers croissants de 10 à 99', async () => {
    expect(parseThresholds('60 75 85')).toEqual([60, 75, 85])
    expect(parseThresholds('60, 75/85')).toEqual([60, 75, 85])
    expect(parseThresholds('85 75 60')).toBeUndefined()
    expect(parseThresholds('60 75')).toBeUndefined()
    expect(parseThresholds('5 75 85')).toBeUndefined()
    expect(parseThresholds('60 75 100')).toBeUndefined()
    expect(parseThresholds('a b c')).toBeUndefined()
    expect(parseThresholds(undefined)).toBeUndefined()
  })

  test('resolveSettings : projet, puis profil, puis défauts (une valeur invalide est sautée)', async () => {
    expect(resolveSettings(undefined, undefined)).toEqual({ thresholds: [70, 80, 90], notifications: 'agent+quota' })
    const profil = '## Réglages\n- seuils : 60 75 85\n- notifications : tout\n'
    expect(resolveSettings(undefined, profil)).toEqual({ thresholds: [60, 75, 85], notifications: 'tout' })
    const projet = '## Réglages du projet\n- seuils : 40 50 60\n- notifications : bof\n'
    expect(resolveSettings(projet, profil)).toEqual({ thresholds: [40, 50, 60], notifications: 'tout' })
  })

  test('notifications : modes et effets', async () => {
    expect(parseNotifications('rien')).toBe('rien')
    expect(parseNotifications('toujours')).toBeUndefined()
    expect(wantsQuotaAlerts('rien')).toBe(false)
    expect(wantsQuotaAlerts('quota')).toBe(true)
    expect(wantsAgentDone('quota')).toBe(false)
    expect(wantsAgentDone('agent+quota')).toBe(true)
    expect(wantsAgentDone('tout')).toBe(true)
  })

  test('decideAlerts et levelOf avec des seuils réglés', async () => {
    expect(levelOf(76, [60, 75, 85])).toBe(75)
    const w = (p: number): Window[] => [{ kind: 'five_hour', percentUsed: p, resetsAt: at1830(18) }]
    const first = decideAlerts(undefined, w(62), [60, 75, 85])
    expect(first.alerts.map(a => a.threshold)).toEqual([60])
    expect(decideAlerts(first.state, w(65), [60, 75, 85]).alerts).toEqual([])
    expect(decideAlerts(first.state, w(90), [60, 75, 85]).alerts.map(a => a.threshold)).toEqual([85])
  })
})
