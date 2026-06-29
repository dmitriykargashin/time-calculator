// Light / dark / auto theme, persisted to localStorage (`tc-theme`) and applied
// by toggling [data-theme] + .dark on <html>. The initial paint is handled by a
// tiny inline <head> script (see nuxt.config) so there's no flash; this
// composable keeps the switcher in sync and tracks the OS preference for "auto".
export type ThemeChoice = 'light' | 'dark' | 'auto'
const KEY = 'tc-theme'

export function useTheme() {
  const theme = useState<ThemeChoice>('tc-theme', () => 'auto')
  const sysDark = useState<boolean>('tc-sys-dark', () => false)

  const resolved = computed<'light' | 'dark'>(() =>
    theme.value === 'auto' ? (sysDark.value ? 'dark' : 'light') : theme.value,
  )

  const apply = () => {
    if (!import.meta.client) return
    const el = document.documentElement
    el.dataset.theme = resolved.value
    el.classList.toggle('dark', resolved.value === 'dark')
  }

  const setTheme = (choice: ThemeChoice) => {
    theme.value = choice
    if (import.meta.client) {
      try {
        localStorage.setItem(KEY, choice)
      } catch {}
      apply()
    }
  }

  let mql: MediaQueryList | undefined
  const onSystem = (e: MediaQueryListEvent) => {
    sysDark.value = e.matches
    if (theme.value === 'auto') apply()
  }

  onMounted(() => {
    try {
      const saved = localStorage.getItem(KEY) as ThemeChoice | null
      if (saved === 'light' || saved === 'dark' || saved === 'auto') theme.value = saved
    } catch {}
    mql = window.matchMedia('(prefers-color-scheme: dark)')
    sysDark.value = mql.matches
    apply()
    mql.addEventListener('change', onSystem)
  })

  onBeforeUnmount(() => mql?.removeEventListener('change', onSystem))

  return { theme, resolved, setTheme }
}
