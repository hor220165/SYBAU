<script setup lang="ts">
import { computed } from 'vue';
import { Crown, Medal, Sparkles, Star } from 'lucide-vue-next';
import type { LeaderboardDisplayEntry } from '@/models/LeaderboardDisplayEntry';
import { resolveMediaUrl } from '@/services/api';
import noProfilePicture from '@/assets/Nopfp.png';

const props = defineProps<{
  player: LeaderboardDisplayEntry;
}>();

const emit = defineEmits<{
  openProfile: [id: number];
}>();

const rankType = computed(() => {
  if (props.player.Rank === 1) return 'gold';
  if (props.player.Rank === 2) return 'silver';
  if (props.player.Rank === 3) return 'bronze';
  return 'plain';
});

const profileImageUrl = computed(() => resolveMediaUrl(props.player.ProfileImageUrl));
</script>

<template>
  <article class="leaderboard-row" :class="[{ 'is-current-user': player.isCurrentUser }, `rank-${rankType}`]">
    <div class="rank-box">
      <Crown v-if="player.Rank === 1" :size="20" />
      <Medal v-else-if="player.Rank === 2 || player.Rank === 3" :size="20" />
      <span v-else>#{{ player.Rank }}</span>
    </div>

    <button
      class="avatar-pill"
      :class="{ 'has-image': !!profileImageUrl, 'is-empty': !profileImageUrl }"
      type="button"
      @click="emit('openProfile', player.Id)"
    >
      <img
        :src="profileImageUrl || noProfilePicture"
        :alt="player.UserName"
        class="avatar-image"
      />
    </button>

    <div class="player-main">
      <div class="player-title-row">
        <h4>{{ player.UserName }}</h4>
        <Star v-if="player.isCurrentUser" class="current-user-star" :size="16" />
      </div>
      <div class="player-subline">
        <span class="level-pill">Level {{ player.Level }}</span>
      </div>
    </div>

    <div class="player-score">
      <span class="xp-value">{{ player.TotalXp.toLocaleString() }} XP</span>
      <span class="xp-caption">
        <Sparkles :size="14" />
        Gesamtfortschritt
      </span>
    </div>
  </article>
</template>

<style scoped>
.leaderboard-row {
  display: grid;
  grid-template-columns: 58px 56px minmax(0, 1fr) auto;
  gap: 16px;
  align-items: center;
  padding: 16px 18px;
  border-radius: 20px;
  background: rgba(15, 23, 42, 0.5);
  border: 1px solid rgba(139, 92, 246, 0.18);
  transition: transform 0.25s ease, border-color 0.25s ease, background 0.25s ease;
}

.leaderboard-row:hover {
  transform: translateY(-2px);
  border-color: rgba(236, 72, 153, 0.3);
  background: rgba(15, 23, 42, 0.64);
}

.is-current-user {
  background: linear-gradient(90deg, rgba(168, 85, 247, 0.18), rgba(236, 72, 153, 0.12));
  border-color: rgba(236, 72, 153, 0.34);
  box-shadow: 0 18px 32px rgba(88, 28, 135, 0.18);
}

.rank-box {
  width: 58px;
  height: 58px;
  border-radius: 18px;
  display: grid;
  place-items: center;
  font-weight: 800;
  color: white;
  background: rgba(30, 41, 59, 0.88);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.rank-gold .rank-box {
  color: #facc15;
  background: rgba(120, 53, 15, 0.25);
}

.rank-silver .rank-box {
  color: #cbd5e1;
}

.rank-bronze .rank-box {
  color: #fb923c;
}

.avatar-pill {
  width: 56px;
  height: 56px;
  border-radius: 999px;
  padding: 0;
  border: 0;
  display: grid;
  place-items: center;
  color: white;
  font-weight: 800;
  letter-spacing: 0.05em;
  overflow: hidden;
  cursor: pointer;
}

.avatar-pill:focus-visible {
  outline: 2px solid rgba(236, 72, 153, 0.65);
  outline-offset: 2px;
}

.avatar-pill.is-empty {
  background: rgba(30, 41, 59, 0.92);
  color: rgba(255, 255, 255, 0.72);
}

.avatar-pill.has-image {
  background: rgba(30, 41, 59, 0.92);
}

.avatar-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.player-main {
  min-width: 0;
}

.player-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.player-title-row h4 {
  margin: 0;
  color: white;
  font-size: 1rem;
  line-height: 1.2;
  word-break: break-word;
}

.level-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 0.78rem;
  font-weight: 700;
}

.current-user-star {
  flex: 0 0 auto;
  color: #fbbf24;
  fill: rgba(251, 191, 36, 0.22);
}

.player-subline {
  margin-top: 10px;
}

.level-pill {
  color: #c4b5fd;
  background: rgba(139, 92, 246, 0.14);
  border: 1px solid rgba(139, 92, 246, 0.24);
}

.player-score {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
  text-align: right;
}

.xp-value {
  color: white;
  font-weight: 700;
}

.xp-caption {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: #cbd5e1;
  font-size: 0.82rem;
}

@media (max-width: 860px) {
  .leaderboard-row {
    grid-template-columns: 52px 48px 1fr;
    gap: 12px;
  }

  .player-score {
    grid-column: 1 / -1;
    align-items: flex-start;
    text-align: left;
    padding-left: 0;
  }

  .rank-box {
    width: 52px;
    height: 52px;
  }

  .avatar-pill {
    width: 48px;
    height: 48px;
    border-radius: 999px;
  }
}

@media (max-width: 560px) {
  .leaderboard-row {
    padding: 14px;
  }

  .player-title-row {
    gap: 8px;
  }
}
</style>
