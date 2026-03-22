<template>
  <div class="admin-container">
    <!-- Header -->
    <Header></Header>
    <Navbar></Navbar>

    <!-- Admin Content -->
    <main class="admin-main">
      <div class="admin-header">
        <h1>🔐 Admin Dashboard</h1>
        <p class="subtitle">Verwalte Challenges, Shop-Items, Workouts und Benutzer</p>
      </div>

      <!-- Tab Navigation -->
      <div class="tab-navigation">
        <button 
          :class="['tab-btn', { active: activeTab === 'challenges' }]"
          @click="activeTab = 'challenges'"
        >
          🎯 Challenges
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'shop' }]"
          @click="activeTab = 'shop'"
        >
          🛍️ Shop
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'users' }]"
          @click="activeTab = 'users'"
        >
          👥 Benutzer
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'workouts' }]"
          @click="activeTab = 'workouts'"
        >
          🏋️ Workouts
        </button>
      </div>

      <!-- Content Sections -->
      <div class="tab-content">
        <!-- Challenges Tab -->
        <div v-if="activeTab === 'challenges'" class="tab-panel">
          <div class="section-header">
            <h2>Challenge Management</h2>
            <button class="btn-primary" @click="openChallengeForm">+ Neue Challenge</button>
          </div>

          <!-- Challenge Form -->
          <div v-if="showChallengeForm" class="form-container">
            <h3>{{ editingChallenge ? 'Challenge bearbeiten' : 'Neue Challenge erstellen' }}</h3>
            <form @submit.prevent="saveChallenge">
              <div class="form-group">
                <label>Name</label>
                <input v-model="challengeForm.name" type="text" required placeholder="z.B. 10km Lauf">
              </div>
              <div class="form-group">
                <label>Beschreibung</label>
                <textarea v-model="challengeForm.description"  placeholder="Beschreibe die Challenge..."></textarea>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>XP Belohnung</label>
                  <input v-model.number="challengeForm.xpReward" type="number" required min="0">
                </div>
                <div class="form-group">
                  <label>Münzen Belohnung</label>
                  <input v-model.number="challengeForm.coinReward" type="number" required min="0">
                </div>
                <div class="form-group">
                  <label>Erforderliches Level</label>
                  <input v-model.number="challengeForm.requiredLevel" type="number" required min="1">
                </div>
              </div>
              <div class="form-actions">
                <button type="submit" class="btn-primary">Speichern</button>
                <button type="button" class="btn-secondary" @click="closeChallengeForm">Abbrechen</button>
              </div>
            </form>
          </div>

          <!-- Challenges List -->
          <div class="list-container">
            <div v-if="challenges.length === 0" class="empty-state">
              <p>Keine Challenges vorhanden</p>
            </div>
            <div v-else class="items-grid">
              <div v-for="challenge in challenges" :key="challenge.id" class="card challenge-card">
                <div class="card-header">
                  <h4>{{ challenge.name }}</h4>
                  <div class="actions">
                    <button class="btn-icon" @click="editChallenge(challenge)" title="Bearbeiten">✏️</button>
                    <button class="btn-icon btn-danger" @click="deleteChallenge(challenge.id)" title="Löschen">🗑️</button>
                  </div>
                </div>
                <p class="description">{{ challenge.description }}</p>
                <div class="card-stats">
                  <span>⭐ {{ challenge.xpReward }} XP</span>
                  <span>💰 {{ challenge.coinReward }} Coins</span>
                  <span>📊 Level {{ challenge.requiredLevel }}+</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Users Tab -->
        <div v-if="activeTab === 'users'" class="tab-panel">
          <div class="section-header">
            <h2>Benutzerverwaltung</h2>
            <input 
              v-model="userSearchQuery"
              type="text" 
              class="search-input"
              placeholder="Nach Benutzername oder Email suchen..."
            >
          </div>

          <!-- Users List -->
          <div class="users-container">
            <div v-if="filteredUsers.length === 0" class="empty-state">
              <p>Keine Benutzer gefunden</p>
            </div>
            <div v-else class="users-table">
              <div class="table-header">
                <div class="col-username">Benutzername</div>
                <div class="col-email">Email</div>
                <div class="col-level">Level</div>
                <div class="col-coins">Münzen</div>
                <div class="col-status">Status</div>
                <div class="col-actions">Aktionen</div>
              </div>
              <div v-for="user in filteredUsers" :key="user.id" class="table-row">
                <div class="col-username">{{ user.username }}</div>
                <div class="col-email">{{ user.email }}</div>
                <div class="col-level">{{ user.avatar?.level ?? 0 }}</div>
                <div class="col-coins">{{ user.coins }}</div>
                <div class="col-status">
                  <span :class="['status-badge', { 'status-admin': user.isAdmin }]">
                    {{ user.isAdmin ? 'Admin' : 'Benutzer' }}
                  </span>
                </div>
                <div class="col-actions">
                  <button 
                    class="btn-icon"
                    @click="toggleAdminStatus(user)"
                    :title="user.isAdmin ? 'Admin-Rechte entfernen' : 'Admin-Rechte geben'"
                  >
                    {{ user.isAdmin ? '👑' : '⭐' }}
                  </button>
                  <button 
                    class="btn-icon"
                    @click="openEditUserForm(user)"
                    title="Bearbeiten"
                  >
                    ✏️
                  </button>
                  <button 
                    class="btn-icon btn-danger"
                    @click="deleteUser(user.id)"
                    title="Löschen"
                  >
                    🗑️
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Edit User Form Modal -->
          <div v-if="showEditUserForm" class="modal-overlay" @click.self="closeEditUserForm">
            <div class="modal-content">
              <h3>Benutzer bearbeiten: {{ editingUser?.username }}</h3>
              <form @submit.prevent="saveUserEdits">
                <div class="form-group">
                  <label>Benutzername</label>
                  <input v-model="editingUser!.username" type="text" required>
                </div>
                <div class="form-group">
                  <label>Email</label>
                  <input v-model="editingUser!.email" type="email" required>
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label>Münzen</label>
                    <input v-model.number="editingUser!.coins" type="number" required min="0">
                  </div>
                  <div class="form-group">
                    <label>Level</label>
                    <input v-model.number="editingUser!.avatar.level" type="number" required min="1">
                  </div>
                </div>
                <div class="form-actions modal-actions">
                  <button type="submit" class="btn-primary">Speichern</button>
                  <button type="button" class="btn-secondary" @click="closeEditUserForm">Abbrechen</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>

        <!-- Shop Tab -->
        <div v-if="activeTab === 'shop'" class="tab-panel">
          <div class="section-header">
            <h2>Shop Item Management</h2>
            <button class="btn-primary" @click="openShopForm">+ Neues Item</button>
          </div>

          <!-- Shop Item Form -->
          <div v-if="showShopForm" class="form-container">
            <h3>{{ editingShopItem ? 'Item bearbeiten' : 'Neues Shop-Item erstellen' }}</h3>
            <form @submit.prevent="saveShopItem">
              <div class="form-group">
                <label>Name</label>
                <input v-model="shopItemForm.name" type="text" required placeholder="z.B. Iron Boots">
              </div>
              <div class="form-group">
                <label>Beschreibung</label>
                <textarea v-model="shopItemForm.description" required placeholder="Beschreibe das Item..."></textarea>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Preis (Münzen)</label>
                  <input v-model.number="shopItemForm.price" type="number" required min="0">
                </div>
                <div class="form-group">
                  <label>Item Typ</label>
                  <select v-model="shopItemForm.type" required>
                    <option value="">-- Wähle einen Typ --</option>
                    <option value="armor">Rüstung</option>
                    <option value="boots">Stiefel</option>
                    <option value="weapon">Waffe</option>
                    <option value="accessory">Zubehör</option>
                    <option value="booster">Booster</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>XP Boost % (optional)</label>
                  <input v-model.number="shopItemForm.xpBoostPercentage" type="number" min="0" max="100">
                </div>
              </div>
              <div class="form-actions">
                <button type="submit" class="btn-primary">Speichern</button>
                <button type="button" class="btn-secondary" @click="closeShopForm">Abbrechen</button>
              </div>
            </form>
          </div>

          <!-- Shop Items List -->
          <div class="list-container">
            <div v-if="shopItems.length === 0" class="empty-state">
              <p>Keine Shop-Items vorhanden</p>
            </div>
            <div v-else class="items-grid">
              <div v-for="item in shopItems" :key="item.id" class="card shop-card">
                <div class="card-header">
                  <h4>{{ item.name }}</h4>
                  <div class="actions">
                    <button class="btn-icon" @click="editShopItem(item)" title="Bearbeiten">✏️</button>
                    <button class="btn-icon btn-danger" @click="deleteShopItem(item.id)" title="Löschen">🗑️</button>
                  </div>
                </div>
                <p class="description">{{ item.description }}</p>
                <div class="card-stats">
                  <span>💰 {{ item.price }} Münzen</span>
                  <span>📦 {{ item.type }}</span>
                  <span v-if="item.xpBoostPercentage > 0">⚡ +{{ item.xpBoostPercentage }}% XP</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Workouts Tab -->
        <div v-if="activeTab === 'workouts'" class="tab-panel">
          <AdminWorkoutPanel />
        </div>

        

      <!-- Status Messages -->
      <div v-if="statusMessage" :class="['status-message', statusType]">
        {{ statusMessage }}
      </div>
    </main>
     <!-- Footer -->
    <FooterComponent />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import AdminWorkoutPanel from '@/components/AdminWorkoutPanel.vue';
