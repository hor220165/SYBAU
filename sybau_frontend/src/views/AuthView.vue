<template>
  <div class="auth-container">
    <div class="glow-bg top-left"></div>
    <div class="glow-bg bottom-right"></div>

    <div class="content-wrapper">
      <div class="logo-section">
        <h1 class="brand-name">SYBAU</h1>
        <p class="brand-slogan">Shape Your Body And Unleash</p>
      </div>

      <div class="auth-card">
        <div class="toggle-container">
          <div 
            class="toggle-bg" 
            :style="{ transform: isLogin ? 'translateX(0%)' : 'translateX(100%)' }"
          ></div>
          <button 
            class="toggle-btn" 
            :class="{ active: isLogin }" 
            @click="isLogin = true"
          >
            Login
          </button>
          <button 
            class="toggle-btn" 
            :class="{ active: !isLogin }" 
            @click="isLogin = false"
          >
            Register
          </button>
        </div>

        <transition name="fade" mode="out-in">
          <form v-if="isLogin" key="login" @submit.prevent class="auth-form">
            <div class="input-group">
              <label>Benutzername</label>
              <div class="input-wrapper">
                <span class="icon">👤</span>
                <input type="text" placeholder="Dein Username" />
              </div>
            </div>

            <div class="input-group">
              <label>Passwort</label>
              <div class="input-wrapper">
                <span class="icon">🔒</span>
                <input type="password" placeholder="........" />
                <span class="eye-icon">👁️</span>
              </div>
            </div>

            <button type="submit" class="action-btn">Login</button>
            
            <p class="footer-text">
              Noch kein Account? <a href="#" @click.prevent="isLogin = false">Jetzt registrieren</a>
            </p>
          </form>

          <form v-else key="register" @submit.prevent class="auth-form">
            <div class="input-group">
              <label>Benutzername</label>
              <div class="input-wrapper">
                <span class="icon">👤</span>
                <input type="text" placeholder="Dein Username" />
              </div>
            </div>

            <div class="input-group">
              <label>E-Mail</label>
              <div class="input-wrapper">
                <span class="icon">✉️</span>
                <input type="email" placeholder="deine@email.com" />
              </div>
            </div>

            <div class="input-group">
              <label>Passwort</label>
              <div class="input-wrapper">
                <span class="icon">🔒</span>
                <input type="password" placeholder="........" />
                <span class="eye-icon">👁️</span>
              </div>
            </div>

            <div class="input-group">
              <label>Passwort bestätigen</label>
              <div class="input-wrapper">
                <span class="icon">🔒</span>
                <input type="password" placeholder="........" />
              </div>
            </div>

            <button type="submit" class="action-btn">Account erstellen</button>

            <p class="footer-text">
              Mit deinem Account erhältst du: <br>
              <span class="small-info">Zugang zu allen Features</span>
            </p>
          </form>
        </transition>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const isLogin = ref(true);
</script>

<style>

html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  width: 100%;
  
}
:root {
  --primary-pink: #ff2d75;
  --primary-glow: rgba(255, 45, 117, 0.6);
  --text-muted: #8b9bb4;
}

* { box-sizing: border-box; }

