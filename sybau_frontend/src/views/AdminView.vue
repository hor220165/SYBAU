<template>
  <div class="admin-container">
    <!-- Header -->
    <Header></Header>
    <Navbar></Navbar>

    <!-- Admin Content -->
    <main class="admin-main">
      <div class="admin-header">
        <h1>Admin Dashboard</h1>
        <p class="subtitle">Verwalte Challenges, Shop-Items und Benutzer</p>
      </div>

      <!-- Tab Navigation -->
      <div class="tab-navigation">
        <button 
          :class="['tab-btn', { active: activeTab === 'challenges' }]"
          @click="activeTab = 'challenges'"
        >
          <Target :size="18" />
          Challenges
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'shop' }]"
          @click="activeTab = 'shop'"
        >
          <ShoppingBag :size="18" />
          Shop
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'users' }]"
          @click="activeTab = 'users'"
        >
          <Users :size="18" />
          Benutzer
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'exercises' }]"
          @click="activeTab = 'exercises'"
        >
          <Dumbbell :size="18" />
          Übungen
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'workouts' }]"
          @click="activeTab = 'workouts'"
        >
          <Activity :size="18" />
          Workouts
        </button>
      </div>

      <!-- Content Sections -->
      <div class="tab-content">
        <!-- Challenges Tab -->
        <div v-if="activeTab === 'challenges'" class="tab-panel">
          <div class="section-header">
            <h2>Challenge Management</h2>
            <button class="btn-primary" @click="openChallengeForm">
              <Plus :size="18" />
              Neue Challenge
            </button>
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
                    <button class="btn-icon" @click="editChallenge(challenge)" aria-label="Bearbeiten" data-tooltip="Bearbeiten">
                      <Pencil :size="18" />
                    </button>
                    <button class="btn-icon btn-danger" @click="deleteChallenge(challenge.id)" aria-label="Löschen" data-tooltip="Löschen">
                      <Trash2 :size="18" />
                    </button>
                  </div>
                </div>
                <p class="description">{{ challenge.description }}</p>
                <div class="card-stats">
                  <span><img src="../assets/XP_Pixel.png" alt="" class="pixel-icon" /> {{ challenge.xpReward }} XP</span>
                  <span><img src="../assets/SYBAU_Coin.png" alt="" class="pixel-icon" /> {{ challenge.coinReward }} Coins</span>
                  <span><Star :size="15" /> Level {{ challenge.requiredLevel }}+</span>
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
                    :aria-label="user.isAdmin ? 'Admin-Rechte entfernen' : 'Admin-Rechte geben'"
                    :data-tooltip="user.isAdmin ? 'Admin entfernen' : 'Admin geben'"
                  >
                    <Crown v-if="user.isAdmin" :size="18" />
                    <Star v-else :size="18" />
                  </button>
                  <button 
                    class="btn-icon"
                    @click="openEditUserForm(user)"
                    aria-label="Bearbeiten"
                    data-tooltip="Bearbeiten"
                  >
                    <Pencil :size="18" />
                  </button>
                  <button 
                    class="btn-icon btn-danger"
                    @click="deleteUser(user.id)"
                    aria-label="Löschen"
                    data-tooltip="Löschen"
                  >
                    <Trash2 :size="18" />
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
            <button class="btn-primary" @click="openShopForm">
              <Plus :size="18" />
              Neues Item
            </button>
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
                <label>Item Bild {{ editingShopItem ? '(optional ändern)' : '(Pflicht)' }}</label>
                <div class="image-upload-row">
                  <label class="image-picker">
                    <input
                      type="file"
                      accept="image/*"
                      :required="!editingShopItem"
                      @change="handleShopImageChange"
                    >
                    <span>{{ shopItemImageFile ? 'Bild ausgewählt' : editingShopItem ? 'Neues Bild wählen' : 'Bild wählen' }}</span>
                  </label>
                  <div v-if="shopItemImagePreview" class="image-preview">
                    <img :src="shopItemImagePreview" alt="">
                  </div>
                </div>
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
                    <option value="Cosmetic">Cosmetic</option>
                    <option value="Booster">Booster</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Rarity</label>
                  <select v-model="shopItemForm.rarity" required>
                    <option value="Common">Common</option>
                    <option value="Rare">Rare</option>
                    <option value="Epic">Epic</option>
                    <option value="Legendary">Legendary</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Max. Anzahl</label>
                  <input v-model.number="shopItemForm.maxQuantity" type="number" required min="1">
                </div>
                <div class="form-group boost-form-group">
                  <label>Boosts (optional)</label>
                  <div class="boost-input-row">
                    <div>
                      <label>XP Boost %</label>
                      <input v-model.number="shopItemForm.xpBoostPercentage" type="number" min="0" max="100">
                    </div>
                    <div>
                      <label>Coin Boost %</label>
                      <input v-model.number="shopItemForm.coinBoostPercentage" type="number" min="0" max="100">
                    </div>
                  </div>
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
                  <div class="shop-card-title">
                    <div class="shop-card-image">
                      <img v-if="getShopImage(item)" :src="getShopImage(item)" alt="">
                      <Package v-else :size="26" />
                    </div>
                    <h4>{{ item.name }}</h4>
                  </div>
                  <div class="actions">
                    <button class="btn-icon" @click="editShopItem(item)" aria-label="Bearbeiten" data-tooltip="Bearbeiten">
                      <Pencil :size="18" />
                    </button>
                    <button class="btn-icon btn-danger" @click="deleteShopItem(item.id)" aria-label="Löschen" data-tooltip="Löschen">
                      <Trash2 :size="18" />
                    </button>
                  </div>
                </div>
                <div class="card-stats">
                  <span><img src="../assets/SYBAU_Coin.png" alt="" class="pixel-icon" /> {{ item.price }} Münzen</span>
                  <span><Package :size="15" /> {{ item.type }}</span>
                  <span v-if="item.xpBoostPercentage > 0"><img src="../assets/XP_Pixel.png" alt="" class="pixel-icon" /> +{{ item.xpBoostPercentage }}% XP</span>
                  <span v-if="item.coinBoostPercentage > 0"><img src="../assets/SYBAU_Coin.png" alt="" class="pixel-icon" /> +{{ item.coinBoostPercentage }}% Coins</span>
                </div>
              </div>
            </div>
          </div>

          <div class="section-header section-header-secondary">
            <h2>Chest Management</h2>
            <button class="btn-primary" @click="openChestForm">
              <Plus :size="18" />
              Neue Chest
            </button>
          </div>

          <div v-if="showChestForm" class="form-container">
            <h3>{{ editingChest ? 'Chest bearbeiten' : 'Neue Chest erstellen' }}</h3>
            <form @submit.prevent="saveChest">
              <div class="form-row">
                <div class="form-group">
                  <label>Name</label>
                  <input v-model="chestForm.name" type="text" required placeholder="z.B. Starter Chest">
                </div>
                <div class="form-group">
                  <label>Preis (Münzen)</label>
                  <input v-model.number="chestForm.price" type="number" required min="1">
                </div>
              </div>

              <div class="form-group">
                <label>Chest Bild {{ editingChest ? '(optional ändern)' : '(Pflicht)' }}</label>
                <div class="image-upload-row">
                  <label class="image-picker">
                    <input
                      type="file"
                      accept="image/*"
                      :required="!editingChest"
                      @change="handleChestImageChange"
                    >
                    <span>{{ chestImageFile ? 'Bild ausgewählt' : editingChest ? 'Neues Bild wählen' : 'Bild wählen' }}</span>
                  </label>
                  <div v-if="chestImagePreview" class="image-preview">
                    <img :src="chestImagePreview" alt="">
                  </div>
                </div>
              </div>

              <div class="form-group">
                <label>Rarity Prozentzahlen (Summe: {{ chestChanceTotal }}%)</label>
                <div class="rarity-rate-grid">
                  <div>
                    <label>Common</label>
                    <input v-model.number="chestForm.commonChance" type="number" min="0" max="100">
                  </div>
                  <div>
                    <label>Rare</label>
                    <input v-model.number="chestForm.rareChance" type="number" min="0" max="100">
                  </div>
                  <div>
                    <label>Epic</label>
                    <input v-model.number="chestForm.epicChance" type="number" min="0" max="100">
                  </div>
                  <div>
                    <label>Legendary</label>
                    <input v-model.number="chestForm.legendaryChance" type="number" min="0" max="100">
                  </div>
                </div>
              </div>

              <div class="form-group">
                <label>Items in dieser Chest</label>
                <div class="chest-item-picker">
                  <label v-for="item in shopItems" :key="item.id" class="chest-item-option">
                    <input v-model="chestForm.itemIds" type="checkbox" :value="item.id">
                    <span class="chest-option-image">
                      <img v-if="getShopImage(item)" :src="getShopImage(item)" alt="">
                      <Package v-else :size="18" />
                    </span>
                    <span>
                      <strong>{{ item.name }}</strong>
                      <small>{{ normalizeRarity(item.rarity) }}</small>
                    </span>
                  </label>
                </div>
              </div>

              <div class="form-actions">
                <button type="submit" class="btn-primary">Speichern</button>
                <button type="button" class="btn-secondary" @click="closeChestForm">Abbrechen</button>
              </div>
            </form>
          </div>

          <div class="list-container">
            <div v-if="chests.length === 0" class="empty-state">
              <p>Keine Chests vorhanden</p>
            </div>
            <div v-else class="items-grid">
              <div v-for="chest in chests" :key="chest.id" class="card shop-card chest-admin-card">
                <div class="card-header">
                  <div class="shop-card-title">
                    <div class="shop-card-image">
                      <img v-if="getChestImage(chest)" :src="getChestImage(chest)" alt="">
                      <Package v-else :size="26" />
                    </div>
                    <h4>{{ chest.name }}</h4>
                  </div>
                  <div class="actions">
                    <button class="btn-icon" @click="editChest(chest)" aria-label="Bearbeiten" data-tooltip="Bearbeiten">
                      <Pencil :size="18" />
                    </button>
                    <button class="btn-icon btn-danger" @click="deleteChest(chest.id)" aria-label="Löschen" data-tooltip="Löschen">
                      <Trash2 :size="18" />
                    </button>
                  </div>
                </div>
                <div class="card-stats">
                  <span><img src="../assets/SYBAU_Coin.png" alt="" class="pixel-icon" /> {{ chest.price }} Münzen</span>
                  <span><Package :size="15" /> {{ getChestItems(chest).length }} Items</span>
                  <span>Common {{ chest.commonChance ?? chest.CommonChance }}%</span>
                  <span>Rare {{ chest.rareChance ?? chest.RareChance }}%</span>
                  <span>Epic {{ chest.epicChance ?? chest.EpicChance }}%</span>
                  <span>Legendary {{ chest.legendaryChance ?? chest.LegendaryChance }}%</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Exercises Tab -->
        <div v-if="activeTab === 'exercises'" class="tab-panel">
          <div class="section-header">
            <h2>Übungen Management</h2>
            <button class="btn-primary" @click="openExerciseForm">
              <Plus :size="18" />
              Neue Übung
            </button>
          </div>

          <!-- Exercise Form -->
          <div v-if="showExerciseForm" class="form-container">
            <h3>{{ editingExercise ? 'Übung bearbeiten' : 'Neue Übung erstellen' }}</h3>
            <form @submit.prevent="saveExercise">
              <div class="form-group">
                <label>Name</label>
                <input v-model="exerciseForm.name" type="text" required placeholder="z.B. Liegestütze">
              </div>
              <div class="form-group">
                <label>Beschreibung</label>
                <textarea v-model="exerciseForm.description" placeholder="Beschreibe die Übung..."></textarea>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Kategorie</label>
                  <select v-model.number="exerciseForm.category" required>
                    <option value="">-- Wähle Kategorie --</option>
                    <option :value="0">Strength</option>
                    <option :value="1">Core</option>
                    <option :value="2">Cardio</option>
                    <option :value="3">Flexibility</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Schwierigkeit</label>
                  <select v-model.number="exerciseForm.difficulty" required>
                    <option value="">-- Wähle Schwierigkeit --</option>
                    <option :value="0">Easy</option>
                    <option :value="1">Medium</option>
                    <option :value="2">Hard</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Einheit</label>
                  <select v-model="exerciseForm.unit" required>
                    <option value="Reps">Reps</option>
                    <option value="Time">Time</option>
                    <option value="Distance">Distance</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>XP pro {{ unitSingularLabels[normalizeUnitValue(exerciseForm.unit)] ?? 'Einheit' }}</label>
                  <input v-model.number="exerciseForm.xpPerRep" type="number" required min="0" step="0.1">
                </div>
                <div class="form-group">
                  <label>Tägliches Limit ({{ unitLimitHints[normalizeUnitValue(exerciseForm.unit)] ?? 'Anzahl' }})</label>
                  <input v-model.number="exerciseForm.dailyLimit" type="number" required min="1">
                </div>
              </div>
              <div class="form-actions">
                <button type="submit" class="btn-primary">Speichern</button>
                <button type="button" class="btn-secondary" @click="closeExerciseForm">Abbrechen</button>
              </div>
            </form>
          </div>

          <!-- Exercises List -->
          <div class="list-container">
            <div v-if="exercises.length === 0" class="empty-state">
              <p>Keine Übungen vorhanden</p>
            </div>
            <div v-else class="items-grid">
              <div v-for="ex in exercises" :key="ex.id" class="card exercise-card">
                <div class="card-header">
                  <h4>{{ ex.name }}</h4>
                  <div class="actions">
                    <button class="btn-icon" @click="editExercise(ex)" aria-label="Bearbeiten" data-tooltip="Bearbeiten">
                      <Pencil :size="18" />
                    </button>
                    <button class="btn-icon btn-danger" @click="deleteExercise(ex.id)" aria-label="Löschen" data-tooltip="Löschen">
                      <Trash2 :size="18" />
                    </button>
                  </div>
                </div>
                <p class="description">{{ ex.description }}</p>
                <div class="card-stats">
                  <span><Layers :size="15" /> {{ categoryLabels[ex.category] ?? ex.category }}</span>
                  <span><Activity :size="15" /> {{ difficultyLabels[ex.difficulty] ?? ex.difficulty }}</span>
                  <span><RotateCcw :size="15" /> {{ unitLabels[normalizeUnitValue(ex.unit ?? ex.Unit)] }}</span>
                  <span><img src="../assets/XP_Pixel.png" alt="" class="pixel-icon" /> {{ ex.xpPerRep }} XP/{{ unitShortLabels[normalizeUnitValue(ex.unit ?? ex.Unit)] }}</span>
                  <span><RotateCcw :size="15" /> Limit: {{ formatExerciseLimit(ex.dailyLimit, ex.unit ?? ex.Unit) }}/Tag</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Workouts Tab -->
        <div v-if="activeTab === 'workouts'" class="tab-panel">
          <div class="section-header">
            <h2>Workout Management</h2>
            <button class="btn-primary" @click="openWorkoutForm">
              <Plus :size="18" />
              Neues Workout
            </button>
          </div>

          <!-- Workout Form -->
          <div v-if="showWorkoutForm" class="form-container">
            <h3>{{ editingWorkout ? 'Workout bearbeiten' : 'Neues Workout erstellen' }}</h3>
            <form @submit.prevent="saveWorkout">
              <div class="form-group">
                <label>Name</label>
                <input v-model="workoutForm.name" type="text" required placeholder="z.B. Oberkörper Power">
              </div>
              <div class="form-group">
                <label>Beschreibung</label>
                <textarea v-model="workoutForm.description" placeholder="Beschreibe das Workout..."></textarea>
              </div>
              <div class="form-group">
                <label>Kategorie</label>
                <select v-model.number="workoutForm.category" required>
                  <option value="">-- Wähle Kategorie --</option>
                  <option :value="0">Strength</option>
                  <option :value="1">Core</option>
                  <option :value="2">Cardio</option>
                  <option :value="3">Flexibility</option>
                </select>
              </div>

              <!-- Exercise Selection -->
              <div class="form-group">
                <label>Übungen hinzufügen</label>
                <div v-for="(we, index) in workoutForm.exercises" :key="index" class="workout-exercise-row">
                  <select v-model.number="we.exerciseId" required>
                    <option value="">-- Übung wählen --</option>
                    <option v-for="ex in exercises" :key="ex.id" :value="ex.id">{{ ex.name }}</option>
                  </select>
                  <input v-model.number="we.dailyLimit" type="number" min="1" placeholder="Limit" class="small-input">
                  <button type="button" class="btn-icon btn-danger" @click="workoutForm.exercises.splice(index, 1)" aria-label="Entfernen" data-tooltip="Entfernen">
                    <Trash2 :size="18" />
                  </button>
                </div>
                <button type="button" class="btn-secondary" @click="workoutForm.exercises.push({ exerciseId: 0, dailyLimit: 50 })">
                  <Plus :size="18" />
                  Übung hinzufügen
                </button>
              </div>

              <div class="form-actions">
                <button type="submit" class="btn-primary">Speichern</button>
                <button type="button" class="btn-secondary" @click="closeWorkoutForm">Abbrechen</button>
              </div>
            </form>
          </div>

          <!-- Workouts List -->
          <div class="list-container">
            <div v-if="workouts.length === 0" class="empty-state">
              <p>Keine Workouts vorhanden</p>
            </div>
            <div v-else class="items-grid">
              <div v-for="wo in workouts" :key="wo.id ?? wo.Id" class="card workout-card">
                <div class="card-header">
                  <h4>{{ wo.name ?? wo.Name }}</h4>
                  <div class="actions">
                    <button class="btn-icon" @click="editWorkout(wo)" aria-label="Bearbeiten" data-tooltip="Bearbeiten">
                      <Pencil :size="18" />
                    </button>
                    <button class="btn-icon btn-danger" @click="deleteWorkout(wo.id ?? wo.Id)" aria-label="Löschen" data-tooltip="Löschen">
                      <Trash2 :size="18" />
                    </button>
                  </div>
                </div>
                <p class="description">{{ wo.description ?? wo.Description }}</p>
                <div class="card-stats">
                  <span><Layers :size="15" /> {{ categoryLabels[wo.category ?? wo.Category] ?? wo.category ?? wo.Category }}</span>
                  <span><Dumbbell :size="15" /> {{ (wo.exercises ?? wo.Exercises)?.length ?? 0 }} Übungen</span>
                </div>
              </div>
            </div>
          </div>
        </div>

      <!-- Status Messages -->
      <MessagePopup
        :message="statusMessage"
        :type="statusType"
        @close="statusMessage = ''"
      />
    </main>
     <!-- Footer -->
    <FooterComponent />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import { useAdmin } from '@/composables/useAdmin';
