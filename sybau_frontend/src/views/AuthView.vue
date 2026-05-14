<template>
  <!-- Vollbild-Hintergrund -->
  <div class="auth-page">
    <!-- Back Button - Text Only -->
    <button class="back-button" @click="goToHome">
      Zurück zur Startseite
    </button>

    <!-- Zentrale Layout-Spalte -->
    <div class="auth-layout">
      <!-- Logo / Headline -->
      <header class="auth-header fade-in">
        <h1 class="brand-name">SYBAU</h1>
        <p class="brand-slogan">Shape Your Body And Unleash</p>
      </header>
      <!-- Login / Register Card -->
      <div class="auth-card fade-in delay-1">
        <!-- Toggle -->
        <div class="toggle">
          <div class="toggle-indicator" :class="{ right: !isLogin }"></div>
          <button :class="{ active: isLogin }" @click="isLogin = true">
            Login
          </button>
          <button :class="{ active: !isLogin }" @click="isLogin = false">
            Register
          </button>
        </div>
        <!-- Formular -->
        <transition name="fade" mode="out-in">
          <form
            v-if="isLogin"
            key="login"
            class="form"
            @submit.prevent="handleLogin"
          >
            <label>E-Mail</label>
            <input
              type="email"
              placeholder="example@gmail.com"
              v-model="email"
              autocomplete="email"
              required
            />
            
            <label>Passwort</label>
            <div class="password-input-wrapper">
              <input 
                :type="showPassword ? 'text' : 'password'" 
                placeholder="••••••••" 
                v-model="password" 
                autocomplete="current-password"
                required
              />
              <button 
                type="button" 
                class="toggle-password" 
                @click="showPassword = !showPassword"
                tabindex="-1"
              >
                <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                  <circle cx="12" cy="12" r="3"/>
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                  <line x1="1" y1="1" x2="23" y2="23"/>
                </svg>
              </button>
            </div>
            
            <button type="submit" class="primary-btn" :disabled="loading">
              <span v-if="loading" class="spinner"></span>
              <span v-else>Login</span>
            </button>
            <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>
            <div class="switch-text">
              <label>Noch kein Account?</label>
              <label class="switch-link" @click="isLogin = false"
                >jetzt registrieren</label
              >
            </div>
          </form>
          <form
            v-else
            key="register"
            class="form"
            @submit.prevent="handleRegister"
          >
            <label>Benutzername</label>
            <input
              placeholder="example01"
              v-model="username"
              autocomplete="username"
              required
            />
            <label>E-Mail</label>
            <input
              placeholder="example@gmail.com"
              type="email"
              v-model="email"
              autocomplete="email"
              required
            />
            
            <label>Passwort</label>
            <div class="password-input-wrapper">
              <input 
                :type="showPassword ? 'text' : 'password'" 
                placeholder="••••••••" 
                v-model="password" 
                autocomplete="new-password"
                required
              />
              <button 
                type="button" 
                class="toggle-password" 
                @click="showPassword = !showPassword"
                tabindex="-1"
              >
                <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                  <circle cx="12" cy="12" r="3"/>
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                  <line x1="1" y1="1" x2="23" y2="23"/>
                </svg>
              </button>
            </div>
            
            <button type="submit" class="primary-btn" :disabled="loading">
              <span v-if="loading" class="spinner"></span>
              <span v-else>Account erstellen</span>
            </button>
            <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>
          </form>
        </transition>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'; 
import { useRouter } from 'vue-router'; 
import { useAuth } from '@/composables/useAuth';
import { userService } from '@/services/api';

const router = useRouter(); 
const { login, googleLogin } = useAuth();

const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined;

const isLogin = ref(true); 
const email = ref(''); 
const password = ref(''); 
const username = ref(''); 
const showPassword = ref(false);
const loading = ref(false);
const errorMessage = ref('');
const googleLoginButtonRef = ref<HTMLDivElement | null>(null);
const googleRegisterButtonRef = ref<HTMLDivElement | null>(null);
let googleScriptEl: HTMLScriptElement | null = null;

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential?: string }) => void;
          }) => void;
          renderButton: (
            parent: HTMLElement,
            options: {
              type?: 'standard' | 'icon';
              theme?: 'outline' | 'filled_blue' | 'filled_black';
              size?: 'large' | 'medium' | 'small';
              text?: 'signin_with' | 'signup_with' | 'continue_with' | 'signin';
              shape?: 'pill' | 'rectangular' | 'circle' | 'square';
              logo_alignment?: 'left' | 'center';
              width?: number;
            },
          ) => void;
        };
      };
    };
  }
}

const parseError = (err: any, fallback: string): string => {
  const data = err.response?.data;
  if (!data) return fallback;
  if (data.message) return data.message;
  if (data.errors) {
    const msgs = Object.values(data.errors).flat() as string[];
    return msgs.join(' ') || fallback;
  }
  if (typeof data === 'string') return data;
  return fallback;
};

