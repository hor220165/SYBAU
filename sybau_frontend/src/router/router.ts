import { createRouter, createWebHistory } from 'vue-router'
import AuthView from '../views/AuthView.vue'
import HomeView from "../views/HomeView.vue";
import ShopView from "@/views/ShopView.vue";
import WorkoutsView from "@/views/WorkoutsView.vue";
import QuestsView from "@/views/QuestsView.vue";
import AvatarView from "@/views/AvatarView.vue";
import LeaderboardView from "@/views/LeaderboardView.vue";
import ProfileView from "@/views/ProfileView.vue";
import AdminView from "@/views/AdminView.vue";

const routes = [
    {
      path: '/',
      redirect: '/auth'
    },
    {
      path: '/auth',
      component: AuthView
    },
    {
      path: '/home',
      component: HomeView
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
        path: '/admin',
        component: AdminView,
        meta: { requiresAdmin: true }
    }
]

export const router = createRouter({
  history: createWebHistory(),
  routes
})

// Route Guard für Admin-Schutz
router.beforeEach((to, from, next) => {
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
