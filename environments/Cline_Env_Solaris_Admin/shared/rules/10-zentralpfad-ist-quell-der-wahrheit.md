<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Zentralpfad Ist Quelle Der Wahrheit

- Der aktuelle `Cline_Env_*`-Ordner ist `AIRGAP_CLINE_HOME`.
- Regeln, Workflows, Skills, Helper, Nutzerstatus und Workspace-Metadaten liegen zentral in diesem Pfad.
- Globale Cline-Stubs duerfen nur einen stabilen Verweis auf diesen Zentralpfad enthalten.
- Wenn in externen Repos gearbeitet wird, bleiben Cline-Hilfsdateien im Zentralpfad.
- Zielrepos erhalten nur fachliche Aenderungen, die direkt zur Nutzeraufgabe gehoeren.