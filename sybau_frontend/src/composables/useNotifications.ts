import { ref, readonly } from 'vue';
import * as signalR from '@microsoft/signalr';

export interface AppNotification {
  id: number;
  type: 'friend_request' | 'friend_accepted' | 'challenge_received' | 'challenge_completed';
  title: string;
  message: string;
  timestamp: Date;
  read: boolean;
}

let connection: signalR.HubConnection | null = null;
const notifications = ref<AppNotification[]>([]);
const unreadCount = ref(0);
let nextId = 1;

// Event-Listener für Views die auf Änderungen reagieren wollen
type EventCallback = (type: string, data: any) => void;
const listeners = new Set<EventCallback>();

function addNotification(type: AppNotification['type'], title: string, message: string) {
  notifications.value.unshift({
    id: nextId++,
    type,
    title,
    message,
    timestamp: new Date(),
    read: false
  });
  unreadCount.value = notifications.value.filter(n => !n.read).length;
}

export function useNotifications() {
  const connect = () => {
    const token = localStorage.getItem('token');
    if (!token) return;

    // Bereits verbunden oder am Verbinden → nicht nochmal
    if (connection && connection.state !== signalR.HubConnectionState.Disconnected) return;

    const baseUrl = (import.meta.env.VITE_API_BASE_URL as string) || 'https://sybau-xll5.onrender.com';
    const hubUrl = baseUrl.replace(/\/+$/, '').replace(/\/api$/i, '') + '/hubs/notifications';

    connection = new signalR.HubConnectionBuilder()
      .withUrl(hubUrl, {
        accessTokenFactory: () => localStorage.getItem('token') || ''
      })
      .withAutomaticReconnect()
      .configureLogging(signalR.LogLevel.Warning)
      .build();

    connection.on('FriendRequestReceived', (data: { friendshipId: number; fromUserName: string }) => {
      addNotification('friend_request', 'Freundschaftsanfrage', `${data.fromUserName} möchte mit dir befreundet sein.`);
      listeners.forEach(cb => cb('friend_request', data));
    });

    connection.on('FriendRequestAccepted', (data: { friendshipId: number; byUserName: string }) => {
      addNotification('friend_accepted', 'Freund hinzugefügt', `${data.byUserName} hat deine Anfrage angenommen!`);
      listeners.forEach(cb => cb('friend_accepted', data));
    });

    connection.onclose(() => {
      console.log('[SignalR] Verbindung geschlossen');
    });

    connection.start()
      .then(() => console.log('[SignalR] Verbunden'))
      .catch(err => console.error('[SignalR] Verbindung fehlgeschlagen:', err));
  };

  const disconnect = () => {
    connection?.stop();
    connection = null;
  };

  const markAsRead = (id: number) => {
    const n = notifications.value.find(n => n.id === id);
    if (n) n.read = true;
    unreadCount.value = notifications.value.filter(n => !n.read).length;
  };

  const markAllAsRead = () => {
    notifications.value.forEach(n => n.read = true);
    unreadCount.value = 0;
  };

  const clearAll = () => {
    notifications.value = [];
    unreadCount.value = 0;
  };

  const onSignalREvent = (cb: EventCallback) => { listeners.add(cb); };
  const offSignalREvent = (cb: EventCallback) => { listeners.delete(cb); };

  return {
    notifications: readonly(notifications),
    unreadCount: readonly(unreadCount),
    connect,
    disconnect,
    markAsRead,
    markAllAsRead,
    clearAll,
    onSignalREvent,
    offSignalREvent
  };
}