.auth-container {
  min-height: 100vh; 
  width: 100vw;
  background-color: #050714;
  background-image: radial-gradient(circle at top left, #1a237e 0%, transparent 40%),
                    radial-gradient(circle at bottom right, #311b92 0%, transparent 40%);
  display: flex;
  justify-content: center;
  align-items: center;
  font-family: 'Inter', 'Segoe UI', sans-serif;
  color: white;
  position: relative;
  overflow: hidden;
}

.glow-bg {
  position: absolute;
  width: 400px;
  height: 400px;
  background: var(--primary-pink);
  filter: blur(1000px);
  opacity: 0.15;
  z-index: 0;
}
.top-left { top: -150px; left: -150px; }
.bottom-right { bottom: -150px; right: -150px; }

.content-wrapper {
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2rem;
  width: 100%;
  max-width: 100vw;
  padding: 20px;
}

.logo-section {
  text-align: center;
  margin-bottom: 10px;
}

.logo-icon {
  width: 70px;
  height: 70px;
  background: linear-gradient(135deg, #ff5e9a, #ff2d75);
  border-radius: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0 auto 15px;
  box-shadow: 0 0 25px var(--primary-glow);
}


.brand-name { font-size: 1.5rem; font-weight: 700; margin: 0; letter-spacing: 1.5px; }
.brand-slogan { font-size: 1rem; color: #8b9bb4; margin-top: 5px; }

.auth-card {
  background: rgba(30, 34, 55, 0.65);
  backdrop-filter: blur(25px);
  -webkit-backdrop-filter: blur(25px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 30px;
  padding: 40px;
  width: 80%;
  box-shadow: 0 25px 60px rgba(0, 0, 0, 0.4);
}

.toggle-container {
  position: relative;
  display: flex;
  background: rgba(0, 0, 0, 0.25);
  border-radius: 15px;
  padding: 5px;
  margin-bottom: 35px;
  height: 60px;
}

.toggle-bg {
  position: absolute;
  top: 5px;
  left: 5px;
  width: calc(50% - 5px);
  height: calc(100% - 10px);
  background: #ff2d75;
  border-radius: 12px;
  transition: transform 0.35s cubic-bezier(0.68, -0.55, 0.27, 1.55);
  box-shadow: 0 0 15px rgba(255, 45, 117, 0.4);
}

.toggle-btn {
  flex: 1;
  background: transparent;
  border: none;
  color: #8b9bb4;
  font-weight: 600;
  font-size: 1.1rem;
  cursor: pointer;
  z-index: 2;
  transition: color 0.3s;
}
.toggle-btn.active { color: white; }

.input-group { margin-bottom: 24px; }
.input-group label { display: block; font-size: 0.9rem; color: #a0aec0; margin-bottom: 10px; font-weight: 500; }

.input-wrapper { position: relative; display: flex; align-items: center; }
.input-wrapper input {
  width: 100%;
  background: rgba(18, 22, 40, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 14px;
  padding: 16px 50px;
  color: white;
  font-size: 1rem;
  outline: none;
  transition: all 0.3s ease;
}
.input-wrapper input:focus {
  border-color: #ff2d75;
  background: rgba(18, 22, 40, 0.9);
  box-shadow: 0 0 0 4px rgba(255, 45, 117, 0.15);
}
.input-wrapper .icon { position: absolute; left: 18px; opacity: 0.6; font-size: 1.2rem; }
.input-wrapper .eye-icon {
  position: absolute;
  right: 18px;
  cursor: pointer;
  opacity: 0.6;
  font-size: 1.2rem;
  transition: opacity 0.2s;
}
.input-wrapper .eye-icon:hover { opacity: 1; }

.action-btn {
  width: 100%;
  padding: 16px;
  background: linear-gradient(90deg, #ff2d75, #ff5e9a);
  border: none;
  border-radius: 14px;
  color: white;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  margin-top: 15px;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 5px 20px rgba(255, 45, 117, 0.3);
}
.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(255, 45, 117, 0.5);
}

.footer-text {
  text-align: center;
  margin-top: 25px;
  font-size: 0.9rem;
  color: #8b9bb4;
  line-height: 1.5;
}
.footer-text a {
  color: #ff2d75;
  text-decoration: none;
  font-weight: 600;
}
.small-info { display: block; margin-top: 5px; font-size: 0.8rem; opacity: 0.6; }

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.fade-enter-from { opacity: 0; transform: translateY(10px); }
.fade-leave-to { opacity: 0; transform: translateY(-10px); }

@media (max-width: 640px) {
  .content-wrapper { max-width: 100%; padding: 15px; }
  .auth-card { padding: 25px; }
}

/* --- Desktop Optimierungen --- */
@media (min-width: 1024px) {
  .content-wrapper { max-width: 900px; padding: 40px; }
  .auth-card { padding: 60px; }
  .brand-name { font-size: 2.5rem; }
  .brand-slogan { font-size: 1.2rem; }
  .toggle-container { height: 80px; }
  .glow-bg { width: 600px; height: 600px; }
}
</style>
