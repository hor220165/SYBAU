<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { Package } from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import ShopFeatureCard from '@/components/ShopFeatureCard.vue';
import ShopChestCard from '@/components/ShopChestCard.vue';
import coinIcon from '@/assets/SYBAU_Coin.png';
import starterChestOpenImage from '@/assets/Starter_Chest_open.png';
import goldChestOpenImage from '@/assets/Gold_Chest_open.png';
import prestigeChestOpenImage from '@/assets/Prestige_Chest_open.png';
import { ItemType } from '@/models/ItemType';
import type { item } from '@/models/Item';
import type { ShopDisplayItem } from '@/models/ShopDisplayItem';
import type { Chest } from '@/models/Chest';
import { itemService, resolveMediaUrl, userService } from '@/services/api';
import FooterComponent from '@/components/FooterComponent.vue';
import { useAuth } from '@/composables/useAuth';
import MessagePopup from '@/components/MessagePopup.vue';
import { useLanguage } from '@/composables/useLanguage';

const items = ref<ShopDisplayItem[]>([]);
const realMoneyItems = ref<ShopDisplayItem[]>([]);
const chests = ref<Chest[]>([]);
const ownedItems = ref<Record<number, number>>({});
const currentCoins = ref(0);
const loading = ref(true);
const error = ref('');
const successMessage = ref('');
const buyingItemId = ref<number | null>(null);
const realMoneyBusyItemId = ref<number | null>(null);
const openingChestId = ref<number | null>(null);
const chestOpening = ref<Chest | null>(null);
const openedReward = ref<any | null>(null);
const chestRevealStarted = ref(false);
const pendingPurchase = ref<{ type: 'item'; item: ShopDisplayItem } | { type: 'chest'; chest: Chest } | null>(null);
const dailyShopExpiresAtUtc = ref('');
const dailyShopServerOffsetMs = ref(0);
const dailyCountdownNowMs = ref(Date.now());
const { refreshUser } = useAuth();
const { text, translate } = useLanguage();
let dailyCountdownTimer: number | undefined;

const popupMessage = ref("");
const popupType = ref<"success" | "error" | "info">("success");

const syncCoinsFromStorage = () => {
  const raw = JSON.parse(localStorage.getItem('user') || '{}');
  currentCoins.value = Number(raw.coins ?? raw.Coins ?? 0);
};

const normalizeTypeValue = (value: unknown) => {
  if (value === ItemType.Booster || value === 'Booster' || value === 'booster') return 'Booster';
  return 'Cosmetic';
};

const getXpBoostValue = (shopItem: item) =>
  Number(
    shopItem.xpBoostPercentage ??
    (shopItem as any).xpBoostPercent ??
    (shopItem as any).XpBoostPercentage ??
    (shopItem as any).XpBoostPercent ??
    0,
  );

const getCoinBoostValue = (shopItem: item) =>
  Number(
    shopItem.coinBoostPercentage ??
    (shopItem as any).coinBoostPercent ??
    (shopItem as any).CoinBoostPercentage ??
    (shopItem as any).CoinBoostPercent ??
    0,
  );

const getRealMoneyPriceValue = (shopItem: item) => {
  const raw = shopItem.realMoneyPrice ?? (shopItem as any).RealMoneyPrice;
  if (raw === null || raw === undefined || raw === '') return null;
  const price = Number(raw);
  return Number.isFinite(price) && price > 0 ? price : null;
};

const getCategory = (shopItem: item): ShopDisplayItem['category'] => {
  const searchBase = `${shopItem.name} ${shopItem.description}`.toLowerCase();

  if (/chest|crate|box|truhe|bundle|pack/.test(searchBase)) {
    return 'chest';
  }

  if (
    normalizeTypeValue(shopItem.type) === 'Booster' ||
    getXpBoostValue(shopItem) > 0 ||
    getCoinBoostValue(shopItem) > 0 ||
    /boost|xp|potion|luck/.test(searchBase)
  ) {
    return 'boost';
  }

  return 'item';
};

const getRarity = (shopItem: item): ShopDisplayItem['rarity'] => {
  // Rarity aus Backend nutzen wenn vorhanden
  if (shopItem.rarity) {
    const rarity = String(shopItem.rarity).toLowerCase();
    if (rarity === 'rare' || rarity === 'epic' || rarity === 'legendary' || rarity === 'mythic') return rarity;
    return 'common';
  }

  const searchBase = `${shopItem.name} ${shopItem.description}`.toLowerCase();
  const xpBoost = getXpBoostValue(shopItem);

  if (/mythic|mythisch/.test(searchBase) || shopItem.price >= 1800 || xpBoost >= 140) {
    return 'mythic';
  }
  if (/legend|legendary/.test(searchBase) || shopItem.price >= 1200 || xpBoost >= 100) {
    return 'legendary';
  }
  if (/epic|gold|premium/.test(searchBase) || shopItem.price >= 700 || xpBoost >= 60) {
    return 'epic';
  }
  if (/rare|silver/.test(searchBase) || shopItem.price >= 350 || xpBoost >= 25) {
    return 'rare';
  }
  return 'common';
};

const getIcon = (category: ShopDisplayItem['category'], rarity: ShopDisplayItem['rarity']) => {
  if (category === 'chest') {
    if (rarity === 'mythic') return '🌌';
    if (rarity === 'legendary') return '👑';
    if (rarity === 'epic') return '💎';
    if (rarity === 'rare') return '🎁';
    return '📦';
  }

  if (category === 'boost') {
    if (rarity === 'mythic') return '🌠';
    if (rarity === 'legendary') return '✨';
    if (rarity === 'epic') return '⚡';
    if (rarity === 'rare') return '🧪';
    return '💫';
  }

  return '🛡️';
};

