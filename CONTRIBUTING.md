# Mitwirken

Beitraege sollen deutsch dokumentiert sein und die exportierbaren Umgebungen nicht von Generatorquellen abhaengig machen.

## Regeln

- Keine Drittanbieter-Installer, VSIX-Dateien, KI-Modelle oder Archive ins Repo einchecken.
- Jede exportierbare Umgebung muss fuer sich allein verstaendlich und nutzbar bleiben.
- Aenderungen an gemeinsamen Regeln muessen in allen acht Umgebungen synchronisiert werden.
- Tests unter `scripts/Test-AllEnvironmentPackages.ps1` muessen erfolgreich laufen.