import { useAdmin } from '@/composables/useAdmin';
import type { Challange } from '@/models/Challange';
import type { item } from '@/models/Item';
import type { user } from '@/models/User';

// State
const activeTab = ref<'challenges' | 'shop' | 'users' | 'workouts'>('challenges');

// Status Messages
const statusMessage = ref('');
const statusType = ref<'success' | 'error'>('success');

// Challenge Management
const showChallengeForm = ref(false);
const editingChallenge = ref<Challange | null>(null);
const challengeForm = ref({
  name: '',
  description: '',
  xpReward: 0,
  coinReward: 0,
  requiredLevel: 1
});
const challenges = ref<Challange[]>([]);

// Shop Management
const showShopForm = ref(false);
const editingShopItem = ref<item | null>(null);
const shopItemForm = ref({
  name: '',
  description: '',
  price: 0,
  type: '',
  xpBoostPercentage: 0
});
const shopItems = ref<item[]>([]);

// User Management
const userSearchQuery = ref('');
const users = ref<user[]>([]);
const showEditUserForm = ref(false);
const editingUser = ref<user | null>(null);

const filteredUsers = computed(() => {
  if (!userSearchQuery.value) return users.value;
  const query = userSearchQuery.value.toLowerCase();
  return users.value.filter(user => 
    user.username.toLowerCase().includes(query) ||
    user.email.toLowerCase().includes(query)
  );
});

