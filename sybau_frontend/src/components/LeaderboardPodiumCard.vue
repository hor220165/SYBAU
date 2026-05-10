<script setup lang="ts">
import { computed } from 'vue';
import { Crown, Star } from 'lucide-vue-next';
import type { LeaderboardDisplayEntry } from '@/models/LeaderboardDisplayEntry';
import { resolveMediaUrl } from '@/services/api';
import noProfilePicture from '@/assets/Nopfp.png';

const props = defineProps<{
  player: LeaderboardDisplayEntry;
  place: 1 | 2 | 3;
}>();

const emit = defineEmits<{
  openProfile: [id: number];
}>();

const cardClass = computed(() => {
  if (props.place === 1) return 'is-first';
  if (props.place === 2) return 'is-second';
  return 'is-third';
});

const badgeLabel = computed(() => `#${props.place}`);
const profileImageUrl = computed(() => resolveMediaUrl(props.player.ProfileImageUrl));

// Pattern removed
</script>

<template>
  <article class="podium-card" :class="cardClass">
    <div class="podium-glow"></div>

    <Crown v-if="place === 1" class="crown-icon" />

    <button class="avatar-shell" type="button" @click="emit('openProfile', player.Id)">
      <div class="avatar-core">
        <img
          :src="profileImageUrl || noProfilePicture"
          :alt="player.UserName"
          class="avatar-image"
        />
      </div>
    </button>

    <div class="badge-row">
      <span class="place-badge">{{ badgeLabel }}</span>
    </div>

    <h3 class="player-name">
      <span>{{ player.UserName }}</span>
      <Star v-if="player.isCurrentUser" class="current-user-star" :size="16" />
    </h3>
    <p class="player-meta">Level {{ player.Level }}</p>
    <p class="player-xp">{{ player.TotalXp.toLocaleString() }} XP</p>
  </article>
</template>

<style scoped>
.podium-card {
  --podium-accent-rgb: 192, 199, 209;
  --podium-highlight-rgb: 243, 244, 246;
  --podium-shadow-rgb: 107, 114, 128;
  position: relative;
  overflow: hidden;
  border-radius: 8px;
  border: 1px solid rgba(var(--podium-highlight-rgb), 0.24);
  background:
    linear-gradient(
      180deg,
      rgba(var(--podium-highlight-rgb), 0.12) 0%,
      rgba(var(--podium-accent-rgb), 0.14) 28%,
      rgba(var(--podium-shadow-rgb), 0.38) 72%,
      rgba(11, 18, 32, 0.98) 100%
    ),
    linear-gradient(180deg, rgba(15, 23, 42, 0.08) 0%, rgba(15, 23, 42, 0.26) 100%);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  padding: 24px 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  min-height: 244px;
  box-shadow:
    0 16px 32px rgba(var(--podium-shadow-rgb), 0.16),
    0 20px 50px rgba(2, 6, 23, 0.28);
}

.is-first {
  --podium-accent-rgb: 212, 175, 55;
  --podium-highlight-rgb: 255, 236, 179;
  --podium-shadow-rgb: 122, 90, 18;
  min-height: 300px;
}

.is-second {
  --podium-accent-rgb: 192, 199, 209;
  --podium-highlight-rgb: 243, 244, 246;
  --podium-shadow-rgb: 107, 114, 128;
  min-height: 252px;
}

.is-third {
  --podium-accent-rgb: 205, 127, 50;
  --podium-highlight-rgb: 241, 195, 138;
  --podium-shadow-rgb: 123, 74, 29;
  min-height: 214px;
}

.podium-glow {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 50% 10%, rgba(var(--podium-highlight-rgb), 0.2), transparent 46%),
    radial-gradient(circle at bottom, rgba(var(--podium-accent-rgb), 0.12), transparent 54%);
  pointer-events: none;
}

.crown-icon {
  position: absolute;
  top: 16px;
  color: #fde68a;
  width: 28px;
  height: 28px;
  filter: drop-shadow(0 0 16px rgba(250, 204, 21, 0.45));
  z-index: 2;
}

.avatar-shell {
  width: 96px;
  height: 96px;
  border-radius: 999px;
  padding: 4px;
  border: 0;
  display: grid;
  place-items: center;
  margin-top: 18px;
  background: linear-gradient(
    135deg,
    rgba(var(--podium-highlight-rgb), 0.98),
    rgba(var(--podium-accent-rgb), 0.94),
    rgba(var(--podium-shadow-rgb), 0.9)
  );
  box-shadow: 0 18px 34px rgba(var(--podium-shadow-rgb), 0.32);
  cursor: pointer;
  position: relative;
  z-index: 2;
}

.avatar-shell:focus-visible {
  outline: 2px solid rgba(var(--podium-highlight-rgb), 0.64);
  outline-offset: 3px;
}

.avatar-core {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  border-radius: inherit;
  background: rgba(15, 23, 42, 0.92);
  color: white;
  font-size: 1.6rem;
  font-weight: 800;
  letter-spacing: 0.04em;
  overflow: hidden;
}

.avatar-image {
  width: 100%;
  height: 100%;
  border-radius: 999px;
  object-fit: cover;
}

.avatar-fallback-icon {
  color: rgba(255, 255, 255, 0.74);
}

.badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  flex-wrap: wrap;
  justify-content: center;
  position: relative;
  z-index: 2;
}

.place-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 999px;
  padding: 6px 12px;
  font-size: 0.8rem;
  font-weight: 700;
}

.place-badge {
  background: rgba(var(--podium-accent-rgb), 0.18);
  border: 1px solid rgba(var(--podium-highlight-rgb), 0.2);
  color: rgb(var(--podium-highlight-rgb));
}

.player-name {
  margin: 14px 0 4px;
  color: white;
  font-size: 1.1rem;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  max-width: 100%;
  position: relative;
  z-index: 2;
}

.player-name span {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}

.current-user-star {
  flex: 0 0 auto;
  color: #fbbf24;
  fill: rgba(251, 191, 36, 0.22);
}

.player-meta {
  margin: 0;
  color: rgba(var(--podium-highlight-rgb), 0.82);
  font-size: 0.92rem;
  position: relative;
  z-index: 2;
}

.player-xp {
  margin: 8px 0 0;
  color: rgb(var(--podium-highlight-rgb));
  font-weight: 700;
  text-shadow: 0 0 12px rgba(var(--podium-shadow-rgb), 0.18);
  position: relative;
  z-index: 2;
}

</style>