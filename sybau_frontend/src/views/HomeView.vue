<template>
  <div class="landing-page">
    <!-- Header -->
    <header class="landing-header">
      <div class="container">
        <div class="logo">
          <img src="../assets/Sybau_Logo_White.png" alt="SYBAU Logo" class="logo-image">
        </div>
        <nav class="nav-buttons">
          <button class="nav-btn" @click="navigateTo('/auth')">Login</button>
          <button class="cta-btn" @click="navigateTo('/auth')">
            <span class="play-icon">▶</span>
            Kostenlos starten
          </button>
        </nav>
      </div>
    </header>

    <!-- Hero Section -->
    <section class="hero-section">
      <div class="container">
        <h1 class="hero-title fade-in">
          Fitness trifft auf<br>
          <span class="gradient-text">Gaming-Power</span>
        </h1>

        <p class="hero-description fade-in delay-1">
          Verwandle dein Training in ein episches RPG-Abenteuer. Levele deinen Avatar, sammle
          XP und Coins, schalte legendäre Items frei und werde zum ultimativen Fitness-Champion!
        </p>

        <div class="hero-buttons fade-in delay-2">
          <button class="primary-btn" @click="navigateTo('/auth')">
            <span class="play-icon">▶</span>
            Kostenlos starten
          </button>
        </div>
      </div>
    </section>

    <!-- Stats Section - Separate Section -->
    <section class="stats-section">
      <div class="container">
        <div class="stats-box" ref="statsBox">
          <div class="stat-item scroll-reveal" v-for="(stat, index) in stats" :key="index" :style="{ transitionDelay: `${index * 0.1}s` }">
            <svg class="stat-icon" xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" v-html="stat.icon"></svg>
            <div class="stat-value">{{ animatedStats[index] }}{{ stat.suffix }}</div>
            <div class="stat-label">{{ stat.label }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section class="features-section" ref="featuresSection">
      <div class="container">
        <h2 class="section-title scroll-reveal">Warum SYBAU?</h2>
        <p class="section-subtitle scroll-reveal">Die perfekte Kombination aus Fitness und Gaming</p>

        <div class="features-grid">
          <div class="feature-card scroll-reveal" v-for="(feature, index) in features" :key="index" :style="{ transitionDelay: `${index * 0.1}s` }">
            <div :class="['feature-icon', feature.iconClass]">
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" v-html="feature.icon"></svg>
            </div>
            <h3 class="feature-title">{{ feature.title }}</h3>
            <p class="feature-description">{{ feature.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- How It Works Section -->
    <section class="how-section" ref="howSection">
      <div class="container">
        <h2 class="section-title scroll-reveal">So funktioniert's</h2>
        <p class="section-subtitle scroll-reveal">In 3 einfachen Schritten zum Fitness-Champion</p>

        <div class="steps-grid">
          <div class="step-card scroll-reveal" v-for="(step, index) in steps" :key="index" :style="{ transitionDelay: `${index * 0.15}s` }">
            <div class="step-number">{{ index + 1 }}</div>
            <div :class="['step-icon', step.iconClass]">
              <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" v-html="step.icon"></svg>
            </div>
            <h3 class="step-title">{{ step.title }}</h3>
            <p class="step-description">{{ step.description }}</p>
          </div>
        </div>

        <div class="cta-section scroll-reveal">
          <button class="cta-large-btn" @click="navigateTo('/auth')">
            <span class="play-icon">▶</span>
            Jetzt kostenlos starten
          </button>
        </div>
      </div>
    </section>

<!-- Tech Stack Section -->
<section class="tech-section">
  <div class="tech-title">Made with</div>

  <div class="marquee">
    <div class="marquee-content">
      <!-- Erste Reihe -->
      <div class="logo-set">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/csharp/csharp-original.svg" alt="C#" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dotnetcore/dotnetcore-original.svg" alt=".NET" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg" alt="Vue" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/typescript/typescript-original.svg" alt="TypeScript" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/html5/html5-original.svg" alt="HTML" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/css3/css3-original.svg" alt="CSS" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/javascript/javascript-original.svg" alt="JavaScript" class="tech-logo">
      </div>
      <!-- Zweite Reihe (identisch) -->
      <div class="logo-set">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/csharp/csharp-original.svg" alt="C#" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dotnetcore/dotnetcore-original.svg" alt=".NET" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg" alt="Vue" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/typescript/typescript-original.svg" alt="TypeScript" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/html5/html5-original.svg" alt="HTML" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/css3/css3-original.svg" alt="CSS" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/javascript/javascript-original.svg" alt="JavaScript" class="tech-logo">
      </div>
      <!-- Dritte Reihe (identisch) -->
      <div class="logo-set">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/csharp/csharp-original.svg" alt="C#" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dotnetcore/dotnetcore-original.svg" alt=".NET" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg" alt="Vue" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/typescript/typescript-original.svg" alt="TypeScript" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/html5/html5-original.svg" alt="HTML" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/css3/css3-original.svg" alt="CSS" class="tech-logo">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/javascript/javascript-original.svg" alt="JavaScript" class="tech-logo">
      </div>
    </div>
  </div>
</section>

    <!-- Footer -->
    <FooterComponent />
  </div>
</template>

<script setup lang="ts">
import FooterComponent from '@/components/FooterComponent.vue';
import { ref, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const featuresSection = ref<HTMLElement | null>(null);
const statsBox = ref<HTMLElement | null>(null);
const howSection = ref<HTMLElement | null>(null);

const stats = ref([
  { 
    value: 100, 
    suffix: '+', 
    label: 'Max Level',
    icon: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>'
  },
  { 
    value: 100, 
    suffix: '+', 
    label: 'Achievements',
    icon: '<path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/>'
  },
  { 
    value: 5000, 
    suffix: '+', 
    label: 'Aktive Nutzer',
    icon: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>'
  },
  { 
    value: 50, 
    suffix: '+', 
    label: 'Workouts',
    icon: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>'
  }
]);

const animatedStats = ref([0, 0, 0, 0]);
const statsAnimated = ref(false);

const features = ref([
  {
    title: 'RPG-Level-System',
    description: 'Sammle XP durch Workouts, steige in Levels auf und werde stärker. Jedes Training bringt dich näher an dein nächstes Level!',
    iconClass: 'icon-red',
    icon: '<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/><path d="M12 18v-6"/><path d="M8 15h8"/>'
  },
  {
    title: 'Avatar & Equipment',
    description: 'Rüste deinen Avatar mit epischen Items aus! Waffe, Rüstung, Accessoire und Boosts geben dir XP- und Coin-Boni.',
    iconClass: 'icon-purple',
    icon: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>'
  },
  {
    title: 'Item Shop',
    description: 'Kaufe Chests von Starter bis Legendary. Luck Potions und mächtige Boost-Items. Finde seltene legendäre Schätze!',
    iconClass: 'icon-pink',
    icon: '<circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>'
  },
  {
    title: 'Quests & Challenges',
    description: 'Tägliche und wöchentliche Quests mit epischen Belohnungen. Schließe Herausforderungen ab und verdiene Coins!',
    iconClass: 'icon-yellow',
    icon: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>'
  },
  {
    title: 'Leaderboards',
    description: 'Messe dich mit Spielern weltweit! Kämpfe um die Top-Position und zeige, wer der wahre Champion ist.',
    iconClass: 'icon-blue',
    icon: '<path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/>'
  },
  {
    title: 'Achievements',
    description: 'Schalte über 100 Achievements frei! Von \'First Steps\' bis \'Legendary Warrior\' - sammle sie alle!',
    iconClass: 'icon-green',
    icon: '<circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/>'
  }
]);

const steps = ref([
  {
    title: 'Erstelle deinen Avatar',
    description: 'Wähle deinen Charakter, gib ihm einen Namen und starte dein Abenteuer!',
    iconClass: 'icon-purple',
    icon: '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>'
  },
  {
    title: 'Trainiere & Level auf',
    description: 'Absolviere Workouts, sammle XP und Coins, rüste deinen Avatar aus und werde stärker!',
    iconClass: 'icon-pink',
    icon: '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>'
  },
  {
    title: 'Dominiere die Rangliste',
    description: 'Kämpfe dich an die Spitze, schalte Achievements frei und werde zur Legende!',
    iconClass: 'icon-green',
    icon: '<polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>'
  }
]);

const navigateTo = (path: string) => {
  router.push(path);
};

// Counter Animation für Stats
const animateCounter = (index: number, target: number, duration: number = 2000) => {
  const start = 0;
  const increment = target / (duration / 16);
  let current = start;

  const timer = setInterval(() => {
    current += increment;
    if (current >= target) {
      animatedStats.value[index] = target.toLocaleString('de-DE');
      clearInterval(timer);
    } else {
      animatedStats.value[index] = Math.floor(current).toLocaleString('de-DE');
    }
  }, 16);
};

// Scroll Reveal Observer
const observeElements = () => {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          
          // Stats Counter Animation - nur wenn Stats Box sichtbar wird
          if (entry.target === statsBox.value && !statsAnimated.value) {
            statsAnimated.value = true;
            stats.value.forEach((stat, index) => {
              setTimeout(() => {
                animateCounter(index, stat.value);
              }, index * 100);
            });
          }
        }
      });
    },
    { threshold: 0.3 } // Stats müssen 30% sichtbar sein
  );

  // Observe stats
  if (statsBox.value) {
    observer.observe(statsBox.value);
  }

  // Observe all scroll-reveal elements
  const scrollElements = document.querySelectorAll('.scroll-reveal');
  scrollElements.forEach((el) => observer.observe(el));
};

