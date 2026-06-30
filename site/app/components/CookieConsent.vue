<script setup lang="ts">
const { open, read, choose, applyStored, hasChoice } = useConsent()
const trackEvent = useTrack()

const show = ref(false)
const details = ref(false)
const analytics = ref(true)

onMounted(() => {
  // Re-grant consent for returning visitors, then decide whether to prompt.
  applyStored()
  const stored = read()
  if (stored) analytics.value = stored.analytics
  show.value = !hasChoice()
})

// Footer "Cookie settings" can re-open the banner.
watch(open, (v) => {
  if (v) {
    const stored = read()
    if (stored) analytics.value = stored.analytics
    details.value = true
    show.value = true
  }
})

const acceptAll = () => {
  choose(true)
  trackEvent('consent', { choice: 'accept' })
  show.value = false
}
const rejectAll = () => {
  choose(false)
  trackEvent('consent', { choice: 'reject' })
  show.value = false
}
const savePrefs = () => {
  choose(analytics.value)
  trackEvent('consent', { choice: 'save', analytics: analytics.value })
  show.value = false
}
</script>

<template>
  <Teleport to="body">
    <Transition name="consent">
      <div
        v-if="show"
        class="consent"
        role="dialog"
        aria-labelledby="consent-title"
        aria-describedby="consent-desc"
      >
        <div class="consent-card">
          <div class="consent-row">
            <span class="consent-icon" aria-hidden="true">
              <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                <path d="M9 12l2 2 4-4" />
              </svg>
            </span>
            <div class="consent-text">
              <h3 id="consent-title">A quick word on cookies</h3>
              <p id="consent-desc">
                Your calculations stay in your browser. We'd like to count anonymous
                visits with Google Analytics to see what's useful.
                <button type="button" class="consent-more" @click="details = !details">
                  {{ details ? 'Show less' : 'Learn more' }}
                </button>
              </p>

              <Transition name="consent-expand">
                <div v-if="details" class="consent-detail">
                  <div class="consent-pref">
                    <div class="consent-pref-head">
                      <span class="consent-pref-name">Essential</span>
                      <span class="consent-tag">Always on</span>
                    </div>
                    <p>Remembers this choice and your theme. No tracking, can't be turned off.</p>
                  </div>
                  <div class="consent-pref">
                    <label class="consent-pref-head consent-toggle">
                      <span class="consent-pref-name">Analytics</span>
                      <input v-model="analytics" type="checkbox" class="consent-switch" />
                    </label>
                    <p>Anonymous page-visit counts via Google Analytics. No personal data.</p>
                  </div>
                </div>
              </Transition>
            </div>
          </div>

          <div class="consent-actions">
            <button type="button" class="btn btn-ghost consent-btn" @click="rejectAll">Reject</button>
            <button v-if="details" type="button" class="consent-save" @click="savePrefs">
              Save choices
            </button>
            <button type="button" class="btn btn-green consent-btn" @click="acceptAll">Accept</button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.consent {
  position: fixed;
  inset-inline: 0;
  bottom: 0;
  z-index: 80;
  display: flex;
  justify-content: center;
  padding: clamp(0.7rem, 2vw, 1.2rem);
  padding-bottom: max(clamp(0.7rem, 2vw, 1.2rem), env(safe-area-inset-bottom));
  pointer-events: none;
}
.consent-card {
  pointer-events: auto;
  width: min(100%, 680px);
  background: var(--card);
  border: 1px solid var(--card-edge);
  border-radius: var(--radius);
  box-shadow: var(--shadow-card), 0 -8px 40px -18px rgba(28, 27, 21, 0.28);
  padding: clamp(1.1rem, 2.4vw, 1.5rem);
}
.consent-row {
  display: flex;
  gap: 0.95rem;
  align-items: flex-start;
}
.consent-icon {
  flex: none;
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border-radius: 12px;
  color: var(--on-green);
  background: linear-gradient(150deg, var(--green-bright), var(--green-deep));
  box-shadow: 0 10px 22px -12px rgba(31, 108, 16, 0.8);
}
.consent-text {
  min-width: 0;
}
.consent-text h3 {
  font-size: 1.05rem;
  margin: 0 0 0.25rem;
}
.consent-text p {
  margin: 0;
  font-size: 0.9rem;
  line-height: 1.55;
  color: var(--ink-soft);
  max-width: none;
}
.consent-more {
  border: 0;
  background: none;
  padding: 0;
  margin-left: 0.3rem;
  font: inherit;
  font-weight: 600;
  color: var(--green-deep);
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
}
.consent-more:hover {
  color: var(--green);
}

.consent-detail {
  display: grid;
  gap: 0.6rem;
  margin-top: 0.85rem;
  overflow: hidden;
}
.consent-pref {
  background: color-mix(in srgb, var(--paper-deep) 70%, transparent);
  border: 1px solid var(--line);
  border-radius: var(--radius-sm);
  padding: 0.7rem 0.85rem;
}
.consent-pref p {
  margin: 0.3rem 0 0;
  font-size: 0.8rem;
  color: var(--ink-faint);
}
.consent-pref-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.6rem;
}
.consent-pref-name {
  font-weight: 600;
  font-size: 0.92rem;
  color: var(--ink);
}
.consent-tag {
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--olive);
  background: color-mix(in srgb, var(--olive) 14%, transparent);
  padding: 0.18em 0.55em;
  border-radius: 999px;
}
.consent-toggle {
  cursor: pointer;
}
/* a small CSS switch built on a checkbox */
.consent-switch {
  appearance: none;
  -webkit-appearance: none;
  position: relative;
  width: 38px;
  height: 22px;
  border-radius: 999px;
  background: var(--line-strong);
  cursor: pointer;
  transition: background 0.2s ease;
  flex: none;
}
.consent-switch::after {
  content: "";
  position: absolute;
  top: 2px;
  left: 2px;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--card);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
  transition: transform 0.2s var(--ease-pop);
}
.consent-switch:checked {
  background: var(--green);
}
.consent-switch:checked::after {
  transform: translateX(16px);
}

.consent-actions {
  display: flex;
  gap: 0.6rem;
  align-items: center;
  justify-content: flex-end;
  margin-top: 1.05rem;
  flex-wrap: wrap;
}
.consent-btn {
  padding: 0.62em 1.3em;
  font-size: 0.9rem;
}
.consent-save {
  border: 0;
  background: none;
  font: inherit;
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--ink-soft);
  cursor: pointer;
  margin-right: auto;
  text-decoration: underline;
  text-underline-offset: 3px;
}
.consent-save:hover {
  color: var(--ink);
}

/* enter/leave: slide up + fade */
.consent-enter-active,
.consent-leave-active {
  transition: transform 0.36s var(--ease-pop), opacity 0.36s ease;
}
.consent-enter-from,
.consent-leave-to {
  transform: translateY(120%);
  opacity: 0;
}
.consent-expand-enter-active,
.consent-expand-leave-active {
  transition: grid-template-rows 0.3s ease, opacity 0.3s ease, margin-top 0.3s ease;
}

@media (max-width: 540px) {
  .consent-actions {
    justify-content: stretch;
  }
  .consent-btn {
    flex: 1;
    justify-content: center;
  }
  .consent-save {
    width: 100%;
    text-align: center;
    margin: 0.2rem 0;
  }
}
</style>
