<script setup lang="ts">
import { ref, watch, nextTick } from "vue";

const props = defineProps<{
  message: string
  type?: "success" | "error" | "info"
  duration?: number
}>();

const emit = defineEmits(["close"]);
const visible = ref(false);

function closePopup() {
  visible.value = false;
  setTimeout(() => emit("close"), 220);
}

watch(
  () => props.message,
  async (newVal) => {
    if (newVal) {
      // Element ins DOM setzen, aber noch nicht sichtbar
      visible.value = false;
      await nextTick(); // sicherstellen, dass DOM gerendert ist
      visible.value = true; // jetzt enter Animation greifen

      if (props.duration !== 0) {
        setTimeout(() => {
          visible.value = false;
          setTimeout(() => emit("close"), 220); // warten bis leave Animation fertig
        }, props.duration ?? 3000);
      }
    }
  },
  { immediate: true }
);
</script>

<template>
  <transition name="popup">
    <div
      v-if="visible"
      :class="['popup', type]"
    >
      <button class="popup-close" type="button" aria-label="Schließen" data-tooltip="Schließen" @click="closePopup">
        ✕
      </button>

      <div class="popup-title">
        {{ type === "error" ? "Error" : type === "info" ? "Info" : "Success" }}
      </div>

      <div class="popup-text">
        {{ message }}
      </div>
    </div>
  </transition>
</template>

<style scoped>
.popup {
  position: fixed;
  bottom: 18px;
  right: 18px;
  z-index: 10001;

  min-width: 240px;
  max-width: 420px;
  padding: 12px 14px 14px 14px;
  border-radius: 12px;
  color: #ecfdf5;
  box-shadow: 0 0 12px rgba(34, 197, 94, 0.5),
              0 0 24px rgba(34, 197, 94, 0.35),
              0 10px 25px rgba(0,0,0,0.5);
  backdrop-filter: blur(10px);
  overflow-wrap: break-word;
}

/* Success / Error */
.popup.success {
  background: rgba(16, 85, 45, 0.95);
  border: 1px solid rgba(34, 197, 94, 0.7);
}

.popup.error {
  background: rgba(120, 25, 25, 0.95);
  border: 1px solid rgba(248, 113, 113, 0.7);
  box-shadow: 0 0 12px rgba(248, 113, 113, 0.5),
              0 0 24px rgba(248, 113, 113, 0.35),
              0 10px 25px rgba(0,0,0,0.5);
}

.popup.info {
  background: rgba(30, 64, 175, 0.95);
  border: 1px solid rgba(96, 165, 250, 0.72);
  box-shadow: 0 0 12px rgba(96, 165, 250, 0.45),
              0 0 24px rgba(96, 165, 250, 0.3),
              0 10px 25px rgba(0,0,0,0.5);
}

/* Title */
.popup-title {
  font-size: 0.8rem;
  font-weight: 700;
  margin-bottom: 4px;
  color: inherit;
}

/* Text */
.popup-text {
  font-size: 0.8rem;
  line-height: 1.3;
  color: #dcfce7;
  word-break: break-word;
}

/* Close Button */
.popup-close {
  position: absolute;
  top: 6px;
  right: 6px;
  border: none;
  background: transparent;
  color: #bbf7d0;
  font-size: 13px;
  cursor: pointer;
}

.popup-close:hover {
  color: white;
}

/* =========================
   Animation via transition
========================= */

.popup-enter-from {
  opacity: 0;
  transform: translateY(20px);
}
.popup-enter-active {
  transition: all 0.25s ease;
}
.popup-leave-to {
  opacity: 0;
  transform: translateY(20px);
}
.popup-leave-active {
  transition: all 0.22s ease;
}
</style>
