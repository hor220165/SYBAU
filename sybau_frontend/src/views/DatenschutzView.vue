<template>
  <div class="legal-page">
    <div class="legal-container">
      <button class="back-button" type="button" @click="goBack">Zurück</button>

      <article class="legal-content">
        <h1>Datenschutzerklärung</h1>
        <p class="intro">
          Diese Datenschutzerklärung beschreibt, welche personenbezogenen Daten im Rahmen des
          Schülerprojekts SYBAU verarbeitet werden. Sie ersetzt keine anwaltliche Prüfung, ist aber
          auf die im Projekt verwendeten Funktionen abgestimmt.
        </p>

        <section>
          <h2>Verantwortlicher</h2>
          <p>
            DidimDynamics, Studentenprojekt, Spengergasse 20, 1050 Wien, Österreich.
            Kontakt: <a href="mailto:hor220165@spengergasse.at">hor220165@spengergasse.at</a>
          </p>
        </section>

        <section>
          <h2>Welche Daten werden verarbeitet?</h2>
          <ul>
            <li>Accountdaten: Benutzername, E-Mail-Adresse und verschlüsselter Passwort-Hash.</li>
            <li>Profildaten: Profilbild, Privatsphäre-Einstellung, Avatar-Level, XP, Coins, Booster und Items.</li>
            <li>Trainingsdaten: Workouts, Übungen, Wiederholungen, Zeiten, Distanzen, Quests, Achievements und Aktivitätsverlauf.</li>
            <li>Soziale Daten: Freundschaften, Freundschaftsanfragen, Challenges und Benachrichtigungen.</li>
            <li>Technische Daten: JWT-Login-Token, Cookie-/Storage-Einwilligung und notwendige Server-Logs.</li>
          </ul>
        </section>

        <section>
          <h2>Zwecke und Rechtsgrundlagen</h2>
          <p>
            Die Verarbeitung erfolgt, damit Accounts erstellt, Logins abgesichert, Spielfortschritt
            gespeichert, Profile angezeigt und App-Funktionen wie Freunde, Leaderboard, Shop,
            Quests und Workouts bereitgestellt werden können. Rechtsgrundlage ist vor allem die
            Vertragserfüllung bzw. Durchführung der gewünschten App-Funktionen nach Art. 6 Abs. 1 lit. b DSGVO.
            Für notwendige Sicherheit, Missbrauchsschutz und Fehleranalyse stützen wir uns auf
            berechtigte Interessen nach Art. 6 Abs. 1 lit. f DSGVO. Optionale Einwilligungen können
            jederzeit widerrufen werden.
          </p>
        </section>

        <section>
          <h2>Speicherung und Anbieter</h2>
          <p>
            Das Frontend wird über Netlify ausgeliefert. Die API läuft auf Render. In Produktion ist
            eine PostgreSQL-Datenbank vorgesehen; Medien wie Profil- und Itembilder werden je nach
            Konfiguration in Supabase Storage oder Cloudinary gespeichert. Lokal in der Entwicklung
            wird SQLite verwendet. Im Browser werden der Login-Token, ein kleiner User-Cache und die
            Cookie-Auswahl in localStorage gespeichert.
          </p>
        </section>

        <section>
          <h2>Google Login</h2>
          <p>
            Falls Google Login aktiviert ist, verarbeitet SYBAU die von Google übermittelten
            Basisdaten wie E-Mail-Adresse, Name und Profilbild, um einen Account zu erstellen oder
            den Login durchzuführen.
          </p>
        </section>

        <section>
          <h2>Speicherdauer</h2>
          <p>
            Account- und Fortschrittsdaten bleiben gespeichert, solange der Account besteht.
            Profilbilder können entfernt werden. Nach einer Account-Löschung werden die zugehörigen
            Accountdaten gelöscht, soweit keine technischen oder gesetzlichen Gründe eine kurze
            Restaufbewahrung erfordern.
          </p>
        </section>

        <section>
          <h2>Empfänger und Weitergabe</h2>
          <p>
            Daten werden nicht zu Werbezwecken verkauft. Eine Verarbeitung durch technische Anbieter
            kann stattfinden, soweit sie für Hosting, Datenbank, Medienablage, Google Login oder
            Betriebssicherheit notwendig ist.
          </p>
        </section>

        <section>
          <h2>Betroffenenrechte</h2>
          <p>
            Betroffene Personen können Auskunft, Berichtigung, Löschung, Einschränkung der
            Verarbeitung, Datenübertragbarkeit und Widerspruch verlangen. Außerdem besteht das Recht,
            sich bei der Österreichischen Datenschutzbehörde zu beschweren.
          </p>
        </section>

        <section>
          <h2>Sicherheit</h2>
          <p>
            Passwörter werden nicht im Klartext gespeichert, sondern gehasht. Authentifizierung
            erfolgt über JWT, sensible API-Endpunkte sind rate-limitiert und dynamische API-Antworten
            werden mit No-Store-Headern ausgeliefert.
          </p>
        </section>

        <p class="updated">Stand: 25. Mai 2026</p>
      </article>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

onMounted(() => {
  window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
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
