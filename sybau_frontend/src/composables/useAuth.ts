import { ref } from 'vue';
import { authService, normalizeUser, userService } from '@/services/api';

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
      user.value = normalizeUser(res.data) ?? JSON.parse(localStorage.getItem('user') || '{}');
    } catch (e) {
      console.error('Fehler beim Aktualisieren des Profils', e);
    }
  };

  loadUserFromStorage();

  const login = async (email: string, password: string) => {
    const res = await authService.login(email, password);
    const token = res.data?.token;
    const u = res.data?.user;
    if (token) localStorage.setItem('token', token);
    if (u) {
      const userToStore = normalizeUser(u);
      if (userToStore) {
        localStorage.setItem('user', JSON.stringify(userToStore));
        user.value = userToStore;
      }
    }
    await refreshProfile();
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
