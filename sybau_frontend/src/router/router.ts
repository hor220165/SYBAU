import { createRouter, createWebHistory } from 'vue-router'
import AuthView from '../views/AuthView.vue'
import DashboardView from "../views/DashboardView.vue";
import ShopView from "@/views/ShopView.vue";
import WorkoutsView from "@/views/WorkoutsView.vue";
import QuestsView from "@/views/QuestsView.vue";
import AvatarView from "@/views/AvatarView.vue";
import LeaderboardView from "@/views/LeaderboardView.vue";
import ProfileView from "@/views/ProfileView.vue";
import AdminView from "@/views/AdminView.vue";
import HomeView from "@/views/HomeView.vue";
import ImpressumView from '@/views/ImpressumView.vue';
import FriendsView from '@/views/FriendsView.vue';
import DatenschutzView from '@/views/DatenschutzView.vue';

const routes = [
    {
      path: '/',
      redirect: '/home'
    },
    {
      path: '/auth',
      component: AuthView
    },
    {
      path: '/impressum',
      component: ImpressumView
    },
    {
      path: '/datenschutz',
      component: DatenschutzView
    },
    {
        path: '/home',
        component: HomeView
    },
    {
      path: '/dashboard',
      component: DashboardView
    },
    {
        path: '/workouts',
        component: WorkoutsView
    },
    {
        path: '/quests',
        component: QuestsView
    },
    {
        path: '/avatar',
        component: AvatarView
    },
    {
        path: '/shop',
        component: ShopView
    },
    {
    path: '/leaderboard',
        component: LeaderboardView
    },
    {
        path: '/profile',
        component: ProfileView
    },
    {
        path: '/friends',
        component: FriendsView
    },
    {
        path: '/admin',
        component: AdminView,
        meta: { requiresAdmin: true }
    }
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(_to, _from, savedPosition) {
    if (savedPosition) return savedPosition;
    return { top: 0, left: 0 };
  }
})

// Route Guard für Admin-Schutz
router.beforeEach((to, _from, next) => {
  if (to.meta.requiresAdmin) {
    const user = JSON.parse(localStorage.getItem('user') || '{}');
    if (user.isAdmin) {
      next();
    } else {
      alert('Du hast keine Admin-Berechtigung!');
      next('/home');
    }
  } else {
    next();
  }
});
