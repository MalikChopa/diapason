// Fonctions pures du mod maitre-agent-bureau : aucune dépendance à `$`,
// pour pouvoir les tester sans moteur.

/** Une fenêtre de quota, comme `session.measure` la donne. */
export type Window = { kind: string; percentUsed: number; resetsAt?: string }

/** Seuils d'alerte, en pourcentage de la fenêtre. */
export const THRESHOLDS = [70, 80, 90] as const

/** État gardé par fenêtre : la fenêtre (resetsAt) et le plus haut seuil déjà signalé. */
export type AlertState = Record<string, { resetsAt?: string; level: number }>

export type Alert = { kind: string; threshold: number; percent: number; resetsAt?: string }

/** Deux dates de reset à moins de 30 min d'écart = la même fenêtre. */
const SAME_WINDOW_MS = 30 * 60 * 1000

/** Nom court d'une fenêtre pour l'affichage. */
export function windowLabel(kind: string): string {
  if (kind === 'five_hour') return '5 h'
  if (kind === 'seven_day') return '7 j'
  if (kind === 'spend_limit') return 'budget'
  return kind
}

/** Dernier élément du chemin, séparateurs / ou \ ; vide si rien. */
export function projectName(cwd: string | undefined): string {
  if (!cwd) return ''
  const parts = cwd.split(/[\\/]+/).filter(p => p.length > 0)
  return parts.length > 0 ? (parts[parts.length - 1] as string) : ''
}

/** HH:MM en heure locale, ou undefined si la date est absente ou invalide. */
export function formatReset(iso: string | undefined): string | undefined {
  if (!iso) return undefined
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return undefined
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  return `${hh}:${mm}`
}

/** Pourcentage arrondi à l'entier, ou undefined s'il n'est pas un nombre. */
function pct(w: Window | undefined): number | undefined {
  if (!w || typeof w.percentUsed !== 'number' || Number.isNaN(w.percentUsed)) return undefined
  return Math.round(w.percentUsed)
}

/** Morceau de la ligne pour la fenêtre de 5 h. */
function fiveHourPart(w: Window | undefined): string {
  const p = pct(w)
  if (p === undefined) return '5 h ?'
  const reset = formatReset(w?.resetsAt)
  return reset ? `5 h ${p} % (reset ${reset})` : `5 h ${p} %`
}

function sevenDayPart(w: Window | undefined): string {
  const p = pct(w)
  return p === undefined ? '7 j ?' : `7 j ${p} %`
}

export type StatusInput = {
  project: string
  agents: number
  rateLimits: readonly Window[] | undefined
  milestone?: string
}

/**
 * La ligne d'état : `🧭 <projet> · [jalon · ]<n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %`.
 * Sans aucun quota : `... · quota ?`.
 */
export function formatStatus(input: StatusInput): string {
  const five = input.rateLimits?.find(w => w.kind === 'five_hour')
  const seven = input.rateLimits?.find(w => w.kind === 'seven_day')
  const parts: string[] = ['🧭 ' + (input.project || 'session')]
  if (input.milestone) parts.push(input.milestone)
  parts.push(input.agents === 1 ? '1 agent' : `${input.agents} agents`)
  if (pct(five) === undefined && pct(seven) === undefined) {
    parts.push('quota ?')
  } else {
    parts.push(fiveHourPart(five), sevenDayPart(seven))
  }
  return parts.join(' · ')
}

/** Plus haut seuil atteint par ce pourcentage, 0 s'il est sous le premier. */
export function levelOf(percent: number): number {
  let level = 0
  for (const t of THRESHOLDS) if (percent >= t) level = t
  return level
}

/**
 * Décide des alertes : au plus une par fenêtre (le plus haut seuil franchi),
 * jamais deux fois le même seuil dans la même fenêtre. Renvoie les alertes et
 * le nouvel état à garder. Une nouvelle fenêtre (reset différent de plus de
 * 30 min, ou pourcentage retombé sous le seuil déjà signalé) repart de zéro.
 */
