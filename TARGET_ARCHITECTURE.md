# SYBAU - Target Architecture

## Stack
- Backend: ASP.NET Core Web API (.NET 9) with C#
- Frontend: Vue 3 + TypeScript with Vite
- Mobile: Ionic Vue + Capacitor (future phase)
- Database: PostgreSQL (production), SQLite (development)
- ORM: Entity Framework Core
- Authentication: JWT + Refresh Tokens
- API Documentation: Swagger/OpenAPI
- Deployment: Docker + docker-compose

## Folder Structure
```
/SYBAU
  /backend
    /Controllers
    /DTOs
    /Models
    /Services
    /Data
    /Migrations
    /Utils
    appsettings.json
    Program.cs
  /frontend
    /src
      /assets
      /components
      /composables
      /router
      /services
      /stores
      /views
      /models
    package.json
    vite.config.ts
  /mobile (future)
    /src
      /components
      /pages
      /services
    package.json
    capacitor.config.ts
  docker-compose.yml
  .env.example
  README.md
```

## Database Schema (PostgreSQL)
- Users (id, username, email, password_hash, is_admin, created_at, updated_at)
- Profiles (user_id, height, weight, age, gender, fitness_level, created_at, updated_at)
- Avatars (id, user_id, current_stage, xp, level, coins, created_at, updated_at)
- AvatarStages (id, name, description, min_xp, max_xp, image_url, unlock_requirements)
- AvatarEquipment (id, avatar_id, item_id, slot, equipped_at)
- Items (id, name, description, type, rarity, price, image_url, stats_modifier, created_at)
- ItemTypes (id, name, description)
- Inventory (id, user_id, item_id, quantity, acquired_at)
- Workouts (id, name, description, category, difficulty, xp_reward, coin_reward, duration_min, created_at)
- Exercises (id, name, description, category, muscle_group, equipment_needed, created_at)
- WorkoutExercises (id, workout_id, exercise_id, sets, reps, duration_sec, order_index)
- WorkoutLogs (id, user_id, workout_id, completed_at, xp_earned, coins_earned, performance_score)
- Challenges (id, name, description, type, start_date, end_date, xp_reward, coin_reward, target_value)
- UserChallenges (id, user_id, challenge_id, progress, completed_at, claimed_at)
- Achievements (id, name, description, icon_url, xp_reward, coin_reward, criteria_type, criteria_value)
- UserAchievements (id, user_id, achievement_id, earned_at)
- Streaks (id, user_id, type, current_streak, longest_streak, last_activity_date, updated_at)
- LeaderboardSnapshots (id, user_id, xp, rank, snapshot_date)
- AdminActions (id, admin_user_id, action_type, target_id, details, timestamp)
- FitnessProviderLinks (id, user_id, provider_type, provider_user_id, access_token, refresh_token, expires_at, created_at, updated_at)
- SyncLogs (id, user_id, provider_type, sync_type, records_synced, status, started_at, completed_at, error_message)
- Notifications (id, user_id, title, message, type, is_read, created_at)

## API Structure
- /api/auth (register, login, refresh, logout)
- /api/users (profile, settings, stats)
- /api/avatars (info, progression, equipment)
- /api/workouts (catalog, logging, history)
- /api/exercises (catalog)
- /api/challenges (active, user progress, leaderboard)
- /api/shop (items, purchase, inventory)
- /api/admin (users, workouts, challenges, items, analytics)
- /api/fitness (provider linking, sync)
- /api/notifications (list, mark as read)

## Mobile Strategy
- Shared API services between web and mobile
- Ionic Vue components for mobile-native UI
- Capacitor plugins for device features (health data, notifications)
- Responsive design that works on both web and mobile
- Offline capability with sync when online