// Use the admin composable
const { 
  createChallenge,
  updateChallenge,
  deleteChallenge: deleteChallengeApi,
  getAllChallenges,
  createShopItem,
  updateShopItem,
  deleteShopItem: deleteShopItemApi,
  getAllShopItems,
  getAllUsers,
  updateUserRole,
  updateUser,
  deleteUserApi
} = useAdmin();

const showMessage = (message: string, type: 'success' | 'error' = 'success') => {
  statusMessage.value = message;
  statusType.value = type;
  setTimeout(() => {
    statusMessage.value = '';
  }, 4000);
};

// ===== CHALLENGES =====
const openChallengeForm = () => {
  editingChallenge.value = null;
  challengeForm.value = {
    name: '',
    description: '',
    xpReward: 0,
    coinReward: 0,
    requiredLevel: 1
  };
  showChallengeForm.value = true;
};

const closeChallengeForm = () => {
  showChallengeForm.value = false;
  editingChallenge.value = null;
};

const editChallenge = (challenge: any) => {
  editingChallenge.value = challenge;
  challengeForm.value = { ...challenge };
  showChallengeForm.value = true;
};

const saveChallenge = async () => {
  try {
    if (editingChallenge.value) {
      await updateChallenge(editingChallenge.value.id, challengeForm.value);
      showMessage('Challenge aktualisiert! ✓');
    } else {
      await createChallenge(challengeForm.value);
      showMessage('Challenge erstellt! ✓');
    }
    closeChallengeForm();
    await loadChallenges();
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Speichern', 'error');
  }
};

const deleteChallenge = async (id: number) => {
  if (confirm('Challenge wirklich löschen?')) {
    try {
      await deleteChallengeApi(id);
      showMessage('Challenge gelöscht! ✓');
      await loadChallenges();
    } catch (err: any) {
      showMessage(err.message || 'Fehler beim Löschen', 'error');
    }
  }
};

