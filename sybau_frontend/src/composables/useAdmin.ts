import API from '@/services/api';
import { ref } from 'vue';

export interface CreateChallengeDto {
  name: string;
  description?: string;
  xpReward: number;
  coinReward: number;
  requiredLevel: number;
}

export interface CreateShopItemDto {
  name: string;
  description: string;
  price: number;
  type: string;
  xpBoostPercentage?: number;
  coinBoostPercentage?: number;
}

export interface CreateExerciseDto {
  name: string;
  description?: string;
  category: number;
  difficulty: number;
  xpPerRep: number;
  dailyLimit: number;
}

export interface CreateWorkoutDto {
  name: string;
  description?: string;
  category: number;
  exercises: { exerciseId: number; dailyLimit: number }[];
}

export interface UpdateUserDto {
  username?: string;
  email?: string;
  coins?: number;
  level?: number;
}

export const useAdmin = () => {
  const isLoading = ref(false);
  const error = ref('');

  // ===== CHALLENGE MANAGEMENT =====
  const createChallenge = async (data: CreateChallengeDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post('/challenge/add', data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Erstellen der Challenge';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateChallenge = async (id: number, data: CreateChallengeDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.put(`/admin/challenges/${id}`, data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Aktualisieren der Challenge';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteChallenge = async (id: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/admin/challenges/${id}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Löschen der Challenge';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const getAllChallenges = async () => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get('/challenges');
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Challenges';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  // ===== SHOP ITEM MANAGEMENT =====
  const createShopItem = async (data: CreateShopItemDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post('/shop/items/add', data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Erstellen des Shop-Items';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateShopItem = async (id: number, data: CreateShopItemDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.put(`/shop/items/${id}`, data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Aktualisieren des Shop-Items';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteShopItem = async (id: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/admin/items/${id}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Löschen des Shop-Items';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const getAllShopItems = async () => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get('/shop/items');
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Shop-Items';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  // ===== USER MANAGEMENT =====
  const getAllUsers = async () => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get('/users');
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Benutzer';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateUserRole = async (userId: number, isAdmin: boolean) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.put(`/admin/users/${userId}/role`, { isAdmin });
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Ändern des Admin-Status';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateUser = async (userId: number, data: UpdateUserDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      console.log(data);
      const response = await API.put(`/admin/users/${userId}`, data);
      console.log('Benutzer aktualisiert:', data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Aktualisieren des Benutzers';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteUserApi = async (userId: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/admin/users/${userId}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Löschen des Benutzers';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  // ===== EXERCISE MANAGEMENT =====
  const getAllExercises = async () => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get('/workouts/exercises');
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Übungen';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const createExercise = async (data: CreateExerciseDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post('/workouts/exercises', data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Erstellen der Übung';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  // ===== WORKOUT MANAGEMENT =====
  const getAllWorkouts = async () => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get('/workouts');
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Workouts';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const createWorkout = async (data: CreateWorkoutDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post('/workouts', data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Erstellen des Workouts';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  // ===== USER STATISTICS =====
  const getUserStats = async (userId: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get(`/admin/users/${userId}/stats`);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Benutzerstatistiken';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  return {
    isLoading,
    error,
    // Challenges
    createChallenge,
    updateChallenge,
    deleteChallenge,
    getAllChallenges,
    // Shop Items
    createShopItem,
    updateShopItem,
    deleteShopItem,
    getAllShopItems,
    // Users
    getAllUsers,
    updateUserRole,
    updateUser,
    deleteUserApi,
    getUserStats,
    // Exercises
    getAllExercises,
    createExercise,
    // Workouts
    getAllWorkouts,
    createWorkout
  };
};
