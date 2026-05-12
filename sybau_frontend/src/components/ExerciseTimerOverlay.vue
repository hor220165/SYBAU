<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="isOpen" class="timer-overlay" @click.self="cancel">
        <div class="timer-modal">

          <!-- ===== SETUP ===== -->
          <template v-if="phase === 'setup'">
            <div class="timer-header">
              <h2>{{ exerciseName }}</h2>
              <button class="timer-close" @click="cancel">&times;</button>
            </div>
            <p class="timer-sub">
              {{ exerciseType === 'Time' ? 'Drücke Start und beginne deine Zeit.' : 'Drücke Start, mache deine Wiederholungen und trage sie danach ein.' }}
            </p>
            <div class="timer-stage">
              <div class="ring-shell ring-shell-idle">
                <div class="ring-shell-inner">
                  <div class="idle-time-text">00:00</div>
                </div>
              </div>
            </div>
            <button class="start-btn" @click="goToReady">Start</button>
          </template>

          <!-- ===== READY 3-2-1 ===== -->
          <template v-if="phase === 'ready'">
            <div class="timer-header">
              <h2>{{ exerciseName }}</h2>
            </div>
            <p class="timer-sub">Mache dich bereit!</p>
            <div class="timer-stage">
              <div class="ring-shell ring-shell-ready">
                <div class="ring-shell-inner">
                  <div class="ready-circle" :class="{ pulse: readyCountdown > 0 }">
                    {{ readyCountdown > 0 ? readyCountdown : 'GO!' }}
                  </div>
                </div>
              </div>
            </div>
          </template>

          <!-- ===== RUNNING ===== -->
          <template v-if="phase === 'running'">
            <div class="timer-header">
              <h2>{{ exerciseName }}</h2>
            </div>
            <div class="timer-stage">
              <div class="ring-shell ring-shell-active">
                <div class="ring-shell-inner">
                  <div class="elapsed-display">
                    <span class="elapsed-time">{{ formatElapsed }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div v-if="exerciseType === 'Reps'" class="min-hint">
              Danach trägst du deine Reps ein
            </div>
            <button class="finish-btn" @click="finish">Fertig</button>
          </template>

          <!-- ===== ENTER-REPS ===== -->
          <template v-if="phase === 'enter-reps'">
            <div class="timer-header">
              <h2>{{ exerciseName }}</h2>
              <button class="timer-close" @click="cancel">&times;</button>
            </div>
            <div class="timer-stage">
              <div class="ring-shell ring-shell-compact ring-shell-frozen">
                <div class="ring-shell-inner">
                  <div class="elapsed-display">
                    <span class="elapsed-time elapsed-frozen">{{ formatElapsed }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="rep-entry-panel">
              <span class="rep-entry-label">Wiederholungen</span>
              <div class="rep-control" role="group" aria-label="Wiederholungen anpassen">
                <button class="rep-step rep-step-wide" aria-label="5 Wiederholungen weniger" @click="adjustReps(-5)">-5</button>
                <button class="rep-step" aria-label="1 Wiederholung weniger" @click="adjustReps(-1)">−</button>
                <div class="rep-readout" aria-live="polite">
                  <strong>{{ targetReps }}</strong>
                </div>
                <button class="rep-step" aria-label="1 Wiederholung mehr" @click="adjustReps(1)">+</button>
                <button class="rep-step rep-step-wide" aria-label="5 Wiederholungen mehr" @click="adjustReps(5)">+5</button>
              </div>
              <p class="rep-limit">Noch {{ remaining }} möglich heute</p>
            </div>
            <button class="confirm-btn" :disabled="targetReps < 1" @click="confirmRepsEntry">
              Prüfen
            </button>
          </template>

          <!-- ===== RESULT ===== -->
          <template v-if="phase === 'result'">
            <div class="timer-header">
              <h2>{{ exerciseName }}</h2>
            </div>
            <template v-if="timeValid || exerciseType === 'Time'">
              <div class="timer-stage">
                <div class="ring-shell ring-shell-success">
                  <div class="ring-shell-inner">
                    <div class="success-icon">&#10003;</div>
                    <p class="result-text">
                      {{ exerciseType === 'Time'
                        ? `${formatElapsed} eingetragen`
                        : `${targetReps} Reps in ${formatElapsed}`
                      }}
                    </p>
                  </div>
                </div>
              </div>
              <button class="confirm-btn" @click="confirmResult">Eintragen</button>
            </template>
            <template v-else>
              <div class="timer-stage">
                <div class="ring-shell ring-shell-fail">
                  <div class="ring-shell-inner">
                    <div class="fail-icon">&#10007;</div>
                    <p class="result-text fail">Zu schnell!</p>
                    <p class="result-detail">
                      Mindestens {{ minSeconds }}s für {{ targetReps }} Reps erwartet.
                      Du hast {{ elapsedSeconds }}s gebraucht.
                    </p>
                  </div>
                </div>
              </div>
              <button class="retry-btn" @click="retry">Erneut versuchen</button>
              <button class="cancel-link" @click="cancel">Abbrechen</button>
            </template>
          </template>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch, onUnmounted } from 'vue';

const props = defineProps<{
  isOpen: boolean;
  exerciseName: string;
  exerciseType: 'Reps' | 'Time';
  xpPerRep: number;
  maxReps: number;
  remaining: number;
}>();

const emit = defineEmits<{
  close: [];
  confirm: [data: { reps: number; elapsedSeconds: number }];
}>();

type Phase = 'setup' | 'ready' | 'running' | 'enter-reps' | 'result';
const phase = ref<Phase>('setup');

const targetReps = ref(1);
const adjustReps = (delta: number) => {
  targetReps.value = Math.max(1, Math.min(targetReps.value + delta, props.remaining));
};

const readyCountdown = ref(0);
const elapsedSeconds = ref(0);
let timerInterval: ReturnType<typeof setInterval> | null = null;
let startTime = 0;

const minSeconds = computed(() => Math.ceil(targetReps.value * 0.75));
const timeValid = computed(() => elapsedSeconds.value >= minSeconds.value);

const formatElapsed = computed(() => {
  const total = elapsedSeconds.value;
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
});

const goToReady = () => {
  phase.value = 'ready';
  readyCountdown.value = 3;
  const cd = setInterval(() => {
    readyCountdown.value--;
    if (readyCountdown.value <= 0) {
      clearInterval(cd);
      startTimer();
    }
  }, 1000);
};

const startTimer = () => {
  phase.value = 'running';
  elapsedSeconds.value = 0;
  startTime = Date.now();
  timerInterval = setInterval(() => {
    elapsedSeconds.value = Math.floor((Date.now() - startTime) / 1000);
  }, 200);
};

const finish = () => {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
  elapsedSeconds.value = Math.floor((Date.now() - startTime) / 1000);
  phase.value = props.exerciseType === 'Time' ? 'result' : 'enter-reps';
};

const confirmRepsEntry = () => {
  phase.value = 'result';
};

const confirmResult = () => {
  const reps = props.exerciseType === 'Time' ? elapsedSeconds.value : targetReps.value;
  emit('confirm', { reps, elapsedSeconds: elapsedSeconds.value });
  emit('close');
};

const retry = () => {
  phase.value = 'enter-reps';
};

const cancel = () => {
  cleanup();
  emit('close');
};

const cleanup = () => {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
};

onUnmounted(cleanup);

watch(() => props.isOpen, (open) => {
  if (open) {
    cleanup();
    targetReps.value = Math.max(1, Math.min(10, props.remaining || 1));
    elapsedSeconds.value = 0;
    phase.value = 'setup';
  }
});
</script>

<style scoped>
/* ===== OVERLAY ===== */
.timer-overlay {
  position: fixed;
  inset: 0;
  background:
    radial-gradient(circle at center, rgba(236, 72, 153, 0.12) 0%, rgba(0, 0, 0, 0) 38%),
    rgba(0, 0, 0, 0.9);
  backdrop-filter: blur(16px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 3000;
  padding: 16px;
  overflow-y: auto;
}

.timer-modal {
  width: 100%;
  max-width: 420px;
  padding: 10px 6px 24px;
  text-align: center;
}

/* ===== HEADER ===== */
.timer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  padding: 0 8px;
}
.timer-header h2 {
  color: white;
  font-size: 22px;
  font-weight: 800;
  margin: 0;
}
.timer-close {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.5);
  font-size: 28px;
  cursor: pointer;
  padding: 0 4px;
  line-height: 1;
}
.timer-close:hover { color: white; }

