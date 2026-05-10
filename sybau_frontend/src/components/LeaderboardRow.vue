<script setup lang="ts">
import { computed } from 'vue';
import { Star } from 'lucide-vue-next';
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
      <span>{{ player.Rank }}</span>
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
        <Star v-if="player.isCurrentUser" class="current-user-star" :size="14" />
      </div>
    </div>

    <div class="player-level">lvl {{ player.Level }}</div>

    <div class="player-score">
      <span class="xp-number">{{ player.TotalXp.toLocaleString() }}</span>
      <span class="xp-unit">XP</span>
    </div>
  </article>
</template>

<style scoped>
.leaderboard-row {
  display: grid;
  grid-template-columns: 28px 42px minmax(0, 1fr) auto auto;
  gap: 14px;
  align-items: center;
  padding: 14px 10px;
  border-radius: 0;
  background: transparent;
  border: 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  transition: background 0.2s ease, border-color 0.2s ease;
}

.leaderboard-row:hover {
  background: rgba(255, 255, 255, 0.025);
  border-color: rgba(236, 72, 153, 0.18);
}

.is-current-user {
  background: linear-gradient(90deg, rgba(168, 85, 247, 0.12), rgba(236, 72, 153, 0.08));
  border-color: rgba(236, 72, 153, 0.24);
}

.rank-box {
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.7);
  font-size: 1rem;
  font-weight: 700;
  line-height: 1;
}

.rank-gold .rank-box {
  color: #d4af37;
}

.rank-silver .rank-box {
  color: #c0c7d1;
}

.rank-bronze .rank-box {
  color: #cd7f32;
}

.avatar-pill {
  width: 42px;
  height: 42px;
  border-radius: 999px;
  padding: 0;
  border: 0;
  display: grid;
  place-items: center;
  color: white;
  overflow: hidden;
  cursor: pointer;
  background: rgba(30, 41, 59, 0.92);
}

.avatar-pill:focus-visible {
  outline: 2px solid rgba(236, 72, 153, 0.65);
  outline-offset: 2px;
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
  gap: 6px;
  min-width: 0;
}

.player-title-row h4 {
  margin: 0;
  color: white;
  font-size: 0.98rem;
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.current-user-star {
  flex: 0 0 auto;
  color: #fbbf24;
  fill: rgba(251, 191, 36, 0.22);
}

.player-level {
  color: rgba(255, 255, 255, 0.66);
  font-size: 0.95rem;
  font-weight: 500;
  white-space: nowrap;
}

.player-score {
  display: inline-flex;
  align-items: baseline;
  justify-content: flex-end;
  gap: 6px;
  min-width: 0;
  white-space: nowrap;
  text-align: right;
}

.xp-number {
  color: #e2e8f0;
  font-size: 0.98rem;
  font-weight: 600;
}

.xp-unit {
  color: #38bdf8;
  font-size: 0.92rem;
  font-weight: 800;
  text-shadow: 0 0 12px rgba(56, 189, 248, 0.28);
}

@media (max-width: 860px) {
  .leaderboard-row {
    grid-template-columns: 24px 38px minmax(0, 1fr) auto auto;
    gap: 10px;
    padding: 12px 8px;
  }

  .avatar-pill {
    width: 38px;
    height: 38px;
  }

  .player-title-row h4 {
    font-size: 0.9rem;
  }

  .player-level,
  .xp-number,
  .xp-unit {
    font-size: 0.84rem;
  }
}

@media (max-width: 560px) {
  .leaderboard-row {
    grid-template-columns: 20px 34px minmax(0, 1fr) auto auto;
    gap: 8px;
    padding: 10px 4px;
  }

  .rank-box {
    font-size: 0.86rem;
  }

  .avatar-pill {
    width: 34px;
    height: 34px;
  }

  .player-title-row h4 {
    font-size: 0.82rem;
  }

  .player-level {
    font-size: 0.76rem;
  }

  .xp-number {
    font-size: 0.78rem;
  }

  .xp-unit {
    font-size: 0.76rem;
  }
}
</style>
