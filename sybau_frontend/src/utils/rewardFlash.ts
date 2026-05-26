export type RewardFlashPayload = {
  xp?: number;
  coins?: number;
};

export function rewardFlashFrom(data: any): RewardFlashPayload {
  return {
    xp: Number(data?.xpEarned ?? data?.XpEarned ?? data?.xpReward ?? data?.XpReward ?? 0) || 0,
    coins: Number(data?.coinsEarned ?? data?.CoinsEarned ?? data?.coinReward ?? data?.CoinReward ?? data?.sellPrice ?? data?.SellPrice ?? 0) || 0,
  };
}

export function dispatchRewardFlash(reward: RewardFlashPayload) {
  const xp = Math.max(0, Number(reward.xp ?? 0));
  const coins = Math.max(0, Number(reward.coins ?? 0));
  if (xp <= 0 && coins <= 0) return;
  window.dispatchEvent(new CustomEvent('sybau:reward-flash', { detail: { xp, coins } }));
}