onMounted(() => {
  observeElements();
});

onUnmounted(() => {
  // Cleanup if needed
});
</script>

<style scoped>
.landing-page {
  min-height: 100vh;
  color: white;
}

/* Fade-in Animations für Hero */
.fade-in {
  opacity: 0;
  transform: translateY(20px);
  animation: fadeInUp 0.8s ease forwards;
}

.fade-in.delay-1 {
  animation-delay: 0.2s;
}

.fade-in.delay-2 {
  animation-delay: 0.4s;
}

@keyframes fadeInUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Scroll Reveal Animation */
.scroll-reveal {
  opacity: 0;
  transform: translateY(40px);
  transition: all 0.6s ease;
}

.scroll-reveal.visible {
  opacity: 1;
  transform: translateY(0);
}

/* Header */
.landing-header {
  padding: 24px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 32px;
}

.landing-header .container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-left: 0;
}


.logo {
  display: flex;
  align-items: center;
  padding-left: 16px; 
}

.logo-image {
  height: 36px;
  width: auto;
}

.nav-buttons {
  display: flex;
  align-items: center;
  gap: 16px;
}

.nav-btn {
  padding: 10px 24px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: transparent;
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.nav-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.3);
}

.cta-btn {
  padding: 10px 24px;
  border-radius: 12px;
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
}

