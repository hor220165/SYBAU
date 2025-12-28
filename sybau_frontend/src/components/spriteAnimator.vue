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
    columns: { type: Number, default: 2 }, // Spalten im Grid
    rows: { type: Number, default: 2 }, // Reihen im Grid
    frameCount: { type: Number, default: 4 }, // Anzahl Frames (max: columns * rows)
    speed: { type: Number, default: 1000 }, // 1 Sekunde pro Frame
    scale: { type: Number, default: 2 }
  },
  setup(props) {
    const canvas = ref<HTMLCanvasElement | null>(null);
    let intervalId: number | null = null;

    onMounted(() => {
      if (!canvas.value) return;
      const ctx = canvas.value.getContext("2d");
      if (!ctx) return;

      // Pixel-Art scharf halten
      ctx.imageSmoothingEnabled = false;

      const sprite = new Image();
      sprite.src = "./src/assets/Pixel-Avatar.png";

      let frame = 0;

      sprite.onload = () => {
        console.log('Sprite geladen:', sprite.width, 'x', sprite.height);
        console.log('Grid:', props.columns, 'x', props.rows, '=', props.frameCount, 'Frames');
        
        function draw() {
          if (!ctx || !canvas.value) return;
          ctx.clearRect(0, 0, canvas.value.width, canvas.value.height);

          // Frame Position im 2x2 Grid berechnen
          const col = frame % props.columns;
          const row = Math.floor(frame / props.columns);

          // Frame aus dem Sprite Sheet zeichnen
          ctx.drawImage(
            sprite,
            col * props.frameWidth, row * props.frameHeight, 
            props.frameWidth, props.frameHeight,
            0, 0, props.frameWidth, props.frameHeight
          );

          console.log('Frame:', frame, '→ Spalte:', col, 'Reihe:', row);
          frame = (frame + 1) % props.frameCount;
        }

        // Sofort ersten Frame zeichnen
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
.sprite-container {
  display: inline-block;
  padding: 16px;
  background: linear-gradient(145deg, #1a1a2e, #16213e);
  border-radius: 12px;
  box-shadow: 
    0 8px 32px rgba(0, 0, 0, 0.4),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

canvas {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
  border: 3px solid #0f3460;
  border-radius: 8px;
  box-shadow: 
    0 0 20px rgba(0, 102, 255, 0.3),
    inset 0 0 10px rgba(0, 0, 0, 0.5);
  display: block;
  width: calc(v-bind(frameWidth) * v-bind(scale) * 1px);
  height: calc(v-bind(frameHeight) * v-bind(scale) * 1px);
}
</style>