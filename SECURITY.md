# Sicherheitsrichtlinie

## Grundsatz

Dieses Projekt liefert Cline-Regeln, Workflows, Skills und lokale Helper-Skripte. Es enthaelt keine Geheimnisse, keine Provider-Konfiguration und keine Drittanbieter-Binaries.

## Sicherheitsmeldungen

Bitte melde Sicherheitsprobleme nicht in oeffentlichen Issues, wenn sie konkrete Schwachstellen, Tokens, interne Pfade oder missbrauchbare Details enthalten. Nutze stattdessen einen privaten Kontaktweg des Repository-Betreibers.

## Air-Gap-Hinweise

- Keine Datei in diesem Repo darf verlangen, dass in der Zielumgebung Internetzugriff besteht.
- Provider-, API-Key- und Modellserverkonfigurationen sind ausserhalb dieses Projekts zu verwalten.
- Cline-Agenten muessen fremde Nutzer- und Agentenordner respektieren.