<script setup lang="ts">

import Navbar from "@/components/Navbar.vue";
import Header from "@/components/Header.vue";
import SpriteAnimator from "@/components/spriteAnimator.vue";
</script>

<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="main-content">
    <!-- Avatar Section -->
    <div class="avatar-section">
      <div class="avatar-display">
        <SpriteAnimator :frameWidth="128" :frameHeight="128" :columns="2" :rows="2" :frameCount="4" :speed="1000"
          :scale="3" />
      </div>
    </div>
  </main>
</template>

<style scoped>
/* Main Content */
.main-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

/* Avatar Section */
.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 40px;
  gap: 24px;
}

.avatar-display {
  position: relative;
  border: 2px solid rgba(236, 72, 153, 0.3);
  border-radius: 20px;
  padding: 24px;
  box-shadow: 0 0 40px rgba(236, 72, 153, 0.2);
  display: inline-block;
}
</style>