<template>
  <div class="sprite-container">
    <canvas ref="canvas" :width="frameWidth" :height="frameHeight"></canvas>
  </div>
</template>

<script lang="ts">
import { defineComponent, onMounted, onUnmounted, ref } from "vue";

export default defineComponent({
  props: {
    frameWidth: { type: Number, default: 128 },
    frameHeight: { type: Number, default: 128 },
    columns: { type: Number, default: 2 },
    rows: { type: Number, default: 2 },
    frameCount: { type: Number, default: 4 },
    speed: { type: Number, default: 1000 },
    scale: { type: Number, default: 2 }
  },
  setup(props) {
    const canvas = ref<HTMLCanvasElement | null>(null);
    let intervalId: number | null = null;

    onMounted(() => {
      if (!canvas.value) return;
      const ctx = canvas.value.getContext("2d");
      if (!ctx) return;

      ctx.imageSmoothingEnabled = false;

      const sprite = new Image();

      const user = JSON.parse(localStorage.getItem('user') || '{}');
      const stage = String(user.avatar?.bodyStage ?? '').trim().toLowerCase();

      const stageToSprite: Record<string, string> = {
        skinny: "./src/assets/Spritesheet_Skinny.png",
        defined: "./src/assets/Spritesheet_Normal.png",
        bodybuilder: "./src/assets/Spritesheet_Bodybuilder.png"
      };

      sprite.src = stageToSprite[stage] || "./src/assets/Spritesheet_Skinny.png";

      let frame = 0;

      sprite.onload = () => {
        function draw() {
          if (!ctx || !canvas.value) return;
          ctx.clearRect(0, 0, canvas.value.width, canvas.value.height);
          const col = frame % props.columns;
          const row = Math.floor(frame / props.columns);
          ctx.drawImage(
            sprite,
            col * props.frameWidth, row * props.frameHeight,
            props.frameWidth, props.frameHeight,
            0, 0, props.frameWidth, props.frameHeight
          );
          frame = (frame + 1) % props.frameCount;
        }

        draw();
        intervalId = setInterval(draw, props.speed);
      };
    });

    onUnmounted(() => {
      if (intervalId) clearInterval(intervalId);
    });

    return { canvas };
  }
});
</script>

<style scoped>
canvas {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
  border-radius: 8px;
  display: block;
  width: calc(v-bind(frameWidth) * v-bind(scale) * 1px);
  height: calc(v-bind(frameHeight) * v-bind(scale) * 1px);
}
</style>