.timer-sub {
  color: rgba(255, 255, 255, 0.55);
  font-size: 14px;
  margin: 0 0 16px;
}
.timer-info {
  color: rgba(255, 255, 255, 0.4);
  font-size: 13px;
  margin-bottom: 16px;
}

/* ===== RING ===== */
.timer-stage {
  display: flex;
  justify-content: center;
  margin: 10px 0 18px;
}
.ring-shell {
  width: min(78vw, 340px);
  aspect-ratio: 1;
  border-radius: 50%;
  padding: 14px;
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.02) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow:
    0 0 0 1px rgba(255, 255, 255, 0.04),
    0 0 32px rgba(236, 72, 153, 0.18);
}
.ring-shell-idle {
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.02) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #f43f5e);
}
/* READY – pink, same gradient as idle but brighter glow */
.ring-shell-ready {
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.04) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow:
    0 0 0 1px rgba(236, 72, 153, 0.08),
    0 0 48px rgba(236, 72, 153, 0.35);
}
.ring-shell-active {
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.02) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #fb7185);
  box-shadow:
    0 0 0 1px rgba(251, 113, 133, 0.06),
    0 0 42px rgba(236, 72, 153, 0.28);
  animation: ring-breathe 2.4s ease-in-out infinite;
}
@keyframes ring-breathe {
  0%, 100% { box-shadow: 0 0 0 1px rgba(236, 72, 153, 0.06), 0 0 32px rgba(236, 72, 153, 0.22); }
  50%       { box-shadow: 0 0 0 1px rgba(251, 113, 133, 0.10), 0 0 52px rgba(236, 72, 153, 0.38); }
}
.ring-shell-frozen {
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.02) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow:
    0 0 0 1px rgba(236, 72, 153, 0.08),
    0 0 28px rgba(236, 72, 153, 0.22);
}
.ring-shell-compact {
  width: min(58vw, 240px);
}
.ring-shell-success {
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.02) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow:
    0 0 0 1px rgba(236, 72, 153, 0.08),
    0 0 28px rgba(236, 72, 153, 0.22);
}
.ring-shell-fail {
  background:
    radial-gradient(circle at center, rgba(255, 255, 255, 0.02) 64%, rgba(255, 255, 255, 0) 66%),
    linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow:
    0 0 0 1px rgba(236, 72, 153, 0.08),
    0 0 28px rgba(236, 72, 153, 0.22);
}
.ring-shell-inner {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: rgba(4, 10, 24, 0.96);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 18px;
}

