export interface Achievement {
  id: number
  key: string
  title: string
  description: string
  xpReward: number
  unlocked: boolean
  unlockedAt: string | null
}

export interface ProfileStats {
  totalWorkouts: number
  trainingHours: number
  caloriesBurned: number
  longestStreak: number
  currentStreak: number
}