.cta-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(236, 72, 153, 0.4);
}

.play-icon {
  font-size: 12px;
}

/* Hero Section */
.hero-section {
  padding: 120px 0 100px;
  text-align: center;
}

.hero-title {
  font-size: clamp(48px, 8vw, 72px);
  font-weight: 800;
  line-height: 1.1;
  margin: 0 0 32px 0;
}

.gradient-text {
  background: linear-gradient(135deg, #a855f7, #ec4899, #f43f5e);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-description {
  font-size: 18px;
  color: rgba(255, 255, 255, 0.8);
  max-width: 700px;
  margin: 0 auto 48px;
  line-height: 1.7;
}

.hero-buttons {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 16px;
}


.primary-btn{
  padding: 16px 40px;
  border-radius: 14px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  transition: all 0.3s ease;
  height: 56px;
  min-width: 200px;
}

.primary-btn {
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  box-shadow: 0 4px 16px rgba(236, 72, 153, 0.3);
}

.primary-btn:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.5);
}

/* Stats Section - Separate mit mehr Padding */
.stats-section {
  padding: 100px 0;
}

.stats-box {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 48px;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0;
  background: transparent;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 0;
}

.stat-icon {
  width: 56px;
  height: 56px;
  color: #ec4899;
  opacity: 0.8;
  filter: drop-shadow(0 0 20px rgba(236, 72, 153, 0.8));
  margin-bottom: 16px;
}

.stat-value {
  font-size: 52px;
  font-weight: 900;
  background: linear-gradient(135deg, #ffffff, #ec4899);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  line-height: 1;
  letter-spacing: -1px;
}

.stat-label {
  font-size: 15px;
  color: rgba(255, 255, 255, 0.65);
  font-weight: 600;
  text-align: center;
  text-transform: uppercase;
  letter-spacing: 1.2px;
}

/* Features Section */
.features-section {
  padding: 80px 0;
}

.section-title {
  font-size: 48px;
  font-weight: 800;
  text-align: center;
  margin: 0 0 16px 0;
}

.section-subtitle {
  font-size: 18px;
  color: rgba(255, 255, 255, 0.7);
  text-align: center;
  margin: 0 0 64px 0;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
}

.feature-card {
  padding: 32px;
  background: rgba(30, 41, 59, 0.6);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 20px;
  transition: all 0.3s ease;
}

.feature-card:hover {
  transform: translateY(-8px);
  border-color: rgba(236, 72, 153, 0.3);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.3);
}