const buildHighlights = (shopItem: item, category: ShopDisplayItem['category']) => {
  const highlights: string[] = [];
  const xpBoost = getXpBoostValue(shopItem);

  if (xpBoost > 0) {
    highlights.push(`+${xpBoost}% XP Boost`);
  }

  if (category === 'chest') {
    highlights.push(text('Loot-Reward Item', 'Loot reward item'));
    highlights.push(text('Ideal für neue Drops', 'Ideal for new drops'));
  } else if (category === 'boost') {
    highlights.push(text('Direkter Fortschritts-Boost', 'Direct progress boost'));
    highlights.push(text('Perfekt für schnelle XP-Runs', 'Perfect for fast XP runs'));
  } else {
    highlights.push(text('Kosmetisches Upgrade', 'Cosmetic upgrade'));
    highlights.push(text('Für Avatar und Sammlung', 'For avatar and collection'));
  }

  if (shopItem.description && !highlights.includes(shopItem.description)) {
    highlights.unshift(shopItem.description);
  }

  return highlights.slice(0, 3);
};

const toDisplayItem = (shopItem: item): ShopDisplayItem => {
  const category = getCategory(shopItem);
  const rarity = getRarity(shopItem);
  const xpBoostPercentage = getXpBoostValue(shopItem);
  const coinBoostPercentage = getCoinBoostValue(shopItem);

  return {
    id: shopItem.id,
    name: shopItem.name,
    description: shopItem.description,
    price: Number(shopItem.price ?? 0),
    realMoneyPrice: getRealMoneyPriceValue(shopItem),
    type: shopItem.type,
    xpBoostPercentage,
    coinBoostPercentage,
    category,
    categoryLabel: category === 'chest' ? text('Chest', 'Chest') : category === 'boost' ? text('Boost', 'Boost') : text('Item', 'Item'),
    rarity,
    icon: getIcon(category, rarity),
    imageUrl: resolveMediaUrl(shopItem.imageUrl ?? (shopItem as any).ImageUrl ?? ''),
    highlights: buildHighlights(shopItem, category),
    ownedQuantity: ownedItems.value[shopItem.id] ?? 0,
  };
};