const loadChallenges = async () => {
  try {
    const res = await getAllChallenges();
    challenges.value = res.data || res || [];
  } catch (err) {
    console.error('Fehler beim Laden der Challenges:', err);
    showMessage('Fehler beim Laden der Challenges', 'error');
  }
};

// ===== SHOP ITEMS =====
const openShopForm = () => {
  editingShopItem.value = null;
  shopItemForm.value = {
    name: '',
    description: '',
    price: 0,
    type: '',
    xpBoostPercentage: 0
  };
  showShopForm.value = true;
};

const closeShopForm = () => {
  showShopForm.value = false;
  editingShopItem.value = null;
};

const editShopItem = (item: any) => {
  editingShopItem.value = item;
  shopItemForm.value = { ...item };
  showShopForm.value = true;
};

const saveShopItem = async () => {
  try {
    if (editingShopItem.value) {
      await updateShopItem(editingShopItem.value.id, shopItemForm.value);
      showMessage('Shop-Item aktualisiert! ✓');
    } else {
      await createShopItem(shopItemForm.value);
      showMessage('Shop-Item erstellt! ✓');
    }
    closeShopForm();
    await loadShopItems();
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Speichern', 'error');
  }
};

const deleteShopItem = async (id: number) => {
  if (confirm('Shop-Item wirklich löschen?')) {
    try {
      await deleteShopItemApi(id);
      showMessage('Shop-Item gelöscht! ✓');
      await loadShopItems();
    } catch (err: any) {
      showMessage(err.message || 'Fehler beim Löschen', 'error');
    }
  }
};

const loadShopItems = async () => {
  try {
    const res = await getAllShopItems();
    shopItems.value = res.data || res || [];
  } catch (err) {
    console.error('Fehler beim Laden der Shop-Items:', err);
    showMessage('Fehler beim Laden der Shop-Items', 'error');
  }
};

// ===== USERS =====
const loadUsers = async () => {
  try {
    const res = await getAllUsers();
    const rawUsers = res.data || res || [];
    // Normalisiere camelCase zu lowercase username
    users.value = rawUsers.map((u: any) => ({
      ...u,
      username: u.userName ?? u.username
    }));
  } catch (err) {
    console.error('Fehler beim Laden der Benutzer:', err);
  }
};

const toggleAdminStatus = async (user: any) => {
  try {
    await updateUserRole(user.id, !user.isAdmin);
    showMessage(`Admin-Status geändert! ✓`);
    await loadUsers();
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Ändern des Admin-Status', 'error');
  }
};

const openEditUserForm = (user: any) => {
  editingUser.value = { ...user };
  showEditUserForm.value = true;
};

const closeEditUserForm = () => {
  showEditUserForm.value = false;
  editingUser.value = null;
};

const saveUserEdits = async () => {
  try {
    if (editingUser.value) {
      await updateUser(editingUser.value.id, editingUser.value);
      showMessage('Benutzer aktualisiert! ✓');
      closeEditUserForm();
      await loadUsers();
    }
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Aktualisieren', 'error');
  }
};

const deleteUser = async (id: number) => {
  if (confirm('Benutzer wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden!')) {
    try {
      await deleteUserApi(id);
      showMessage('Benutzer gelöscht! ✓');
      await loadUsers();
    } catch (err: any) {
      showMessage(err.message || 'Fehler beim Löschen', 'error');
    }
  }
};

// Load data on mount
onMounted(async () => {
  await loadChallenges();
  await loadShopItems();
  await loadUsers();
});
</script>

