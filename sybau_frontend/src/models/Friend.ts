export interface FriendshipDto {
    id: number;
    friendId: number;
    friendUserName: string;
    friendProfileImageUrl?: string;
    friendLevel: number;
    friendExperience: number;
    friendBodyStage: string;
    friendsSince: string;
}

export interface FriendRequestDto {
    id: number;
    fromUserId: number;
    fromUserName: string;
    fromUserProfileImageUrl?: string;
    fromUserLevel: number;
    sentAt: string;
}

export interface SentFriendRequestDto {
    id: number;
    toUserId: number;
    toUserName: string;
    toUserProfileImageUrl?: string;
    toUserLevel: number;
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
    goalUnit: 'reps' | 'time' | 'distance';
    expiresAt: string;
    createdAt: string;
    completedAt?: string;
    challengerId: number;
    challengerUserName: string;
    challengerProgress: number;
    challengerHiddenAt?: string;
    opponentId: number;
    opponentUserName: string;
    opponentProgress: number;
    opponentHiddenAt?: string;
    winnerId?: number;
    winnerUserName?: string;
}

export interface CreateFriendChallengeDto {
    opponentId: number;
    title: string;
    description?: string;
    goalAmount: number;
    goalUnit: 'reps' | 'time' | 'distance';
    distanceUnit?: 'm' | 'km';
    durationHours: number;
}
