<script setup lang="ts">
const { theme, setTheme } = useTheme()

const opts = [
  { value: 'light', label: 'Light' },
  { value: 'auto', label: 'System' },
  { value: 'dark', label: 'Dark' },
] as const
</script>

<template>
  <ClientOnly>
    <div class="theme-switch" role="group" aria-label="Color theme">
      <button
        v-for="o in opts"
        :key="o.value"
        type="button"
        class="theme-opt"
        :class="{ on: theme === o.value }"
        :aria-pressed="theme === o.value"
        :aria-label="`${o.label} theme`"
        :title="`${o.label} theme`"
        @click="setTheme(o.value)"
      >
        <svg v-if="o.value === 'light'" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
        </svg>
        <svg v-else-if="o.value === 'auto'" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="2" y="3" width="20" height="14" rx="2" />
          <path d="M8 21h8M12 17v4" />
        </svg>
        <svg v-else viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8z" />
        </svg>
      </button>
    </div>
    <template #fallback>
      <div class="theme-switch-skel" aria-hidden="true" />
    </template>
  </ClientOnly>
</template>

<style scoped>
.theme-switch {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 3px;
  border-radius: 999px;
  border: 1px solid var(--line-strong);
  background: color-mix(in srgb, var(--card) 65%, transparent);
}
.theme-opt {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border: 0;
  background: none;
  border-radius: 999px;
  color: var(--ink-faint);
  cursor: pointer;
  transition: color 0.18s, background 0.18s;
}
.theme-opt:hover {
  color: var(--ink);
}
.theme-opt.on {
  color: var(--green-deep);
  background: color-mix(in srgb, var(--green) 16%, transparent);
}
.theme-switch-skel {
  width: 102px;
  height: 38px;
  border-radius: 999px;
  border: 1px solid var(--line);
}
</style>
