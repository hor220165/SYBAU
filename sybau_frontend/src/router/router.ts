import { createRouter, createWebHistory } from 'vue-router'
import AuthView from '../views/AuthView.vue'
import HomeView from "../views/HomeView.vue";

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
    }
]

export const router = createRouter({
  history: createWebHistory(),
  routes
})
