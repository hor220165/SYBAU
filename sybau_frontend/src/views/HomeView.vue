<template>
  <div>
    <h1>Pixel Avatar Test</h1>
  <SpriteAnimator
  :frameWidth="128"
  :frameHeight="128"
  :columns="2"
  :rows="2"
  :frameCount="4"
  :speed="1000"
  :scale="3"
/>
  </div>
</template>

<script lang="ts">
import SpriteAnimator from "../components/spriteAnimator.vue";

export default {
  components: { SpriteAnimator }
}
</script>
