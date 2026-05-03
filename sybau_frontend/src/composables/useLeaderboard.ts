import { ref, computed } from 'vue';
import type { LeaderBoard } from '@/models/LeaderBoard';
import { userService } from '@/services/api';

const leaderboard = ref<LeaderBoard[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);

export async function loadLeaderboard() {
  loading.value = true;
  error.value = null;
  try {
    const res = await userService.getLeaderboard();
    // Debug: log the full response to inspect shape during development
    // eslint-disable-next-line no-console
    console.debug('getLeaderboard response', res);

    // Handle common response shapes: either the array is at res.data or res.data.data
    const raw = Array.isArray(res.data) ? res.data : Array.isArray(res.data?.data) ? res.data.data : null;

    if (raw) {
      // Map API response (camelCase/lowercase) to client model (PascalCase)
      leaderboard.value = raw.map((item: any) => ({
        Id: item.Id ?? item.id,
        Rank: Number(item.Rank ?? item.rank ?? 0),
        UserName: item.UserName ?? item.userName ?? item.username ?? '',
        ProfileImageUrl: item.ProfileImageUrl ?? item.profileImageUrl ?? '',
        Experience: Number(item.Experience ?? item.experience ?? 0),
        TotalXp: Number(item.TotalXp ?? item.totalXp ?? item.Experience ?? item.experience ?? 0),
        Level: Number(item.Level ?? item.level ?? 0)
      })) as LeaderBoard[];
    } else {
      // unexpected shape — store empty and surface an error message
      leaderboard.value = [];
      // eslint-disable-next-line no-console
      console.warn('Unexpected leaderboard response shape', res.data);
      error.value = 'Unerwartete Antwort vom Server';
    }
  } catch (e: any) {
    // eslint-disable-next-line no-console
    console.error('loadLeaderboard error', e);
    error.value = e.response?.data?.message ?? JSON.stringify(e.response?.data) ?? e.message ?? 'Fehler beim Laden';
  } finally {
    loading.value = false;
  }
}

export function useLeaderboard() {
  const sortedLeaderboard = computed(() => [...leaderboard.value].sort((a, b) => a.Rank - b.Rank));
  return { leaderboard, sortedLeaderboard, loading, error, loadLeaderboard };
}
