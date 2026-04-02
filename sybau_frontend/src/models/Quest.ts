export interface UserQuest {
    id: number;
    questId: number;
    name: string;
    description: string;
    type: 'daily' | 'weekly' | 'monthly';
    rarity: string;
    targetType: string;
    progress: number;
    targetValue: number;
    xpReward: number;
    coinReward: number;
    isCompleted: boolean;
    isRewardClaimed: boolean;
    timeLeft: string;
}

export interface QuestStats {
    completed: number;
    active: number;
    totalXpEarned: number;
}
