<template>
  <div class="legal-page">
    <div class="legal-container">
      <button class="back-button" type="button" @click="goBack">Zurück</button>

      <article class="legal-content">
        <h1>Datenschutzerklärung</h1>
        <p class="intro">
          Hier erklären wir kurz und verständlich, welche Daten SYBAU braucht, wo sie gespeichert
          werden und wofür sie verwendet werden.
        </p>

        <section>
          <h2>Verantwortlicher</h2>
          <p>
            DidimDynamics, Schülerprojekt der Spengergasse, Spengergasse 20, 1050 Wien, Österreich.
            Kontakt: <a href="mailto:hor220165@spengergasse.at">hor220165@spengergasse.at</a>
          </p>
        </section>

        <section>
          <h2>Welche Daten speichert SYBAU?</h2>
          <ul>
            <li>Account: Benutzername, E-Mail-Adresse und ein geschützter Passwort-Hash.</li>
            <li>Profil: Profilbild, Privatsphäre-Einstellung, Avatar-Level, XP, Coins, Booster und Items.</li>
            <li>Training: Übungen, Wiederholungen, Zeiten, Distanzen, Quests, Achievements und Aktivität.</li>
            <li>Freunde: Freundschaften, Anfragen, Challenges und Benachrichtigungen.</li>
            <li>Browser: Login-Token, ein kleiner User-Cache und die Cookie-/Storage-Auswahl.</li>
          </ul>
        </section>

        <section>
          <h2>Wofür werden die Daten genutzt?</h2>
          <p>
            Die Daten werden verwendet, damit Login, Profil, Fortschritt, Training, Leaderboard,
            Shop, Freunde und Benachrichtigungen funktionieren. Außerdem helfen technische Daten
            dabei, Fehler zu finden und den Account vor Missbrauch zu schützen.
          </p>
        </section>

        <section>
          <h2>Wo liegen die Daten?</h2>
          <p>
            Die Website wird über Vercel ausgeliefert. Die API läuft auf Render. Die Produktionsdaten
            liegen in einer PostgreSQL-Datenbank bei Supabase. Bilder für Profile, Items und Chests
            liegen in Supabase Storage. Im Browser werden Login-Token, User-Cache und Cookie-Auswahl
            in localStorage gespeichert.
          </p>
        </section>

        <section>
          <h2>Speicherdauer</h2>
          <p>
            Account- und Fortschrittsdaten bleiben gespeichert, solange der Account besteht.
            Profilbilder können entfernt werden. Bei einer Account-Löschung werden die zugehörigen
            Daten gelöscht, soweit das technisch möglich ist und keine kurze Restaufbewahrung nötig
            ist.
          </p>
        </section>

        <section>
          <h2>Wer bekommt Daten?</h2>
          <p>
            Die Daten werden nicht verkauft und nicht für Werbung weitergegeben. Technisch beteiligt
            sind Vercel für die Website, Render für die API und Supabase für Datenbank und Bilder.
            SYBAU nutzt keinen Google Login und kein Google Tracking. Echtgeld-Käufe sind aktuell nur
            ein Platzhalter im Shop; es werden dafür keine Zahlungsdaten verarbeitet.
          </p>
        </section>

        <section>
          <h2>Deine Rechte</h2>
          <p>
            Du kannst fragen, welche Daten gespeichert sind, falsche Daten berichtigen lassen oder
            die Löschung deines Accounts verlangen. Du kannst dich außerdem bei der Österreichischen
            Datenschutzbehörde beschweren.
          </p>
        </section>

        <section>
          <h2>Sicherheit</h2>
          <p>
            Passwörter werden nicht im Klartext gespeichert. Für Logins verwendet SYBAU JWT-Token,
            wichtige API-Endpunkte sind begrenzt und dynamische Antworten werden nicht im Browser
            zwischengespeichert.
          </p>
        </section>

        <p class="updated">Stand: 25. Mai 2026</p>
      </article>
    </div>
  </div>
</template>

<script setup lang="ts">
import { nextTick, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const scrollToTop = () => {
  window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
  document.documentElement.scrollTop = 0;
  document.body.scrollTop = 0;
};

onMounted(async () => {
  scrollToTop();
  await nextTick();
  scrollToTop();
  window.requestAnimationFrame(scrollToTop);
});

const goBack = () => {
  router.back();
};
</script>

<style scoped>
.legal-page {
  min-height: 100vh;
  padding: 80px 20px 40px;
  color: white;
}

.legal-container {
  max-width: 800px;
  margin: 0 auto;
}

.back-button {
  position: fixed;
  top: 32px;
  left: 32px;
  z-index: 100;
  padding: 0;
  border: none;
  background: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.back-button:hover {
  color: #ec4899;
  transform: translateX(-4px);
}

.legal-content h1 {
  margin: 0 0 24px;
  color: white;
  font-size: 40px;
  font-weight: 700;
}

.intro {
  margin-bottom: 44px;
  color: rgba(255, 255, 255, 0.76);
  font-size: 16px;
  line-height: 1.8;
}

.legal-content section {
  margin-bottom: 42px;
  padding-bottom: 28px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.legal-content h2 {
  margin: 0 0 16px;
  color: rgba(255, 255, 255, 0.72);
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.legal-content p,
.legal-content li {
  color: rgba(255, 255, 255, 0.72);
  font-size: 15px;
  line-height: 1.8;
}

.legal-content ul {
  display: grid;
  gap: 10px;
  margin: 0;
  padding-left: 20px;
}

.legal-content a {
  color: #ec4899;
  text-decoration: none;
  border-bottom: 1px solid transparent;
}

.legal-content a:hover {
  border-bottom-color: #ec4899;
}

.updated {
  margin: 56px 0 0;
  color: rgba(255, 255, 255, 0.48);
  font-size: 13px;
  text-align: center;
}

@media (max-width: 768px) {
  .legal-page {
    padding: 60px 20px 40px;
  }

  .back-button {
    top: 20px;
    left: 20px;
  }

  .legal-content h1 {
    font-size: 32px;
  }
}
</style>