export function decideAlerts(
  prev: AlertState | undefined,
  windows: readonly Window[],
): { alerts: Alert[]; state: AlertState } {
  const state: AlertState = { ...(prev ?? {}) }
  const alerts: Alert[] = []
  for (const w of windows) {
    if (typeof w.percentUsed !== 'number' || Number.isNaN(w.percentUsed)) continue
    // Même valeur que celle affichée (69,6 s'affiche « 70 % » : le seuil de 70 % est franchi).
    const rounded = Math.round(w.percentUsed)
    const old = state[w.kind]
    let known = old?.level ?? 0
    if (old) {
      const a = old.resetsAt ? Date.parse(old.resetsAt) : NaN
      const b = w.resetsAt ? Date.parse(w.resetsAt) : NaN
      const isOtherWindow = !Number.isNaN(a) && !Number.isNaN(b) && Math.abs(a - b) > SAME_WINDOW_MS
      if (isOtherWindow || rounded < known) known = 0
    }
    const level = levelOf(rounded)
    if (level > known) {
      alerts.push({ kind: w.kind, threshold: level, percent: w.percentUsed, resetsAt: w.resetsAt })
      known = level
    }
    const entry: { resetsAt?: string; level: number } = { level: known }
    if (w.resetsAt !== undefined) entry.resetsAt = w.resetsAt
    state[w.kind] = entry
  }
  return { alerts, state }
}

/** Texte d'une alerte de quota. */
export function alertText(a: Alert): string {
  const reset = formatReset(a.resetsAt)
  const base = `Quota ${windowLabel(a.kind)} : ${a.threshold} % atteint (${Math.round(a.percent)} %)`
  return reset ? `${base}, reset ${reset}` : base
}

/** Vrai si le type d'agent est un agent maître : `ma-*` ou `maitre-agent:ma-*`. */
export function isMaAgent(type: string | undefined): boolean {
  return !!type && /^(maitre-agent:)?ma-/.test(type)
}

/** Nom court d'un type d'agent : sans préfixe de plugin. */
export function shortAgentName(type: string): string {
  const i = type.lastIndexOf(':')
  return i >= 0 ? type.slice(i + 1) : type
}

/** Coupe à `max` caractères (points de code), avec une ellipse si coupé. */
export function truncate(text: string, max: number): string {
  const chars = Array.from(text)
  if (chars.length <= max) return text
  return chars.slice(0, Math.max(0, max - 1)).join('').trimEnd() + '…'
}

/** Première ligne utile d'un rapport : sans titre markdown, gras, code ni puce. */
export function firstLine(answer: string | undefined): string {
  for (const raw of (answer ?? '').split(/\r?\n/)) {
    const line = raw
      .replace(/^\s*(#{1,6}|[-*>]+|\d+[.)])\s+/, '')
      .replace(/[*_`]+/g, '')
      .trim()
    if (line.length > 0) return line
  }
  return ''
}

/** Texte du toast de fin d'agent, 80 caractères au plus au total. */
export function agentDoneText(type: string, answer: string | undefined, reason?: string): string {
  const name = shortAgentName(type)
  let line = firstLine(answer)
  if (line === '') line = reason === 'aborted' ? 'interrompu' : reason === 'error' ? 'erreur' : 'terminé (rapport vide)'
  return truncate(`${name} : ${line}`, 80)
}

/** Jalon d'un HANDOFF.md : la ligne « Jalon : ... » (puce et gras tolérés), 40 caractères au plus. */
export function parseMilestone(handoff: string | undefined): string | undefined {
  if (!handoff) return undefined
  for (const raw of handoff.split(/\r?\n/)) {
    const m = /^\s*(?:[-*]\s+)?(?:\*\*)?Jalon(?: actuel)?(?:\*\*)?\s*:(?:\*\*)?\s*(.+?)\s*$/i.exec(raw)
    if (m && m[1]) {
      const v = m[1].replace(/[*_`]+/g, '').trim()
      // un gabarit non rempli (« <jalon …> ») n'est pas un jalon
      if (v.length > 0 && !v.startsWith('<')) return truncate(v, 40)
    }
  }
  return undefined
}