const goToHome = () => {
  router.push('/');
};

const renderGoogleButtons = async () => {
  await nextTick();
  if (!window.google?.accounts.id || !googleClientId) return;

  const renderConfig = {
    theme: 'outline' as const,
    size: 'medium' as const,
    text: 'signin_with' as const,
    shape: 'pill' as const,
    logo_alignment: 'left' as const,
    width: 460,
  };

  if (googleLoginButtonRef.value) {
    googleLoginButtonRef.value.innerHTML = '';
    window.google.accounts.id.renderButton(googleLoginButtonRef.value, renderConfig);
  }

  if (googleRegisterButtonRef.value) {
    googleRegisterButtonRef.value.innerHTML = '';
    window.google.accounts.id.renderButton(googleRegisterButtonRef.value, renderConfig);
  }
};

const handleLogin = async () => {
  loading.value = true;
  errorMessage.value = '';
  try { 
    const res = await login(email.value, password.value); 
    const token = res.data?.token; 
    if (token) {
      await userService.getProfile();
      router.push('/dashboard');
    } else {
      errorMessage.value = 'Kein Token erhalten — Login fehlgeschlagen.';
    }
  } catch (err: any) { 
    errorMessage.value = parseError(err, 'Ungültige E-Mail oder Passwort.');
  } finally {
    loading.value = false;
  }
};

const handleRegister = async () => {
  loading.value = true;
  errorMessage.value = '';
  try { 
    const { register } = useAuth();
    await register(username.value, email.value, password.value); 
    await login(email.value, password.value); 
    await userService.getProfile();
    router.push('/dashboard');
  } catch (err: any) { 
    errorMessage.value = parseError(err, 'Registrierung fehlgeschlagen.');
  } finally {
    loading.value = false;
  }
}; 

const handleGoogleCredential = async (response: { credential?: string }) => {
  if (!response.credential) {
    errorMessage.value = 'Google Login fehlgeschlagen.';
    return;
  }

  loading.value = true;
  errorMessage.value = '';
  try {
    const res = await googleLogin(response.credential);
    const token = res.data?.token;
    if (token) {
      await userService.getProfile();
      router.push('/dashboard');
    } else {
      errorMessage.value = 'Kein Token erhalten — Google Login fehlgeschlagen.';
    }
  } catch (err: any) {
    errorMessage.value = parseError(err, 'Google Login fehlgeschlagen.');
  } finally {
    loading.value = false;
  }
};

const ensureGoogleScript = async () => {
  if (!googleClientId) {
    return;
  }

  if (window.google?.accounts.id) {
    window.google.accounts.id.initialize({
      client_id: googleClientId,
      callback: handleGoogleCredential,
    });
    await renderGoogleButtons();
    return;
  }

  await new Promise<void>((resolve, reject) => {
    googleScriptEl = document.createElement('script');
    googleScriptEl.src = 'https://accounts.google.com/gsi/client';
    googleScriptEl.async = true;
    googleScriptEl.defer = true;
    googleScriptEl.onload = () => resolve();
    googleScriptEl.onerror = () => reject(new Error('Google script failed'));
    document.head.appendChild(googleScriptEl);
  });

  window.google?.accounts.id.initialize({
    client_id: googleClientId,
    callback: handleGoogleCredential,
  });
  await renderGoogleButtons();
};

onMounted(() => {
  void ensureGoogleScript();
});

watch(isLogin, () => {
  void renderGoogleButtons();
});

onBeforeUnmount(() => {
  if (googleScriptEl?.parentNode) {
    googleScriptEl.parentNode.removeChild(googleScriptEl);
  }
});
</script>

<style>
/* === Reset === */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html {
  height: 100%;
  overflow-x: hidden;
}

