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
    // Nur Basis-Userinfos in LocalStorage speichern
    localStorage.setItem('user', JSON.stringify({ 
        id: data.id, 
        userName: data.userName, 
        email: data.email 
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
    getItems: () => API.get('/items'),
    getUserItems: () => API.get('/users/items'),
    getBoosts: () => API.get('/boosts')
};

export const boostService = {
    getBoosts: () => API.get('/boosts'),
    getUserBoosts: () => API.get('/users/boosts')
};

export default API;