<template>
  <!-- Vollbild-Hintergrund -->
  <div class="auth-page">

    <!-- Zentrale Layout-Spalte -->
    <div class="auth-layout">

      <!-- Logo / Headline -->
      <header class="auth-header">
        <h1 class="brand-name">SYBAU</h1>
        <p class="brand-slogan">Shape Your Body And Unleash</p>
      </header>

      <!-- Login / Register Card -->
      <div class="auth-card">

        <!-- Toggle -->
        <div class="toggle">
          <div
            class="toggle-indicator"
            :class="{ right: !isLogin }"
          ></div>

          <button
            :class="{ active: isLogin }"
            @click="isLogin = true"
          >
            Login
          </button>

          <button
            :class="{ active: !isLogin }"
            @click="isLogin = false"
          >
            Register
          </button>
        </div>

        <!-- Formular -->
        <transition name="fade" mode="out-in">
          <form v-if="isLogin" key="login" class="form">
            <label>E-Mail</label>
            <input type="email" placeholder="Deine Email" />

            <label>Passwort</label>
            <input type="password" placeholder="••••••••" />

            <button class="primary-btn">Login</button>
          </form>

          <form v-else key="register" class="form">
            <label>Benutzername</label>
            <input />

            <label>E-Mail</label>
            <input type="email" />

            <label>Passwort</label>
            <input type="password" />

            <button class="primary-btn">Account erstellen</button>
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
  overflow: hidden;
  font-family: system-ui, sans-serif;
  background: #050714;
  background:
    radial-gradient(circle at top left, #1a237e, transparent 45%),
    radial-gradient(circle at bottom right, #311b92, transparent 45%),
    #050714;
  background-attachment: fixed;
}

/* === Vollbild-Container === */
.auth-page {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
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
  box-shadow: 0 25px 60px rgba(0,0,0,0.5);
}

/* === Toggle === */
.toggle {
  position: relative;
  display: flex;
  background: rgba(0,0,0,0.3);
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
  background: rgba(18,22,40,0.7);
  color: white;
}

.form input::placeholder {
  color: #6b7280;
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
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.primary-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(255, 45, 117, 0.3);
}

/* === Animation === */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>