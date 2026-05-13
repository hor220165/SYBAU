<template>
  <div class="sprite-container">
    <canvas ref="canvas" :width="frameWidth" :height="frameHeight"></canvas>
  </div>
</template>

<script lang="ts">
import { defineComponent, onMounted, onUnmounted, ref, watch } from "vue";
import skinnySprite from "@/assets/Spritesheet_Skinny.png";
import normalSprite from "@/assets/Spritesheet_Normal.png";
import bodybuilderSprite from "@/assets/Spritesheet_Bodybuilder.png";

export default defineComponent({
  props: {
    bodyStage: { type: String, default: "" },
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
    let intervalId: ReturnType<typeof window.setInterval> | null = null;
    let activeSprite: HTMLImageElement | null = null;

    const stageToSprite: Record<string, string> = {
      skinny: skinnySprite,
      defined: normalSprite,
      normal: normalSprite,
      bodybuilder: bodybuilderSprite
    };

    const getStoredBodyStage = () => {
      try {
        const user = JSON.parse(localStorage.getItem("user") || "{}");
        return String(user.avatar?.bodyStage ?? user.avatar?.BodyStage ?? "").trim().toLowerCase();
      } catch {
        return "";
      }
    };

    const clearAnimation = () => {
      if (intervalId) {
        window.clearInterval(intervalId);
        intervalId = null;
      }
    };

    const drawSprite = () => {
      if (!canvas.value) return;
      const ctx = canvas.value.getContext("2d");
      if (!ctx) return;

      ctx.imageSmoothingEnabled = false;
      clearAnimation();

      const sprite = new Image();
      activeSprite = sprite;

      const stage = String(props.bodyStage || getStoredBodyStage()).trim().toLowerCase();
      sprite.src = stageToSprite[stage] || skinnySprite;

      let frame = 0;

      sprite.onload = () => {
        if (activeSprite !== sprite) return;

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
        intervalId = window.setInterval(draw, props.speed);
      };
    };

    onMounted(drawSprite);

    watch(
      () => [props.bodyStage, props.speed, props.frameWidth, props.frameHeight, props.columns, props.frameCount],
      drawSprite
    );

    onUnmounted(() => {
      clearAnimation();
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