import { resolveMediaUrl } from '@/services/api';
import {
  Activity,
  Crown,
  Dumbbell,
  Layers,
  Package,
  Pencil,
  Plus,
  RotateCcw,
  ShoppingBag,
  Star,
  Target,
  Trash2,
  Users
} from 'lucide-vue-next';
import type { Challange } from '@/models/Challange';
import type { item } from '@/models/Item';
import type { user } from '@/models/User';

// State
const activeTab = ref<'challenges' | 'shop' | 'users' | 'exercises' | 'workouts'>('challenges');

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
  xpBoostPercentage: 0,
  coinBoostPercentage: 0,
  rarity: 'Common',
  maxQuantity: 5
});
const shopItemImageFile = ref<File | null>(null);
const shopItemImagePreview = ref('');
const shopItems = ref<item[]>([]);
const showChestForm = ref(false);
const editingChest = ref<any | null>(null);
const chestForm = ref({
  name: '',
  price: 0,
  commonChance: 70,
  rareChance: 20,
  epicChance: 8,
  legendaryChance: 2,
  itemIds: [] as number[]
});
const chestImageFile = ref<File | null>(null);
const chestImagePreview = ref('');
const chests = ref<any[]>([]);
const chestChanceTotal = computed(() =>
  Number(chestForm.value.commonChance ?? 0) +
  Number(chestForm.value.rareChance ?? 0) +
  Number(chestForm.value.epicChance ?? 0) +
  Number(chestForm.value.legendaryChance ?? 0)
);