body {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: system-ui, sans-serif;
  background: #050714;
  background:
    radial-gradient(circle at top left, #1a237e, transparent 45%),
    radial-gradient(circle at bottom right, #311b92, transparent 45%), #050714;
  background-attachment: fixed;
}

/* === Fade-in Animations === */
.fade-in {
  opacity: 0;
  transform: translateY(20px);
  animation: fadeInUp 0.8s ease forwards;
}

.fade-in.delay-1 {
  animation-delay: 0.2s;
}

@keyframes fadeInUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* === Back Button - Text Only === */
.back-button {
  position: fixed;
  top: 32px;
  left: 32px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.3s ease;
  z-index: 100;
  padding: 0;
}

.back-button:hover {
  color: #ff2d75;
  transform: translateX(-4px);
}

/* === Vollbild-Container === */
.auth-page {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow-y: auto;
  padding: 88px 0 32px;
}

/* === Zentrale Spalte === */
.auth-layout {
  width: 100%;
  max-width: 600px;
  padding: 24px;
}

/* === Header === */
.auth-header {
  text-align: center;
  margin-bottom: 32px;
}

.brand-name {
  font-size: 2.2rem;
  margin: 0;
  color: white;
}

.brand-slogan {
  color: #8b9bb4;
  margin-top: 8px;
}

/* === Card === */
.auth-card {
  background: rgba(30, 34, 55, 0.7);
  backdrop-filter: blur(20px);
  border-radius: 24px;
  width: 600px;
  max-width: 100%;
  padding: 30px;
  box-shadow: 0 25px 60px rgba(0, 0, 0, 0.5);
}

/* === Toggle === */
.toggle {
  position: relative;
  display: flex;
  background: rgba(0, 0, 0, 0.3);
  border-radius: 14px;
  margin-bottom: 24px;
}

.toggle button {
  flex: 1;
  padding: 14px;
  background: none;
  border: none;
  color: #8b9bb4;
  font-weight: 600;
  cursor: pointer;
  z-index: 1;
  transition: all 0.3s ease;
}

.toggle button.active {
  color: white;
}

.toggle-indicator {
  position: absolute;
  width: 50%;
  height: 100%;
  background: #ff2d75;
  border-radius: 14px;
  transition: transform 0.3s ease;
}

.toggle-indicator.right {
  transform: translateX(100%);
}

/* === Formular === */
.form {
  display: flex;
  flex-direction: column;
}

.form label {
  margin-top: 16px;
  color: #a0aec0;
  font-size: 0.9rem;
}

.form input {
  margin-top: 6px;
  padding: 14px;
  border-radius: 12px;
  border: none;
  background: rgba(18, 22, 40, 0.7);
  color: white;
  transition: all 0.3s ease;
}

.form input:focus {
  outline: none;
  background: rgba(18, 22, 40, 0.9);
  box-shadow: 0 0 0 2px rgba(255, 45, 117, 0.3);
}

.form input::placeholder {
  color: #6b7280;
}

/* === Password Input Wrapper === */
.password-input-wrapper {
  position: relative;
  margin-top: 6px;
}

.password-input-wrapper input {
  width: 100%;
  padding-right: 45px;
  margin-top: 0;
}

.toggle-password {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.5);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.toggle-password:hover {
  color: #ff2d75;
}

.toggle-password svg {
  width: 20px;
  height: 20px;
}

/* === Button === */
.primary-btn {
  margin-top: 24px;
  padding: 14px;
  border-radius: 14px;
  border: none;
  background: linear-gradient(90deg, #ff2d75, #ff5e9a);
  color: white;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.primary-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(255, 45, 117, 0.3);
}

.primary-btn:active {
  transform: translateY(0);
}

.primary-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

.auth-divider {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 18px;
}

.auth-divider span {
  flex: 1;
  height: 1px;
  background: rgba(255, 255, 255, 0.12);
}

.auth-divider p {
  color: #8b9bb4;
  font-size: 0.9rem;
  font-weight: 600;
}

.google-btn {
  margin-top: 18px;
  height: 52px;
  border-radius: 999px;
  border: 2px solid #8a8a8a;
  background: #ffffff;
  color: #202124;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.google-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.18);
}

.google-mark {
  color: #4285f4;
  font-size: 2rem;
  font-weight: 800;
  line-height: 1;
}

.google-btn-host {
  margin-top: 18px;
  display: flex;
  justify-content: center;
}

.google-btn-host > div {
  width: 100%;
}

/* Make the GIS button thinner */
.google-btn-host iframe {
  height: 40px !important;
}

.google-btn-host > div > div {
  max-height: 40px;
}

/* === Spinner === */
.spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 2.5px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  vertical-align: middle;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* === Form Animation === */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* === Switch Text === */
.switch-text {
  text-align: center;
  margin-top: 16px;
}

/* === Fehlermeldung === */
.error-msg {
  margin-top: 14px;
  padding: 12px 16px;
  background: rgba(255, 45, 75, 0.12);
  border: 1px solid rgba(255, 45, 75, 0.3);
  border-radius: 12px;
  color: #ff6b8a;
  font-size: 0.9rem;
  text-align: center;
}

.switch-text label {
  display: inline;
  color: #8b9bb4;
  font-size: 0.9rem;
}

.switch-link {
  color: #ff2d75;
  cursor: pointer;
  font-weight: 600;
  margin-left: 4px;
  transition: all 0.3s ease;
}

.switch-link:hover {
  color: #ff5e9a;
  text-decoration: underline;
}

/* === Responsive === */
@media (max-width: 768px) {
  .back-button {
    top: 20px;
    left: 20px;
    font-size: 14px;
  }

  .auth-page {
    align-items: flex-start;
    padding: 72px 0 24px;
  }

  .auth-layout {
    padding: 16px;
  }

  .auth-header {
    margin-bottom: 20px;
  }

  .auth-card {
    border-radius: 18px;
    padding: 20px;
  }

  .brand-name {
    font-size: 1.8rem;
  }
}
</style>