const formatRealMoneyPrice = (value?: number | null) =>
  Number(value ?? 0).toLocaleString('de-AT', {
    style: 'currency',
    currency: 'EUR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

const dailyCountdown = computed(() => {
  const expiresAt = Date.parse(dailyShopExpiresAtUtc.value);
  if (!Number.isFinite(expiresAt)) return '00:00:00';

  const serverNow = dailyCountdownNowMs.value + dailyShopServerOffsetMs.value;
  const remainingSeconds = Math.max(0, Math.floor((expiresAt - serverNow) / 1000));
  const hours = Math.floor(remainingSeconds / 3600);
  const minutes = Math.floor((remainingSeconds % 3600) / 60);
  const seconds = remainingSeconds % 60;
  return [hours, minutes, seconds].map(value => String(value).padStart(2, '0')).join(':');
});

const tickDailyCountdown = () => {
  dailyCountdownNowMs.value = Date.now();
  const expiresAt = Date.parse(dailyShopExpiresAtUtc.value);
  if (!Number.isFinite(expiresAt) || loading.value) return;

  const serverNow = dailyCountdownNowMs.value + dailyShopServerOffsetMs.value;
  if (serverNow >= expiresAt) {
    dailyShopExpiresAtUtc.value = '';
    void loadShopItems();
  }
};

const loadProfile = async () => {
  try {
    await userService.getProfile();
  } catch (profileError) {
    console.warn('Profil konnte nicht aktualisiert werden:', profileError);
  } finally {
    syncCoinsFromStorage();
    refreshUser(); 
  }
};

const loadShopItems = async () => {
  loading.value = true;
  error.value = '';

  try {
    const response = await itemService.getDailyShop();
    const dailyShop = response.data ?? {};
    const rawItems = dailyShop.items ?? dailyShop.Items ?? [];
    const serverTime = dailyShop.serverTimeUtc ?? dailyShop.ServerTimeUtc;
    const expiresAt = dailyShop.expiresAtUtc ?? dailyShop.ExpiresAtUtc;

    dailyShopExpiresAtUtc.value = String(expiresAt ?? '');
    dailyShopServerOffsetMs.value = serverTime ? Date.parse(serverTime) - Date.now() : 0;
    dailyCountdownNowMs.value = Date.now();
    items.value = rawItems.map(toDisplayItem);
  } catch (shopError: any) {
    console.error('Fehler beim Laden der Shop-Items:', shopError);
    error.value = shopError.response?.data?.message || shopError.response?.data || text('Fehler beim Laden der Shop-Items', 'Could not load shop items');
  } finally {
    loading.value = false;
  }
};

const loadRealMoneyItems = async () => {
  try {
    const response = await itemService.getShopItems();
    const rawItems = Array.isArray(response.data) ? response.data : [];
    realMoneyItems.value = rawItems
      .map(toDisplayItem)
      .filter(item => Number(item.realMoneyPrice ?? 0) > 0);
  } catch (shopError) {
    console.error('Fehler beim Laden der Echtgeld-Angebote:', shopError);
    realMoneyItems.value = [];
  }
};

const toDisplayChest = (raw: any): Chest => ({
  id: Number(raw.id ?? raw.Id ?? 0),
  name: String(raw.name ?? raw.Name ?? ''),
  price: Number(raw.price ?? raw.Price ?? 0),
  imageUrl: resolveMediaUrl(raw.imageUrl ?? raw.ImageUrl ?? ''),
  commonChance: Number(raw.commonChance ?? raw.CommonChance ?? 0),
  rareChance: Number(raw.rareChance ?? raw.RareChance ?? 0),
  epicChance: Number(raw.epicChance ?? raw.EpicChance ?? 0),
  legendaryChance: Number(raw.legendaryChance ?? raw.LegendaryChance ?? 0),
  mythicChance: Number(raw.mythicChance ?? raw.MythicChance ?? 0),
  items: (raw.items ?? raw.Items ?? []).map((item: any) => ({
    ...item,
    id: item.id ?? item.Id,
    name: item.name ?? item.Name,
    imageUrl: item.imageUrl ?? item.ImageUrl,
  })),
});

const loadChests = async () => {
  try {
    const response = await itemService.getChests();
    chests.value = (Array.isArray(response.data) ? response.data : []).map(toDisplayChest);
  } catch (chestError) {
    console.error('Fehler beim Laden der Chests:', chestError);
  }
};

const closeChestOpening = () => {
  if (chestRevealStarted.value && !openedReward.value && openingChestId.value) return;
  chestOpening.value = null;
  openedReward.value = null;
  chestRevealStarted.value = false;
  openingChestId.value = null;
};

const getOpenChestImage = (chest: Chest | null) => {
  const name = String(chest?.name ?? '').toLowerCase();
  const imageUrl = String(chest?.imageUrl ?? '').toLowerCase();
  const search = `${name} ${imageUrl}`;
  if (search.includes('premium') || search.includes('prestige')) return prestigeChestOpenImage;
  if (search.includes('gold')) return goldChestOpenImage;
  return starterChestOpenImage;
};

const openChest = (chest: Chest) => {
  pendingPurchase.value = null;
  chestOpening.value = chest;
  openedReward.value = null;
  chestRevealStarted.value = false;
};

const revealChest = async () => {
  if (!chestOpening.value || chestRevealStarted.value) return;
  openingChestId.value = chestOpening.value.id;
  chestRevealStarted.value = true;

  try {
    const response = await itemService.openChest(chestOpening.value.id);
    openedReward.value = response.data?.item ?? response.data?.Item ?? null;
    const remainingCoins = response.data?.remainingCoins ?? response.data?.RemainingCoins;
    if (remainingCoins !== undefined) currentCoins.value = Number(remainingCoins);
    await loadProfile();
    await loadOwnedItems();
    await loadShopItems();
  } catch (openError: any) {
    chestOpening.value = null;
    chestRevealStarted.value = false;
    popupType.value = 'error';
    popupMessage.value = openError.response?.data?.message || openError.response?.data || text('Chest konnte nicht geöffnet werden', 'Chest could not be opened');
  } finally {
    openingChestId.value = null;
  }
};

const requestOpenChest = (chest: Chest) => {
  if (openingChestId.value !== null) return;
  pendingPurchase.value = { type: 'chest', chest };
};

const buyItem = async (shopItem: ShopDisplayItem) => {
  pendingPurchase.value = null;
  buyingItemId.value = shopItem.id;
  error.value = '';
  successMessage.value = '';

  try {
  await itemService.buyItem(shopItem.id);
  await loadProfile();

  // Owned-Quantity lokal hochzählen
  ownedItems.value[shopItem.id] = (ownedItems.value[shopItem.id] ?? 0) + 1;
  // Items neu mappen damit Quantity aktualisiert wird
  items.value = items.value.map(i => ({ ...i, ownedQuantity: ownedItems.value[i.id] ?? 0 }));

  popupType.value = "success";
  popupMessage.value = text(
    `${shopItem.name} gekauft! Verbleibende Coins: ${currentCoins.value}`,
    `${shopItem.name} purchased! Remaining coins: ${currentCoins.value}`
  );
} catch (buyError: any) {
  console.error("Fehler beim Kauf:", buyError);

  popupType.value = "error";
  popupMessage.value =
    buyError.response?.data?.message ||
    buyError.response?.data ||
    text("Kauf fehlgeschlagen", "Purchase failed");
} finally {
  buyingItemId.value = null;
}

};

const requestBuyItem = (shopItem: ShopDisplayItem) => {
  if (buyingItemId.value !== null) return;
  pendingPurchase.value = { type: 'item', item: shopItem };
};

const requestRealMoneyPurchase = async (shopItem: ShopDisplayItem) => {
  if (realMoneyBusyItemId.value !== null) return;
  realMoneyBusyItemId.value = shopItem.id;

  try {
    const response = await itemService.startRealMoneyPurchase(shopItem.id);
    popupType.value = 'info';
    popupMessage.value = response.data?.message || text('Echtgeld-Käufe sind noch in Arbeit.', 'Real-money purchases are still in progress.');
  } catch (purchaseError: any) {
    const message =
      purchaseError.response?.data?.message ||
      purchaseError.response?.data ||
      text('Echtgeld-Käufe sind noch in Arbeit.', 'Real-money purchases are still in progress.');
    popupType.value = purchaseError.response?.status === 501 ? 'info' : 'error';
    popupMessage.value = message;
  } finally {
    realMoneyBusyItemId.value = null;
  }
};

const confirmPurchase = () => {
  if (!pendingPurchase.value) return;
  if (pendingPurchase.value.type === 'item') {
    buyItem(pendingPurchase.value.item);
  } else {
    openChest(pendingPurchase.value.chest);
  }
};

const pendingPurchaseName = computed(() => {
  if (!pendingPurchase.value) return '';
  return pendingPurchase.value.type === 'item'
    ? pendingPurchase.value.item.name
    : pendingPurchase.value.chest.name;
});

const pendingPurchasePrice = computed(() => {
  if (!pendingPurchase.value) return 0;
  return pendingPurchase.value.type === 'item'
    ? pendingPurchase.value.item.price
    : pendingPurchase.value.chest.price;
});
const canConfirmPurchase = computed(() => currentCoins.value >= pendingPurchasePrice.value);

const rewardRarity = computed(() => {
  const raw = String(openedReward.value?.rarity ?? openedReward.value?.Rarity ?? 'common').toLowerCase();
  if (raw === 'rare' || raw === 'epic' || raw === 'legendary' || raw === 'mythic') return raw;
  return 'common';
});

const rarityLabel = (rarity: string) => (rarity === 'mythic' ? 'Mythisch' : translate(rarity));
const rewardName = (reward: any) => translate(reward?.name ?? reward?.Name ?? '');
const rewardImageUrl = (reward: any) => resolveMediaUrl(reward?.imageUrl ?? reward?.ImageUrl ?? '');

const loadOwnedItems = async () => {
  try {
    const res = await userService.getUserBoosters();
    const boosters = res.data ?? [];
    const map: Record<number, number> = {};
    for (const b of boosters) {
      map[b.id] = b.quantity ?? 1;
    }
    ownedItems.value = map;
  } catch (e) {
    console.warn('Inventar konnte nicht geladen werden', e);
  }
};

const loadPageData = async () => {
  syncCoinsFromStorage();
  await loadProfile();
  await loadOwnedItems();
  await Promise.all([loadShopItems(), loadChests(), loadRealMoneyItems()]);
};

onMounted(() => {
  void loadPageData();
  dailyCountdownTimer = window.setInterval(tickDailyCountdown, 1000);
});

onUnmounted(() => {
  if (dailyCountdownTimer !== undefined) {
    window.clearInterval(dailyCountdownTimer);
  }
});
</script>

<template>

  <MessagePopup
  v-if="popupMessage"
  :message="popupMessage"
  :type="popupType"
  @close="popupMessage = ''"
/>

  <div class="shop-page-shell">
    <Header />
    <Navbar />

    <main class="shop-page">
      <section class="shop-hero-card">
        <div class="hero-copy">
          <h1>{{ text('Item Shop', 'Item Shop') }}</h1>
          <p>{{ text('Booster, Chests und mehr.', 'Boosters, chests and more.') }}</p>
        </div>

      </section>

      <div v-if="loading" class="state-box">{{ text('Lade Shop-Items…', 'Loading shop items…') }}</div>
      <div v-if="error" class="state-box state-box-error">{{ error }}</div>

      <template v-if="!loading">
        <section v-if="items.length" class="section-card">
          <div class="section-heading section-heading-spread daily-section-heading">
            <div>
              <div class="title-with-icon">
                <h2>{{ text('Tägliche Items', 'Daily items') }}</h2>
              </div>
              <p>{{ text('3 Items direkt kaufbar.', '3 items available directly.') }}</p>
            </div>
            <span class="daily-reset-timer">{{ dailyCountdown }}</span>
          </div>

          <div class="feature-grid">
            <ShopFeatureCard
              v-for="shopItem in items"
              :key="`daily-${shopItem.id}`"
              :item="shopItem"
              :current-coins="currentCoins"
              :busy="buyingItemId === shopItem.id"
              @buy="requestBuyItem"
            />
          </div>
        </section>

        <section v-if="chests.length" class="section-card">
          <div class="section-heading section-heading-spread">
            <div>
              <div class="title-with-icon">
                <Package :size="20" />
                <h2>Chests</h2>
              </div>
              <p>{{ text('Öffne Chests für seltene, legendäre und mythische Drops.', 'Open chests for a chance at rare, legendary and mythic loot.') }}</p>
            </div>
          </div>

          <div class="items-grid chest-grid">
            <ShopChestCard
              v-for="chest in chests"
              :key="`chest-${chest.id}`"
              :chest="chest"
              :current-coins="currentCoins"
              :busy="openingChestId === chest.id"
              @open="requestOpenChest"
            />
          </div>
        </section>

        <section v-if="realMoneyItems.length" class="section-card">
          <div class="section-heading section-heading-spread">
            <div>
              <div class="title-with-icon">
                <h2>Echtgeld-Angebote</h2>
              </div>
              <p>Die Preise kommen aus dem Admin-Bereich. Die Zahlungsabwicklung ist noch nicht freigeschaltet.</p>
            </div>
          </div>

          <div class="real-money-grid">
            <article
              v-for="shopItem in realMoneyItems"
              :key="`real-money-${shopItem.id}`"
              class="real-money-card"
            >
              <div class="real-money-image-shell">
                <img v-if="shopItem.imageUrl" :src="shopItem.imageUrl" alt="" class="real-money-image" />
                <Package v-else :size="42" />
              </div>

              <div class="real-money-copy">
                <h3>{{ translate(shopItem.name) }}</h3>
                <p>{{ shopItem.categoryLabel }}</p>
                <strong>{{ formatRealMoneyPrice(shopItem.realMoneyPrice) }}</strong>
              </div>

              <button
                class="real-money-buy"
                type="button"
                :disabled="realMoneyBusyItemId === shopItem.id"
                @click="requestRealMoneyPurchase(shopItem)"
              >
                {{ realMoneyBusyItemId === shopItem.id ? '...' : 'Kaufen' }}
              </button>
            </article>
          </div>
        </section>

        <section class="section-card earn-card">
          <div class="earn-copy">
            <div class="earn-title">
              <div>
                <h2>{{ text('Coins verdienen', 'Earn coins') }}</h2>
                <p>{{ text('Schließe Aktivitäten ab. Die Coins werden danach automatisch deinem Konto gutgeschrieben.', 'Complete activities. Coins are added to your account automatically afterwards.') }}</p>
              </div>
            </div>
          </div>

          <div class="earn-stats">
            <article class="earn-pill">
              <div>
                <span>{{ text('Workout abschließen', 'Complete workout') }}</span>
                <strong>
                  <img :src="coinIcon" alt="" class="earn-coin" />
                  50–150
                </strong>
              </div>
            </article>
            <article class="earn-pill">
              <div>
                <span>{{ text('Quest erledigen', 'Complete quest') }}</span>
                <strong>
                  <img :src="coinIcon" alt="" class="earn-coin" />
                  100–500
                </strong>
              </div>
            </article>
          </div>
        </section>
      </template>
    </main>
     <!-- Footer -->
    <FooterComponent />

    <Teleport to="body">
      <Transition name="confirm-pop">
        <div v-if="pendingPurchase" class="confirm-overlay" @click.self="pendingPurchase = null">
          <div class="confirm-dialog">
            <h3>{{ text('Bist du sicher?', 'Are you sure?') }}</h3>
            <p>{{ translate(pendingPurchaseName) }} {{ text('kaufen', 'buy') }}</p>
            <div class="confirm-price">
              <span>{{ text('Kosten', 'Cost') }}</span>
              <strong>
                <img :src="coinIcon" alt="" />
                {{ pendingPurchasePrice }}
              </strong>
            </div>
            <div class="confirm-actions">
              <button class="confirm-cancel" type="button" @click="pendingPurchase = null">{{ text('Abbrechen', 'Cancel') }}</button>
              <button class="confirm-buy" type="button" :disabled="!canConfirmPurchase" @click="confirmPurchase">
                {{ pendingPurchase.type === 'chest' ? text('Öffnen', 'Open') : text('Kaufen', 'Buy') }}
              </button>
            </div>
          </div>
        </div>
      </Transition>

      <Transition name="chest-open">
        <div v-if="chestOpening" class="chest-open-overlay" @click.self="closeChestOpening">
          <div class="chest-open-stage" :class="{ revealed: chestRevealStarted }">
            <button
              v-if="openedReward"
              class="chest-open-close"
              type="button"
              aria-label="Schließen"
              data-tooltip="Schließen"
              @click="closeChestOpening"
            >
              &times;
            </button>

            <button
              v-if="!chestRevealStarted"
              class="opening-chest-button"
              type="button"
              @click="revealChest"
            >
              <img :src="chestOpening.imageUrl" alt="" class="opening-chest-image" />
              <span class="opening-text">{{ text('Klicke zum Öffnen', 'Click to open') }}</span>
            </button>

            <div v-else class="opened-chest-scene">
              <div class="opened-chest-reveal" :class="{ 'has-reward': openedReward }">
                <img :src="getOpenChestImage(chestOpening)" alt="" class="opened-chest-image" />
                <div v-if="openedReward" class="reward-card reward-from-chest">
                  <div class="reward-burst"></div>
                  <div class="reward-image">
                    <img
                      v-if="rewardImageUrl(openedReward)"
                      :src="rewardImageUrl(openedReward)"
                      alt=""
                    />
                    <span v-else>✨</span>
                  </div>
                </div>
              </div>
              <div v-if="!openedReward" class="opening-text opening-text-loading">{{ text('Öffnet...', 'Opening...') }}</div>
              <div v-else class="reward-meta-below">
                <h3>{{ rewardName(openedReward) }}</h3>
                <p :class="`reward-rarity-${rewardRarity}`">{{ rarityLabel(rewardRarity) }}</p>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.shop-page-shell {
  min-height: 100vh;
  color: white;
}

.shop-page {
  width: min(1280px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 48px;
  display: grid;
  gap: 24px;
}

.section-card,
.state-box,
.empty-box {
  border-radius: 22px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.62);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-shadow: 0 18px 42px rgba(2, 6, 23, 0.24);
}

.shop-hero-card {
  display: block;
  padding: 0;
  background: transparent;
}

.hero-copy h1 {
  margin: 0;
  font-size: clamp(2rem, 4vw, 3.4rem);
  line-height: 1;
}

.hero-copy p {
  margin: 16px 0 0;
  color: rgba(255, 255, 255, 0.84);
  max-width: 58ch;
  line-height: 1.65;
}

.section-card {
  padding: clamp(22px, 3vw, 30px);
}

.section-heading {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 22px;
}

.section-heading p {
  margin: 0;
  color: #cbd5e1;
}

.section-heading-spread {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.title-with-icon {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title-with-icon h2 {
  margin: 0;
  font-size: 1.2rem;
}

.title-with-icon svg {
  color: #facc15;
}

.daily-section-heading > div {
  min-width: 0;
}

.mini-pill {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 10px 14px;
  color: #fde68a;
  background: rgba(250, 204, 21, 0.1);
  border: 1px solid rgba(250, 204, 21, 0.2);
  white-space: nowrap;
}

.daily-reset-timer {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 8px 12px;
  color: #f9a8d4;
  background: rgba(236, 72, 153, 0.12);
  border: 1px solid rgba(236, 72, 153, 0.3);
  font-weight: 900;
  font-variant-numeric: tabular-nums;
  line-height: 1;
  white-space: nowrap;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 18px;
}

.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 18px;
}

.chest-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
  margin-bottom: 18px;
}

.coin-pack-grid,
.real-money-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
  align-items: stretch;
}

.coin-pack-card,
.real-money-card {
  position: relative;
  min-height: 252px;
  display: flex;
  flex-direction: column;
  padding: clamp(16px, 2vw, 22px);
  padding-bottom: 64px;
  overflow: hidden;
  border-radius: 22px;
  background:
    radial-gradient(circle at 50% 18%, rgba(236, 72, 153, 0.16), transparent 36%),
    rgba(8, 10, 31, 0.78);
  border: 1px solid rgba(236, 72, 153, 0.2);
  box-shadow: 0 20px 38px rgba(2, 6, 23, 0.22);
}

.coin-pack-image-shell,
.real-money-image-shell {
  min-height: 116px;
  display: grid;
  place-items: center;
  color: #fce7f3;
}

.coin-pack-image,
.real-money-image {
  width: min(148px, 70%);
  height: 116px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 18px 24px rgba(0, 0, 0, 0.42));
}

