<template>
  <div class="landing-page">
    <header class="landing-header">
      <div class="container header-inner">
        <button class="logo-button" type="button" @click="navigateTo('/home')" aria-label="SYBAU Home">
          <img :src="shortLogo" alt="SYBAU Logo" class="logo-image">
        </button>

        <nav class="nav-buttons" aria-label="Landing Navigation">
          <button class="nav-btn" type="button" @click="navigateTo('/auth')">{{ copy.login }}</button>
          <button class="webplayer-btn" type="button" @click="navigateTo('/auth')">{{ copy.webplayer }}</button>
        </nav>
      </div>
    </header>

    <main>
      <section class="hero-section">
        <div class="container hero-content">
          <h1 class="hero-title fade-in">
            {{ copy.heroTitle }}
          </h1>
          <p class="hero-subtitle fade-in delay-1">
            {{ copy.heroSubtitle }}
          </p>
          <div class="hero-actions fade-in delay-2">
            <button class="primary-btn" type="button" @click="navigateTo('/auth')">{{ copy.primaryAction }}</button>
          </div>
        </div>
      </section>

      <section class="stats-section" ref="statsBox">
        <div class="container stats-box">
          <div
            class="stat-item scroll-reveal"
            v-for="(stat, index) in stats"
            :key="stat.label"
            :style="{ transitionDelay: `${index * 0.08}s` }"
          >
            <span class="stat-value">{{ animatedStats[index] }}{{ stat.suffix }}</span>
            <span class="stat-label">{{ stat.label }}</span>
          </div>
        </div>
      </section>

      <section class="product-section" id="product-preview">
        <div class="container">
          <div
            class="showcase-row scroll-reveal"
            :class="section.layout"
            v-for="section in productSections"
            :key="section.id"
          >
            <div class="showcase-copy">
              <h3>{{ section.title }}</h3>
              <p>{{ section.text }}</p>
              <ul>
                <li v-for="item in section.points" :key="item">{{ item }}</li>
              </ul>
            </div>

            <div class="showcase-media" :class="section.mediaClass" aria-hidden="true">
              <img :src="section.image" alt="" class="mockup-image">
            </div>
          </div>

          <div class="avatar-section scroll-reveal">
            <div class="avatar-copy">
              <h3>{{ copy.avatarTitle }}</h3>
              <p>
                {{ copy.avatarText }}
              </p>
            </div>

            <div class="avatar-phases" :aria-label="copy.avatarAria">
              <div
                v-for="(phase, index) in avatarPhases"
                :key="phase.name"
                class="phase-item"
                :style="{ '--phase-delay': `${index * 0.08}s` }"
              >
                <div
                  class="avatar-sprite phase-sprite"
                  :style="{ backgroundImage: `url(${phase.sprite})` }"
                ></div>
                <span>{{ phase.name }}</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section class="tech-section">
        <div class="tech-title">{{ copy.techTitle }}</div>
        <div class="marquee" :aria-label="copy.techAria">
          <div class="marquee-content">
            <div class="logo-set" v-for="setIndex in 3" :key="setIndex">
              <img
                v-for="tech in techStack"
                :key="`${setIndex}-${tech.name}`"
                :src="tech.icon"
                :alt="tech.name"
                class="tech-logo"
              >
            </div>
          </div>
        </div>
      </section>
    </main>

    <FooterComponent />
  </div>
</template>