<style scoped>
.admin-container {
  width: 100%;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.admin-main {
  padding: 40px 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.admin-header {
  text-align: center;
  margin-bottom: 50px;
  color: white;
}

.admin-header h1 {
  font-size: 2.5em;
  margin: 0;
  font-weight: bold;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
}

.subtitle {
  font-size: 1.1em;
  opacity: 0.95;
  margin: 10px 0 0 0;
}

/* Tab Navigation */
.tab-navigation {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
  justify-content: center;
  flex-wrap: wrap;
}

.tab-btn {
  padding: 12px 28px;
  font-size: 1em;
  border: none;
  border-radius: 25px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.tab-btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.tab-btn.active {
  background: white;
  color: #667eea;
  font-weight: 600;
}

/* Tab Content */
.tab-panel {
  background: white;
  border-radius: 15px;
  padding: 30px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  flex-wrap: wrap;
  gap: 20px;
}

.section-header h2 {
  margin: 0;
  color: #333;
  font-size: 1.8em;
}

.search-input {
  padding: 10px 20px;
  border: 2px solid #e0e0e0;
  border-radius: 20px;
  font-size: 1em;
  width: 300px;
  max-width: 100%;
}

/* Form Styles */
.form-container {
  background: #f8f9fa;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  padding: 25px;
  margin-bottom: 30px;
}

.form-container h3 {
  margin-top: 0;
  color: #333;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #333;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 12px;
  border: 1px solid #d0d0d0;
  border-radius: 8px;
  font-size: 1em;
  font-family: inherit;
  transition: border-color 0.3s ease;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-group textarea {
  resize: vertical;
  min-height: 100px;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.btn-primary,
.btn-secondary {
  padding: 12px 28px;
  border: none;
  border-radius: 8px;
  font-size: 1em;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
}

.btn-secondary {
  background: #e0e0e0;
  color: #333;
}

.btn-secondary:hover {
  background: #d0d0d0;
}

/* Items Grid */
.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.card {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 10px;
  padding: 20px;
  transition: all 0.3s ease;
}

.card:hover {
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
  transform: translateY(-5px);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 12px;
}

.card-header h4 {
  margin: 0;
  color: #333;
  flex: 1;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn-icon {
  background: none;
  border: none;
  font-size: 1.2em;
  cursor: pointer;
  transition: transform 0.3s ease;
}

.btn-icon:hover {
  transform: scale(1.2);
}

.btn-icon.btn-danger:hover {
  filter: brightness(1.2);
}

.description {
  color: #666;
  margin: 10px 0;
  font-size: 0.95em;
}

.card-stats {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 0.9em;
}

.card-stats span {
  padding: 6px 12px;
  background: #f0f0f0;
  border-radius: 6px;
  color: #555;
}

/* Users Table */
.users-container {
  background: white;
  color: #333;
}

.users-table {
  overflow-x: auto;
}

.table-header {
  display: grid;
  grid-template-columns: 2fr 2fr 1fr 1fr 1fr 2fr;
  gap: 15px;
  padding: 15px;
  background: #f0f0f0;
  border-radius: 8px;
  font-weight: 600;
  color: #333;
  margin-bottom: 10px;
}

.table-row {
  display: grid;
  grid-template-columns: 2fr 2fr 1fr 1fr 1fr 2fr;
  gap: 15px;
  padding: 15px;
  border-bottom: 1px solid #e0e0e0;
  align-items: center;
  color: #333;
}

.table-row:hover {
  background: #f9f9f9;
}

.col-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-start;
}

.status-badge {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 20px;
  background: #e0e0e0;
  color: #333;
  font-size: 0.85em;
  font-weight: 600;
}

.status-badge.status-admin {
  background: #ffd700;
  color: #333;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 15px;
  padding: 30px;
  max-width: 500px;
  width: 90%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-content h3 {
  margin-top: 0;
  color: #333;
}

.modal-actions {
  justify-content: flex-end;
}

/* Status Messages */
.status-message {
  position: fixed;
  bottom: 20px;
  right: 20px;
  padding: 16px 24px;
  border-radius: 8px;
  font-weight: 600;
  z-index: 2000;
  animation: slideIn 0.3s ease-out;
}

.status-message.success {
  background: #4caf50;
  color: white;
}

.status-message.error {
  background: #f44336;
  color: white;
}

@keyframes slideIn {
  from {
    transform: translateX(400px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
  font-size: 1.1em;
}

/* Responsive */
@media (max-width: 768px) {
  .admin-header h1 {
    font-size: 1.8em;
  }

  .tab-navigation {
    flex-direction: column;
  }

  .tab-btn {
    width: 100%;
  }

  .section-header {
    flex-direction: column;
    align-items: stretch;
  }

  .search-input {
    width: 100%;
  }

  .items-grid {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .table-header,
  .table-row {
    grid-template-columns: 1fr;
    gap: 10px;
  }

  .col-username::before { content: "Benutzername: "; font-weight: 600; }
  .col-email::before { content: "Email: "; font-weight: 600; }
  .col-level::before { content: "Level: "; font-weight: 600; }
  .col-coins::before { content: "Münzen: "; font-weight: 600; }
  .col-status::before { content: "Status: "; font-weight: 600; }
  .col-actions::before { content: "Aktionen: "; font-weight: 600; }
}
</style>