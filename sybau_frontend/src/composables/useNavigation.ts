import { useRouter, useRoute } from 'vue-router';
import { useNotifications } from '@/composables/useNotifications';

export function useNavigation() {
    const router = useRouter();
    const route = useRoute();
    const { disconnect, clearAll } = useNotifications();

    const navigateTo = (path: string) => {
        router.push(path);
    };

    const isActiveRoute = (path: string) => {
        return route.path === path;
    };

    const logout = () => {
        disconnect();
        clearAll();
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        router.push('/auth');
    }

    return {
        navigateTo,
        isActiveRoute,
        logout
    };
}