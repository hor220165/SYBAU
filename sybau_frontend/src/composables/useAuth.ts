import { ref } from 'vue';
import { authService } from '@/services/api';

const user = ref<any>(null);

const syncUserFromStorage = () => {
  const raw = localStorage.getItem('user');

  if (!raw) {
    user.value = null;
    return null;
  }

  try {
    const parsedUser = JSON.parse(raw);
    user.value = parsedUser;
    return parsedUser;
  } catch {
    localStorage.removeItem('user');
    user.value = null;
    return null;
  }
};

const setUser = (nextUser: any | null) => {
  if (!nextUser) {
    localStorage.removeItem('user');
    user.value = null;
    return;
  }

  localStorage.setItem('user', JSON.stringify(nextUser));
  user.value = nextUser;
};

export function useAuth() {
  syncUserFromStorage();

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
        coins: u.coins ?? 0,
        isAdmin: u.isAdmin ?? false,
        avatar: {
          bodyStage: u.avatar?.bodyStage,
          level: u.avatar?.level ?? 0,
          experience: u.avatar?.experience ?? 0,
        }
      };
      console.log('User to store:', userToStore); // DEBUG
      setUser(userToStore);
    }
    return res;
  };

  const register = async (username: string, email: string, password: string) => {
    return authService.register(username, email, password);
  };

  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };

  return { user, login, register, logout, syncUserFromStorage, setUser };
}
