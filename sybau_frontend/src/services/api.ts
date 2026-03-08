import axios from 'axios';
import { useRouter } from 'vue-router';

const API = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL,
    headers: {
        'Content-Type': 'application/json'
    }
});

// Attach token from localStorage (if exists)
API.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

API.interceptors.response.use(
    (res) => res,
    (err) => {
        // Handle 401 Unauthorized - Token expired oder ungültig
        if (err.response?.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            // Redirect to auth (wenn Vue Router verfügbar)
            try {
                const router = useRouter();
                router.push('/auth');
            } catch (e) {
                window.location.href = '/auth';
            }
        }
        return Promise.reject(err);
    }
);

export const authService = {
    login: (email: string, password: string) =>
        API.post('/auth/login', { email, password }),
    register: (username: string, email: string, password: string) =>
        API.post('/auth/register', { username, email, password })
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
        coins: data.coins,
        isAdmin: data.isAdmin,
        avatar: { 
          bodyStage: data.avatar?.bodyStage,
          level: data.avatar?.level,
          experience: data.avatar?.experience
        }
    }));
    return { data };
    },
    getLeaderboard: () => API.get('/users/leaderboard'),
        //Update Profile bzw Username ändern geht noch NICHT!!!!
    updateProfile: (data: { UserName?: string}) => {
        // Aktualisiere in localStorage UND Backend
        const user = JSON.parse(localStorage.getItem('user') || '{}');
        const updated = { ...user, ...data };
        localStorage.setItem('user', JSON.stringify(updated));
       return API.put('/users/profile', data);
    },
    changePassword: (oldPassword: string, newPassword: string) =>
        API.post("/users/profile/change-password", {
        OldPassword: oldPassword,
        NewPassword: newPassword
}),
    deleteAccount: () =>
        API.delete('/users/account'),
    updateBoostSlots: (slots: Array<number | null>) =>
        API.put('/users/boosts/slots', { slots })
};

export const itemService = {
    getShopItems: () => API.get('/shop/items'),
    getUserItems: () => API.get('/users/items'),
    getBoosts: () => API.get('/boosts'),
    buyItem: (itemId: number) => API.post(`/shop/buy-item/${itemId}`)
};

export const boostService = {
    getBoosts: () => API.get('/boosts'),
    getUserBoosts: () => API.get('/users/boosts')
};

export const workoutService = {
    getWorkouts: (category?: string) =>
        API.get('/workouts', {
            params: category ? { category } : undefined
        }),
    getWorkoutById: (id: number) => API.get(`/workouts/${id}`),
    getExercises: (category?: string) =>
        API.get('/workouts/exercises', {
            params: category ? { category } : undefined
        }),
    createWorkout: (data: unknown) => API.post('/workouts', data),
    createExercise: (data: unknown) => API.post('/workouts/exercises', data)
};

export const adminService = {
    // Challenges
    getChallenges: () => API.get('/admin/challenges'),
    createChallenge: (data: any) => API.post('/admin/challenges', data),
    updateChallenge: (id: number, data: any) => API.put(`/admin/challenges/${id}`, data),
    deleteChallenge: (id: number) => API.delete(`/admin/challenges/${id}`),
    
    // Items (Shop)
    getItems: () => API.get('/admin/items'),
    createShopItem: (data: any) => API.post('/admin/items', data),
    updateShopItem: (id: number, data: any) => API.put(`/admin/items/${id}`, data),
    deleteShopItem: (id: number) => API.delete(`/admin/items/${id}`),
    
    // Users
    getAllUsers: () => API.get('/admin/users'),
    getUserStats: (id: number) => API.get(`/admin/users/${id}/stats`),
    updateUserRole: (id: number, data: any) => API.put(`/admin/users/${id}/role`, data),
    updateUser: (id: number, data: any) => API.put(`/admin/users/${id}`, data),
    deleteUser: (id: number) => API.delete(`/admin/users/${id}`)
};

export default API;