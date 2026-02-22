<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import Navbar from "@/components/Navbar.vue";
import Header from "@/components/Header.vue";
import { useAuth } from '@/composables/useAuth';
import { useLeaderboard } from '@/composables/useLeaderboard';
import { userService } from '@/services/api';

const router = useRouter();
const { user, logout } = useAuth();
const { sortedLeaderboard, loadLeaderboard } = useLeaderboard();

// Profile editing
const editingUsername = ref<string>(user.value?.username ?? user.value?.UserName ?? '');
const savingProfile = ref(false);

async function saveProfile() {
  savingProfile.value = true;
  try {
    await userService.updateProfile({ UserName: editingUsername.value });
    // Update local user object
    const u = { ...user.value };
    if ('username' in u) u.username = editingUsername.value;
    else u.UserName = editingUsername.value;
    user.value = u;
    localStorage.setItem('user', JSON.stringify(u));
    alert('Profil gespeichert!');
  } catch (err: any) {
    if (err.response?.status === 401) {
      alert('Session abgelaufen. Bitte melden Sie sich erneut an.');
      logout();
      router.push('/auth');
    } else {
      alert('Fehler beim Speichern: ' + (err.response?.data?.message || err.message));
    }
  } finally {
    savingProfile.value = false;
  }
}

// Progress (read-only)
const level = computed(() => user.value?.avatar.level ?? user.value?.avatar.Level ?? 1);
const experience = computed(() => user.value?.avatar.experience ?? user.value?.avatar.Experience ?? 0);
const completedChallenges = ref(0);
const leaderboardPosition = computed(() => {
  const name = user.value?.username ?? user.value?.UserName ?? user.value?.userName ?? '';
  const idx = sortedLeaderboard.value.findIndex((u: any) => (u.UserName ?? u.username ?? '').toLowerCase() === name.toLowerCase());
  if (idx >= 0 && idx < sortedLeaderboard.value.length) {
    const rank = sortedLeaderboard.value[idx]?.Rank;
    return rank ?? idx + 1;
  }
  return '—';
});


// Security actions
const oldPassword = ref('');
const newPassword = ref('');
const changingPassword = ref(false);

async function changePassword() {
  if (!oldPassword.value || !newPassword.value) return alert('Bitte beide Felder ausfüllen.');
  changingPassword.value = true;
  try {
    await userService.changePassword(oldPassword.value, newPassword.value);
    oldPassword.value = '';
    newPassword.value = '';
    alert('Passwort erfolgreich geändert!');
  } catch (err: any) {
    if (err.response?.status === 401) {
      alert('Session abgelaufen. Bitte melden Sie sich erneut an.');
      logout();
      router.push('/auth');
    } else {
      alert(err.response?.data);
    }
  } finally {
    changingPassword.value = false;
  }
}

async function deleteAccount() {
  if (!confirm('Account wirklich löschen? Diese Aktion ist endgültig.')) return;
  try {
    await userService.deleteAccount();
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    logout();
    router.push('/auth');
  } catch (err: any) {
    alert('Fehler beim Löschen: ' + (err.response?.data?.message || err.message));
  }
}

onMounted(async () => {
  try {
    // Profile vom Backend laden (speichert in localStorage)
    await userService.getProfile();
    // Aus localStorage laden statt rohe API Response
    user.value = JSON.parse(localStorage.getItem('user') || '{}');
    editingUsername.value = user.value.userName;

    // Leaderboard laden
    await loadLeaderboard();
  } catch (err) {
    console.error('Fehler beim Laden von Profile oder Leaderboard', err);
  }
});
</script>

<template>
  <div class="dashboard-container">
    <Header />
    <Navbar />

    <main class="main-content profile-grid">
      <!-- Profile -->
      <section class="card profile-card">
        <h2>Profil</h2>
        <div class="field">
          <label>Benutzername</label>
          <input v-model="editingUsername" />
        </div>
        <div class="field">
          <label>E-Mail</label>
          <input :value="user?.email ?? user?.Email ?? ''" readonly />
        </div>
        <div class="actions">
          <button class="btn-primary" @click="saveProfile" :disabled="savingProfile">Speichern</button>
        </div>
      </section>

      <!-- Progress -->
      <section class="card progress-card">
        <h2>Fortschritt</h2>
        <div class="progress-row"><strong>Level:</strong> {{ level }}</div>
        <div class="progress-row"><strong>XP:</strong> {{ experience }}</div>
        <div class="progress-row"><strong>Absolvierte Challenges:</strong> {{ completedChallenges }}</div>
        <div class="progress-row"><strong>Leaderboard-Position:</strong> {{ leaderboardPosition }}</div>
      </section>

      <!-- Security -->
      <section class="card security-card">
        <h2>Sicherheit</h2>
        <div class="field">
          <label>Altes Passwort</label>
          <input type="password" v-model="oldPassword" />
        </div>
        <div class="field">
          <label>Neues Passwort</label>
          <input type="password" v-model="newPassword" />
        </div>
        <div class="actions">
          <button class="btn-primary" @click="changePassword" :disabled="changingPassword">Passwort ändern</button>
        </div>

        <hr />
        <div class="danger">
          <h3>Account löschen</h3>
          <p>Diese Aktion ist endgültig.</p>
          <button class="btn-danger" @click="deleteAccount">Account löschen</button>
        </div>
      </section>
    </main>

  </div>
</template>

<style scoped>
.main-content.profile-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  padding: 40px;
  max-width: 1200px;
  margin: 0 auto;
}
.card {
  background: rgba(15,23,42,0.6);
  padding: 18px;
  border-radius: 12px;
  border: 1px solid rgba(59,130,246,0.06);
}
.profile-card { grid-column: 1 / 2; }
.security-card { grid-column: 1 / 2; }
.progress-card { grid-column: 2/ 3; }
.field { margin: 12px 0; display:flex; flex-direction:column; }
.field label { font-size: 13px; color:#93c5fd; margin-bottom:6px; }
.field input { padding:8px 10px; border-radius:8px; border:1px solid rgba(255,255,255,0.06); background:rgba(2,6,23,0.4); color:white; }
.avatar-display-small, .avatar-big { background: rgba(236,72,153,0.08); padding:12px; border-radius:12px; text-align:center; color:white; font-weight:700; }
.avatar-big { font-size:22px; padding:24px; margin-bottom:12px; }
.actions { margin-top:12px; }
.btn-primary { padding:8px 12px; background:linear-gradient(90deg,#3b82f6,#06b6d4); border:none; color:white; border-radius:8px; }
.btn-danger { padding:8px 12px; background:linear-gradient(90deg,#ef4444,#b91c1c); border:none; color:white; border-radius:8px; }
.empty { color:#94a3b8; }
.btn-toggle { align-self:flex-end; padding:6px 8px; border-radius:6px; }
.progress-row { margin:8px 0; }
.danger { margin-top:12px; background:rgba(255,0,0,0.03); padding:12px; border-radius:8px; }

@media (max-width: 900px) {
  .main-content.profile-grid { grid-template-columns: 1fr; }
}
</style>