/* ===== IDLE / READY ===== */
.idle-time-text {
  color: rgba(255, 255, 255, 0.9);
  font-size: 62px;
  font-weight: 300;
  font-variant-numeric: tabular-nums;
  letter-spacing: 1px;
}
.ready-circle {
  width: 132px;
  height: 132px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 54px;
  font-weight: 900;
  color: white;
  transition: all 0.3s;
}
.ready-circle.pulse {
  animation: pulse 0.5s ease-in-out;
}
@keyframes pulse {
  0%, 100% { transform: scale(1); border-color: rgba(236, 72, 153, 0.4); }
  50% { transform: scale(1.08); border-color: rgba(236, 72, 153, 0.7); }
}

/* ===== ELAPSED ===== */
.elapsed-display { margin: 0; }
.elapsed-time {
  font-size: clamp(52px, 12vw, 86px);
  font-weight: 300;
  color: white;
  font-variant-numeric: tabular-nums;
  letter-spacing: 0;
  text-shadow: 0 0 20px rgba(236, 72, 153, 0.28);
}
.elapsed-time.elapsed-frozen {
  font-size: clamp(28px, 6vw, 44px);
  text-shadow: 0 0 12px rgba(236, 72, 153, 0.18);
}
.min-hint {
  color: rgba(255, 255, 255, 0.35);
  font-size: 13px;
  margin-bottom: 4px;
}

/* ===== REP ENTRY ===== */
.rep-entry-panel {
  width: 100%;
  max-width: 420px;
  margin: -2px auto 20px;
}
.rep-entry-label {
  display: block;
  margin: 0 0 10px;
  color: rgba(255, 255, 255, 0.58);
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.rep-control {
  display: grid;
  grid-template-columns: 56px 52px minmax(94px, 1fr) 52px 56px;
  height: 72px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.11);
  border-radius: 14px;
  background: rgba(4, 10, 24, 0.82);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.06),
    0 14px 34px rgba(0, 0, 0, 0.22);
}
.rep-step {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  border: 0;
  border-right: 1px solid rgba(255, 255, 255, 0.08);
  background: transparent;
  color: white;
  cursor: pointer;
  font-size: 22px;
  font-weight: 900;
  line-height: 1;
  padding: 0;
  font-family: inherit;
  appearance: none;
  transition: background 0.18s ease, color 0.18s ease;
}
.rep-step-wide {
  color: rgba(255, 255, 255, 0.72);
  font-size: 15px;
}
.rep-step:hover,
.rep-step:focus-visible {
  background: rgba(236, 72, 153, 0.14);
  color: white;
  outline: none;
}
.rep-step:last-child {
  border-right: 0;
}
.rep-readout {
  display: flex;
  align-items: center;
  justify-content: center;
  border-right: 1px solid rgba(255, 255, 255, 0.08);
  background:
    radial-gradient(circle at center, rgba(236, 72, 153, 0.17), rgba(236, 72, 153, 0.04) 62%, transparent 72%),
    rgba(255, 255, 255, 0.035);
}
.rep-readout strong {
  color: white;
  font-size: 48px;
  font-weight: 950;
  line-height: 1;
  font-variant-numeric: tabular-nums;
  transform: translateY(-1px);
}
.rep-limit {
  color: rgba(255, 255, 255, 0.42);
  font-size: 13px;
  margin: 12px 0 0;
}

