<template>
  <div class="impressum-page">
    <div class="impressum-container">
      <button class="back-button" @click="goBack">
        Zurück
      </button>

      <div class="impressum-content">
        <h1 class="impressum-title">Impressum</h1>

        <section class="impressum-section">
          <h2>Informationspflicht gemäß § 5 E-Commerce-Gesetz</h2>
          <p><strong>DidimDynamics</strong></p>
          <p>Studentenprojekt</p>
          <p>
            Spengergasse 20<br>
            1050 Wien<br>
            Österreich
          </p>
        </section>

        <section class="impressum-section">
          <h2>Kontakt</h2>
          <p>
            E-Mail: <a href="mailto:hor220165@spengergasse.at">hor220165@spengergasse.at</a><br>
            Website: <a href="https://github.com/hor220165/DidimDynamics" target="_blank">github.com/hor220165/DidimDynamics</a>
          </p>
        </section>

        <section class="impressum-section">
          <h2>Team</h2>
          <div class="team-list">
            <div class="team-member">
              <span class="member-name">Viktor Horvath</span>
              <span class="member-role">Team Lead & Backend</span>
            </div>
            <div class="team-member">
              <span class="member-name">David Novakovic</span>
              <span class="member-role">Frontend</span>
            </div>
            <div class="team-member">
              <span class="member-name">Bakir Duric</span>
              <span class="member-role">Backend</span>
            </div>
            <div class="team-member">
              <span class="member-name">David Pfeiffer</span>
              <span class="member-role">Frontend</span>
            </div>
          </div>
        </section>

        <section class="impressum-section">
          <h2>Haftungsausschluss</h2>
          
          <h3>Haftung für Inhalte</h3>
          <p>
            Die Inhalte unserer Webseite wurden mit größter Sorgfalt erstellt. Für die Richtigkeit, 
            Vollständigkeit und Aktualität der Inhalte können wir jedoch keine Gewähr übernehmen. 
            Gemäß § 7 ECG sind wir für eigene Inhalte auf diesen Seiten nach den allgemeinen 
            Gesetzen verantwortlich.
          </p>

          <h3>Haftung für Links</h3>
          <p>
            Unser Angebot enthält Links zu externen Webseiten Dritter, auf deren Inhalte wir keinen 
            Einfluss haben. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter 
            oder Betreiber der Seiten verantwortlich.
          </p>

          <h3>Urheberrecht</h3>
          <p>
            Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen 
            dem österreichischen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und 
            jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen 
            Zustimmung des jeweiligen Autors bzw. Erstellers.
          </p>
        </section>

        <section class="impressum-section">
          <h2>Datenschutzerklärung</h2>
          <p>
            Die Nutzung unserer Webseite ist in der Regel ohne Angabe personenbezogener Daten möglich. 
            Soweit auf unseren Seiten personenbezogene Daten (beispielsweise Name, Anschrift oder 
            E-Mail-Adressen) erhoben werden, erfolgt dies stets auf freiwilliger Basis. Diese Daten 
            werden ohne Ihre ausdrückliche Zustimmung nicht an Dritte weitergegeben.
          </p>
          <p>
            Wir weisen darauf hin, dass die Datenübertragung im Internet Sicherheitslücken aufweisen 
            kann. Ein lückenloser Schutz der Daten vor dem Zugriff durch Dritte ist nicht möglich.
          </p>
        </section>

        <div class="impressum-footer">
          <p>© 2026 DidimDynamics</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter();

const goBack = () => {
  router.back();
};
</script>

<style scoped>
.impressum-page {
  min-height: 100vh;
  padding: 80px 20px 40px;
  color: white;
}

.impressum-container {
  max-width: 720px;
  margin: 0 auto;
}

.back-button {
  position: fixed;
  top: 32px;
  left: 32px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
  z-index: 100;
  padding: 0;
}

.back-button:hover {
  color: #ec4899;
  transform: translateX(-4px);
}

.impressum-content {
  background: transparent;
  padding: 0;
}

.impressum-title {
  font-size: 40px;
  font-weight: 700;
  margin: 0 0 48px 0;
  color: white;
  letter-spacing: -0.5px;
}

.impressum-section {
  margin-bottom: 48px;
  padding-bottom: 32px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.impressum-section:last-of-type {
  border-bottom: none;
}

.impressum-section h2 {
  font-size: 18px;
  font-weight: 600;
  color: white;
  margin: 0 0 20px 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-size: 14px;
  opacity: 0.6;
}

.impressum-section h3 {
  font-size: 16px;
  font-weight: 600;
  color: white;
  margin: 24px 0 12px 0;
}

.impressum-section p {
  font-size: 15px;
  line-height: 1.8;
  color: rgba(255, 255, 255, 0.7);
  margin: 0 0 16px 0;
}

.impressum-section a {
  color: #ec4899;
  text-decoration: none;
  transition: all 0.2s ease;
  border-bottom: 1px solid transparent;
}

.impressum-section a:hover {
  border-bottom-color: #ec4899;
}

.team-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.team-member {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.team-member:last-child {
  border-bottom: none;
}

.member-name {
  font-size: 15px;
  font-weight: 500;
  color: white;
}

.member-role {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
}

.impressum-footer {
  margin-top: 64px;
  padding-top: 32px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  text-align: center;
}

.impressum-footer p {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.4);
  margin: 0;
}

/* Responsive */
@media (max-width: 768px) {
  .impressum-page {
    padding: 60px 20px 40px;
  }

  .back-button {
    top: 20px;
    left: 20px;
  }

  .impressum-title {
    font-size: 32px;
    margin-bottom: 40px;
  }

  .impressum-section {
    margin-bottom: 40px;
    padding-bottom: 24px;
  }

  .team-member {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}
</style>