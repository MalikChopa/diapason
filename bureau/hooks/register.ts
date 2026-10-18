// maitre-agent-bureau : ce que la barre d'état du terminal ne peut pas afficher
// dans l'onglet Code de l'app Claude de bureau.
//   1. ligne d'état (quota, agents en cours, jalon),
//   2. alertes de quota à 70, 80 et 90 %,
//   3. toast à la fin d'un sous-agent ma-*.
// Rien ne sort de la machine : tout passe par `$` (affichage, session, fichier local, store du mod).
import type { EngineInterface, Register } from 'claude-code'

import {
  agentDoneText,
  alertText,
  decideAlerts,
  formatStatus,
  isMaAgent,
  parseMilestone,
  projectName,
  windowLabel,
} from './lib'
import type { AlertState, Window } from './lib'

type Api = EngineInterface

/** Clé du store : seuils déjà signalés, par fenêtre. */
const ALERTS_KEY = 'quota-alerts'

/** Statuts d'un agent qui compte comme « en cours ». */
const ACTIVE = new Set(['pending', 'running', 'waiting'])

/** Type de chaque sous-agent lancé, gardé au `agent.spawn` (repli de `$.agent.list()`). */
const spawnedTypes = new Map<string, string>()

type RefreshOptions = {
  /** Fenêtres de quota déjà connues (sinon on les demande à `$.session.usage()`). */
  rateLimits?: readonly Window[]
  /** Un agent à compter même si la liste ne le montre pas encore. */
  includeAgent?: string
  /** Un agent à ne plus compter (il vient de finir). */
  excludeAgent?: string
}

/** Recompose la ligne d'état. Ne lève jamais : un échec laisse l'ancienne ligne. */
async function refresh($: Api, options: RefreshOptions = {}): Promise<void> {
  try {
    let cwd: string | undefined
    try {
      cwd = await $.session.cwd()
    } catch {
      cwd = undefined
    }

    let rateLimits = options.rateLimits
    if (rateLimits === undefined) {
      try {
        rateLimits = (await $.session.usage()).rateLimits
      } catch {
        rateLimits = []
      }
    }

    const active = new Set<string>()
    try {
      for (const a of await $.agent.list()) if (ACTIVE.has(a.status)) active.add(a.id)
    } catch {
      // liste indisponible : on compte seulement ce qu'on sait
    }
    if (options.includeAgent) active.add(options.includeAgent)
    if (options.excludeAgent) active.delete(options.excludeAgent)

    let milestone: string | undefined
    try {
      milestone = parseMilestone(await $.fs.read('docs/HANDOFF.md'))
    } catch {
      milestone = undefined // pas de HANDOFF dans ce dossier : pas de jalon
    }

    $.ui.status(formatStatus({ project: projectName(cwd), agents: active.size, rateLimits, milestone }))
  } catch {
    // jamais bloquant
  }
}

/** Toast, et notification système si le canal existe. Ne lève jamais. */
async function say($: Api, text: string, title: string): Promise<void> {
  try {
    $.ui.toast(text)
  } catch {
    // rien
  }
  try {
    await $.ui.notify(text, { title })
  } catch {
    // canal absent (appel impossible) ou écriture refusée : le toast a déjà prévenu
  }
}

/** Alertes de quota : une fois par seuil et par fenêtre, état gardé dans le store du mod. */
async function checkQuota($: Api, windows: readonly Window[]): Promise<void> {
  try {
    if (windows.length === 0) return
    const stored = (await $.store.get(ALERTS_KEY)) as AlertState | undefined
    const { alerts, state } = decideAlerts(stored && typeof stored === 'object' ? stored : undefined, windows)
    if (JSON.stringify(state) !== JSON.stringify(stored ?? {})) await $.store.set(ALERTS_KEY, state)
    for (const a of alerts) await say($, alertText(a), `Quota ${windowLabel(a.kind)}`)
  } catch {
    // jamais bloquant
  }
}

export const register: Register = on => {
  // Au lancement de la session et à chaque tour : (re)pose la ligne d'état.
  // `turn.start` couvre aussi un rechargement à chaud du mod (pas de `session.start` alors).
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  on('turn.start', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId === undefined) await refresh($)
    return result
  })

  // Le quota a bougé d'un point : ligne d'état et alertes.
  on('session.measure', async ($, e, next) => {
    const result = await next(e)
    await refresh($, { rateLimits: e.rateLimits })
    await checkQuota($, e.rateLimits)
    return result
  })

  // Un sous-agent démarre : on retient son type et on recompte.
  on('agent.spawn', async ($, e, next) => {
    const result = await next(e)
    // Ce gestionnaire conditionne le lancement d'un sous-agent : jamais d'exception ici.
    try {
      const id = result?.agentId
      if (id !== undefined) {
        if (typeof e.subagentType === 'string') spawnedTypes.set(id, e.subagentType)
        await refresh($, { includeAgent: id })
      }
    } catch {
      // jamais bloquant : le compteur sera corrigé au prochain rafraîchissement
    }
    return result
  }).catch(($, e, next) => {
    // Filet du moteur (forme documentée : `.catch` sur l'enregistrement) : si le gestionnaire lève quand même,
    // le lancement du sous-agent continue sans nous.
    return next(e)
  })

  // Fin d'un tour de sous-agent (pas d'événement « agent.end » dans l'API) : toast pour les ma-*.
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    const id = e.agentId
    if (id === undefined) return result // tour du fil principal
    try {
      let type: string | undefined
      try {
        type = (await $.agent.list()).find(a => a.id === id)?.type
      } catch {
        type = undefined
      }
      type = type ?? spawnedTypes.get(id)
      if (isMaAgent(type)) {
        await say($, agentDoneText(type as string, e.answer, e.reason), 'Agent terminé')
      }
    } catch {
      // jamais bloquant
    }
    await refresh($, { excludeAgent: id })
    return result
  })
}