/* ===== BUTTONS ===== */
.start-btn, .finish-btn, .confirm-btn, .retry-btn {
  width: 100%;
  height: 52px;
  border-radius: 14px;
  border: none;
  font-size: 17px;
  font-weight: 800;
  color: white;
  cursor: pointer;
  transition: all 0.2s;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}
.confirm-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.finish-btn { margin-top: 24px; }
.retry-btn { margin-bottom: 8px; }
.cancel-link {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.4);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  padding: 12px 0 0;
  display: block;
  width: 100%;
  text-align: center;
}
.cancel-link:hover { color: rgba(255, 255, 255, 0.65); }

/* ===== RESULT ===== */
.success-icon {
  font-size: 58px;
  color: #22c55e;
  margin: 0 0 8px;
  text-shadow: 0 0 20px rgba(34, 197, 94, 0.5);
}
.fail-icon {
  font-size: 64px;
  color: #ef4444;
  margin: 12px 0 8px;
  text-shadow: 0 0 20px rgba(239, 68, 68, 0.5);
}
.result-text {
  color: white;
  font-size: 18px;
  font-weight: 700;
  margin: 0 0 16px;
}
.result-text.fail { color: #fca5a5; }
.result-detail {
  color: rgba(255, 255, 255, 0.55);
  font-size: 14px;
  margin-bottom: 20px;
  line-height: 1.5;
}
.result-rewards {
  margin-top: 18px;
  margin-bottom: 20px;
}

/* ===== TRANSITIONS ===== */
.fade-enter-active, .fade-leave-active { transition: opacity 0.25s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

/* ===== RESPONSIVE – Mobile ===== */
@media (max-width: 480px) {
  .timer-overlay {
    padding: 10px;
    align-items: flex-start;
    padding-top: 24px;
  }
  .timer-modal {
    padding: 8px 4px 20px;
    max-width: 100%;
  }
  .timer-header h2 {
    font-size: 19px;
  }
  .timer-sub {
    font-size: 13px;
    margin-bottom: 12px;
  }
  .rep-entry-panel {
    max-width: 100%;
    margin-bottom: 18px;
  }
  .rep-control {
    grid-template-columns: 46px 44px minmax(76px, 1fr) 44px 46px;
    height: 60px;
    border-radius: 12px;
  }
  .rep-step {
    font-size: 20px;
  }
  .rep-step-wide {
    font-size: 13px;
  }
  .rep-readout strong {
    font-size: 40px;
  }
  .ring-shell-compact {
    width: min(52vw, 200px);
  }
  .idle-time-text {
    font-size: 48px;
  }
  .elapsed-time {
    font-size: clamp(42px, 11vw, 68px);
  }
  .elapsed-time.elapsed-frozen {
    font-size: clamp(22px, 5vw, 36px);
  }
  .start-btn, .finish-btn, .confirm-btn, .retry-btn {
    height: 48px;
    font-size: 16px;
    border-radius: 12px;
  }
}

/* Very small phones (360px and below) */
@media (max-width: 360px) {
  .timer-overlay {
    padding: 8px;
    padding-top: 16px;
  }
  .timer-header h2 {
    font-size: 17px;
  }
  .rep-control {
    grid-template-columns: 40px 38px minmax(64px, 1fr) 38px 40px;
    height: 56px;
  }
  .rep-step {
    font-size: 18px;
  }
  .rep-step-wide {
    font-size: 12px;
  }
  .rep-readout strong {
    font-size: 36px;
  }
  .ring-shell-compact {
    width: min(50vw, 180px);
  }
}
</style>