<script setup lang="ts">
import FooterComponent from '@/components/FooterComponent.vue';
import { onMounted, onUnmounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import shortLogo from '@/assets/Sybau_logo_short.png';
import skinnySprite from '@/assets/Spritesheet_Skinny.png';
import normalSprite from '@/assets/Spritesheet_Normal.png';
import bodybuilderSprite from '@/assets/Spritesheet_Bodybuilder.png';
import dashboardMockup from '@/assets/mockups/Dashboard-Mockup2.png';
import workoutsMockup from '@/assets/mockups/Workouts-Mockup.png';
import questsMockup from '@/assets/mockups/Quests-Mockup.png';
import shopMockup from '@/assets/mockups/Shop-Mockup.png';
import leaderboardMockup from '@/assets/mockups/Leaderboard-Mockup.png';

const router = useRouter();
const statsBox = ref<HTMLElement | null>(null);
let observer: IntersectionObserver | null = null;

const copy = {
  login: 'Login',
  webplayer: 'Webplayer',
  heroTitle: 'Trainieren, leveln, sichtbar stärker werden.',
  heroSubtitle: 'Dein Training wird zu Fortschritt, den du jeden Tag direkt siehst.',
  primaryAction: 'Webplayer öffnen',
  avatarTitle: 'Drei Phasen, kein abstrakter Fortschritt.',
  avatarText: 'Der Charakter entwickelt sich mit deinem Training. Die Veränderung bleibt bewusst sichtbar und simpel.',
  avatarAria: 'Avatar Phasen',
  techTitle: 'Made with',
  techAria: 'Technologien',
};

const stats = [
  { value: 100, suffix: '+', label: 'Max Level' },
  { value: 100, suffix: '+', label: 'Achievements' },
  { value: 5000, suffix: '+', label: 'Aktive Nutzer' },
  { value: 50, suffix: '+', label: 'Workouts' },
];

const productSections = [
  {
    id: 'dashboard',
    title: 'Alles startet mit deinem Avatar.',
    text: 'Level, XP, Coins, Items und Tagesfortschritt sitzen direkt im Blick. Der Screen zeigt sofort, was dein Training gebracht hat.',
    image: dashboardMockup,
    mediaClass: 'dashboard-media',
    layout: 'image-right',
    points: ['Avatar als Mittelpunkt', 'Level- und XP-Fortschritt', 'Streak, Rang und Quests'],
  },
  {
    id: 'workouts',
    title: 'Eintragen bleibt schnell.',
    text: 'Timer, Wiederholungen und Belohnungen sind auf Mobile so gestaltet, dass man nach dem Satz nicht lange suchen muss.',
    image: workoutsMockup,
    mediaClass: 'workouts-media',
    layout: 'image-left',
    points: ['Timer-Modus', 'Reps sauber ändern', 'Belohnung direkt sichtbar'],
  },
  {
    id: 'shop',
    title: 'Chests und Items fühlen sich nach Loot an.',
    text: 'Der Shop zeigt Booster, Chests und Item-Besitz im gleichen Gaming-Stil wie der Rest der App.',
    image: shopMockup,
    mediaClass: 'shop-media',
    layout: 'image-right',
    points: ['Chests mit Drop-Idee', 'Items mit XP- und Coin-Boosts', 'Pixel-Art bleibt im Fokus'],
  },
  {
    id: 'quests',
    title: 'Klare Ziele statt leere Motivation.',
    text: 'Quests geben dem Training kleine Aufgaben, Fortschritt und Rewards. So entsteht ein Loop, der nicht kompliziert wirkt.',
    image: questsMockup,
    mediaClass: 'quests-media',
    layout: 'image-left',
    points: ['Daily und Weekly Quests', 'XP und Coins als Rewards', 'Claim-Feedback im Header'],
  },
  {
    id: 'leaderboard',
    title: 'Ranking macht Fortschritt vergleichbar.',
    text: 'Wer trainiert, sieht nicht nur eigene Zahlen, sondern auch, wie weit die Spitze entfernt ist.',
    image: leaderboardMockup,
    mediaClass: 'leaderboard-media',
    layout: 'image-right',
    points: ['Top Champions', 'globale Rangliste', 'Level und XP im Vergleich'],
  },
];

const avatarPhases = [
  { name: 'Skinny', sprite: skinnySprite },
  { name: 'Defined', sprite: normalSprite },
  { name: 'Bodybuilder', sprite: bodybuilderSprite },
];

const techStack = [
  { name: 'C#', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/csharp/csharp-original.svg' },
  { name: '.NET', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dotnetcore/dotnetcore-original.svg' },
  { name: 'Vue', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg' },
  { name: 'TypeScript', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/typescript/typescript-original.svg' },
  { name: 'Flutter', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/flutter/flutter-original.svg' },
  { name: 'Dart', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dart/dart-original.svg' },
  { name: 'HTML', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/html5/html5-original.svg' },
  { name: 'CSS', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/css3/css3-original.svg' },
  { name: 'JavaScript', icon: 'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/javascript/javascript-original.svg' },
];

const animatedStats = ref(['0', '0', '0', '0']);
const statsAnimated = ref(false);
const numberLocale = 'de-DE';

const navigateTo = (path: string) => {
  router.push(path);
};

const animateCounter = (index: number, target: number, duration = 1600) => {
  const increment = target / (duration / 16);
  let current = 0;

  const timer = window.setInterval(() => {
    current += increment;
    if (current >= target) {
      animatedStats.value[index] = target.toLocaleString(numberLocale);
      window.clearInterval(timer);
      return;
    }

    animatedStats.value[index] = Math.floor(current).toLocaleString(numberLocale);
  }, 16);
};

const observeRevealElements = (forceVisible = false) => {
  if (statsBox.value) observer?.observe(statsBox.value);
  document.querySelectorAll('.scroll-reveal').forEach((element) => {
    if (forceVisible || element.getBoundingClientRect().top < window.innerHeight) {
      element.classList.add('visible');
    }
    observer?.observe(element);
  });
};

const observeElements = () => {
  observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;

        entry.target.classList.add('visible');

        if (entry.target === statsBox.value && !statsAnimated.value) {
          statsAnimated.value = true;
          stats.forEach((stat, index) => {
            window.setTimeout(() => animateCounter(index, stat.value), index * 80);
          });
        }
      });
    },
    { threshold: 0.22 }
  );

  observeRevealElements();
};

onMounted(observeElements);

onUnmounted(() => {
  observer?.disconnect();
});
</script>

<style scoped>
.landing-page {
  min-height: 100vh;
  color: #fff;
  background:
    radial-gradient(circle at top left, #1a237e, transparent 45%),
    radial-gradient(circle at bottom right, #311b92, transparent 45%),
    #050714;
  background-repeat: no-repeat;
  background-attachment: fixed;
  overflow-x: hidden;
}

.container {
  width: min(1180px, calc(100% - 48px));
  margin: 0 auto;
}

.landing-header {
  position: sticky;
  top: 0;
  z-index: 50;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(5, 8, 18, 0.46);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

.header-inner {
  min-height: 78px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.logo-button {
  display: inline-flex;
  align-items: center;
  padding: 0;
  border: 0;
  background: transparent;
}

.logo-image {
  height: 42px;
  width: auto;
  display: block;
}

.nav-buttons,
.hero-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.nav-btn,
.webplayer-btn,
.primary-btn {
  height: 46px;
  border-radius: 12px;
  padding: 0 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 740;
  line-height: 1;
  color: white;
  cursor: pointer;
  appearance: none;
  transition: transform 0.18s ease, border-color 0.18s ease, background 0.18s ease, box-shadow 0.18s ease;
}

.nav-btn {
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(15, 23, 42, 0.48);
}

.webplayer-btn,
.primary-btn {
  border: 1px solid rgba(244, 63, 94, 0.54);
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  box-shadow: 0 14px 32px rgba(244, 63, 94, 0.22);
}

.nav-btn:hover,
.webplayer-btn:hover,
.primary-btn:hover {
  transform: translateY(-2px);
  border-color: rgba(236, 72, 153, 0.55);
}

.hero-section {
  min-height: calc(100vh - 78px);
  display: flex;
  align-items: center;
  padding: 104px 0 78px;
}

.hero-content {
  max-width: 860px;
  text-align: center;
}

.hero-title {
  max-width: 720px;
  margin: 0 auto;
  font-size: clamp(3rem, 6.2vw, 5.45rem);
  line-height: 1;
  font-weight: 800;
  letter-spacing: 0;
}

.hero-subtitle {
  max-width: 560px;
  margin: 24px auto 0;
  color: rgba(226, 232, 240, 0.68);
  font-size: 1.08rem;
  line-height: 1.7;
  font-weight: 500;
}

.hero-actions {
  margin-top: 38px;
  flex-wrap: wrap;
  justify-content: center;
}

.primary-btn {
  height: 56px;
  padding: 0 28px;
}

.mockup-image {
  display: block;
  width: 100%;
  height: auto;
  object-fit: contain;
  filter: drop-shadow(0 38px 70px rgba(0, 0, 0, 0.36));
  user-select: none;
}

.fade-in {
  opacity: 0;
  transform: translateY(18px);
  animation: fadeInUp 0.72s ease forwards;
}

.fade-in.delay-1 {
  animation-delay: 0.16s;
}

.fade-in.delay-2 {
  animation-delay: 0.28s;
}

.scroll-reveal {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.58s ease, transform 0.58s ease;
}

.scroll-reveal.visible {
  opacity: 1;
  transform: translateY(0);
}

@keyframes fadeInUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.stats-section {
  padding: 24px 0 80px;
}

.stats-box {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: clamp(18px, 4vw, 62px);
  align-items: start;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  padding: 34px 0;
}

.stat-item {
  display: grid;
  gap: 6px;
  justify-items: center;
  text-align: center;
}

.stat-value {
  color: white;
  font-size: clamp(2.1rem, 4vw, 3.8rem);
  line-height: 1;
  font-weight: 780;
}

.stat-label {
  color: rgba(226, 232, 240, 0.6);
  font-weight: 650;
  letter-spacing: 0.11em;
  text-transform: uppercase;
  font-size: 0.76rem;
}

.product-section {
  scroll-margin-top: 96px;
  padding: 20px 0 72px;
}

.showcase-row {
  min-height: 520px;
  display: grid;
  grid-template-columns: minmax(330px, 0.92fr) minmax(420px, 1.08fr);
  align-items: center;
  gap: clamp(20px, 4vw, 72px);
  padding: clamp(34px, 6vw, 78px) 0;
  overflow: visible;
}

.showcase-copy h3 {
  margin: 0 0 18px;
  font-size: clamp(2.05rem, 4.4vw, 4.1rem);
  line-height: 1;
  font-weight: 800;
}

.showcase-copy p {
  margin: 0 0 22px;
  max-width: 560px;
  color: rgba(226, 232, 240, 0.72);
  font-size: 1.04rem;
  line-height: 1.75;
  font-weight: 520;
}

.showcase-copy ul {
  display: grid;
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.showcase-copy li {
  display: flex;
  align-items: center;
  gap: 10px;
  color: rgba(255, 255, 255, 0.86);
  font-weight: 680;
}

.showcase-copy li::before {
  content: '';
  width: 7px;
  height: 7px;
  flex: 0 0 auto;
  border-radius: 50%;
  background: #22d3ee;
  box-shadow: 0 0 14px rgba(34, 211, 238, 0.66);
}

.showcase-media {
  position: relative;
  min-height: 440px;
  display: flex;
  align-items: center;
  pointer-events: none;
}

.image-right .showcase-media {
  justify-content: flex-end;
}

.image-left {
  grid-template-columns: minmax(420px, 1.08fr) minmax(330px, 0.92fr);
}

.image-left .showcase-media {
  order: 1;
  justify-content: flex-start;
}

.image-left .showcase-copy {
  order: 2;
}

.dashboard-media .mockup-image,
.leaderboard-media .mockup-image {
  width: min(620px, 43vw);
  max-width: none;
  margin-right: 0;
}

.quests-media .mockup-image {
  width: min(620px, 43vw);
  max-width: none;
  margin-right: 0;
  transform: translateX(-28px);
}

.workouts-media .mockup-image,
.shop-media .mockup-image {
  width: min(330px, 24vw);
  max-width: none;
  margin-left: 0;
}

.avatar-section {
  display: grid;
  justify-items: center;
  gap: clamp(42px, 6vw, 76px);
  padding: clamp(64px, 9vw, 112px) 0;
}

.avatar-copy {
  max-width: 760px;
  text-align: center;
}

.avatar-copy h3 {
  margin: 0 0 18px;
  font-size: clamp(2.05rem, 4.4vw, 4.1rem);
  line-height: 1;
  font-weight: 800;
}

.avatar-copy p {
  margin: 0 auto;
  max-width: 620px;
  color: rgba(226, 232, 240, 0.72);
  font-size: 1.04rem;
  line-height: 1.75;
  font-weight: 520;
}

.avatar-phases {
  position: relative;
  width: min(980px, 100%);
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  align-items: end;
  gap: clamp(16px, 3vw, 46px);
  padding: 8px 0 34px;
}

.avatar-phases::before {
  content: '';
  position: absolute;
  left: 16%;
  right: 16%;
  bottom: 74px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.18), rgba(236, 72, 153, 0.2), rgba(255, 255, 255, 0.18), transparent);
}

.avatar-phases::after {
  content: '';
  position: absolute;
  left: 20%;
  right: 20%;
  bottom: 73px;
  height: 3px;
  background: linear-gradient(90deg, transparent, rgba(236, 72, 153, 0.18), transparent);
  filter: blur(8px);
}

.phase-item {
  position: relative;
  z-index: 1;
  display: grid;
  justify-items: center;
  gap: 18px;
  animation: phaseRise 0.7s ease both;
  animation-delay: var(--phase-delay);
  transition: transform 0.24s ease;
}

.phase-item::after {
  content: '';
  position: absolute;
  bottom: 70px;
  width: 7px;
  height: 7px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.78);
  box-shadow: 0 0 18px rgba(236, 72, 153, 0.26);
}

.phase-item:hover {
  transform: translateY(-6px);
}

.avatar-sprite {
  width: 128px;
  height: 128px;
  background-repeat: no-repeat;
  background-size: 200% 200%;
  background-position: 0 0;
  image-rendering: pixelated;
}

.phase-sprite {
  width: clamp(190px, 18vw, 280px);
  height: clamp(190px, 18vw, 280px);
  filter: drop-shadow(0 20px 24px rgba(0, 0, 0, 0.42));
  transition: transform 0.24s ease, filter 0.24s ease;
  will-change: background-position;
}

.phase-item:hover .phase-sprite {
  transform: scale(1.06);
  filter: drop-shadow(0 26px 32px rgba(0, 0, 0, 0.46));
  animation: avatarSpritePreview 2.6s steps(1, end) infinite;
}

.phase-item span {
  color: white;
  font-size: 1rem;
  font-weight: 760;
}

@keyframes phaseRise {
  from {
    opacity: 0;
    transform: translateY(16px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes avatarSpritePreview {
  0%,
  24% {
    background-position: 0 0;
  }
  25%,
  49% {
    background-position: 100% 0;
  }
  50%,
  74% {
    background-position: 0 100%;
  }
  75%,
  100% {
    background-position: 100% 100%;
  }
}

.tech-section {
  padding: 70px 0 64px;
  overflow: hidden;
  text-align: center;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.tech-title {
  margin-bottom: 28px;
  color: rgba(226, 232, 240, 0.56);
  font-size: 0.88rem;
  font-weight: 700;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

.marquee {
  position: relative;
  overflow: hidden;
  white-space: nowrap;
}

.marquee::before,
.marquee::after {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  z-index: 2;
  width: 110px;
  pointer-events: none;
}

.marquee::before {
  left: 0;
  background: linear-gradient(90deg, #050714, transparent);
}

.marquee::after {
  right: 0;
  background: linear-gradient(270deg, #050714, transparent);
}

.marquee-content {
  display: inline-flex;
  gap: 72px;
  animation: scroll 42s linear infinite;
  will-change: transform;
}

.logo-set {
  display: flex;
  align-items: center;
  gap: 50px;
}

.tech-logo {
  width: 76px;
  height: 76px;
  object-fit: contain;
  opacity: 0.8;
  transition: opacity 0.18s ease, transform 0.18s ease;
}

.tech-logo:hover {
  opacity: 1;
  transform: translateY(-2px);
}

@keyframes scroll {
  to {
    transform: translateX(calc(-100% / 3));
  }
}

@media (max-width: 1120px) {
  .showcase-row,
  .image-left {
    grid-template-columns: 1fr;
  }

  .dashboard-media .mockup-image,
  .leaderboard-media .mockup-image,
  .quests-media .mockup-image {
    width: min(600px, 82vw);
  }

  .workouts-media .mockup-image,
  .shop-media .mockup-image {
    width: min(330px, 68vw);
  }

  .showcase-media {
    min-height: 390px;
    justify-content: center;
  }

  .image-left .showcase-copy,
  .image-left .showcase-media {
    order: 0;
  }

  .showcase-copy {
    max-width: 760px;
  }
}

@media (max-width: 820px) {
  .landing-page {
    background-attachment: scroll;
  }

  .container {
    width: min(100% - 32px, 1180px);
  }

  .header-inner {
    min-height: 68px;
  }

  .logo-image {
    height: 34px;
  }

  .nav-btn {
    display: none;
  }

  .webplayer-btn {
    padding: 0 16px;
    height: 40px;
  }

  .hero-section {
    min-height: calc(100svh - 68px);
    padding: 72px 0 56px;
  }

  .hero-title {
    font-size: clamp(2.45rem, 11.5vw, 4.4rem);
  }

  .hero-subtitle {
    max-width: 360px;
    margin-top: 20px;
    font-size: 0.98rem;
    line-height: 1.65;
  }

  .hero-actions {
    margin-top: 30px;
  }

  .stats-box {
    grid-template-columns: repeat(2, 1fr);
    gap: 24px 32px;
    padding: 26px 0;
  }

  .product-section {
    padding-top: 8px;
  }

  .showcase-row {
    min-height: auto;
    grid-template-columns: minmax(0, 0.94fr) minmax(0, 1.06fr);
    gap: 14px;
    padding: 46px 0;
    text-align: left;
  }

  .image-left {
    grid-template-columns: minmax(0, 1.06fr) minmax(0, 0.94fr);
  }

  .image-left .showcase-media {
    order: 1;
  }

  .image-left .showcase-copy {
    order: 2;
  }

  .showcase-copy {
    justify-self: stretch;
    max-width: none;
    min-width: 0;
  }

  .showcase-copy h3 {
    margin-bottom: 9px;
    font-size: clamp(1.1rem, 4.8vw, 1.45rem);
    line-height: 1.08;
  }

  .showcase-copy p {
    margin: 0 0 10px;
    max-width: none;
    font-size: clamp(0.68rem, 2.6vw, 0.84rem);
    line-height: 1.45;
  }

  .showcase-copy ul {
    width: auto;
    gap: 5px;
    margin: 0;
    text-align: left;
  }

  .showcase-copy li {
    gap: 6px;
    font-size: clamp(0.62rem, 2.4vw, 0.78rem);
    line-height: 1.3;
  }

  .showcase-copy li::before {
    width: 5px;
    height: 5px;
  }

  .showcase-media {
    width: auto;
    min-height: 0;
    justify-content: flex-end;
  }

  .image-left .showcase-media {
    justify-content: flex-start;
  }

  .image-right .showcase-media {
    justify-content: flex-end;
  }

  .dashboard-media .mockup-image,
  .leaderboard-media .mockup-image,
  .quests-media .mockup-image {
    width: min(220px, 44vw);
  }

  .workouts-media .mockup-image,
  .shop-media .mockup-image {
    width: min(140px, 30vw);
  }

  .quests-media .mockup-image {
    transform: translateX(-12px);
  }

  .avatar-section {
    padding: 54px 0;
  }

  .avatar-phases {
    gap: 8px;
  }

  .phase-sprite {
    width: clamp(140px, 30vw, 190px);
    height: clamp(140px, 30vw, 190px);
  }

  .tech-logo {
    width: 58px;
    height: 58px;
  }

  .logo-set {
    gap: 34px;
  }
}

@media (max-width: 520px) {
  .hero-actions {
    width: auto;
  }

  .primary-btn {
    width: auto;
    min-width: 210px;
  }

  .stats-box {
    gap: 22px;
  }

  .stat-label {
    font-size: 0.68rem;
  }

  .showcase-copy h3 {
    font-size: clamp(1rem, 4.6vw, 1.24rem);
  }

  .showcase-row {
    gap: 10px;
    padding: 38px 0;
  }

  .showcase-copy p {
    font-size: clamp(0.62rem, 2.45vw, 0.74rem);
  }

  .showcase-copy li {
    font-size: clamp(0.58rem, 2.3vw, 0.7rem);
  }

  .dashboard-media .mockup-image,
  .leaderboard-media .mockup-image,
  .quests-media .mockup-image {
    width: min(185px, 42vw);
  }

  .workouts-media .mockup-image,
  .shop-media .mockup-image {
    width: min(118px, 29vw);
  }

  .quests-media .mockup-image {
    transform: translateX(-8px);
  }
}
</style>
