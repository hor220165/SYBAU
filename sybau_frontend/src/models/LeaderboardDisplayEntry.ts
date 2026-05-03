export interface LeaderboardDisplayEntry {
  Id: number;
  Rank: number;
  UserName: string;
  ProfileImageUrl?: string;
  Experience: number;
  TotalXp: number;
  Level: number;
  initials: string;
  isCurrentUser: boolean;
}
