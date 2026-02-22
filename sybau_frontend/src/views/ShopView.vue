<script setup lang="ts">
import { ref, onMounted } from 'vue';
import Navbar from "@/components/Navbar.vue";
import Header from "@/components/Header.vue";
import { itemService } from '@/services/api';
import type { item } from '@/models/Item';

const items = ref<item[]>([]);
const loading = ref(false);
const error = ref('');

const loadShopItems = async () => {
  loading.value = true;
  error.value = '';
  try {
    const res = await itemService.getShopItems();
    items.value = res.data || res || [];
  } catch (err: any) {
    console.error('Fehler beim Laden der Shop-Items:', err);
    error.value = err.response?.data?.message || 'Fehler beim Laden der Shop-Items';
  } finally {
    loading.value = false;
  }
};

const buyItem = async (item: item) => {
  // TODO: Buy logic - sende request zum Backend
  console.log('Kaufe Item:', item);
  alert(`${item.name} gekauft! (Spielfunktion noch nicht implementiert)`);
};

onMounted(loadShopItems);
</script>

<template>
  <div class="shop-container">
    <!-- Header -->
    <Header></Header>

    <!-- Navigation -->
    <Navbar></Navbar>

    <!-- Main Content -->
    <main class="shop-main">
      <div class="shop-header">
        <h1>🛒 Shop</h1>
        <p class="subtitle">Kaufe Items und Boosts um dein Avatar zu verbessern</p>
      </div>

      <!-- Loading / Error States -->
      <div v-if="loading" class="loading">
        ⏳ Lade Shop-Items...
      </div>
      <div v-else-if="error" class="error-message">
        {{ error }}
        <button class="btn-retry" @click="loadShopItems">Erneut versuchen</button>
      </div>

      <!-- Items Grid -->
      <div v-else class="shop-grid">
        <div v-if="items.length === 0" class="empty-state">
          <p>Keine Items im Shop vorhanden.</p>
        </div>
        <div v-else class="items-grid">
          <div v-for="item in items" :key="item.id" class="item-card">
            <div class="item-header">
              <h3>{{ item.name }}</h3>
              <span class="item-type">{{ item.type }}</span>
            </div>
            <p class="item-description">{{ item.description }}</p>
            <div class="item-details">
              <span v-if="item.xpBoostPercentage > 0" class="boost-badge">
                ⚡ +{{ item.xpBoostPercentage }}% XP
              </span>
            </div>
            <div class="item-footer">
              <div class="price">
                <span class="coins-icon">💰</span>
                <span class="price-value">{{ item.price }}</span>
              </div>
              <button class="btn-buy" @click="buyItem(item)">Kaufen</button>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped>
.shop-container {
  width: 100%;
  min-height: 100vh;
}

.shop-main {
  padding: 40px 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.shop-header {
  text-align: center;
  margin-bottom: 50px;
  color: white;
}

.shop-header h1 {
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

.loading,
.error-message {
  background: white;
  border-radius: 15px;
  padding: 40px;
  text-align: center;
  font-size: 1.1em;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  color: #333;
}

.error-message {
  color: #d32f2f;
}

.btn-retry {
  margin-top: 20px;
  padding: 10px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-retry:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
}

.shop-grid {
  background: white;
  border-radius: 15px;
  padding: 30px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
}

.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.item-card {
  background: linear-gradient(135deg, #f5f7fa 0%, #eff3f8 100%);
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  padding: 20px;
  transition: all 0.3s ease;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.item-card:hover {
  border-color: #667eea;
  box-shadow: 0 8px 30px rgba(102, 126, 234, 0.2);
  transform: translateY(-5px);
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.item-header h3 {
  margin: 0;
  font-size: 1.3em;
  color: #333;
}

.item-type {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8em;
  font-weight: 600;
  text-transform: capitalize;
}

.item-description {
  color: #666;
  font-size: 0.95em;
  margin: 0;
  flex-grow: 1;
}

.item-details {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.boost-badge {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(102, 126, 234, 0.2));
  border: 1px solid #667eea;
  color: #667eea;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 0.85em;
  font-weight: 600;
}

.item-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
  margin-top: auto;
}

.price {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 1.1em;
  font-weight: bold;
  color: #333;
}

.coins-icon {
  font-size: 1.2em;
}

.price-value {
  color: #667eea;
}

.btn-buy {
  padding: 10px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  flex-shrink: 0;
}

.btn-buy:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
}

.btn-buy:active {
  transform: translateY(0);
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
  font-size: 1.1em;
}

/* Responsive */
@media (max-width: 768px) {
  .shop-header h1 {
    font-size: 1.8em;
  }

  .shop-main {
    padding: 20px;
  }

  .items-grid {
    grid-template-columns: 1fr;
  }

  .item-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