.feature-icon {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
  background: transparent;
  border: none;
}

.feature-icon svg {
  width: 40px;
  height: 40px;
}

.icon-red svg {
  color: #f43f5e;
  filter: drop-shadow(0 0 10px rgba(244, 63, 94, 0.5));
}

.icon-purple svg {
  color: #a855f7;
  filter: drop-shadow(0 0 10px rgba(168, 85, 247, 0.5));
}

.icon-pink svg {
  color: #ec4899;
  filter: drop-shadow(0 0 10px rgba(236, 72, 153, 0.5));
}

.icon-yellow svg {
  color: #fbbf24;
  filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.5));
}

.icon-blue svg {
  color: #3b82f6;
  filter: drop-shadow(0 0 10px rgba(59, 130, 246, 0.5));
}

.icon-green svg {
  color: #22c55e;
  filter: drop-shadow(0 0 10px rgba(34, 197, 94, 0.5));
}

.feature-title {
  font-size: 22px;
  font-weight: 700;
  margin: 0 0 12px 0;
}

.feature-description {
  font-size: 15px;
  color: #e371ff;
  line-height: 1.6;
  margin: 0;
}

/* How It Works Section */
.how-section {
  padding: 80px 0;
}

.steps-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  margin-bottom: 64px;
}

.step-card {
  padding: 40px 32px;
  background: rgba(30, 41, 59, 0.6);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 20px;
  text-align: center;
  position: relative;
  transition: all 0.3s ease;
}

.step-card:hover {
  transform: translateY(-8px);
  border-color: rgba(236, 72, 153, 0.3);
}

.step-number {
  position: absolute;
  top: -20px;
  left: 50%;
  transform: translateX(-50%);
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: 700;
  box-shadow: 0 4px 16px rgba(236, 72, 153, 0.4);
}

.step-icon {
  width: 80px;
  height: 80px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 24px;
  background: transparent;
}

.step-icon svg {
  width: 48px;
  height: 48px;
}

.step-title {
  font-size: 24px;
  font-weight: 700;
  margin: 0 0 16px 0;
}

.step-description {
  font-size: 15px;
  color: #e371ff;
  line-height: 1.6;
  margin: 0;
}

.cta-section {
  text-align: center;
}

.cta-large-btn {
  padding: 20px 48px;
  border-radius: 16px;
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-weight: 700;
  font-size: 18px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 12px;
  transition: all 0.3s ease;
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.4);
}

.cta-large-btn:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(236, 72, 153, 0.6);
}

/* Footer */
.landing-footer {
  padding: 32px 0;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin-top: 80px;
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.footer-brand {
  font-size: 20px;
  font-weight: 800;
  color: white;
  margin: 0;
  letter-spacing: 0.5px;
}

.footer-tagline {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 24px;
}

.footer-copyright {
  color: rgba(255, 255, 255, 0.5);
  font-size: 13px;
  margin: 0;
}

.footer-link {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s ease;
  padding: 0;
  text-decoration: underline;
}

.footer-link:hover {
  color: #ec4899;
}

/* Tech Stack Section */
.tech-section {
  padding: 60px 0 40px;
  overflow: hidden;
  text-align: center;
}

.tech-title {
  font-size: 18px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 32px;
  text-transform: uppercase;
  letter-spacing: 2px;
}

.marquee {
  overflow: hidden;
  white-space: nowrap;
  position: relative;
}

.marquee-content {
  display: inline-flex;
  gap: 80px;
  animation: scroll 40s linear infinite;
  will-change: transform;
}

.logo-set {
  display: flex;
  align-items: center;
  gap: 60px;
}

.tech-logo {
  height: 80px;  /* ✅ Größer: 80px statt 56px */
  width: auto;
  opacity: 0.7;
  transition: all 0.3s ease;
  filter: grayscale(0%);
}

.tech-logo:hover {
  opacity: 1;
  transform: translateY(-1px);
}

@keyframes scroll {
  0% {
    transform: translateX(0);
  }
  100% {
    transform: translateX(calc(-100% / 3));
  }
}

/* Responsive */
@media (max-width: 768px) {
  .tech-logo {
    height: 56px;  /* ✅ Mobile: 56px statt 40px */
  }
  
  .logo-set {
    gap: 40px;
  }
  
  .marquee-content {
    gap: 60px;
  }
}

/* Responsive Breakpoints */

/* Tablet (1024px und kleiner) */
@media (max-width: 1024px) {
  .container {
    padding: 0 24px;
  }

  .logo-image {
    height: 32px;
  }

  .hero-title {
    font-size: clamp(40px, 7vw, 60px);
  }

  .hero-description {
    font-size: 16px;
    max-width: 600px;
  }

  .features-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
  }

  .steps-grid {
    grid-template-columns: 1fr;
    gap: 24px;
  }

  .stats-box {
    grid-template-columns: repeat(2, 1fr);
    gap: 32px;
  }

  .section-title {
    font-size: 40px;
  }

  .section-subtitle {
    font-size: 16px;
  }
}

