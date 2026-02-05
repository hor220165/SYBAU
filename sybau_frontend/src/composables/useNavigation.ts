import { useRouter, useRoute } from 'vue-router';

export function useNavigation() {
    const router = useRouter();
    const route = useRoute();

    const navigateTo = (path: string) => {
        router.push(path);
    };

    const isActiveRoute = (path: string) => {
        return route.path === path;
    };

    const logout = () => {
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