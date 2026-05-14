<template>
  <Transition name="cookie-consent">
    <section v-if="visible" class="cookie-consent" aria-label="Cookie Hinweis">
      <div class="cookie-copy">
        <ShieldCheck class="cookie-icon" aria-hidden="true" />
        <div>
          <p class="cookie-title">Cookies & Datenschutz</p>
          <p class="cookie-text">
            Wir nutzen notwendige Speicherung für Login und Sicherheit. Optionale Cookies
            werden nur verwendet, wenn du zustimmst.
          </p>
        </div>
      </div>
      <div class="cookie-actions">
        <button class="cookie-button ghost" type="button" @click="saveConsent('declined')">
          Ablehnen
        </button>
        <button class="cookie-button primary" type="button" @click="saveConsent('accepted')">
          Zustimmen
        </button>
      </div>
    </section>
  </Transition>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { ShieldCheck } from 'lucide-vue-next';

const storageKey = 'sybau_cookie_consent_v1';
const visible = ref(false);

type ConsentChoice = 'accepted' | 'declined';

onMounted(() => {
  visible.value = localStorage.getItem(storageKey) == null;
});

function saveConsent(choice: ConsentChoice) {
  localStorage.setItem(storageKey, choice);
  visible.value = false;
}
</script>

<style scoped>
.cookie-consent {
  position: fixed;
  left: 50%;
  bottom: 18px;
  z-index: 1000;
  display: flex;
  width: min(720px, calc(100vw - 28px));
  transform: translateX(-50%);
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 14px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  background: rgba(5, 8, 18, 0.94);
  box-shadow: 0 22px 55px rgba(0, 0, 0, 0.38);
  color: #fff;
  backdrop-filter: blur(18px);
}

.cookie-copy {
  display: flex;
  min-width: 0;
  align-items: flex-start;
  gap: 12px;
}

.cookie-icon {
  flex: 0 0 auto;
  width: 22px;
  height: 22px;
  color: #7dd3fc;
}

.cookie-title {
  margin: 0 0 4px;
  font-size: 14px;
  font-weight: 800;
}

.cookie-text {
  margin: 0;
  color: rgba(255, 255, 255, 0.72);
  font-size: 13px;
  line-height: 1.42;
}

.cookie-actions {
  display: flex;
  flex: 0 0 auto;
  gap: 8px;
}

.cookie-button {
  min-height: 38px;
  border: 0;
  border-radius: 10px;
  padding: 0 14px;
  font-weight: 800;
  cursor: pointer;
}

.cookie-button.ghost {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.82);
}

.cookie-button.primary {
  background: #ec4899;
  color: #fff;
}

.cookie-consent-enter-active,
.cookie-consent-leave-active {
  transition: opacity 180ms ease, transform 180ms ease;
}

.cookie-consent-enter-from,
.cookie-consent-leave-to {
  opacity: 0;
  transform: translate(-50%, 12px);
}

@media (max-width: 640px) {
  .cookie-consent {
    align-items: stretch;
    flex-direction: column;
    gap: 12px;
    padding: 13px;
  }

  .cookie-actions {
    display: grid;
    grid-template-columns: 1fr 1fr;
  }
}
</style>