// Exercise Management
const showExerciseForm = ref(false);
const editingExercise = ref<any | null>(null);
const exerciseForm = ref({
  name: '',
  description: '',
  category: '' as number | '',
  difficulty: '' as number | '',
  unit: 'Reps',
  xpPerRep: 1,
  dailyLimit: 200
});
const exercises = ref<any[]>([]);

// Workout Management
const showWorkoutForm = ref(false);
const editingWorkout = ref<any | null>(null);
const workoutForm = ref({
  name: '',
  description: '',
  category: '' as number | '',
  exercises: [{ exerciseId: 0, dailyLimit: 50 }] as { exerciseId: number; dailyLimit: number }[]
});
const workouts = ref<any[]>([]);

const categoryLabels: Record<number, string> = { 0: 'Strength', 1: 'Core', 2: 'Cardio', 3: 'Flexibility' };
const difficultyLabels: Record<number, string> = { 0: 'Easy', 1: 'Medium', 2: 'Hard' };
type ExerciseUnitKey = 'reps' | 'time' | 'distance';
const unitLabels: Record<ExerciseUnitKey, string> = { reps: 'Reps', time: 'Time', distance: 'Distance' };
const unitShortLabels: Record<ExerciseUnitKey, string> = { reps: 'Rep', time: 'Sek', distance: 'm' };
const unitSingularLabels: Record<ExerciseUnitKey, string> = { reps: 'Rep', time: 'Sekunde', distance: 'Meter' };
const unitLimitHints: Record<ExerciseUnitKey, string> = { reps: 'Reps', time: 'Sekunden', distance: 'Meter' };

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
  createChest: createChestApi,
  updateChest: updateChestApi,
  deleteChest: deleteChestApi,
  getAllChests,
  getAllUsers,
  updateUserRole,
  updateUser,
  deleteUserApi,
  getAllExercises,
  createExercise,
  updateExercise,
  updateExerciseUnit,
  deleteExercise: deleteExerciseApi,
  getAllWorkouts,
  createWorkout,
  updateWorkout,
  deleteWorkout: deleteWorkoutApi
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
  shopItemImageFile.value = null;
  shopItemImagePreview.value = '';
  shopItemForm.value = {
    name: '',
    description: '',
    price: 0,
    type: '',
    xpBoostPercentage: 0,
    coinBoostPercentage: 0,
    rarity: 'Common',
    maxQuantity: 5
  };
  showShopForm.value = true;
};

