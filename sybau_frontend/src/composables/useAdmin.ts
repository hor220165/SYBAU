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
  rarity?: string;
  imageFile?: File | null;
}

export interface CreateExerciseDto {
  name: string;
  description?: string;
  category: number;
  difficulty: number;
  unit: 'Reps' | 'Time' | 'Distance';
  xpPerRep: number;
  dailyLimit: number;
}

export interface CreateChestDto {
  name: string;
  price: number;
  commonChance: number;
  rareChance: number;
  epicChance: number;
  legendaryChance: number;
  mythicChance: number;
  itemIds: number[];
  imageFile?: File | null;
}

const shopItemToFormData = (data: CreateShopItemDto) => {
  const formData = new FormData();
  formData.append('name', data.name);
  formData.append('description', data.description);
  formData.append('price', String(data.price));
  formData.append('type', data.type);
  formData.append('xpBoostPercentage', String(data.xpBoostPercentage ?? 0));
  formData.append('coinBoostPercentage', String(data.coinBoostPercentage ?? 0));
  formData.append('rarity', data.rarity || 'Common');
  if (data.imageFile) {
    formData.append('image', data.imageFile);
  }
  return formData;
};

const chestToFormData = (data: CreateChestDto) => {
  const formData = new FormData();
  formData.append('name', data.name);
  formData.append('price', String(data.price));
  formData.append('commonChance', String(data.commonChance));
  formData.append('rareChance', String(data.rareChance));
  formData.append('epicChance', String(data.epicChance));
  formData.append('legendaryChance', String(data.legendaryChance));
  formData.append('mythicChance', String(data.mythicChance ?? 0));
  data.itemIds.map(Number).filter(Boolean).forEach((id, index) => {
    formData.append('itemIds', String(id));
    formData.append('ItemIds', String(id));
    formData.append(`itemIds[${index}]`, String(id));
    formData.append(`ItemIds[${index}]`, String(id));
  });
  if (data.imageFile) {
    formData.append('image', data.imageFile);
    formData.append('Image', data.imageFile);
  }
  return formData;
};

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
      const response = await API.post('/challenges/add', data);
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
      const response = await API.post('/shop/items/add', shopItemToFormData(data), {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Erstellen des Shop-Items';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateShopItem = async (id: number, data: CreateShopItemDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post(`/shop/items/${id}/update`, shopItemToFormData(data), {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Aktualisieren des Shop-Items';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteShopItem = async (id: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/shop/items/${id}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Löschen des Shop-Items';
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

  const createChest = async (data: CreateChestDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post('/shop/chests/add', chestToFormData(data));
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Erstellen der Chest';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateChest = async (id: number, data: CreateChestDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.post(`/shop/chests/${id}/update`, chestToFormData(data));
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Aktualisieren der Chest';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteChest = async (id: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/shop/chests/${id}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Löschen der Chest';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const getAllChests = async () => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.get('/shop/chests');
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Laden der Chests';
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
      const response = await API.put(`/admin/users/${userId}`, data);
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

  const updateExercise = async (id: number, data: CreateExerciseDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.put(`/workouts/exercises/${id}`, data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Aktualisieren der Übung';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const updateExerciseUnit = async (id: number, unit: CreateExerciseDto['unit']) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.put(`/workouts/exercises/${id}/unit`, { unit });
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Aktualisieren der Einheit';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteExercise = async (id: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/workouts/exercises/${id}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || err.response?.data || 'Fehler beim Löschen der Übung';
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

  const updateWorkout = async (id: number, data: CreateWorkoutDto) => {
    isLoading.value = true;
    error.value = '';
    try {
      const response = await API.put(`/workouts/${id}`, data);
      return response.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Aktualisieren des Workouts';
      throw new Error(error.value);
    } finally {
      isLoading.value = false;
    }
  };

  const deleteWorkout = async (id: number) => {
    isLoading.value = true;
    error.value = '';
    try {
      await API.delete(`/workouts/${id}`);
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Fehler beim Löschen des Workouts';
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
    createChest,
    updateChest,
    deleteChest,
    getAllChests,
    // Users
    getAllUsers,
    updateUserRole,
    updateUser,
    deleteUserApi,
    getUserStats,
    // Exercises
    getAllExercises,
    createExercise,
    updateExercise,
    updateExerciseUnit,
    deleteExercise,
    // Workouts
    getAllWorkouts,
    createWorkout,
    updateWorkout,
    deleteWorkout
  };
};