/* Mobile (768px und kleiner) */
@media (max-width: 768px) {
  .container {
    padding: 0 20px;
  }

  /* Header */
  .landing-header {
    padding: 16px 0;
  }

  .logo-image {
    height: 26px;
  }

  .nav-buttons {
    gap: 8px;
  }

  .nav-btn {
    padding: 8px 16px;
    font-size: 13px;
  }

  .cta-btn {
    padding: 8px 16px;
    font-size: 13px;
    gap: 6px;
  }

  .play-icon {
    font-size: 10px;
  }

  /* Hero Section */
  .hero-section {
    padding: 80px 0 60px;
  }

  .hero-title {
    font-size: clamp(32px, 9vw, 48px);
    margin-bottom: 24px;
  }

  .hero-description {
    font-size: 15px;
    margin-bottom: 32px;
    padding: 0 10px;
  }

  .hero-buttons {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    gap: 16px;
  }

  .primary-btn{
    padding: 14px 28px;
    font-size: 15px;
    height: 48px;
    min-width: unset;
    width: 100%;
  }

  /* Stats Section */
  .stats-section {
    padding: 60px 0;
  }

  .stats-box {
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
  }

  .stat-icon {
    width: 40px;
    height: 40px;
    margin-bottom: 12px;
  }

  .stat-value {
    font-size: 36px;
  }

  .stat-label {
    font-size: 12px;
    letter-spacing: 1px;
  }

  /* Features Section */
  .features-section {
    padding: 60px 0;
  }

  .section-title {
    font-size: 32px;
    margin-bottom: 12px;
  }

  .section-subtitle {
    font-size: 15px;
    margin-bottom: 48px;
  }

  .features-grid {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .feature-card {
    padding: 24px;
  }

  .feature-icon {
    width: 48px;
    height: 48px;
    margin-bottom: 16px;
  }

  .feature-icon svg {
    width: 28px;
    height: 28px;
  }

  .feature-title {
    font-size: 18px;
    margin-bottom: 10px;
  }

  .feature-description {
    font-size: 14px;
  }

  /* How It Works Section */
  .how-section {
    padding: 60px 0;
  }

  .steps-grid {
    grid-template-columns: 1fr;
    gap: 28px;
    margin-bottom: 48px;
  }

  .step-card {
    padding: 32px 24px;
  }

  .step-number {
    width: 40px;
    height: 40px;
    font-size: 20px;
    top: -16px;
  }

  .step-icon {
    width: 64px;
    height: 64px;
    margin-bottom: 20px;
  }

  .step-icon svg {
    width: 36px;
    height: 36px;
  }

  .step-title {
    font-size: 20px;
    margin-bottom: 12px;
  }

  .step-description {
    font-size: 14px;
  }

  .cta-large-btn {
    padding: 16px 36px;
    font-size: 16px;
    gap: 10px;
  }

  /* Footer */
  .landing-footer {
    padding: 24px 0;
    margin-top: 60px;
  }

  .footer-content {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }

  .footer-left {
    align-items: center;
  }

  .footer-brand {
    font-size: 18px;
  }

  .footer-tagline {
    font-size: 12px;
  }

  .footer-right {
    flex-direction: column;
    gap: 8px;
  }

  .footer-copyright {
    font-size: 12px;
  }

  .footer-link {
    font-size: 12px;
  }
}

/* Small Mobile (480px und kleiner) */
@media (max-width: 480px) {
  .container {
    padding: 0 16px;
  }

  .logo-image {
    height: 22px;
  }

  .hero-title {
    font-size: 28px;
  }

  .hero-description {
    font-size: 14px;
  }

  .stats-box {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .stat-value {
    font-size: 32px;
  }

  .section-title {
    font-size: 28px;
  }

  .section-subtitle {
    font-size: 14px;
  }

  .feature-card {
    padding: 20px;
  }

  .step-card {
    padding: 28px 20px;
  }
}
</style>