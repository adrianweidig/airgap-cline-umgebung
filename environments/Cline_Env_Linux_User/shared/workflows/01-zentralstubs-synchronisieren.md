<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Zentralstubs Synchronisieren

1. Bestimme `AIRGAP_CLINE_HOME`.
2. Schreibe nur markierte Air-Gap-Stubs direkt neu.
3. Wenn eine bestehende Zieldatei nicht als Air-Gap-managed markiert ist, erst Backup mit Zeitstempel anlegen.
4. Synchronisiere Workflows nach `~/.cline/data/workflows`.
5. Synchronisiere Skills nach `~/.cline/skills`.
6. Windows zusaetzlich mit `Documents/Cline/Rules` kompatibel halten.
7. Ergebnis in `state/last-stub-sync.json` dokumentieren.