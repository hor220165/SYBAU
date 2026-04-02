export interface FriendshipDto {
    id: number;
    friendId: number;
    friendUserName: string;
    friendLevel: number;
    friendExperience: number;
    friendBodyStage: string;
    friendsSince: string;
}

export interface FriendRequestDto {
    id: number;
    fromUserId: number;
    fromUserName: string;
    fromUserLevel: number;
    sentAt: string;
}

export interface FriendChallengeDto {
    id: number;
    title: string;
    description?: string;
    xpReward: number;
    coinReward: number;
    status: string;
    goalAmount: number;
    expiresAt: string;
    createdAt: string;
    completedAt?: string;
    challengerId: number;
    challengerUserName: string;
    challengerProgress: number;
    opponentId: number;
    opponentUserName: string;
    opponentProgress: number;
    winnerId?: number;
    winnerUserName?: string;
}

export interface CreateFriendChallengeDto {
    opponentId: number;
    title: string;
    description?: string;
    xpReward: number;
    coinReward: number;
    goalAmount: number;
    durationHours: number;
}