const closeShopForm = () => {
  showShopForm.value = false;
  editingShopItem.value = null;
  shopItemImageFile.value = null;
  shopItemImagePreview.value = '';
};

const editShopItem = (item: any) => {
  editingShopItem.value = item;
  shopItemImageFile.value = null;
  shopItemImagePreview.value = getShopImage(item);
  shopItemForm.value = {
    name: item.name ?? '',
    description: item.description ?? '',
    price: Number(item.price ?? 0),
    type: normalizeItemType(item.type),
    xpBoostPercentage: Number(item.xpBoostPercentage ?? item.xpBoostPercent ?? 0),
    coinBoostPercentage: Number(item.coinBoostPercentage ?? item.coinBoostPercent ?? 0),
    rarity: normalizeRarity(item.rarity),
    maxQuantity: Number(item.maxQuantity ?? 5)
  };
  showShopForm.value = true;
};

const normalizeItemType = (value: unknown) => {
  if (value === 1 || value === '1' || value === 'Booster' || value === 'booster') return 'Booster';
  return 'Cosmetic';
};

const normalizeRarity = (value: unknown) => {
  const raw = String(value || 'Common').toLowerCase();
  if (raw === 'rare') return 'Rare';
  if (raw === 'epic') return 'Epic';
  if (raw === 'legendary') return 'Legendary';
  return 'Common';
};

const getShopImage = (item: any) => resolveMediaUrl(item?.imageUrl ?? item?.ImageUrl ?? '');
const getChestImage = (chest: any) => resolveMediaUrl(chest?.imageUrl ?? chest?.ImageUrl ?? '');
const getChestItems = (chest: any) => chest?.items ?? chest?.Items ?? [];

const handleShopImageChange = (event: Event) => {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0] ?? null;
  shopItemImageFile.value = file;
  shopItemImagePreview.value = file ? URL.createObjectURL(file) : getShopImage(editingShopItem.value);
};

const buildShopItemDescription = () => {
  const parts = [];
  if (Number(shopItemForm.value.xpBoostPercentage) > 0) {
    parts.push(`${shopItemForm.value.xpBoostPercentage}% XP-Boost`);
  }
  if (Number(shopItemForm.value.coinBoostPercentage) > 0) {
    parts.push(`${shopItemForm.value.coinBoostPercentage}% Coin-Boost`);
  }
  return parts.length > 0 ? parts.join(' ') : shopItemForm.value.name;
};

