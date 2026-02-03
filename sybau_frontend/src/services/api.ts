import axios from 'axios';

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
        // optional: handle global auth errors (401) here
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
    getProfile: () => API.get('/users/profile'),
    getLeaderboard: () => API.get('/users/leaderboard')
};

export default API;