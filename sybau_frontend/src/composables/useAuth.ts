import { ref } from 'vue';
import { authService, userService } from '@/services/api';

const user = ref<any>(null);

export function useAuth() {
  const loadUserFromStorage = () => {
    const raw = localStorage.getItem('user');
    if (raw) user.value = JSON.parse(raw);
  };

   const refreshUser = () => {
    loadUserFromStorage();
  };

  const refreshProfile = async () => {
    try {
      const res = await userService.getProfile();
      // getProfile speichert bereits in localStorage, jetzt user.value direkt updaten
      user.value = res.data ? {
        id: res.data.id,
        userName: res.data.userName,
        email: res.data.email,
        coins: res.data.coins,
        isAdmin: res.data.isAdmin,
        avatar: {
          bodyStage: res.data.avatar?.bodyStage,
          level: res.data.avatar?.level,
          experience: res.data.avatar?.experience
        }
      } : JSON.parse(localStorage.getItem('user') || '{}');
    } catch (e) {
      console.error('Fehler beim Aktualisieren des Profils', e);
    }
  };

  loadUserFromStorage();

  const login = async (email: string, password: string) => {
    const res = await authService.login(email, password);
    const token = res.data?.token;
    const u = res.data?.user;
    console.log('Login response:', res.data); // DEBUG
    if (token) localStorage.setItem('token', token);
    if (u) {
      const userToStore = {
        id: u.id,
        userName: u.userName,
        email: u.email,
        coins: u.coins ?? u.Coins ?? 0,
        avatar: { bodyStage: u.avatar?.bodyStage }
      };
      console.log('User to store:', userToStore); // DEBUG
      localStorage.setItem('user', JSON.stringify(userToStore));
      user.value = userToStore;
    }
    return res;
  };

  const register = async (username: string, email: string, password: string) => {
    return authService.register(username, email, password);
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    user.value = null;
  };

  return { user, login, register, logout, refreshUser, refreshProfile };
}