const saveShopItem = async () => {
  try {
    if (!editingShopItem.value && !shopItemImageFile.value) {
      showMessage('Bitte ein Bild für das Shop-Item auswählen', 'error');
      return;
    }
    const payload = {
      ...shopItemForm.value,
      description: buildShopItemDescription(),
      imageFile: shopItemImageFile.value
    };
    if (editingShopItem.value) {
      await updateShopItem(editingShopItem.value.id, payload);
      showMessage('Shop-Item aktualisiert! ✓');
    } else {
      await createShopItem(payload);
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

// ===== CHESTS =====
const openChestForm = () => {
  editingChest.value = null;
  chestImageFile.value = null;
  chestImagePreview.value = '';
  chestForm.value = {
    name: '',
    price: 0,
    commonChance: 70,
    rareChance: 20,
    epicChance: 8,
    legendaryChance: 2,
    itemIds: []
  };
  showChestForm.value = true;
};

const closeChestForm = () => {
  showChestForm.value = false;
  editingChest.value = null;
  chestImageFile.value = null;
  chestImagePreview.value = '';
};

const editChest = (chest: any) => {
  editingChest.value = chest;
  chestImageFile.value = null;
  chestImagePreview.value = getChestImage(chest);
  chestForm.value = {
    name: chest.name ?? chest.Name ?? '',
    price: Number(chest.price ?? chest.Price ?? 0),
    commonChance: Number(chest.commonChance ?? chest.CommonChance ?? 70),
    rareChance: Number(chest.rareChance ?? chest.RareChance ?? 20),
    epicChance: Number(chest.epicChance ?? chest.EpicChance ?? 8),
    legendaryChance: Number(chest.legendaryChance ?? chest.LegendaryChance ?? 2),
    itemIds: getChestItems(chest).map((item: any) => Number(item.id ?? item.Id)).filter(Boolean)
  };
  showChestForm.value = true;
};

const handleChestImageChange = (event: Event) => {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0] ?? null;
  chestImageFile.value = file;
  chestImagePreview.value = file ? URL.createObjectURL(file) : getChestImage(editingChest.value);
};

const saveChest = async () => {
  try {
    if (!editingChest.value && !chestImageFile.value) {
      showMessage('Bitte ein Bild für die Chest auswählen', 'error');
      return;
    }
    if (chestChanceTotal.value !== 100) {
      showMessage('Die Rarity-Prozentzahlen müssen zusammen 100 ergeben', 'error');
      return;
    }
    if (chestForm.value.itemIds.length === 0) {
      showMessage('Bitte mindestens ein Item in die Chest legen', 'error');
      return;
    }

    const payload = {
      ...chestForm.value,
      itemIds: chestForm.value.itemIds.map(Number).filter(Boolean),
      imageFile: chestImageFile.value
    };

    if (editingChest.value) {
      await updateChestApi(editingChest.value.id ?? editingChest.value.Id, payload);
      showMessage('Chest aktualisiert! ✓');
    } else {
      await createChestApi(payload);
      showMessage('Chest erstellt! ✓');
    }
    closeChestForm();
    await loadChests();
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Speichern der Chest', 'error');
  }
};

const deleteChest = async (id: number) => {
  if (confirm('Chest wirklich löschen?')) {
    try {
      await deleteChestApi(id);
      showMessage('Chest gelöscht! ✓');
      await loadChests();
    } catch (err: any) {
      showMessage(err.message || 'Fehler beim Löschen der Chest', 'error');
    }
  }
};

const loadChests = async () => {
  try {
    const res = await getAllChests();
    chests.value = res.data || res || [];
  } catch (err) {
    console.error('Fehler beim Laden der Chests:', err);
    showMessage('Fehler beim Laden der Chests', 'error');
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

// ===== EXERCISES =====
const openExerciseForm = () => {
  editingExercise.value = null;
  exerciseForm.value = {
    name: '',
    description: '',
    category: '',
    difficulty: '',
    unit: 'Reps',
    xpPerRep: 1,
    dailyLimit: 200
  };
  showExerciseForm.value = true;
};

const closeExerciseForm = () => {
  showExerciseForm.value = false;
  editingExercise.value = null;
};

const editExercise = (exercise: any) => {
  editingExercise.value = exercise;
  exerciseForm.value = {
    name: exercise.name ?? exercise.Name ?? '',
    description: exercise.description ?? exercise.Description ?? '',
    category: exercise.category ?? exercise.Category ?? '',
    difficulty: exercise.difficulty ?? exercise.Difficulty ?? '',
    unit: normalizeUnitText(exercise.unit ?? exercise.Unit),
    xpPerRep: Number(exercise.xpPerRep ?? exercise.XpPerRep ?? 1),
    dailyLimit: Number(exercise.dailyLimit ?? exercise.DailyLimit ?? 200)
  };
  showExerciseForm.value = true;
};

const normalizeUnitValue = (raw: unknown): ExerciseUnitKey => {
  if (typeof raw === 'number') {
    if (raw === 1) return 'time';
    if (raw === 2) return 'distance';
    return 'reps';
  }
  const value = String(raw ?? '').toLowerCase();
  if (value === 'time') return 'time';
  if (value === 'distance') return 'distance';
  return 'reps';
};

const normalizeUnitText = (raw: unknown): 'Reps' | 'Time' | 'Distance' => {
  const normalized = normalizeUnitValue(raw);
  if (normalized === 'time') return 'Time';
  if (normalized === 'distance') return 'Distance';
  return 'Reps';
};

const normalizeExerciseCategory = (raw: unknown): number => {
  if (typeof raw === 'number' && Number.isFinite(raw)) return raw;
  const value = String(raw ?? '').toLowerCase();
  if (value === 'core') return 1;
  if (value === 'cardio') return 2;
  if (value === 'flexibility') return 3;
  return 0;
};

const normalizeExerciseDifficulty = (raw: unknown): number => {
  if (typeof raw === 'number' && Number.isFinite(raw)) return raw;
  const value = String(raw ?? '').toLowerCase();
  if (value === 'hard') return 2;
  if (value === 'medium') return 1;
  return 0;
};

const buildExercisePayload = () => {
  const unit = normalizeUnitText(exerciseForm.value.unit);
  return {
    name: exerciseForm.value.name,
    description: exerciseForm.value.description || null,
    category: normalizeExerciseCategory(exerciseForm.value.category),
    difficulty: normalizeExerciseDifficulty(exerciseForm.value.difficulty),
    unit,
    xpPerRep: Number(exerciseForm.value.xpPerRep ?? 1),
    dailyLimit: Number(exerciseForm.value.dailyLimit ?? 200)
  };
};

const formatExerciseLimit = (rawLimit: unknown, rawUnit: unknown): string => {
  const limit = Number(rawLimit ?? 0);
  const unit = normalizeUnitValue(rawUnit);
  if (unit === 'time') {
    const hours = Math.floor(limit / 3600);
    const minutes = Math.floor((limit % 3600) / 60);
    const seconds = Math.floor(limit % 60);
    return [hours, minutes, seconds].map((part) => String(part).padStart(2, '0')).join(':');
  }
  if (unit === 'distance') {
    if (limit >= 1000) return `${(limit / 1000).toLocaleString('de-DE', { maximumFractionDigits: 2 })} km`;
    return `${limit.toLocaleString('de-DE')} m`;
  }
  return `${limit.toLocaleString('de-DE')} Reps`;
};

const saveExercise = async () => {
  try {
    const payload = buildExercisePayload();
    let savedExercise: any;
    if (editingExercise.value) {
      const exerciseId = editingExercise.value.id ?? editingExercise.value.Id;
      savedExercise = await updateExercise(exerciseId, payload as any);
      savedExercise = await updateExerciseUnit(exerciseId, payload.unit);
      showMessage('Übung aktualisiert! ✓');
    } else {
      savedExercise = await createExercise(payload as any);
      const createdId = savedExercise?.id ?? savedExercise?.Id;
      if (createdId) {
        savedExercise = await updateExerciseUnit(createdId, payload.unit);
      }
      showMessage('Übung erstellt! ✓');
    }
    const serverUnit = normalizeUnitText(savedExercise?.unit ?? savedExercise?.Unit ?? payload.unit);
    if (serverUnit !== payload.unit) {
      throw new Error('Einheit wurde vom Server nicht übernommen.');
    }
    closeExerciseForm();
    await loadExercises();
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Speichern', 'error');
  }
};

const deleteExercise = async (id: number) => {
  if (confirm('Übung wirklich löschen? Sie darf keine gespeicherten Aktivitäten haben.')) {
    try {
      await deleteExerciseApi(id);
      showMessage('Übung gelöscht! ✓');
      await loadExercises();
      await loadWorkouts();
    } catch (err: any) {
      showMessage(err.message || 'Fehler beim Löschen', 'error');
    }
  }
};

const loadExercises = async () => {
  try {
    const res = await getAllExercises();
    exercises.value = res.data || res || [];
  } catch (err) {
    console.error('Fehler beim Laden der Übungen:', err);
  }
};

// ===== WORKOUTS =====
const openWorkoutForm = () => {
  editingWorkout.value = null;
  workoutForm.value = {
    name: '',
    description: '',
    category: '',
    exercises: [{ exerciseId: 0, dailyLimit: 50 }]
  };
  showWorkoutForm.value = true;
};

const closeWorkoutForm = () => {
  showWorkoutForm.value = false;
  editingWorkout.value = null;
};

const normalizeWorkoutExercises = (workout: any) => {
  const list = workout.exercises ?? workout.Exercises ?? [];
  return list.map((entry: any) => ({
    exerciseId: Number(entry.exerciseId ?? entry.ExerciseId ?? entry.id ?? entry.Id ?? 0),
    dailyLimit: Number(entry.dailyLimit ?? entry.DailyLimit ?? 50)
  })).filter((entry: { exerciseId: number; dailyLimit: number }) => entry.exerciseId > 0);
};

const editWorkout = (workout: any) => {
  editingWorkout.value = workout;
  workoutForm.value = {
    name: workout.name ?? workout.Name ?? '',
    description: workout.description ?? workout.Description ?? '',
    category: workout.category ?? workout.Category ?? '',
    exercises: normalizeWorkoutExercises(workout)
  };
  if (workoutForm.value.exercises.length === 0) {
    workoutForm.value.exercises = [{ exerciseId: 0, dailyLimit: 50 }];
  }
  showWorkoutForm.value = true;
};

const saveWorkout = async () => {
  try {
    const validExercises = workoutForm.value.exercises.filter(e => e.exerciseId > 0);
    if (validExercises.length === 0) {
      showMessage('Bitte mindestens eine Übung hinzufügen', 'error');
      return;
    }
    const payload = {
      ...workoutForm.value,
      exercises: validExercises
    } as any;
    if (editingWorkout.value) {
      await updateWorkout(editingWorkout.value.id ?? editingWorkout.value.Id, payload);
      showMessage('Workout aktualisiert! ✓');
    } else {
      await createWorkout(payload);
      showMessage('Workout erstellt! ✓');
    }
    closeWorkoutForm();
    await loadWorkouts();
  } catch (err: any) {
    showMessage(err.message || 'Fehler beim Speichern', 'error');
  }
};

const deleteWorkout = async (id: number) => {
  if (confirm('Workout wirklich löschen?')) {
    try {
      await deleteWorkoutApi(id);
      showMessage('Workout gelöscht! ✓');
      await loadWorkouts();
    } catch (err: any) {
      showMessage(err.message || 'Fehler beim Löschen', 'error');
    }
  }
};

const loadWorkouts = async () => {
  try {
    const res = await getAllWorkouts();
    workouts.value = res.data || res || [];
  } catch (err) {
    console.error('Fehler beim Laden der Workouts:', err);
  }
};

// Load data on mount
onMounted(async () => {
  await loadChallenges();
  await loadShopItems();
  await loadChests();
  await loadUsers();
  await loadExercises();
  await loadWorkouts();
});
</script>

<style scoped>
.admin-container {
  width: 100%;
  min-height: 100vh;
  background:
    radial-gradient(circle at top left, rgba(236, 72, 153, 0.14), transparent 34%),
    radial-gradient(circle at top right, rgba(244, 63, 94, 0.12), transparent 32%),
    #020617;
  color: #f8fafc;
}

.admin-main {
  padding: 36px 28px 52px;
  max-width: 1400px;
  margin: 0 auto;
}

.admin-header {
  margin-bottom: 26px;
}

.admin-header h1 {
  font-size: clamp(2rem, 4vw, 3.3rem);
  margin: 0;
  font-weight: 900;
  letter-spacing: 0;
}

.subtitle {
  font-size: 1rem;
  color: #a8b3c7;
  margin: 8px 0 0;
}

.tab-navigation {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
  flex-wrap: wrap;
}

.tab-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  min-height: 48px;
  padding: 0 18px;
  font-size: 0.98rem;
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 14px;
  background: rgba(15, 23, 42, 0.72);
  color: #a8b3c7;
  cursor: pointer;
  transition: transform 0.2s ease, border-color 0.2s ease, background 0.2s ease, color 0.2s ease;
  font-weight: 800;
}

.tab-btn:hover {
  border-color: rgba(236, 72, 153, 0.45);
  color: #f8fafc;
  transform: translateY(-1px);
}

.tab-btn.active {
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.95), rgba(244, 63, 94, 0.9));
  border-color: rgba(255, 255, 255, 0.18);
  color: #fff;
  box-shadow: 0 16px 32px rgba(236, 72, 153, 0.24);
}

.tab-panel {
  background: rgba(15, 23, 42, 0.7);
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 28px;
  padding: clamp(18px, 3vw, 30px);
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.26);
  backdrop-filter: blur(18px);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 14px;
}

