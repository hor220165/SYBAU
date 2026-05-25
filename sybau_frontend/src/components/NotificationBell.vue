<script setup lang="ts">
import { ref } from 'vue';
import { useNotifications } from '@/composables/useNotifications';
import { useRouter } from 'vue-router';

const router = useRouter();
const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();
const showDropdown = ref(false);

const toggle = () => {
  showDropdown.value = !showDropdown.value;
};

const close = () => {
  showDropdown.value = false;
};

const handleClick = (n: any) => {
  markAsRead(n.id);
  if (n.type === 'friend_request' || n.type === 'friend_accepted') {
    router.push('/friends');
  }
  close();
};

const iconForType = (type: string) => {
  switch (type) {
    case 'friend_request': return '👋';
    case 'friend_accepted': return '🤝';
    case 'challenge_received': return '⚔️';
    case 'challenge_completed': return '🏆';
    default: return '🔔';
  }
};

const timeAgo = (date: Date) => {
  const diff = Date.now() - new Date(date).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Gerade eben';
  if (mins < 60) return `vor ${mins} Min.`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `vor ${hrs} Std.`;
  return `vor ${Math.floor(hrs / 24)} Tag(en)`;
};
</script>

<template>
  <div class="notification-wrapper" v-click-outside="close">
    <button
      class="notification-bell"
      type="button"
      aria-label="Benachrichtigungen"
      data-tooltip="Benachrichtigungen"
      @click="toggle"
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none"
           stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
      </svg>
      <span v-if="unreadCount > 0" class="badge">{{ unreadCount > 9 ? '9+' : unreadCount }}</span>
    </button>

    <Transition name="dropdown">
      <div v-if="showDropdown" class="dropdown">
        <div class="dropdown-header">
          <span class="dropdown-title">Benachrichtigungen</span>
          <button v-if="unreadCount > 0" class="mark-read-btn" @click="markAllAsRead">
            Alle gelesen
          </button>
        </div>

        <div v-if="notifications.length === 0" class="dropdown-empty">
          Keine Benachrichtigungen
        </div>

        <div v-else class="dropdown-list">
          <div v-for="n in notifications" :key="n.id"
               class="notification-item" :class="{ unread: !n.read }"
               @click="handleClick(n)">
            <span class="notification-icon">{{ iconForType(n.type) }}</span>
            <div class="notification-content">
              <span class="notification-title">{{ n.title }}</span>
              <span class="notification-msg">{{ n.message }}</span>
              <span class="notification-time">{{ timeAgo(n.timestamp) }}</span>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.notification-wrapper {
  position: relative;
}

.notification-bell {
  position: relative;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  padding: 8px;
  border-radius: 10px;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.notification-bell:hover {
  color: white;
  background: rgba(255, 255, 255, 0.08);
}

.badge {
  position: absolute;
  top: 2px;
  right: 2px;
  background: #ff2d75;
  color: white;
  font-size: 11px;
  font-weight: 700;
  min-width: 18px;
  height: 18px;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
  animation: badgePop 0.3s ease;
}

@keyframes badgePop {
  0% { transform: scale(0); }
  50% { transform: scale(1.3); }
  100% { transform: scale(1); }
}

.dropdown {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  width: 340px;
  max-height: 420px;
  background: rgba(20, 24, 45, 0.97);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
  z-index: 9999;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.dropdown-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.dropdown-title {
  color: white;
  font-weight: 600;
  font-size: 0.95rem;
}

.mark-read-btn {
  background: none;
  border: none;
  color: #ff2d75;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.mark-read-btn:hover {
  opacity: 0.8;
}

.dropdown-empty {
  padding: 32px 16px;
  text-align: center;
  color: rgba(255, 255, 255, 0.4);
  font-size: 0.9rem;
}

.dropdown-list {
  overflow-y: auto;
  max-height: 360px;
}

.notification-item {
  display: flex;
  gap: 12px;
  padding: 12px 16px;
  cursor: pointer;
  transition: background 0.15s ease;
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}

.notification-item:hover {
  background: rgba(255, 255, 255, 0.05);
}

.notification-item.unread {
  background: rgba(255, 45, 117, 0.06);
}

.notification-item.unread::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: #ff2d75;
  border-radius: 0 3px 3px 0;
}

.notification-icon {
  font-size: 1.4rem;
  flex-shrink: 0;
  margin-top: 2px;
}

.notification-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.notification-title {
  color: white;
  font-weight: 600;
  font-size: 0.85rem;
}

.notification-msg {
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.82rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.notification-time {
  color: rgba(255, 255, 255, 0.35);
  font-size: 0.75rem;
  margin-top: 2px;
}

/* Dropdown Transition */
.dropdown-enter-active {
  transition: all 0.2s ease;
}
.dropdown-leave-active {
  transition: all 0.15s ease;
}
.dropdown-enter-from {
  opacity: 0;
  transform: translateY(-8px) scale(0.96);
}
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.98);
}

@media (max-width: 768px) {
  .dropdown {
    width: 300px;
    right: -60px;
  }
}
</style>