.coin-pack-copy,
.real-money-copy {
  margin-top: auto;
  display: grid;
  gap: 8px;
}

.coin-pack-copy h3,
.real-money-copy h3 {
  margin: 0;
  color: white;
  font-size: clamp(1.12rem, 1.8vw, 1.45rem);
  line-height: 1.05;
  font-weight: 900;
}

.real-money-copy p {
  margin: 0;
  color: rgba(255, 255, 255, 0.62);
  font-size: 0.82rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.coin-pack-copy strong,
.real-money-copy strong {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #facc15;
  font-size: clamp(1.15rem, 2vw, 1.5rem);
  line-height: 1;
  font-weight: 900;
}

.coin-pack-copy img {
  width: 23px;
  height: 23px;
  object-fit: contain;
  image-rendering: pixelated;
}

.coin-pack-buy,
.real-money-buy {
  position: absolute;
  right: 16px;
  bottom: 16px;
  min-width: 96px;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
  border-radius: 8px;
  color: white;
  background:
    linear-gradient(135deg, rgba(34, 197, 94, 0.24), rgba(20, 83, 45, 0.86)),
    rgba(6, 78, 59, 0.7);
  border: 1px solid rgba(74, 222, 128, 0.42);
  box-shadow: 0 14px 28px rgba(21, 128, 61, 0.16), inset 0 0 20px rgba(34, 197, 94, 0.08);
  font-weight: 900;
  line-height: 1;
}

.coin-pack-buy {
  cursor: default;
}

.real-money-buy {
  cursor: pointer;
  transition: transform 0.18s ease, filter 0.18s ease;
}

.real-money-buy:hover:not(:disabled) {
  transform: translateY(-1px);
  filter: brightness(1.08);
}

.real-money-buy:disabled {
  cursor: wait;
  opacity: 0.72;
}

.confirm-overlay {
  position: fixed;
  inset: 0;
  z-index: 10020;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(0, 0, 0, 0.68);
  backdrop-filter: blur(8px);
}

.confirm-dialog {
  width: min(360px, 92vw);
  padding: 22px;
  border-radius: 18px;
  background: rgba(15, 23, 42, 0.96);
  border: 1px solid rgba(236, 72, 153, 0.28);
  box-shadow: 0 26px 60px rgba(0, 0, 0, 0.42);
}

.confirm-dialog h3 {
  margin: 0;
  color: white;
  font-size: 1.25rem;
  font-weight: 900;
}

.confirm-dialog p {
  margin: 8px 0 16px;
  color: rgba(255, 255, 255, 0.68);
  font-weight: 800;
}

.confirm-price {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 12px 14px;
  border-radius: 12px;
  background: rgba(2, 6, 23, 0.48);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.confirm-price span {
  color: rgba(255, 255, 255, 0.58);
  font-weight: 800;
}

.confirm-price strong {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: #f8fafc;
  font-weight: 900;
  line-height: 1;
}

.confirm-price img {
  width: 20px;
  height: 20px;
  object-fit: contain;
  image-rendering: pixelated;
}

.confirm-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 18px;
}

.confirm-actions button {
  min-height: 44px;
  border-radius: 11px;
  font-weight: 900;
  cursor: pointer;
}

.confirm-cancel {
  border: 1px solid rgba(148, 163, 184, 0.22);
  background: rgba(30, 41, 59, 0.76);
  color: rgba(255, 255, 255, 0.72);
}

.confirm-buy {
  border: 1px solid rgba(74, 222, 128, 0.42);
  background: linear-gradient(135deg, rgba(34, 197, 94, 0.24), rgba(20, 83, 45, 0.86));
  color: white;
}

.confirm-buy:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.confirm-pop-enter-active,
.confirm-pop-leave-active {
  transition: opacity 0.18s ease;
}

.confirm-pop-enter-active .confirm-dialog,
.confirm-pop-leave-active .confirm-dialog {
  transition: transform 0.18s ease;
}

.confirm-pop-enter-from,
.confirm-pop-leave-to {
  opacity: 0;
}

.confirm-pop-enter-from .confirm-dialog,
.confirm-pop-leave-to .confirm-dialog {
  transform: translateY(12px) scale(0.96);
}

.chest-open-overlay {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: grid;
  place-items: center;
  padding: 24px;
  background:
    radial-gradient(circle at 50% 42%, rgba(236, 72, 153, 0.16), transparent 34%),
    rgba(0, 0, 0, 0.82);
  backdrop-filter: blur(10px);
}

.chest-open-stage {
  position: relative;
  width: min(620px, 92vw);
  min-height: min(620px, 82vh);
  display: grid;
  place-items: center;
  background: transparent;
}

.chest-open-close {
  position: fixed;
  top: clamp(18px, 4vw, 34px);
  right: clamp(18px, 4vw, 38px);
  z-index: 3;
  border: 0;
  background: transparent;
  color: white;
  font-size: 44px;
  line-height: 1;
  cursor: pointer;
  opacity: 0.92;
  transition: transform 0.18s ease, opacity 0.18s ease;
}

.chest-open-close:hover {
  transform: scale(1.08);
  opacity: 1;
}

.opening-chest-button {
  display: grid;
  justify-items: center;
  gap: 22px;
  border: 0;
  padding: 0;
  background: transparent;
  color: inherit;
  cursor: pointer;
}

.opening-chest-image {
  width: clamp(240px, 32vw, 410px);
  height: clamp(240px, 32vw, 410px);
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 28px 42px rgba(0, 0, 0, 0.54));
  animation: chestOpenPulse 1.05s ease-in-out infinite;
}

