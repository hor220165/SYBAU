<template>
  <footer class="landing-footer">
    <div class="container">
      <div class="footer-content">
        <div class="footer-left">
          <h3 class="footer-brand">SYBAU</h3>
          <p class="footer-tagline">Shape Your Body And Unleash</p>
        </div>
        <div class="footer-right">
          <p class="footer-copyright">&copy; 2026 SYBAU. Alle Rechte vorbehalten.</p>
          <button class="footer-link" @click="navigateTo('/impressum')">Impressum</button>
          <button class="footer-link" @click="navigateTo('/datenschutz')">Datenschutz</button>
        </div>
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { nextTick } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const scrollToTop = () => {
  window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
  document.documentElement.scrollTop = 0;
  document.body.scrollTop = 0;
};

const navigateTo = async (path: string) => {
  await router.push(path);
  await nextTick();
  scrollToTop();
  window.requestAnimationFrame(scrollToTop);
};
</script>

<style scoped>
.landing-footer {
  padding: 32px 0;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin-top: 80px;
}

.container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 32px;
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.footer-brand {
  font-size: 20px;
  font-weight: 800;
  color: white;
  margin: 0;
  letter-spacing: 0.5px;
}

.footer-tagline {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 24px;
}

.footer-copyright {
  color: rgba(255, 255, 255, 0.5);
  font-size: 13px;
  margin: 0;
}

.footer-link {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s ease;
  padding: 0;
  text-decoration: underline;
}

.footer-link:hover {
  color: #ec4899;
}

/* Responsive */
@media (max-width: 768px) {
  .landing-footer {
    padding: 24px 0;
  }

  .footer-content {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }

  .footer-left {
    align-items: center;
  }

  .footer-right {
    flex-direction: column;
    gap: 8px;
  }
}
</style>
