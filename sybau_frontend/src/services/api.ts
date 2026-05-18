import axios from 'axios';
import { API_BASE_URL, resolveApiUrl } from '@/config';

const API = axios.create({
    baseURL: API_BASE_URL,
    timeout: 30000,
    headers: {
        'Content-Type': 'application/json'
    }
});

export function resolveMediaUrl(path?: string | null) {
    if (!path) return '';
    return resolveApiUrl(path);
}

export function normalizeUser(data: any) {
    if (!data) return null;
    const avatar = data.avatar ?? data.Avatar ?? {};
    return {
        id: data.id ?? data.Id,
        userName: data.userName ?? data.UserName,
        email: data.email ?? data.Email,
        profileImageUrl: data.profileImageUrl ?? data.ProfileImageUrl,
        coins: data.coins ?? data.Coins ?? 0,
        totalXp: data.totalXp ?? data.TotalXp ?? 0,
        isAdmin: data.isAdmin ?? data.IsAdmin ?? false,
        isProfilePrivate: data.isProfilePrivate ?? data.IsProfilePrivate ?? false,
        avatar: {
            id: avatar.id ?? avatar.Id,
            bodyStage: avatar.bodyStage ?? avatar.BodyStage,
            level: avatar.level ?? avatar.Level ?? 1,
            experience: avatar.experience ?? avatar.Experience ?? 0,
            xpForNextLevel: avatar.xpForNextLevel ?? avatar.XpForNextLevel ?? 1000,
            boost1: avatar.boost1 ?? avatar.Boost1,
            boost2: avatar.boost2 ?? avatar.Boost2,
            boost3: avatar.boost3 ?? avatar.Boost3,
            boost4: avatar.boost4 ?? avatar.Boost4
        }
    };
}

// Attach token from localStorage (if exists)
API.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    if (config.data instanceof FormData && config.headers) {
        delete config.headers['Content-Type'];
    }
    return config;
});

API.interceptors.response.use(
    (res) => res,
    (err) => {
        // Handle 401 Unauthorized - Token expired oder ungültig
        // Auth-Endpunkte (login/register) ausschließen, damit deren Fehler normal im catch landen
        const url = err.config?.url || '';
        const isAuthRequest = url.includes('/auth/');
        if (err.response?.status === 401 && !isAuthRequest) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/auth';
        }
        return Promise.reject(err);
    }
);

export const authService = {
    login: (email: string, password: string) =>
        API.post('/auth/login', { email, password }),
    register: (username: string, email: string, password: string) =>
        API.post('/auth/register', { username, email, password }),
    googleLogin: (idToken: string) =>
        API.post('/auth/google', { idToken })
};

