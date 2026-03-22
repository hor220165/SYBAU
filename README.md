# SYBAU - Shape Your Body And Unleash

<div align="center">
  <img src="sybau_frontend/src/assets/Sybau_Logo_White.png" alt="SYBAU Logo" width="200"/>
  
  **Verwandle dein Training in ein episches RPG-Abenteuer!**
</div>

---

## Über das Projekt

SYBAU ist eine Fitness-Web-App, die Gamification-Elemente mit Workout-Tracking kombiniert. Nutzer können ihren Avatar leveln, Items sammeln, Quests abschließen und sich in globalen Leaderboards messen – während sie gleichzeitig ihre Fitness verbessern!

## Tech Stack

**Frontend:**
- Vue 3 + TypeScript + Vite
- Vue Router + Axios
- Custom CSS (Gradients, Glassmorphism)

**Backend:**
- ASP.NET Core 10.0 + C#
- SQLite + Entity Framework Core
- JWT Authentication
- RESTful API

---

## Team

- **Viktor Horvath** – Team Lead, Backend
- **David Novakovic** – Backend, Frontend
- **Bakir Duric** – Backend
- **David Pfeiffer** – Frontend

---

### Backend starten
```bash
cd sybau_backend
dotnet restore
dotnet ef database update
dotnet run --launch-profile "Local (http)"
```
Backend läuft auf: `http://localhost:5243`

### Frontend starten
```bash
cd sybau_frontend
npm install
npm run dev (local)
npm run dev:network (interner Server, jeder kann zugreifen)
```
Frontend läuft auf: `http://localhost:5173`

---

<div align="center">
  
**Made with 💪 by Team DidimDynamics**

</div>