.section-header h2 {
  margin: 0;
  color: #f8fafc;
  font-size: clamp(1.35rem, 2vw, 1.85rem);
  font-weight: 900;
}

.search-input {
  min-height: 46px;
  padding: 0 16px;
  border: 1px solid rgba(148, 163, 184, 0.22);
  border-radius: 14px;
  font-size: 0.95rem;
  width: min(360px, 100%);
  background: rgba(2, 6, 23, 0.48);
  color: #f8fafc;
}

.search-input::placeholder {
  color: #64748b;
}

.search-input:focus {
  outline: none;
  border-color: rgba(236, 72, 153, 0.65);
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.14);
}

.form-container {
  background: rgba(2, 6, 23, 0.38);
  border: 1px solid rgba(148, 163, 184, 0.16);
  border-radius: 22px;
  padding: clamp(18px, 2.4vw, 26px);
  margin-bottom: 28px;
}

.form-container h3,
.modal-content h3 {
  margin: 0 0 18px;
  color: #f8fafc;
  font-size: 1.2rem;
  font-weight: 900;
}

.form-group {
  margin-bottom: 18px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 800;
  color: #a8b3c7;
  font-size: 0.88rem;
}

.form-group input,
.form-group textarea,
.form-group select,
.workout-exercise-row select,
.workout-exercise-row .small-input {
  width: 100%;
  min-height: 46px;
  padding: 12px 14px;
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 14px;
  font-size: 0.95rem;
  font-family: inherit;
  color: #f8fafc;
  background: rgba(15, 23, 42, 0.78);
  transition: border-color 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}