export const userService = {
    // Hole User aus localStorage statt API (falls bereits vorhanden)
    getProfile: async () => {
        const { data } = await API.get('/users/profile');
        const normalized = normalizeUser(data);
        if (normalized) {
            localStorage.setItem('user', JSON.stringify(normalized));
        }
        return { data };
    },
    getPublicProfile: (id: number) =>
        API.get(`/users/${id}/profile`),
    getLeaderboard: () => API.get('/users/leaderboard'),
    updateProfile: (data: { UserName?: string; IsProfilePrivate?: boolean }) =>
        API.put('/users/profile', data),
    uploadProfileImage: (file: File) => {
        const formData = new FormData();
        formData.append('image', file);
        return API.post('/users/profile/image', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
    },
    removeProfileImage: () =>
        API.delete('/users/profile/image'),
    changePassword: (oldPassword: string, newPassword: string) =>
        API.post("/users/profile/change-password", {
        OldPassword: oldPassword,
        NewPassword: newPassword
}),
    deleteAccount: () =>
        API.delete('/users/profile'),
    updateBoostSlots: (slots: Array<number | null>) =>
        API.put('/users/boosts/slots', { slots }),
    getUserBoosters: () =>
        API.get('/users/boosts'),
    getStreaks: () =>
        API.get('/users/profile/streaks'),
    getActivityYears: () =>
        API.get('/users/profile/activity-years'),
    getWeeklyActivity: (from: string, to: string) =>
        API.get(`/users/profile/weekly-activity?from=${from}&to=${to}`),
    getRecentActivities: (limit = 10) =>
        API.get(`/users/profile/recent-activities?limit=${limit}`)
};

export const itemService = {
    getShopItems: () => API.get('/shop/items'),
    getDailyShop: () => API.get('/shop/daily'),
    getChests: () => API.get('/shop/chests'),
    getUserItems: () => API.get('/users/items'),
    buyItem: (itemId: number) => API.post(`/shop/buy-item/${itemId}`),
    sellItem: (itemId: number) => API.post(`/shop/sell-item/${itemId}`),
    openChest: (chestId: number) => API.post(`/shop/chests/${chestId}/open`)
};

export const workoutService = {
    getExercises: (category?: string) => {
        const today = new Date();
        const date = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
        return API.get('/workouts/exercises', { params: { ...(category ? { category } : {}), date } });
    },
    getWorkouts: (category?: string) => API.get('/workouts', { params: category ? { category } : {} }),
    getWorkoutById: (id: number) => API.get(`/workouts/${id}`),
    createWorkout: (data: any) => API.post('/workouts', data),
    updateWorkout: (id: number, data: any) => API.put(`/workouts/${id}`, data),
    deleteWorkout: (id: number) => API.delete(`/workouts/${id}`),
    createExercise: (data: any) => API.post('/workouts/exercises', data),
    updateExercise: (id: number, data: any) => API.put(`/workouts/exercises/${id}`, data),
    updateExerciseUnit: (id: number, unit: string) => API.put(`/workouts/exercises/${id}/unit`, { unit }),
    deleteExercise: (id: number) => API.delete(`/workouts/exercises/${id}`),
    logExercise: (exerciseId: number, reps: number, elapsedSeconds?: number) => {
        const today = new Date();
        const date = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
        return API.post('/workouts/exercises/log', { exerciseId, reps, date, ...(elapsedSeconds != null ? { elapsedSeconds } : {}) });
    }
};

export const questService = {
    getMyQuests: () => API.get('/quests'),
    getStats: () => API.get('/quests/stats'),
    claimReward: (userQuestId: number) => API.post(`/quests/${userQuestId}/claim`),
    logActivity: (type: 'Steps' | 'Kilometers', value: number) => {
        const today = new Date();
        const date = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
        return API.post('/quests/activity', { type, value, date });
    },
    getTodayActivity: () => API.get('/quests/activity/today')
};

export const achievementService = {
    getAll: () => API.get('/achievements'),
    getProfileStats: () => API.get('/achievements/stats'),
    getTodayXp: () => API.get('/achievements/today-xp')
};
export const friendService = {
    // Freundschaften
    getFriends: () => API.get('/friends'),
    getPendingRequests: () => API.get('/friends/requests'),
    getSentRequests: () => API.get('/friends/requests/sent'),
    sendFriendRequest: (userName: string) => API.post('/friends/request', { userName }),
    acceptRequest: (id: number) => API.post(`/friends/requests/${id}/accept`),
    declineRequest: (id: number) => API.post(`/friends/requests/${id}/decline`),
    removeFriend: (id: number) => API.delete(`/friends/${id}`),
    getFriendsLeaderboard: () => API.get('/friends/leaderboard'),

    // Freundes-Challenges
    getChallenges: () => API.get('/friends/challenges'),
    getPendingChallenges: () => API.get('/friends/challenges/pending'),
    createChallenge: (data: any) => API.post('/friends/challenges', data),
    acceptChallenge: (id: number) => API.post(`/friends/challenges/${id}/accept`),
    declineChallenge: (id: number) => API.post(`/friends/challenges/${id}/decline`),
    deleteChallenge: (id: number) => API.delete(`/friends/challenges/${id}`),
    hideChallenge: (id: number) => API.delete(`/friends/challenges/${id}`),
    updateProgress: (id: number, amount: number) => API.put(`/friends/challenges/${id}/progress`, { amount })
};

export default API;