.opening-text {
  color: rgba(255, 255, 255, 0.72);
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  animation: openHintPulse 1.1s ease-in-out infinite alternate;
}

.opened-chest-scene {
  display: grid;
  justify-items: center;
  gap: 18px;
}

.opened-chest-reveal {
  position: relative;
  width: min(520px, 86vw);
  min-height: clamp(260px, 34vw, 430px);
  display: grid;
  place-items: center;
}

.opened-chest-reveal.has-reward {
  height: min(500px, 62vh);
  min-height: 390px;
  align-items: end;
}

.opened-chest-image {
  width: clamp(260px, 34vw, 440px);
  height: clamp(210px, 28vw, 350px);
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 28px 42px rgba(0, 0, 0, 0.54));
  animation: rewardReveal 0.42s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.opened-chest-reveal.has-reward .opened-chest-image {
  width: clamp(250px, 27vw, 360px);
  height: clamp(190px, 21vw, 270px);
  filter: brightness(0.58) saturate(0.85) drop-shadow(0 28px 42px rgba(0, 0, 0, 0.6));
}

.opening-text-loading {
  color: rgba(255, 255, 255, 0.62);
}

.reward-card {
  position: relative;
  display: grid;
  justify-items: center;
  gap: 10px;
  text-align: center;
  animation: rewardReveal 0.62s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.reward-from-chest {
  position: absolute;
  top: clamp(-8px, -1.5vw, 0px);
  left: 50%;
  transform: translateX(-50%);
  width: min(340px, 78vw);
  animation: rewardFromChest 0.72s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.reward-from-chest .reward-image {
  width: clamp(132px, 13vw, 178px);
  height: clamp(132px, 13vw, 178px);
}

.reward-from-chest .reward-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.reward-meta-below {
  display: grid;
  justify-items: center;
  gap: 8px;
  text-align: center;
  animation: rewardReveal 0.48s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.reward-burst {
  position: absolute;
  top: -50px;
  width: 260px;
  height: 260px;
  border-radius: 999px;
  background: radial-gradient(circle, rgba(250, 204, 21, 0.2), rgba(236, 72, 153, 0.14) 34%, transparent 68%);
  filter: blur(2px);
  animation: rewardGlow 1.4s ease-in-out infinite alternate;
  pointer-events: none;
}

.reward-image {
  position: relative;
  z-index: 1;
  width: clamp(140px, 18vw, 210px);
  height: clamp(140px, 18vw, 210px);
  display: grid;
  place-items: center;
}

.reward-image img {
  width: auto;
  height: auto;
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 24px 34px rgba(0, 0, 0, 0.55));
  animation: rewardFloat 1.9s ease-in-out infinite;
}

.reward-image span {
  font-size: clamp(5rem, 12vw, 8rem);
  filter: drop-shadow(0 20px 30px rgba(0, 0, 0, 0.45));
}

.reward-card h3 {
  position: relative;
  z-index: 1;
  margin: 0;
  color: white;
  font-size: clamp(1.8rem, 3.2vw, 2.8rem);
  font-weight: 900;
  line-height: 0.95;
  text-shadow: 0 18px 34px rgba(0, 0, 0, 0.4);
}

.reward-meta-below h3 {
  margin: 0;
  color: white;
  font-size: clamp(2rem, 3.8vw, 3.4rem);
  font-weight: 900;
  line-height: 0.95;
  text-shadow: 0 18px 34px rgba(0, 0, 0, 0.4);
}

.reward-card p,
.reward-meta-below p {
  position: relative;
  z-index: 1;
  margin: 0;
  color: var(--reward-rarity-color, #cbd5e1);
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  font-size: clamp(1rem, 2vw, 1.3rem);
  text-shadow: 0 0 18px color-mix(in srgb, var(--reward-rarity-color, #cbd5e1) 45%, transparent);
}

.reward-rarity-common {
  --reward-rarity-color: #cbd5e1;
}

.reward-rarity-rare {
  --reward-rarity-color: #60a5fa;
}

.reward-rarity-epic {
  --reward-rarity-color: #c084fc;
}

.reward-rarity-legendary {
  --reward-rarity-color: #fbbf24;
}

.reward-rarity-mythic {
  --reward-rarity-color: #f472b6;
}

.chest-open-enter-active,
.chest-open-leave-active {
  transition: opacity 0.22s ease;
}

.chest-open-enter-from,
.chest-open-leave-to {
  opacity: 0;
}

@keyframes chestOpenPulse {
  0%, 100% {
    transform: translateY(0) scale(1) rotate(-1deg);
  }
  50% {
    transform: translateY(-8px) scale(1.12) rotate(1deg);
  }
}

@keyframes openHintPulse {
  from {
    opacity: 0.48;
    filter: brightness(0.82);
  }
  to {
    opacity: 1;
    filter: brightness(1.18);
  }
}

@keyframes rewardReveal {
  from {
    opacity: 0;
    transform: translateY(28px) scale(0.72);
    filter: blur(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
  }
}

@keyframes rewardFromChest {
  from {
    opacity: 0;
    transform: translate(-50%, 120px) scale(0.58);
    filter: blur(8px);
  }
  60% {
    opacity: 1;
    transform: translate(-50%, -14px) scale(1.06);
    filter: blur(0);
  }
  to {
    opacity: 1;
    transform: translate(-50%, 0) scale(1);
    filter: blur(0);
  }
}

@keyframes rewardFloat {
  0%, 100% { transform: translateY(0) scale(1); }
  50% { transform: translateY(-8px) scale(1.03); }
}

@keyframes rewardGlow {
  from { transform: scale(0.92); opacity: 0.72; }
  to { transform: scale(1.08); opacity: 1; }
}

.earn-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 20px;
  align-items: center;
}

.earn-title {
  display: flex;
  align-items: center;
  gap: 16px;
}

.earn-title-coin {
  width: 42px;
  height: 42px;
  image-rendering: pixelated;
  flex: 0 0 auto;
}

.earn-title h2 {
  margin: 0;
  font-size: 1.35rem;
}

.earn-title p {
  margin: 8px 0 0;
  color: #cbd5e1;
  line-height: 1.5;
}

.earn-stats {
  display: grid;
  grid-template-columns: repeat(2, minmax(170px, 1fr));
  gap: 12px;
}

.earn-pill {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 18px;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(255, 255, 255, 0.075);
}

.earn-coin {
  width: 24px;
  height: 24px;
  image-rendering: pixelated;
  flex: 0 0 auto;
}

.earn-pill span {
  display: block;
  color: rgba(255, 255, 255, 0.62);
  font-size: 0.82rem;
  font-weight: 700;
}

.earn-pill strong {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
  color: white;
  font-size: 1.05rem;
}

.state-box,
.empty-box {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 26px;
}

.state-box-error {
  color: #fecaca;
  background: rgba(127, 29, 29, 0.32);
}

.state-box-success {
  color: #dcfce7;
  background: rgba(20, 83, 45, 0.3);
}

@media (max-width: 980px) {
  .earn-card,
  .section-heading-spread {
    grid-template-columns: 1fr;
  }

  .chest-grid,
  .coin-pack-grid,
  .real-money-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .section-heading-spread {
    align-items: flex-start;
  }

}

@media (max-width: 760px) {
  .shop-page {
    width: min(100%, calc(100% - 24px));
    padding-top: 24px;
  }

  .earn-stats {
    grid-template-columns: 1fr;
  }

  .chest-grid,
  .coin-pack-grid,
  .real-money-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }

  .section-card {
    padding: 16px;
  }

  .coin-pack-card,
  .real-money-card {
    min-height: 198px;
    padding: 10px;
    padding-bottom: 52px;
    border-radius: 18px;
  }

  .coin-pack-image-shell,
  .real-money-image-shell {
    min-height: 76px;
  }

  .coin-pack-image,
  .real-money-image {
    width: min(92px, 88%);
    height: 74px;
  }

  .coin-pack-copy,
  .real-money-copy {
    gap: 6px;
  }

  .coin-pack-copy h3,
  .real-money-copy h3 {
    font-size: 0.82rem;
    line-height: 1.08;
    text-align: center;
  }

  .coin-pack-copy strong,
  .real-money-copy strong {
    justify-content: center;
    gap: 5px;
    font-size: 1rem;
  }

  .coin-pack-copy img {
    width: 18px;
    height: 18px;
  }

  .real-money-copy p {
    text-align: center;
    font-size: 0.68rem;
  }

  .coin-pack-buy,
  .real-money-buy {
    left: 10px;
    right: 10px;
    bottom: 10px;
    min-width: 0;
    min-height: 36px;
    padding: 0 8px;
    border-radius: 8px;
    font-size: 0.9rem;
  }
}

@media (max-width: 560px) {
  .shop-page {
    width: min(100%, calc(100% - 16px));
    gap: 18px;
  }

  .section-card,
  .state-box,
  .empty-box {
    border-radius: 22px;
  }
}
</style>
