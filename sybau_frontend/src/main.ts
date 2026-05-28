import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import { router } from './router/router.ts'
import { initializeTheme } from './composables/useTheme'

initializeTheme();
const app = createApp(App);

// v-click-outside Directive
app.directive('click-outside', {
  mounted(el, binding) {
    el._clickOutside = (e: MouseEvent) => {
      if (!el.contains(e.target as Node)) binding.value();
    };
    document.addEventListener('click', el._clickOutside);
  },
  unmounted(el) {
    document.removeEventListener('click', el._clickOutside);
  }
});

app.use(router).mount('#app');