.form-group input::placeholder,
.form-group textarea::placeholder {
  color: #64748b;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus,
.workout-exercise-row select:focus,
.workout-exercise-row .small-input:focus {
  outline: none;
  border-color: rgba(236, 72, 153, 0.7);
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.14);
  background: rgba(15, 23, 42, 0.96);
}

.form-group textarea {
  resize: vertical;
  min-height: 104px;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: 18px;
}

.boost-form-group {
  grid-column: span 2;
}

.boost-input-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(150px, 1fr));
  gap: 18px;
}

.boost-input-row label {
  font-size: 0.82rem;
  color: #94a3b8;
}

.section-header-secondary {
  margin-top: 32px;
}

.rarity-rate-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(120px, 1fr));
  gap: 14px;
}

.rarity-rate-grid label {
  font-size: 0.82rem;
  color: #94a3b8;
}

.chest-item-picker {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
  gap: 12px;
  max-height: 310px;
  overflow-y: auto;
  padding-right: 4px;
}

.chest-item-option {
  display: grid;
  grid-template-columns: 20px 42px minmax(0, 1fr);
  align-items: center;
  gap: 10px;
  padding: 10px;
  border-radius: 14px;
  background: rgba(15, 23, 42, 0.58);
  border: 1px solid rgba(148, 163, 184, 0.14);
  cursor: pointer;
}

.chest-item-option input {
  width: 16px;
  height: 16px;
}

.chest-option-image {
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  border-radius: 12px;
  background: rgba(2, 6, 23, 0.45);
  color: #fce7f3;
}

.chest-option-image img {
  width: 82%;
  height: 82%;
  object-fit: contain;
  image-rendering: pixelated;
}

.chest-item-option strong,
.chest-item-option small {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.chest-item-option strong {
  color: #f8fafc;
  font-size: 0.9rem;
}

.chest-item-option small {
  color: #94a3b8;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 0.72rem;
}

.image-upload-row {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}

.image-picker {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 30px;
  padding: 0;
  border: 0;
  background: transparent;
  color: #f472b6;
  font-weight: 900;
  cursor: pointer;
  text-decoration: none;
  transition: color 0.2s ease;
}

.image-picker:hover {
  color: #f9a8d4;
}

.image-picker input {
  position: absolute;
  inset: 0;
  opacity: 0;
  cursor: pointer;
}

.image-preview,
.shop-card-image {
  display: grid;
  place-items: center;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(148, 163, 184, 0.16);
}

.image-preview {
  width: 70px;
  height: 70px;
  border-radius: 16px;
}

.image-preview img,
.shop-card-image img {
  width: 82%;
  height: 82%;
  object-fit: contain;
  image-rendering: pixelated;
}

.shop-card-title {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.shop-card-image {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  color: #fce7f3;
  flex: 0 0 auto;
}

.form-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 20px;
}

.btn-primary,
.btn-secondary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  min-height: 44px;
  padding: 0 18px;
  border-radius: 14px;
  font-size: 0.96rem;
  font-weight: 900;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease, background 0.2s ease;
}

.btn-primary {
  border: 1px solid rgba(255, 255, 255, 0.16);
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  box-shadow: 0 14px 30px rgba(236, 72, 153, 0.24);
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 18px 36px rgba(236, 72, 153, 0.34);
}

.btn-secondary {
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: rgba(30, 41, 59, 0.86);
  color: #fce7f3;
}

.btn-secondary:hover {
  border-color: rgba(236, 72, 153, 0.42);
  transform: translateY(-1px);
}

.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 18px;
}

.card {
  background: rgba(30, 41, 59, 0.68);
  border: 1px solid rgba(148, 163, 184, 0.16);
  border-radius: 18px;
  padding: 20px;
  transition: transform 0.2s ease, border-color 0.2s ease, background 0.2s ease;
}

.card:hover {
  border-color: rgba(236, 72, 153, 0.38);
  background: rgba(30, 41, 59, 0.86);
  transform: translateY(-2px);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 14px;
  margin-bottom: 12px;
}

