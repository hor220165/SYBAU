# SQLite to Supabase PostgreSQL Import

Dieses Tool importiert einmalig die Daten aus `sybau.db` in die PostgreSQL-Datenbank, die ueber `ConnectionStrings__DefaultConnection` konfiguriert ist.

## Render Environment Variable

In Render muss beim Backend gesetzt sein:

```bash
ConnectionStrings__DefaultConnection=<Supabase Session Pooler Connection String>
```

Der Connection String gehoert nicht in GitHub und nicht in `appsettings.json`.

## Lokal ausfuehren

Aus dem Backend-Projektordner:

```bash
cd Sybau_Backend/Sybau_Backend
ConnectionStrings__DefaultConnection='<Supabase Session Pooler Connection String>' dotnet run -- --import-sqlite --sqlite-path sybau.db
```

PowerShell:

```powershell
$env:ConnectionStrings__DefaultConnection = "<Supabase Session Pooler Connection String>"
dotnet run -- --import-sqlite --sqlite-path sybau.db
```

## Auf Render ausfuehren

Wenn `sybau.db` im Build-Image vorhanden ist:

```bash
dotnet Sybau_Backend.dll --import-sqlite --sqlite-path /app/sybau.db
```

## Sicherheit

Der Import migriert zuerst die PostgreSQL-Datenbank. Danach bricht er ab, falls bereits Daten in Nicht-Seed-Tabellen vorhanden sind. Die Seed-Tabellen `Quests` und `Achievements` duerfen existieren und werden anhand ihrer IDs aktualisiert.

Alte SQLite-Dateien duerfen weniger Spalten haben als das aktuelle EF-Model. Das Import-Tool liest vor jeder Tabelle `PRAGMA table_info`, importiert nur vorhandene SQLite-Spalten und setzt fehlende nullable Spalten auf `null`. Fehlende required Spalten bekommen einen Typ-Default und werden als Warnung geloggt.

Nur falls ihr bewusst bestehende Daten anhand gleicher Primary Keys upserten wollt:

```bash
dotnet run -- --import-sqlite --sqlite-path sybau.db --allow-existing-data
```
