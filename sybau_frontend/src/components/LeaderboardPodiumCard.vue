<script setup lang="ts">
import { computed } from 'vue';
import { BadgeCheck, Crown } from 'lucide-vue-next';
import type { LeaderboardDisplayEntry } from '@/models/LeaderboardDisplayEntry';

const props = defineProps<{
  player: LeaderboardDisplayEntry;
  place: 1 | 2 | 3;
}>();

const cardClass = computed(() => {
  if (props.place === 1) return 'is-first';
  if (props.place === 2) return 'is-second';
  return 'is-third';
});

const badgeLabel = computed(() => `#${props.place}`);
</script>

<template>
  <article class="podium-card" :class="cardClass">
    <div class="podium-glow"></div>
    <Crown v-if="place === 1" class="crown-icon" />

    <div class="avatar-shell">
      <div class="avatar-core">{{ player.initials }}</div>
    </div>

    <div class="badge-row">
      <span class="place-badge">{{ badgeLabel }}</span>
      <span v-if="player.isCurrentUser" class="me-badge">
        <BadgeCheck :size="14" />
        Du
      </span>
    </div>

    <h3 class="player-name">{{ player.UserName }}</h3>
    <p class="player-meta">Level {{ player.Level }}</p>
    <p class="player-xp">{{ player.Experience.toLocaleString() }} XP</p>
  </article>
</template>

<style scoped>
.podium-card {
  position: relative;
  overflow: hidden;
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(15, 23, 42, 0.72);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  padding: 24px 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  min-height: 238px;
  box-shadow: 0 20px 50px rgba(2, 6, 23, 0.28);
}

.is-first {
  min-height: 288px;
  background:
    linear-gradient(180deg, rgba(245, 158, 11, 0.18), rgba(15, 23, 42, 0.86)),
    rgba(15, 23, 42, 0.72);
  border-color: rgba(250, 204, 21, 0.38);
}

.is-second {
  min-height: 252px;
  background:
    linear-gradient(180deg, rgba(148, 163, 184, 0.16), rgba(15, 23, 42, 0.86)),
    rgba(15, 23, 42, 0.72);
  border-color: rgba(203, 213, 225, 0.26);
}

.is-third {
  min-height: 224px;
  background:
    linear-gradient(180deg, rgba(249, 115, 22, 0.16), rgba(15, 23, 42, 0.86)),
    rgba(15, 23, 42, 0.72);
  border-color: rgba(251, 146, 60, 0.24);
}

.podium-glow {
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at top, rgba(255, 255, 255, 0.16), transparent 55%);
  pointer-events: none;
}

.crown-icon {
  position: absolute;
  top: 16px;
  color: #fde68a;
  width: 28px;
  height: 28px;
  filter: drop-shadow(0 0 16px rgba(250, 204, 21, 0.45));
}

.avatar-shell {
  width: 96px;
  height: 96px;
  border-radius: 999px;
  padding: 4px;
  display: grid;
  place-items: center;
  margin-top: 18px;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.9), rgba(59, 130, 246, 0.9));
  box-shadow: 0 18px 34px rgba(76, 29, 149, 0.32);
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
}

.badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  flex-wrap: wrap;
  justify-content: center;
}

.place-badge,
.me-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 999px;
  padding: 6px 12px;
  font-size: 0.8rem;
  font-weight: 700;
}

.place-badge {
  background: rgba(255, 255, 255, 0.14);
  color: white;
}

.me-badge {
  background: rgba(168, 85, 247, 0.16);
  color: #e9d5ff;
  border: 1px solid rgba(168, 85, 247, 0.3);
}

.player-name {
  margin: 14px 0 4px;
  color: white;
  font-size: 1.1rem;
  font-weight: 700;
}

.player-meta {
  margin: 0;
  color: #c4b5fd;
  font-size: 0.92rem;
}

.player-xp {
  margin: 8px 0 0;
  color: #f8fafc;
  font-weight: 600;
}

@media (max-width: 768px) {
  .podium-card,
  .is-first,
  .is-second,
  .is-third {
    min-height: unset;
  }

  .avatar-shell {
    width: 82px;
    height: 82px;
    margin-top: 10px;
  }
}
</style>