.card-header h4 {
  margin: 0;
  color: #f8fafc;
  flex: 1;
  min-width: 0;
  font-size: 1.08rem;
  font-weight: 900;
  overflow-wrap: anywhere;
}

.actions,
.col-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: flex-start;
}

.btn-icon {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  padding: 0;
  border: 1px solid rgba(148, 163, 184, 0.16);
  border-radius: 12px;
  background: rgba(15, 23, 42, 0.72);
  color: #fce7f3;
  cursor: pointer;
  transition: transform 0.2s ease, border-color 0.2s ease, background 0.2s ease, color 0.2s ease;
}

.btn-icon::after {
  content: attr(data-tooltip);
  position: absolute;
  left: 50%;
  top: calc(100% + 10px);
  z-index: 25;
  padding: 8px 10px;
  border-radius: 10px;
  background: rgba(2, 6, 23, 0.96);
  border: 1px solid rgba(236, 72, 153, 0.34);
  color: #fce7f3;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.32);
  font-size: 0.78rem;
  font-weight: 900;
  line-height: 1;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transform: translate(-50%, 4px);
  transition: opacity 0.12s ease, transform 0.12s ease;
}

.btn-icon:hover::after,
.btn-icon:focus-visible::after {
  opacity: 1;
  transform: translate(-50%, 0);
}

.btn-icon svg {
  display: block;
  width: 18px;
  height: 18px;
  color: inherit;
  stroke: currentColor;
  stroke-width: 2.4;
  flex: 0 0 auto;
}

.btn-icon:hover {
  border-color: rgba(236, 72, 153, 0.45);
  background: rgba(236, 72, 153, 0.16);
  transform: translateY(-1px);
}

.btn-icon.btn-danger {
  color: #fb7185;
}

.btn-icon.btn-danger:hover {
  border-color: rgba(251, 113, 133, 0.45);
  background: rgba(190, 18, 60, 0.18);
}

.description {
  color: #a8b3c7;
  margin: 10px 0 16px;
  font-size: 0.95rem;
  line-height: 1.55;
}

.card-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  font-size: 0.86rem;
}

.card-stats span {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 7px 10px;
  background: rgba(15, 23, 42, 0.72);
  border: 1px solid rgba(148, 163, 184, 0.14);
  border-radius: 999px;
  color: #fce7f3;
  font-weight: 800;
}

.pixel-icon {
  width: 16px;
  height: 16px;
  object-fit: contain;
  image-rendering: pixelated;
  flex: 0 0 auto;
}

.users-container {
  color: #f8fafc;
}

.users-table {
  overflow-x: auto;
}

.table-header,
.table-row {
  display: grid;
  grid-template-columns: minmax(150px, 1.3fr) minmax(220px, 1.7fr) minmax(70px, 0.6fr) minmax(90px, 0.7fr) minmax(110px, 0.8fr) minmax(150px, 1fr);
  gap: 14px;
  align-items: center;
  min-width: 900px;
}

.table-header {
  padding: 14px 16px;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(148, 163, 184, 0.14);
  border-radius: 16px;
  font-weight: 900;
  color: #a8b3c7;
  margin-bottom: 10px;
  font-size: 0.84rem;
}

.table-row {
  padding: 16px;
  border: 1px solid rgba(148, 163, 184, 0.12);
  border-radius: 16px;
  background: rgba(30, 41, 59, 0.54);
  color: #f8fafc;
  margin-bottom: 10px;
}

.table-row:hover {
  border-color: rgba(236, 72, 153, 0.32);
}

.col-email {
  color: #a8b3c7;
  overflow-wrap: anywhere;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  background: rgba(236, 72, 153, 0.14);
  border: 1px solid rgba(236, 72, 153, 0.28);
  color: #fbcfe8;
  font-size: 0.82rem;
  font-weight: 900;
}

.status-badge.status-admin {
  background: rgba(250, 204, 21, 0.14);
  border-color: rgba(250, 204, 21, 0.32);
  color: #fde68a;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(2, 6, 23, 0.74);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 3200;
  padding: 18px;
  backdrop-filter: blur(12px);
}

.modal-content {
  background: #0f172a;
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 22px;
  padding: 26px;
  max-width: 540px;
  width: min(540px, 100%);
  box-shadow: 0 26px 70px rgba(0, 0, 0, 0.38);
}

.modal-actions {
  justify-content: flex-end;
}

.empty-state {
  text-align: center;
  padding: 52px 20px;
  color: #94a3b8;
  font-size: 1rem;
  background: rgba(2, 6, 23, 0.3);
  border: 1px dashed rgba(148, 163, 184, 0.18);
  border-radius: 18px;
}

.workout-exercise-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 110px auto;
  gap: 10px;
  align-items: center;
  margin-bottom: 10px;
}

@media (max-width: 900px) {
  .admin-main {
    padding: 28px 20px 44px;
  }

  .tab-navigation {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .section-header {
    align-items: stretch;
  }

  .section-header .btn-primary,
  .search-input {
    width: 100%;
  }

  .items-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .admin-main {
    padding: 22px 14px 38px;
  }

  .tab-navigation {
    grid-template-columns: 1fr;
  }

  .tab-btn {
    justify-content: flex-start;
    padding: 0 16px;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .form-actions,
  .modal-actions {
    flex-direction: column;
  }

  .btn-primary,
  .btn-secondary {
    width: 100%;
  }

  .table-header {
    display: none;
  }

  .table-row {
    min-width: 0;
    grid-template-columns: 1fr;
    gap: 10px;
  }

  .col-username::before { content: "Benutzername: "; font-weight: 900; color: #94a3b8; }
  .col-email::before { content: "Email: "; font-weight: 900; color: #94a3b8; }
  .col-level::before { content: "Level: "; font-weight: 900; color: #94a3b8; }
  .col-coins::before { content: "Münzen: "; font-weight: 900; color: #94a3b8; }
  .col-status::before { content: "Status: "; font-weight: 900; color: #94a3b8; }
  .col-actions::before { content: "Aktionen: "; font-weight: 900; color: #94a3b8; align-self: center; }

  .workout-exercise-row {
    grid-template-columns: 1fr;
  }

  .workout-exercise-row .btn-icon {
    width: 44px;
  }

  .workout-exercise-row .small-input {
    max-width: none;
  }

}
</style>
