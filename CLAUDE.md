# Regler for dette repoet

- **Aldri legg hemmeligheter i repoet.** Ingen API-nøkler, tokens, passord,
  sertifikater eller private nøkler i kode, konfigurasjon, commits eller
  dokumentasjon. Repoet og GitHub Pages-siden er offentlige. Trengs en
  hemmelighet i bygget, legges den i GitHub secrets (Settings -> Secrets and
  variables -> Actions) og leses i workflowen med `${{ secrets.NAVN }}`, slik
  byggeworkflowen allerede gjør med `secrets.GITHUB_TOKEN`.
- Spillet kjører i nettleseren, så alt som bygges inn i HTML5-versjonen kan
  leses av hvem som helst. En hemmelighet som spillet selv trenger mens det
  kjører, kan derfor ikke skjules der, heller ikke via GitHub secrets. Den må
  i så fall ligge bak en egen server.

- **Gi alltid lenken til spillet etter endringer som kan prøves:**
  https://thurbohnek.github.io/Roller/ . Siden bygges og publiseres
  automatisk ved hver push til `main` (tar et par minutter). Vent til
  byggingen er publisert før lenken gis, og si fra at en privat fane eller
  omlasting kan trengs for å få nyeste versjon.

- **Lenken skal stå helt sist i svaret**, så Mathias kan teste uten å
  bla opp.
- **Rett over lenken står Mathias sin siste melding, ordrett, som et
  sitat** med overskriften "Siste melding fra deg:", så han ser hvilken
  melding svaret gjelder.

- **Test slutten av en bane med teststart.** Marken kan ikke flyttes, men
  banen kan: `python3 Util/baner/hule.py N --teststart PX` (bane 5-9)
  flytter banen så marken starter PX px før slutten (se
  `lib/teststart.lua`). Push, test i nettleseren, og sett det tilbake
  med `python3 Util/baner/hule.py N --oppsett` og en ny push før lenken
  gis. Hele banen må også testes fra vanlig start.

- **Hver oppdatering spillerne merker, får en oppføring i
  `lib/nyheter.lua`** (øverst, neste nummer, 1-4 korte linjer på engelsk).
  Den vises én gang på startskjermen ("What's new"). Varselet om at en
  ny versjon er klar kommer av seg selv (`lib/oppdatering.lua` sjekker
  `versjon.txt` som byggingen legger ut).

- **Alt grensesnitt bygges med `lib/ui.lua`** (farger, skrift, knapper,
  paneler, ikoner), og nye ikoner og bakgrunner tegnes i
  `Util/grafikk/lag_ui.py`, så stilen er lik overalt.

Se `KODEBASE.md` for hvordan koden henger sammen og `SPILLIDE.md` for
spillideen.
