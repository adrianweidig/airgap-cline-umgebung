<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Nutzer- Und Agententrennung

- Vor Schreibarbeit in `users/` muss `OWNER.json` geprueft werden.
- Wenn Owner-Daten nicht zum aktuellen Nutzer passen, ist Schreiben verboten.
- Jeder Task-Agent arbeitet in einem eigenen Agentenordner.
- Fremde Agentenordner duerfen nur gelesen werden, wenn der Mensch dies explizit verlangt.
- Nutze `shared/helpers/python/guard_owner.py` oder den plattformspezifischen Wrapper, wenn ein Schreibziel unter `users/` liegt.