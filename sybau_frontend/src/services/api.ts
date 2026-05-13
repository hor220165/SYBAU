import axios from 'axios';
import { API_BASE_URL, resolveApiUrl } from '@/config';

const API = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json'
    }
});

export function resolveMediaUrl(path?: string | null) {
    if (!path) return '';
    return resolveApiUrl(path);
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
    const { data } = await API.get('/users/profile');  // holt alles vom Backend
    // Wichtige Userinfos in LocalStorage speichern
    localStorage.setItem('user', JSON.stringify({ 
        id: data.id, 
        userName: data.userName, 
        email: data.email,
        profileImageUrl: data.profileImageUrl,
        coins: data.coins,
        totalXp: data.totalXp ?? data.TotalXp,
        isAdmin: data.isAdmin,
        avatar: { 
          bodyStage: data.avatar?.bodyStage,
          level: data.avatar?.level,
          experience: data.avatar?.experience
        }
    }));
    return { data };
    },
    getPublicProfile: (id: number) =>
        API.get(`/users/${id}/profile`),
    getLeaderboard: () => API.get('/users/leaderboard'),
    updateProfile: (data: { UserName?: string}) => {
        // Aktualisiere in localStorage UND Backend
        const user = JSON.parse(localStorage.getItem('user') || '{}');
        const updated = { ...user, ...data };
        localStorage.setItem('user', JSON.stringify(updated));
       return API.put('/users/profile', data);
    },
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
    getWeeklyActivity: (from: string, to: string) =>
        API.get(`/users/profile/weekly-activity?from=${from}&to=${to}`),
    getRecentActivities: (limit = 10) =>
        API.get(`/users/profile/recent-activities?limit=${limit}`)
};

export const itemService = {
    getShopItems: () => API.get('/shop/items'),
    getChests: () => API.get('/shop/chests'),
    getUserItems: () => API.get('/users/items'),
    getBoosts: () => API.get('/boosts'),
    buyItem: (itemId: number) => API.post(`/shop/buy-item/${itemId}`),
    sellItem: (itemId: number) => API.post(`/shop/sell-item/${itemId}`),
    openChest: (chestId: number) => API.post(`/shop/chests/${chestId}/open`)
};

export const boostService = {
    getBoosts: () => API.get('/boosts'),
    getUserBoosts: () => API.get('/users/boosts')
};

export const adminService = {
    // Challenges
    getChallenges: () => API.get('/admin/challenges'),
    createChallenge: (data: any) => API.post('/admin/challenges', data),
    updateChallenge: (id: number, data: any) => API.put(`/admin/challenges/${id}`, data),
    deleteChallenge: (id: number) => API.delete(`/admin/challenges/${id}`),
    
    // Items (Shop)
    getItems: () => API.get('/admin/items'),
    createShopItem: (data: any) => API.post('/shop/items/add', data, {
        headers: { 'Content-Type': 'multipart/form-data' }
    }),
    updateShopItem: (id: number, data: any) => API.post(`/shop/items/${id}/update`, data, {
        headers: { 'Content-Type': 'multipart/form-data' }
    }),
    deleteShopItem: (id: number) => API.delete(`/shop/items/${id}`),
    createChest: (data: any) => API.post('/shop/chests/add', data),
    updateChest: (id: number, data: any) => API.post(`/shop/chests/${id}/update`, data),
    deleteChest: (id: number) => API.delete(`/shop/chests/${id}`),
    getChests: () => API.get('/shop/chests'),
    
    // Users
    getAllUsers: () => API.get('/admin/users'),
    getUserStats: (id: number) => API.get(`/admin/users/${id}/stats`),
    updateUserRole: (id: number, data: any) => API.put(`/admin/users/${id}/role`, data),
    updateUser: (id: number, data: any) => API.put(`/admin/users/${id}`, data),
    deleteUser: (id: number) => API.delete(`/admin/users/${id}`),
    createExercise: (data: any) => API.post('/workouts/exercises', data),
    updateExercise: (id: number, data: any) => API.put(`/workouts/exercises/${id}`, data),
    updateExerciseUnit: (id: number, unit: string) => API.put(`/workouts/exercises/${id}/unit`, { unit }),
    deleteExercise: (id: number) => API.delete(`/workouts/exercises/${id}`)
};

export const workoutService = {
    getExercises: (category?: string) => API.get('/workouts/exercises', { params: category ? { category } : {} }),
    getWorkouts: (category?: string) => API.get('/workouts', { params: category ? { category } : {} }),
    getWorkoutById: (id: number) => API.get(`/workouts/${id}`),
    createWorkout: (data: any) => API.post('/workouts', data),
    updateWorkout: (id: number, data: any) => API.put(`/workouts/${id}`, data),
    deleteWorkout: (id: number) => API.delete(`/workouts/${id}`),
    createExercise: (data: any) => API.post('/workouts/exercises', data),
    updateExercise: (id: number, data: any) => API.put(`/workouts/exercises/${id}`, data),
    updateExerciseUnit: (id: number, unit: string) => API.put(`/workouts/exercises/${id}/unit`, { unit }),
    deleteExercise: (id: number) => API.delete(`/workouts/exercises/${id}`),
    logExercise: (exerciseId: number, reps: number, elapsedSeconds?: number) => API.post('/workouts/exercises/log', { exerciseId, reps, ...(elapsedSeconds != null ? { elapsedSeconds } : {}) })
};

export const questService = {
    getMyQuests: () => API.get('/quests'),
    getStats: () => API.get('/quests/stats'),
    claimReward: (userQuestId: number) => API.post(`/quests/${userQuestId}/claim`),
    logActivity: (type: 'Steps' | 'Kilometers', value: number) => API.post('/quests/activity', { type, value }),
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
