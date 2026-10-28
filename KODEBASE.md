# Kodebase-oversikt

Dette er et arkitektur-/kartleggingsdokument, ikke en logg (den er
`TIL-ORJAN.md`). Formålet er å gi et grunnlag for å rydde opp: hva finnes,
hva brukes faktisk, og hva er død kode som trygt kan slettes.

## Motoren

Corona/Solar2D, scene-basert via biblioteket `composer`. Hver "scene" er en
egen `.lua`-fil som returnerer et `scene`-objekt med `create`/`show`/`hide`/
`destroy`-hendelser. Navigering skjer med `composer.gotoScene("navn")` (bytter
hele scenen) eller `composer.showOverlay("navn", ...)` (legger en scene oppå
uten å fjerne den under, brukes til pause-/dødsmeny).

`ssk2/` er et eksternt, generelt utility-bibliotek (Roaming Gamer SSK2),
urørt tredjepartskode, ikke noe å rydde i.

## Mappestruktur

**Endret 2026-09-10.** Prosjektet var tidligere helt flatt (alle `.lua`-
filer i roten). Nå:

- Roten: bare `main.lua` og `config.lua` (må ligge her, Solar2D krever det),
  pluss `build.settings`, mappene under, og alle asset-mapper (bilder/lyd)
  som ikke er rørt.
- `scenes/` — alle Composer-scener (splash-skjermer, menyer, pause-/
  dødsmeny, alle ni baner).
- `lib/` — delte moduler som ikke er egne scener (fysikkformer, kamera,
  liv/poeng, banevalg-systemet, tredjeparts lagringsbibliotek).
- `dod-kode/` — bekreftet ubrukt kode, se `dod-kode/README.md`.
- `opprinnelig-fra-dropbox/` — de 306 originale filene fra Dropbox, helt
  urørt, lagt til 2026-09-10 så Ørjan kan bla i dem direkte på GitHub.
  Ikke en del av selve spillet, se `opprinnelig-fra-dropbox/README.md`.
  Ekskludert fra alle bygg via `excludeFiles` i `build.settings`, ellers
  hadde HTML5-bunten blitt ~28 MB større for ingenting siden
  `Util/recipe-html5.lua` bruker hele repo-roten som `projectPath`.
- `ssk2/` — tredjepartsbibliotek, urørt.

I Solar2D er `require("navn")` og `composer.gotoScene("navn")` bokstavelig
talt en fil-sti, så alle scenenavn heter nå `"scenes.navn"` (f.eks
`"scenes.level1"`) og alle modul-`require`-kall heter `"lib.navn"` (f.eks
`require("lib.liv")`). Bilde-/lyd-stier er IKKE påvirket, de er alltid
relative til prosjektroten uansett hvilken `.lua`-fil som laster dem.

## Faktisk scene-flyt (bekreftet ved å spore alle `gotoScene`/`showOverlay`-kall)

```
main.lua
  └─ gotoScene("scenes.gotomenu")        [endret 2026-09-15, matcher Ørjans
                  nyere versjon; gikk før rett til gotolevel1/bane 1]
       └─ (1.5s) gotoScene("scenes.menu")
            └─ trykk "storyknapp" → (2s) gotoScene("scenes.chooselevel")

scenes/level1.lua .. level9.lua     [selve banen, valgt via chooselevel-gridet]
  ├─ showOverlay("scenes.dodmenu1")        [alltid dodmenu1, uansett hvilken bane]
  ├─ showOverlay("scenes.pausemenu1")      [alltid pausemenu1, uansett hvilken bane]
  └─ mål nådd ("mal2" vs "del4")  → lm.unlockNextLevel() → showOverlay("scenes.gotonextlevel")
                  [alle ni baner. Endret 2026-09-15, gikk før alltid til
                  "gotochooselevel"/banevalget (fikset dit 2026-09-10, level2-9
                  gikk før alltid til gotolevel2). Se scenes/gotonextlevel.lua.]

scenes/pausemenu1.lua (delt av alle baner)
  ├─ "retry"      → gotoScene("scenes.gotoretry")   [egen mellomscene, fikset
  │                  2026-09-10 i to omganger, se "Kjente feil" punkt 4]
  │                  └─ (0.8s) removeScene + gotoScene("scenes.level" .. lm.currentLevel)
  │                  [om liv.erTom(): går i stedet til "scenes.adoffer", se under.
  │                  Endret 2026-09-15, gikk før rett til "scenes.gotolevel1"]
  ├─ "main menu"  → gotoScene("scenes.gotomenu") → gotoScene("scenes.menu")
  └─ "levels"     → gotoScene("scenes.gotochooselevel") → gotoScene("scenes.chooselevel")
                     └─ lm.init() (lib/ogt_levelmanager.lua) bygger rutenettet
                          └─ trykk på en rute → gotoScene("scenes.level" .. N)
                             [rett til levelN, IKKE via gotolevelN]

scenes/dodmenu1.lua (delt av alle baner)
  └─ samme struktur som pausemenu1.lua, "retry"/"main menu"/"levels", samme
     "gotoretry"-omvei og samme "adoffer"-avstikker når liv.erTom().

scenes/adoffer.lua (ny 2026-09-15, "ingen liv igjen"-skjermen)
  ├─ "se kort reklame"  → placeholder-nedtelling → liv.addToScore(1) → gotoScene("scenes.gotoretry")
  ├─ "se lang reklame"  → placeholder-nedtelling → liv.addToScore(3) → gotoScene("scenes.gotoretry")
  └─ "fortsett uten"    → liv.new() (10 liv) + liv.lagreliv() → gotoScene("scenes.gotolevel1")
                  [full livsrefill lagt til 2026-09-15, gikk før til bane 1
                  med fortsatt 0 liv]

scenes/gotonextlevel.lua (ny 2026-09-15, "banen er fullført"-splashen)
  └─ (0.8s) removeScene + gotoScene("scenes.level" .. (lm.currentLevel+1))
                  [om lm.anotherLevel() er usann (siste bane fullført):
                  gotoScene("scenes.gotochooselevel") i stedet, tilbake til
                  banevalget som før]

scenes/chooselevel.lua / gotochooselevel.lua
  → lm.init() i lib/ogt_levelmanager.lua, som leser lib/ogt_lmdata.lua
```

**Viktigst å forstå:** Selve banevalget hopper rett til `levelN`, ikke via
`gotolevelN`. `gotolevel1.lua`-splashen nås på appstart, og på "retry" når
spilleren er tom for liv velger "fortsett uten" på `scenes/adoffer.lua`
(se over). `gotoretry.lua` er en tilsvarende splash, men for
"retry på gjeldende bane" (se "Kjente feil" punkt 4 for hvorfor den finnes).
Disse to er de eneste `gotolevelN`-lignende filene som fortsatt er i bruk
(`gotolevel2.lua` til `gotolevel9.lua` ligger i `dod-kode/`, se der for
historikken).

## Fil-for-fil, gruppert

Filnavnene under er skrevet uten mappe-prefiks for lesbarhet (`gotolevel1.lua`
i stedet for `scenes/gotolevel1.lua`), se "Mappestruktur" over for hvor de
faktisk ligger nå. Alt merket **død kode** ligger i `dod-kode/`
i stedet for i `scenes/`/`lib/` (ikke slettet, se `dod-kode/README.md`).
Beskrivelsene under er ellers uendret siden flyttingen ikke påvirker hva
filene gjør.

### Kjerne / alltid i bruk
- `main.lua` — appens startpunkt, laster ssk2, går til hovedmenyen
  (`gotomenu`, endret 2026-09-15, se "Faktisk scene-flyt" over).
- `config.lua` — skjermoppløsning (540×960, kun landscape), skaleringsmodus.
- `build.settings` — orientering, feilsøkingsinnstillinger.

### Splash-skjermer ("gotoX")
- `gotolevel1.lua` — **i bruk**, appens faktiske startskjerm, og der
  "fortsett uten"-knappen på `scenes/adoffer.lua` går når spilleren er
  tom for liv og ikke vil se reklame (se `lib/liv.lua`).
- `gotoretry.lua` — **ny fil, 2026-09-10, i bruk**. Samme mønster som
  `gotolevel1.lua`, men for "retry på gjeldende bane" i stedet for
  "start på nytt fra bane 1". Se "Kjente feil" punkt 4 for hvorfor den
  finnes (retry krasjet fortsatt uten den).
- `gotolevel2.lua` til `gotolevel9.lua` — **død kode** (`dod-kode/`).
  `gotolevel2.lua` var **i bruk, men bugget** fram til 2026-09-10: vist
  fra "neste bane"-knappen i level2 til level9
  (`goto2`/`showOverlay("gotolevel2")`), uansett hvilken bane som faktisk
  fullføres, og selv den gikk videre til bane 1, ikke bane 2. `level1.lua`
  gjorde det riktig fra før (går til `gotochooselevel`, tilbake til
  banevalg). Fikset ved å la alle ni baner gjøre som `level1.lua`, se
  "Kjente feil". `gotolevel3.lua`-`gotolevel9.lua` var alltid dødt,
  ingenting navigerte dit noensinne. **Ikke å forveksle** med den nye
  `gotonextlevel.lua` under, en helt annen (og riktig virkende) fil som
  faktisk går videre til neste bane.
- `gotonextlevel.lua` — **ny fil, 2026-09-15, i bruk**. Vises fra alle ni
  baners `goto2()` når `mal2`/`del4`-målet nås (fullført bane), i stedet
  for at koden gikk rett til `gotochooselevel` (banevalget). Går videre
  til `scenes.level` .. `(lm.currentLevel+1)` om det finnes en neste bane
  (`lm.anotherLevel()`), ellers til `gotochooselevel` som før (siste
  bane fullført). Samme trygge splash-mønster som `gotoretry.lua`.
- `gotomenu.lua`, `gotochooselevel.lua` — **i bruk**, splash mellom
  pausemeny og hhv. hovedmeny/banevalg.
- `adoffer.lua` — **ny fil, 2026-09-15, i bruk**. Vises fra
  `pausemenu1.lua`/`dodmenu1.lua` sin "retry" når `liv.erTom()`, i
  stedet for at koden gikk rett til `gotolevel1`. Kort reklame gir 1
  liv, lang reklame gir 3, "fortsett uten" kaller `liv.new()` (fulle
  10 liv igjen) før den går til `gotolevel1` som før (lagt til
  2026-09-15, gikk før dit med fortsatt 0 liv). Selve reklamen er en
  tydelig merket PLACEHOLDER (nedtelling), ikke koblet til noe
  reklame-SDK ennå. **Utvidet 2026-09-15** med kjøp av forsøk, etter
  ønske fra Mathias: tre pakker (10 forsøk / 15 kr, 25 / 29 kr,
  100 / 79 kr) i tabellen `PAKKER` øverst i fila. Kjøpene er også
  PLACEHOLDER, en bekreft/avbryt-boks som sier rett ut at ingen betaling
  er koblet til spillet og at forsøkene er gratis. Både reklame og kjøp
  ender i `giForsokOgFortsett()`, som legger til forsøk
  (`liv.addToScore`), lagrer og går til `gotoretry`, så bare
  `visKjopPlaceholder()` skal byttes ut med et ekte `store.purchase(
  pakke.id )` den dagen produktene finnes. Priser og antall er tall uten
  dekning i noen butikk. Lagt ut i **to kolonner** (reklame til venstre,
  kjøp til høyre, "fortsett uten" i full bredde nederst) fordi
  innholdsflaten er liggende, se punkt 12 i "Kjente feil". Se
  `TIL-ORJAN.md` for detaljer.

### Menyer
- `menu.lua` — **i bruk**, hovedmeny (bg1-5, "spill"-knapp til `chooselevel`).
- `chooselevel.lua` — **i bruk**, viser banevalg-rutenettet
  (delegerer til `ogt_levelmanager.lua`).
- `menu1.lua`, `menu backup.lua`, `options.lua`, `brett.lua`, `play.lua`,
  `hoydehopp.lua` — **død kode**, ikke navigert til noe sted, flere har i
  tillegg egne knuste bilde-referanser (se `TIL-ORJAN.md`).

### Pause-/dødsmeny
- `pausemenu1.lua` — **i bruk, av ALLE ni baner**. Eneste pausemeny som
  faktisk vises. To feil fra samme runde rettet 2026-09-15 (se
  `TIL-ORJAN.md`): (1) `resume1()` ("main menu") og `resume3()`
  ("levels") manglet `liv.erTom()`-sjekken som `resume()` ("retry")
  alt hadde, så de trakk liv og gikk rett til målet uansett, uten å
  vise `scenes.adoffer` når livet ble tomt. (2) `resume()`, `resume1()`
  og `resume3()` kalte alle `physics.start()` rett etter de startet
  navigering bort fra banen, noe som satte fysikken til banen man
  FORLOT i gang igjen midt i fade-overgangen (marken falt synlig videre
  i et sekund eller to). Kun `resume4()` ("fortsett spillet", den
  eneste knappen som blir i samme bane) skal kalle `physics.start()`.
- `pausemenu2.lua` til `pausemenu9.lua` — **100 % død kode**. Bekreftet:
  ingen fil i hele repoet refererer til `"pausemenu2"` gjennom `"pausemenu9"`
  i det hele tatt.
- `dodmenu1.lua` — **i bruk, av ALLE ni baner**. Samme mønster som
  pausemenu1. Fikk pcall-sikkerhetsnettet på alle tre knappene
  (retry/main menu/levels) 2026-09-10, samme dekning som
  pausemenu1.lua nå. Samme to feil og samme fiks som pausemenu1.lua
  over, 2026-09-15 (har ingen `resume4`/"fortsett"-knapp i det hele
  tatt, så her ble `physics.start()` fjernet fra alle tre knappene).
- `dodmenu2.lua` til `dodmenu9.lua` — **100 % død kode**, samme bekreftelse
  som pausemenu2-9.

### Baner
- `level1.lua` — **ferdig, fungerer.** Egen, unik grafikk for banestykkene
  (`level1/1-4.png`). Kollisjonsformene i `lib/shapedefs.lua` ("1","2","3","4")
  ble sporet fra denne banens bilder.
- `level2.lua`, `level3.lua`, `level4.lua` — **byttet ut 2026-09-14** med
  Ørjans nyere versjon (mottatt som zip fra Mathias). Egne, riktig sporede
  kollisjonsformer i `lib/shapedefs2.lua`/`shapedefs3.lua`/`shapedefs4.lua`
  (ikke lenger `lib/shapedefs.lua` sine, som var sporet fra bane 1 og ikke
  stemte, se "Kjente feil" nedenfor), sammen med nye bakke-bilder
  (`level2/1-4.png` osv, alle byttet ut samtidig med formene siden de hører
  sammen). Har nå samme fulle knekk-/støveffekt-system som `level1.lua`
  (`onLocalCollision1`-`onLocalCollision9`, ni "knott"-fysikkobjekter).
  Portert til `scenes.`/`lib.`-mappestrukturen og alle våre etablerte
  rettelser (retry via `scenes.gotoretry`, `lm.currentLevel`-sporing,
  dobbeltklikk-fiksen, `transition.cancel()`+`.stage`-vakt), se
  `TIL-ORJAN.md` for detaljene og hva som bevisst IKKE ble tatt med fra
  Ørjans zip (egne per-bane pausemeny/dødsmeny-filer, blant annet).
- `level7.lua` til `level9.lua` — **fortsatt ufullstendige, ifølge Ørjan.**
  Var 100 % byte-identiske filer med knuste bildestier (bekreftet med
  `diff`). **Stiene rettet 2026-09-10** (Ørjan: greit å gjøre siden
  spillet ikke er under aktiv grafikk-utvikling), bildene refereres nå
  med riktig mappe-prefiks (`background/back_cave.png`,
  `level7/1.png` osv). Disse filene er dermed ikke lenger byte-identiske
  (hver har sin egen `levelN/`-sti), men deler fortsatt de samme
  plassholderbildene og de samme (feil, sporet fra bane 1) kollisjonsformene
  i `lib/shapedefs.lua` (se "Kjente feil"). Ørjans zip dekket bare bane 1-4,
  så disse tre venter fortsatt på tilsvarende retting. Bane 5 og 6 fikk
  hver sin egen prosedyregenererte bane 2026-09-15, se under.
> **VIKTIG, 2026-09-15, siste runde: bane 5 og 6 er tegnet på nytt med
> NYE former i bane 1-4 sin stil.** Historikken i to steg:
>
> 1. Først ble den prosedyregenererte grafikken kastet og erstattet med
>    kopier av ekte fliser fra bane 2/3/4, etter at Mathias sammenlignet
>    bildene: "5 og 6 ser ikke like bra ut, vil ha identisk bakke og tak
>    utseende som de første banene."
> 2. Så presiserte han hva han egentlig mente: "Jeg mente jeg ville ha
>    looken, ikke ren kopi. Så du må lage nye baner med samme look."
>    Kopiene er derfor også borte. Bane 5 og 6 har nå egne former, malt i
>    en stil som er **målt** ut av den ekte kunsten.
>
> Selve stilmodellen står i "Bane 5 og 6: stilmodellen" rett under
> `level6.lua`, og den er verdt å lese før man rører terreng i dette
> spillet. Kort: kunsten er to flate farger, ikke en gradering, og
> kantstreken ligger bare på vannrette kanter.
>
> **Alt som står om generator-scriptet, luftlommer, hengende tak,
> `ceiling_curve()`, `apply_gap_taper()` og fargemåling i avsnittene
> nedenfor er historikk** fra de tidligere forsøkene, beholdt fordi det
> forklarer hvorfor ting ble prøvd, men ingenting av det er i bruk nå.

- `level5.lua` — **egen bane, 2026-09-15.** Første
  bane med ordentlig innhold utover bane 1-4: nedoverbakke (samme
  diagonale flis-plassering som alle andre baner, se "Faktisk
  scene-flyt") og et hull man kan falle gjennom og dø i (`firkant3`
  flyttet en ekstra halv flis-lengde unna `firkant2`, fanget opp av
  den eksisterende `dod`-dødssonen). Grafikken (`level5/1-4.png`) er
  ikke håndtegnet som resten av spillet, men generert med et
  Python-script; selve kollisjonsformen i `lib/shapedefs5.lua` er
  regnet ut direkte fra de samme koordinatene kurven ble tegnet med
  (ikke sporet i etterkant), så form og bilde stemmer eksakt overens
  per konstruksjon. `del1` (marken sin egen form) kopiert uendret fra
  `lib/shapedefs4.lua`. Hver flis har sin EGEN bratte
  nedoverbakke-kurve (fra ~12 % ned ved venstrekant til ~83 % ned ved
  høyrekant, målt fra bane 4 sin ekte kunst), ikke én jevn kurve over
  alle fire flisene som i det aller første forsøket — den jevne
  varianten plasserte bakken altfor langt fra der marken faktisk
  starter (verdenskoordinat 0,0), så marken falt gjennom tomt rom uten
  at noen bakke kom i syne. Se `TIL-ORJAN.md` for hele prosessen,
  inkludert et mellomsteg der bane 4 sine bilder ble lånt midlertidig
  for å teste selve mekanikken isolert fra grafikken, og en
  skaleringsfeil (kollisjonsformene var regnet ut i kildebildets
  pikselstørrelse, 3840×2351, i stedet for den faktiske viste
  størrelsen 7680×4702 som `display.newImageRect` strekker til). To
  runder til, samme dag: kollisjonen fulgte fortsatt kurven dårlig
  (bare 6 rette linjestykker per flis, økt til 40), og selve terrenget
  var for kantete (den gamle boks-filtrerte støyen ga alltid en
  sagtakket rest uansett glattingsbredde, byttet til jevn
  "value noise" mellom en håndfull kontrollpunkter). Enda en runde,
  samme dag: parallax-bakgrunnen brukte en gammel, ubrukt bildesett
  (`background/dirt1.png`/`back_cave.png`, uten "1"-prefiks) i feil
  størrelse (klemt til halv høyde) og for få fliser (12 mot bane 4 sine
  20, gikk tom for bakgrunn før banen var over). Hele
  bakgrunns-oppsettet byttet ut med en eksakt kopi av bane 4 sitt.
  Terrenget fikk i tillegg en avrundet, ikke hardt avkuttet, start og
  slutt (`apply_edge_taper()` i generator-scriptet, kun de ytterste 90
  pikslene på flis 1 sin venstrekant og flis 4 sin høyrekant, resten
  urørt). Se `TIL-ORJAN.md` for alle detaljene, inkludert
  generator-scriptet (ligger i en økt-scratchpad, ikke i selve
  repoet). Siste runde, samme dag: bakken var én ubrutt skråning,
  Mathias ba om at den skal se ut som en faktisk hule med ganger og
  rom, slik bane 1-4 sin håndtegnede kunst har (flere separate
  bakkestykker med luft mellom, ikke én sammenhengende flate). Lagt
  til `gap_ranges()` (to luftlommer per flis, holdt unna
  kant-avrundingen og markens faktiske startpunkt) og
  `ceiling_curve()` (et hengende, rent visuelt hule-tak nær toppen av
  bildet, ingen kollisjon). Samme prinsipp som hullet mellom flis 2/3,
  bare i mindre skala og inni hver flis. **Bane 6 fikk samme
  hule-behandling samtidig** (se under), bakgrunnsfiksen og
  kant-avrundingen over gjelder fortsatt bare bane 5.
- `level6.lua` — **egen, prosedyregenerert bane, 2026-09-15.** Bygget
  rett med den ferdig fiksede generatoren fra bane 5 (riktig
  visningsskala, 40 kollisjons-linjestykker per flis, jevn
  "value noise"-kurve, luftlommer og hengende tak for hule-følelsen),
  bare med andre tilfeldighetsfrø så terrenget ser annerledes ut enn
  bane 5, og uten hullet mellom flis 2/3 (vanlig diagonal
  flis-cascade, ingen ekstra avstand mellom flisene, samme som bane
  1-4). Ny `lib/shapedefs6.lua`, byttet ut fra den delte, feile
  `lib/shapedefs.lua`. `del1`-formen (marken) kopiert uendret fra
  `lib/shapedefs4.lua`, identisk med bane 5 sin. Har IKKE fått
  bane 5 sin bakgrunnsfiks eller kant-avrunding ennå (de ble bedt om
  spesifikt for bane 5).

### Bane 5 og 6 etter byttet (2026-09-15, gjeldende)

Flisene og kollisjonsformene kommer nå rett fra bane 2/3/4. Ingen
generator er involvert lenger, og `level5.lua`/`level6.lua` selv er
uendret (de peker på samme filnavn som før):

| Plass | Bane 5 | Bane 6 |
|---|---|---|
| flis 1 | `level3/1.png` + `shapedefs3` sin `["1"]` | `level4/1.png` + `shapedefs4` sin `["1"]` |
| flis 2 | `level2/2.png` + `shapedefs2` sin `["2"]` | `level3/2.png` + `shapedefs3` sin `["2"]` |
| flis 3 | `level4/3.png` + `shapedefs4` sin `["3"]` | `level2/3.png` + `shapedefs2` sin `["3"]` |
| flis 4 | `level3/4.png` + `shapedefs3` sin `["4"]` | `level4/4.png` + `shapedefs4` sin `["4"]` |

Hver flis er hentet fra den PLASSEN den hadde i sin egen bane (flis 1
brukes som flis 1 osv.), fordi bakken starter og slutter i ulik høyde
avhengig av plass i rekka. Målte start- og slutthøyde på alle 16
håndtegnede flisene først, og kontrollerte at fallet fra én flis til
neste havner innenfor spennet som allerede finnes i bane 1-4 (673-5244
enheter). Kombinasjonene over gir 1144-3606, altså godt innenfor.
Kontrollerte også at marken ikke spawner inni fjell med de valgte flis
1-ene (`level1/1.png` ville gjort nettopp det, den er en flat plate helt
øverst, så den er ikke brukt).

Bildene er tonet ett hakk mørkere for bane 5 og to for bane 6 (samme
0,98-faktor per hakk som før, kun rød/grønn), som er den eneste
forskjellen fra originalkunsten. Det er gjort ved å endre selve
palett-tabellen i PNG-ene, så pikslene ellers er bit for bit like
originalen, og filene holder seg små (90-200 kB, mot 1,6 MB for de
prosedyregenererte).

Bane 5 har fortsatt den ekstra halve flis-lengden mellom flis 2 og 3
(`firkant3` i `level5.lua`), altså et bevisst hull. Med den nye kunsten
er spranget 3974 enheter bortover og 3751 nedover, som krever rundt 790
enheter/s fart ut fra kanten. Ikke testet i praksis, se `TIL-ORJAN.md`.

  **Runde til, samme dag (etter mer nettleser-testing):** fire separate
  rettelser i generator-scriptet, alle i `TIL-ORJAN.md` sin
  2026-09-15-oppføring "tak-kollisjon, pigger ved hullene, og gradert
  farge" i detalj. Kort: (1) `ceiling_curve()` regnet før helt
  uavhengig av `tile_curve()` (gulvet), og kunne dermed strekke seg
  LENGER ned enn gulvet enkelte steder (opptil 239px inni gulvet på
  det verste), som gjorde at marken landet oppå taket i stedet for på
  gulvet. Regner nå taket i forhold til gulvet, garantert minst
  `MIN_TUNNEL` (220px) klaring, eller fjerner taket helt der selv ikke
  det er plass. (2) Tak sin nedre klipp-grense hevet fra H*0.03 til
  H*0.05 for et tydeligere solid fjell-lag. (3) `apply_gap_taper()`
  skrevet om fra bunnen (femte forsøk, se kommentarene i selve
  scriptet for de fire mislykkede forsøkene før): hull-kanter avrundes
  nå med en ekte kvart-sirkel av fast radius (`FILLET_RADIUS`) som
  aldri senker gulvet mer enn radiusen, i stedet for å tynne gulvet
  til null tykkelse (som alltid ga et nål/pigg-utseende uansett hvor
  glatt avrundingen matematisk var). Antall hull per flis varierer nå
  (1-3, var alltid 2), bredden varierer (70-130px, var alltid 100px),
  og et tredje, finere støy-lag er lagt til gulv-kurven for mindre
  mekanisk utseende. (4) `_shade()` byttet til `_shade_by_distance()`:
  bruker en ekte 2D-avstandstransform (nærmeste gjennomsiktige piksel i
  alle retninger, ikke bare rett opp) for rim/fill-fargeovergangen,
  målt direkte mot `level4/2.png`, som pakker rim-fargen rundt ALLE
  eksponerte kanter (hull, undersiden av taket) i stedet for bare den
  øverste gulv-flaten. Regenererte alle åtte `level5/6/1-4.png` og
  begge `shapedefs5/6.lua`. Samme frø-mønster for bane 6 som før
  (`+1000` på alle nye støy-frø òg).

**Fargeprogresjon (mørkere jo lenger ut i spillet):** designprinsipp
fra Mathias, hver bane skal være mørkere enn forrige, som å dra dypere
ned i en hule, men VELDIG gradvis, spilleren skal knapt merke det.
Målt presist fra bane 3/4 sin faktiske kunst (ikke bane 1, som er
opplæringsbanen og en outlier): dyp bakkefarge ~(38,14,1), kantfarge
~(63,27,4). Bane 5 sin farge er dette ett "mørke-steg" (faktor 0,98 på
rød/grønn kanal, satt ned fra en først altfor merkbar 0,85) mørkere,
bane 6 to steg (0,98²). Blåkanalen holdes på bunnivå (1) i stedet for
å skaleres videre ned, den store overgangen skjedde allerede mellom
bane 1 og 2 i den ekte kunsten. Se `TIL-ORJAN.md` for målingene.

**Luftlommene og taket, presisert:** luftlommene skal kun ligge inni
hver flis (aldri ved flis-skjøtene, det var allerede riktig), og deres
kanter skal være avrundet, ikke rette utstansinger (`apply_gap_taper()`
i generator-scriptet). Det hengende taket måtte i tillegg trekkes vekk
helt i starten av flis 1, markens faktiske startpunkt (verdenskoordinat
0,0) treffer lokal rad ~25 i bildet, rett der taket ellers ville
startet, så uten dette sto marken visuelt inni fjellet ved spawn
(`apply_ceiling_spawn_clearance()`). Se `TIL-ORJAN.md` for tallene.

**Kollisjonsformene, funnet ved å faktisk tegne dem oppå kunsten:**
`SEGMENTS_PER_TILE = 40` sine jevnt fordelte samplingspunkter (~96px
mellomrom) var bredere enn en luftlomme sin kant-avrunding (70px),
så ett enkelt linjestykke kunne gå fra normal bakkehøyde til bunnen
av bildet uten noe punkt innimellom, en høy tynn feilaktig SOLID
kollisjonsvegg tvers gjennom det som skulle være åpent rom. Fikset
med `_dense_grid()`: samme 40-punkts grunnfordeling, med ekstra tette
punkter presset inn rundt hver rask overgang (luftlomme-kanter,
kant-avrunding). Taket har nå også egne kollisjonsformer (var rent
visuelt før), samme trapes-teknikk speilvendt fra toppen (y=0) ned
til tak-kurven. Antall fixtures per flis gikk fra ~40 til over 130.
Se `TIL-ORJAN.md` for detaljene og hvordan feilen ble oppdaget
(et referansebilde med kollisjonsformene tegnet oppå kunsten).

**Tak-klaringen ved spawn, rettet på nytt:** forrige forsøk på
`apply_ceiling_spawn_clearance()` hadde riktig idé men et fortegn
baklengs i egen verifikasjon (regnet "tak-verdi minus markens rad" og
kalte positivt trygt, riktig sjekk er omvendt siden taket er solid
FRA toppen av bildet OG NED), så marken spawnet fortsatt 125 enheter
inni fjellet i praksis, til tross for en rapportert "trygg klaring".
Skrevet om til en flat, trygg sone (`SPAWN_CLEAR_FLAT`, tak presset
mot null) som dekker markens HELE kroppsbredde ved spawn (alle ni
kroppsdelene deler samme rad, kolonner ca 60-170), etterfulgt av en
lengre glidende overgang (`SPAWN_CLEAR_RAMP`) tilbake til normal
tak-dybde. Se `TIL-ORJAN.md` for hele regnefeilen og den nye,
kolonne-for-kolonne-sjekkede klaringen.

### Banevalg-systemet
- `ogt_levelmanager.lua` / `ogt_lmdata.lua` — **i bruk**, tredjeparts-aktig
  "level select grid"-bibliotek (paginert rutenett, lås/opplåsing,
  stjerner). `ogt_lmdata.lua` er konfigurasjonen (antall baner, låste
  baner, bildefiler). To ting funnet ved gjennomgang 2026-09-10, begge
  **fikset samme dag**: `k.beforeLeaving()` (kjører hver gang du
  trykker en banerute) lagde en splash-sprite som aldri ble fjernet,
  fjernes nå i `selectLevel()` sin `goto()` rett før scenebyttet. Og
  selve scenebyttet når du trykker en banerute (`sceneMgr.gotoScene()`
  i `selectLevel`) manglet pcall-sikkerhetsnettet som resten av kjeden
  dit (pausemeny → gotochooselevel → chooselevel → init/makeGrid) fikk
  under feilsøkingen, har det nå også.
  `k.numUnlocked` (hvor mange baner som er åpne fra start) satt tilbake
  til **4** 2026-09-15 (sto til `k.totalLevels`/9, en midlertidig
  debug-overstyring fra en tidligere økt), etter at Ørjans egen nyere
  `ogt_lmdata.lua` bekreftet 4 som riktig verdi — det er nøyaktig så
  mange baner som faktisk er ferdige, se `level2.lua`-punktet lenger
  ned og "Kjente feil".
  `selectLevel()` sjekker nå liv FØR banen startes (2026-09-15, per
  Mathias): kunne før starte en hvilken som helst ulåst bane direkte
  fra banevalget selv med 0 liv, uten at reklame-for-liv-skjermen
  (`scenes/adoffer.lua`) noen gang ble vist — liv ble kun sjekket i
  pause-/dødsmenyen. Kaller `liv.lastliv()` (må lastes på nytt her,
  banevalget kan nås før noen bane er åpnet denne økten) og går til
  `scenes.adoffer` i stedet for valgt bane om `liv.erTom()`.

### Delte spillobjekter
- `perspective.lua` — kamerasystem (parallakse, lag), tredjepartsbibliotek
  ("Perspective" av Caleb P), urørt. Lag 1 av 8 er alltid fremst (tegnes
  sist av `Perspective.createView()`, siden løkka går `numLayers` ned
  til 1 og `view:insert()` legger til bakerst i lista). Pauseknappen
  (`knapp1`) legges i lag 2 med `parallaxRatio = 0` (så den ikke ruller
  med kameraet) i alle ni `levelN.lua`, men lag 2 lå likevel BAK lag 1
  der banen/marken/gulvet ligger, altså bak selve banen. Rettet
  2026-09-15 ved å legge til `camera:layer(2):toFront()` rett etter i
  alle ni banefiler (flytter kun rekkefølgen lag 2 tegnes i, endrer
  ikke hvilket lag noe tilhører eller rulle-oppførselen). Se
  `TIL-ORJAN.md`.
- `shapedefs.lua` — auto-generert av PhysicsEditor, kollisjonsformer. Se
  "Kjente feil".
- `liv.lua` — "liv" = spillerens liv/poengsum, lagres til fil
  (`system.pathForFile("liv.txt", ...)`, på HTML5 vedvarende
  nettleser-lagring). **Trekkes bare fra når du bruker en knapp i
  pause-/dødsmenyen (retry/main menu/levels), ikke av noe som skjer
  inni selve spillingen.** Ørjan bekreftet 2026-09-10: liv skal ha
  reell betydning (ikke ferdig kodet), og skal kunne nå null, da skal
  spilleren kunne se en reklame for å få liv tilbake (1 min reklame =
  1 liv, lang reklame = flere), eller heller starte på nytt fra bane 1
  om man ikke vil se reklame. Bugen som hindret telleren fra
  noensinne å nå null er fikset (`liv.endreliv()` la feilaktig til 2
  liv i stedet for å trekke fra ved siste liv). "Retry" i
  `pausemenu1.lua`/`dodmenu1.lua` sjekker nå `liv.erTom()`: har du
  liv igjen, restartes gjeldende bane; er du tom, går du i stedet til
  `scenes.adoffer` (ny fil, 2026-09-15, se "Splash-skjermer"), som
  viser reklame-for-liv-skjermen Ørjan beskrev. `liv.addToScore(val)`
  og `liv.new()` var begge tomme stubber fram til 2026-09-15, fylt inn
  til hhv. å legge til liv (reklame-knappene) og nullstille til fulle
  10 liv igjen (`adoffer.lua` sin "fortsett uten"-knapp, per Mathias:
  å starte helt på nytt bør gi fulle liv, ikke fortsatt 0). Reklamevisningen
  selv er fortsatt en PLACEHOLDER (nedtelling, ikke et faktisk
  SDK-kall), men resten av flyten (legg til/nullstill liv, lagre, gå
  videre til riktig bane) er ferdig kodet. Dødsskjermen
  (`showOverlay("dodmenu1")`) trigges
  fortsatt av noe helt separat: en fysikk-kollisjon mellom et
  "dod"-objekt og spillerens hode (`del9`), uavhengig av
  live-telleren.

  **Visningen (`liv.hent()`) endret 2026-09-15**, per Mathias: tallet
  viser nå hvor mange forsøk du har igjen ETTER det du holder på med
  (`liv_igjen - 1`, aldri under 0), ikke den rå telleren. Står det 0 er
  dette siste forsøk, og dør du kommer reklame-skjermen. Før viste den
  "1" på siste forsøk, som fikk folk til å tro de hadde ett forsøk i
  bakhånd. Selve telleren og alt regnestykket rundt er uendret, kun
  visningen. `scenes/adoffer.lua` sier derfor "forsøk" og ikke "liv"
  på knappene sine, ellers ville "+1 liv" sett ut som om ingenting
  skjedde (telleren står på 0 både før og under det ekstra forsøket).
  Samme funksjon fikk samtidig en **retry-knapp**: trykk på
  livteller/markikonet, så spretter det opp en retry-knapp rett under
  (trykk igjen for å skjule den). Den gjør nøyaktig det samme som
  retry-knappen i pausemenyen, inkludert `liv.erTom()`-sjekken og
  omveien om `scenes.gotoretry`. Ligger her, altså ett sted for alle ni
  banene. `livText`/`livbilde` var utilsiktede globaler og er nå lokale,
  og den gamle telleren fjernes før en ny tegnes (banefilene kaller
  `liv.hent()` både med en gang og igjen etter tre sekunder, så det lå
  hele tiden to oppå hverandre).
- `mark.lua` — bygger spillerkarakterens kroppsdeler (hale/hode),
  fysikk-leddet sammen. **`require`t av `menu.lua` og `level1.lua`,
  men `mark.hent()` blir aldri faktisk kalt noe sted** (begge fanger
  funksjonen i en lokal variabel og bruker den ikke). `level1.lua`
  bygger i stedet spillerkroppen med ca 90-100 linjer kopiert kode
  rett i egen fil. Reelt sett dødt, bortsett fra at selve `require`-
  kallet kjører harmløst.
  **Om kollisjonsboksene på marken (spurt av Ørjan 2026-09-10):**
  `shapedefs.lua` har faktisk ferdige `"hale"`/`"hode"`-former, men de
  brukes IKKE av `level1.lua` sin ormekropp. I stedet brukes
  hånd-skrevne, innebygde former (`del1Shape`/`del9Shape`). Sjekket
  hvorfor: `del1` (halen) krympes fra 55×35 til 27×17 rett før
  kollisjonsformen legges på, og de innebygde formene stemmer med den
  krympede størrelsen, mens `shapedefs.lua` sine `"hale"`/`"hode"`
  er sporet fra bildet i original (ukrympet) størrelse. Å bytte dem
  inn direkte ville gitt en dobbelt så stor usynlig kollisjonsboks.
  Ikke rørt fysikk-koden på dette, se "Kjente feil" punkt 5 for
  hvorfor (Ørjan sjekker om en nyere, 3-delt versjon av marken
  finnes).
- `gameUI.lua` — liten delt hjelpefunksjon (`dragBody`), i bruk.
- `GGData.lua` — tredjeparts lagringsbibliotek, urørt.
- `game.lua`, `livddadas.lua` — **død kode**, gamle/kommenterte varianter av
  `liv.lua`, aldri `require`t noe sted. Snodig detalj: filnavn og innhold
  er byttet om. `game.lua` inneholder (til tross for navnet) en gammel
  `liv`-modul med udefinerte `saveScore()`/`loadScore()`-kall (ville
  krasjet hvis den noen gang ble brukt). `livddadas.lua` inneholder i
  stedet en gammel `game`-modul (score.txt/high_score, fungerende
  internt). Ufarlig siden begge er 100 % ubrukte, men en felle for
  filnavn-basert gjetting hvis noen vurderer å gjenopplive en av dem.

### Bane 5 og 6: stilmodellen

Målt på tolv ekte fliser (bane 2, 3 og 4) 2026-09-15, og det er denne
modellen `level5/1-4.png` og `level6/1-4.png` er tegnet etter.

**Kunsten er to flate farger, ikke en gradering.**

| | farge |
|---|---|
| kropp | `rgb(38,14,1)` |
| kantstrek | `rgb(72,33,6)` |

Resten av paletten (25-49 indekser per fil) er blandinger mellom de to
og det gjennomsiktige. Flere forsøk på en glatt gradering lignet aldri,
og dette er grunnen.

**Kantstreken ligger bare på vannrette kanter.** Dette er det viktigste
enkeltpunktet, og det som ble bommet på i alle de tidligere forsøkene:

| kanten vender | andel med kantstrek |
|---|---|
| vannrett (topp og bunn) | 92-93 % (spenn 74-100) |
| loddrett | 18 % (spenn 6-35) |

Legger man lik kantfarge rundt hele formen, ser steinen ut som en
utstanset plate i stedet for noe lys faller på ovenfra. Streken er
median 43 piksler dyp, p90 87.

**Det blå er IS, ikke bare en farge.** Fixturene under den har
`friction = 0.05` i stedet for `3`. Målt i `lib/shapedefs4.lua`: 125 av
519 fixtures har 0.05, ingen av de andre banene har en eneste, og
is-fixturene inneholder 6,7-12,6 % blå piksler mot 0,1-1,2 % i
stein-fixturene. `level4/1` har ingen blå farge og ingen is-fixtures.

Isen ligger på **gulvflaten man ruller på**, som et tynt lag 6-20 px
under overflaten (94,6 % og 98,4 % av de blå pikslene i `level4/2` og
`level4/3` ligger på nederste bit i kolonnen). `level4/4` er 45/55 fordi
halve isen der ligger på hulemunnens overheng. Is på en stein man ikke
kan komme på gjør ingenting, så legg den aldri på takskår.

Visuelt er isen et **skarpt** cyan band, `rgb(44,106,130)` på det
sterkeste, med hard innerkant. Toner man den mykt ut leser den som en
flekk i steinen i stedet for et eget materiale. Bane 5 og 6 har 65 og 62
is-fixtures, 0,44-1,46 % av kroppen blå, dybde median 14-16 px.

**Formene** er alle bygget av én kloss: en skive med en toppkurve og en
bunnkurve. Høyt tårn er en smal tjukk skive, kile er en der toppen
stuper mens bunnen står (så massen spisser seg ut i en tunge), takskår
er en tynn fritt liggende skive, og hulemunn er en tjukk skive som
spisser seg ut over gulvet. Topp og bunn må IKKE gå parallelt, da blir
alt flate bånd uten karakter.

**Konturene** er en glattet tilfeldig gange med noen få bevisste knekk,
ikke summer av sinuser. Sinuser gir tette skvulp (cirka 150 px mellom
hver bølge); den ekte kunsten har lange sveip på 500-900 px.

Verktøyene som gjorde dette ligger ikke i repoet, de var
engangs-scripts. Tallene over er det som trengs for å gjøre det om
igjen.

**Kollisjonen** er 878 (bane 5) og 1018 (bane 6) fixtures, 187-262 per
flis, mot 67-308 i de ekte banene. Hver fixture er et trapes på 100 px
bortover og høyst 160 px nedover, med hjørnene på skivens egen topp- og
bunnkurve, så bilde og kollisjon kommer fra de samme kurvene. Trapeser
tynnere enn 14 px slippes, så de hårtynne spissene på kilene er rent
visuelle.

Oppdelingen **nedover** er viktig og ble lagt til 2026-09-16. Første
utgave laget ett trapes per kolonne som spente hele steinens tykkelse,
og de ble median 140 enheter breie og 1380-1714 høye, altså forhold
rundt 1:10. De ekte er kompakte: 288-376 x 218-293. Box2D regner
dårligere på så langstrakte polygoner, og de 1400 enheter høye skjøtene
er den typen kant en rullende kropp kan hekte seg på. Hold fixturene
omtrent like høye som de er breie.

Bare den **øverste** skiva i et is-område får `friction = 0.05`. Isen er
et lag på overflata, ikke hele steinsøyla, og i bane 4 ligger 98-100 %
av is-fixturene i selve overflata.

Koordinatavbildning, bekreftet mot bane 3 og 4 sine egne shapedefs:

    X = (bildepiksel_x - 1920) * 2
    Y = (bildepiksel_y - 1175.5) * 2

og hjørnene må ha positiv signert flate (alle 400 undersøkte fixtures i
`lib/shapedefs4.lua` har det).

**Spawn.** Marken står i `del1 = (0,0)`, og `firkant1` er sentrert i
(3500, 2300) med 7680 x 4702 enheter mot et bilde på 3840 x 2351 px.
Marken starter derfor ved bildepunkt **(116-170, 26)** i flis 1 i bane 2
til 9, unntatt bane 7, der flisene er flyttet 1130 enheter mot venstre
(`firkant1.x = 3500 - 1130`) så marken starter ved (640-735, 26) (se bane
7 under). Bane 1 har dobbelt så stor flis, se NB under. Flis 1 må ha bakke rett under der: de ekte banene har den
111-210 px nede, altså 171-369 enheters fall. Første utgave av bane 5/6
hadde 1699 og 1809, og banen åpnet med at marken stupte nesten en hel
flishøyde (meldt av Mathias 2026-09-15). Rettet, nå 355 og 373.

Mønsteret i flis 1 er: bakken starter høyt (167-251 px) og faller jevnt
utover flisa. Bane 4 går 251 → 650 → 1036 → 1320 → 1680.

**NB om bane 1:** `level1/1.png` er **7680x4702** bildepunkter, mens
`level2/1.png` til `level6/1.png` er 3840x2351. Alle vises på 7680x4702,
så omregningen bildepunkt til spillkoordinat er 1:1 i bane 1 og 1:2 i de
andre. Marken starter derfor ved bildepunkt (232-354, 51) i bane 1.

Flisa er dessuten utendørs og har malt himmel, `rgb(167, 202, 255)`,
øverst. Den er ugjennomsiktig, så en gjennomsiktighetstest melder
feilaktig «stein» der. Målt mot kollisjonsformene står marken i fri
luft: overkanten av bakken ligger på y = 400 under halen, 538 under
midten og 644 under hodet, altså omtrent 400 enheters fall. Bane 1 er i
orden. (Tidligere notat om at bane 1 spawner inni stein var feil,
rettet 2026-09-16.)

**Stilmodellen, målt på nytt 2026-09-16 mot `level3/1.png`:**

| Dybde under omrisset | Farge |
|---|---|
| 0,5 til 1,5 px | `rgb(10, 2, 0)` konturstrek |
| 1,5 til 60 px | `rgb(70, 32, 5)` rim |
| 60 til 130 px | `rgb(47, 19, 2)` overgang |
| over 130 px | `rgb(38, 14, 1)` kropp |

Fargefordeling i de ekte: 56 prosent kropp, 12 prosent rim, 31 prosent
mellomtoner. Korn: 372 avlange prikker per flis, 16 x 10 px, én per
90 x 90 px rute.

Renderen bygger masken først og henter all farge av avstandstransformen.
Variasjonen ligger i hvor dypt rimen går, ikke i et lysfelt oppå massen.
Legger man på et lysfelt forsvinner den flate kroppsfargen.

**Is:** bare `level4/2.png`, `3` og `4` har blått blant de seksten ekte
flisene, og der er det 0,4 til 1,9 prosent av massen. Bane 2 og 3 har
null. Tverrsnitt inn fra kanten: `rgb(15,50,63)` kald konturstrek på 0
til 2 px, `rgb(36,96,118)` med glans på 2 til 7, `rgb(30,84,104)` på 7
til 16, `rgb(20,60,74)` på 16 til 30. Båndtykkelsen varierer 10 til 123
px, og isen dekker 20 til 26 prosent av omrisset.

**Flisene rører aldri flisekanten.** Alle fire kantradene er 0,0 prosent
stein i de ekte. Formene lukker seg inne i flisa, så konturstreken går
hele veien rundt. Klaringen er 2 til 210 px.

**Sprekkene går i huletaket, aldri i gulvet.** De er gjennomsiktige
spalter hogd ned fra overkanten av den øvre massen. Legger man dem i
gulvflata bryter de bakken marken ruller på.

**Målt spillbarhet bane 5/6 (2026-09-16):** takhøyde 786 til 1608
enheter, spawn-fall 285 og 253, verste motbakke 0 px, fall mellom fliser
784 til 4269, dødslinje-klaring 612 til 622, alle fjorten hopp krever
202 til 243 enheter/s med landingen lavere enn avsatsen.

**Kollisjonsklosser:** 1491 og 948 mot 505 til 743 i de ekte banene.
Takmassen spores grovt, og dybden deles i skiver som blir tjukkere
nedover (80 px øverst, så fordobling) i stedet for jevne 160 px. Jevne
skiver ga 12 klosser per kolonne på en 2000 px tjukk gulvblokk, der bare
den øverste noen gang blir berørt.

samme format som den ekte kunsten, 79-97 kB per flis.

## Bane 7: én masse per flis, rett fra Ørjans tegning (2026-09-27)

**Tegningen viser hele banen, ikke én flis.** Rød prikk er spawn, lilla
strek er `dod` (rotert 31,48 grader i `level7.lua`), gul strek er `mal2`
(rotert 45 grader, nederst til høyre), og de fire blå massene er de fire
flisene. Flisene ligger på skrå, hver 7680 x 4702 enheter forskjøvet fra
den forrige, så dødslinja går gjennom hver flis på samme sted: bildepunkt
y = 567 + 0,612 x.

Alt lages av `Util/baner/lag_bane.py` fra `Util/baner/tegning7.jpg`.
Scriptet ligger i repoet, og bildene og kollisjonen er generert av det,
så de skal ikke redigeres for hånd:

    pip install numpy scipy pillow
    python3 Util/baner/lag_bane.py 7 --sjekk   # bare målinger
    python3 Util/baner/lag_bane.py 7           # skriver level7/*.png og lib/shapedefs7.lua

Scriptet nekter å skrive noe hvis målingene faller utenfor kravene.

- **Formen er en fri, lukket kontur** hentet rett fra den blå streken, ikke
  en topp- og en bunnkurve. Endene blir derfor runde, og hodene, knekkene
  og de bølgete kantene er Ørjans egne. Den gamle modellen med topp- og
  bunnkurve kunne bare gi loddrett avkuttede ender, og det var derfor den
  forrige utgaven så firkantet ut.
- **Massene er strukket 1,3 til 1,7 ganger bortover.** Tegnet i riktig
  forhold blir gapet over flisekanten rundt 650 px, og hodet på neste
  masse har en avrundet venstreside. Marken ville da landet der og måttet
  klatre. Gapet er nå 44 til 70 px, med et fall på 765 til 939 px rett ned
  på toppen av neste hode.
- **Banen er flyttet 1130 enheter mot venstre** (`firkant1.x`, `dod.x` og
  `mal2.x` i `level7.lua`), så marken står over bildepunkt 640-735, der
  toppen av første masse begynner å helle nedover mot høyre. Med 600 sto
  marken ytterst på venstre kant av den flate toppen, vippet bakover og
  falt ut. Scriptet sjekker nå både fallet fremover og bakken bak marken. **Flytt aldri selve marken (`del1.x`).**
  Første forsøk satte `del1.x = 600`, og da ble fysikken NaN og bane 7
  krasjet med en gang i nettleseren (`assertion failed!` i
  `transition.to`). Trolig fordi sveiseleddene til knottene bruker
  `(knott.x, knott.x)` som festepunkt, som bare ligger nær marken når den
  står rundt x=0.
- **To oppbøyde lepper er slipt ned**, ytterst på masse 1 og 3. Marken
  ville blitt liggende i dumpa foran dem. Bølger under 25 px er beholdt.
- **Kollisjonen** har 1013 klosser. Trapesene er høyst 100 px brede, og en
  kolonne deles så lenge toppen avviker mer enn 8 px fra en rett linje,
  ellers blir det en usynlig rampe over hakk og overheng. Dekning er
  99,7-99,8 %.
- **Stilen** er målt i `level4/1.png`: rim `rgb(72,33,6)` omtrent 70 px ned
  fra toppen og opp fra bunnen (loddrett avstand, ikke euklidsk, derfor
  nesten ingen rim på sidene), glir over i kroppen `rgb(38,14,1)`. Ingen
  is.

Målt: spawn-fall 145-170 px, verste motbakke 20-25 px etter landing, alle
tre landinger på toppen av neste hode ved 156, 200 og 248 enheter/s. Ut
av flis 4 treffer marken `mal2` før `dod` ved alle tre fartene.

## Bane 8: fri plassering av flisene, fra Ørjans tegning (2026-09-27)

Laget med samme verktøy som bane 7, nå `Util/baner/lag_bane.py`, som tar
banenummeret som argument:

    python3 Util/baner/lag_bane.py 8 --sjekk   # bare målinger
    python3 Util/baner/lag_bane.py 8           # skriver level8/*.png, lib/shapedefs8.lua og lib/baneoppsett8.lua

Tegning 8 (`Util/baner/tegning8.jpg`) har smalere og brattere masser
enn tegning 7, med hodet 400-1000 px inn bak en skrå venstreside. Lagt i
den faste diagonalen måtte de strekkes 2-2,4 ganger bortover, og marken
landet i en motbakke uansett. Derfor:

- **Flisene ligger fritt.** Massene er skalert likt i begge retninger
  (7,1-9,5 flispiksler per tegningspiksel), og hver flis er lagt slik at
  hodetoppen på neste masse står 180 px til høyre for og 600 px under
  kanten på den forrige. Flisene overlapper hverandre, det er greit fordi
  bildene er gjennomsiktige utenfor massene.
- **`lib/baneoppsett8.lua` er generert** og gir sentrum for de fire
  flisene, `dod` (posisjon og rotasjon) og `mal2`. `level8.lua` leser den,
  så bilder, kollisjon og plassering kan ikke komme i utakt.
- **Dødslinja** er en rett linje med samme helning som banen, lagt 250 px
  under all bakke man kan stå på. Den krysser inn i massene, som i
  tegningen.
- **Spawn:** hele marken skal stå i helningen etter kammen, med minst
  20 px fall under seg og ingen lavere bakke bak. Første forsøk tillot 40
  px lavere bakke bak, og marken ble liggende i balanse på kammen.
- I tegning 8 krysser den lilla streken inn i massene, så avskjæringen
  under den (brukt i bane 7) er slått av.

Målt: spawn-fall 160-226 px, alle tre hopp lander på eller bak neste
hodetopp ved 156, 200 og 248 enheter/s, verste motbakke 17 px, ingen
overlapp mellom massene, 879 kollisjonsklosser. Testet i Chromium mot
den publiserte versjonen: marken ruller gjennom hele banen og treffer
målet uten at noen trykker.

**Bakgrunnen** følger banens retning: vinkelen fra spawn til målet og
steget mellom hulebitene (1999 enheter, som 1705/1044 i de andre banene)
står i `lib/baneoppsett8.lua` under `bakgrunn`. Ellers er oppsettet det
samme som i bane 4-7: `1dirt1` 40 skjermer langt i lag 6 (følger banen
1:1) og 20 hulebiter per lag.

**Bakgrunnen i bane 7 (rettet 2026-09-27)** var fortsatt det gamle
oppsettet: `dirt1` bare 20 skjermer langt og 12 hulebiter per lag.
Jordlaget i lag 6 følger banen 1:1 og rakk bare til omtrent x = 16 400
av rundt 30 000, så bakgrunnen forsvant halvveis. Samme feil som bane 5
og 6 hadde 2026-09-15. Byttet til nøyaktig samme blokk som bane 5.

**Måltreffet lekket mellom banene (rettet i alle ni banefilene).**
`onCollision1` sjekket bare `agro.type == "mal2" and hit.type == "del4"`.
Mens neste bane starter, ligger marken fra forrige bane fortsatt i
fysikkverdenen og faller gjennom sitt eget mål. Det utløste målet i den
nye banen med en gang: bane 8 -> 9 hoppet rett videre til banevalget og
krasjet med `attempt to compare nil with number`. Sjekken sammenligner nå
med banens egne objekter (`agro == mal2 and hit == del4`).

**Kameraet ble ødelagt av forrige bane (rettet i alle ni banefilene).**
`camera` er global (`_G.camera`). Når spillet går rett videre til neste
bane, lager neste bane sitt kamera før forrige banes `scene:hide` kjører,
og den kalte `camera:destroy()` på det nye kameraet. Hver bane husker nå
sitt eget kamera i `egetKamera` og ødelegger bare det.

### Forrige utgave: tynne svevende band (2026-09-27), forkastet

Tolket tegningen som én flis og la 3-4 tynne band i hver flis, 13 i alt i
stedet for 4. Formene var bygget av en topp- og en bunnkurve per kolonne,
så endene ble loddrette kutt, og banen så firkantet ut.

### Forrige utgave: søyler etter bane 4 (2026-09-24), forkastet

Bane 4 er ikke en tunnel slik bane 3 er. Den er **stående søyler man
hopper mellom, som trapper seg nedover mot høyre.** Målt på de fire ekte
flisene: 2 til 4 søyler per flis, bredde 596 til 2229 px, høyde 656 til
2055, **underkanten på y 2148 til 2288 i alle**, altså samme grunnlinje.
Gap 40 til 376 px, toppen av neste 237 til 1285 px lavere. Tetthet i
omskrevet boks 0,51 til 0,82. Fyllgrad 31 til 41 prosent, flis 4
(hulemunnen) 60. Is i flis 2, 3 og 4, ingen i flis 1.

Bane 7 har derfor **ingen takmasse**. Det gir 828 kollisjonsklosser, mot
bane 5 og 6 sine 1491 og 948 og de ekte banenes 505 til 743.

**Regel om gap, lært tre ganger:** det effektive gapet er ikke avstanden
mellom blokkene, det er avstanden mellom der de fortsatt er tjukke nok
til å bære, altså 120 px. Tilspissingen på endene gjorde 150 px tegnet
til 273 px målt, og i bane 5 til 459 px. En lavere topp gir en tynnere
søyle og skyver landingspunktet enda lenger inn: da jeg senket en topp
for å få større fall, ble gapet 363 px og kravet steg fra 245 til 286
enheter/s. **Hold søyla tjukk, flytt den sidelengs.**

**Kroppsfargen er rgb(38, 14, 1) i bane 2, 3 og 4, nøyaktig lik.** Den
gradvise mørkningen i bane 5 og 6 finnes ikke i den ekte kunsten, den er
innført av meg.

## Bane 8 slakere og ny bane 9 (2026-09-28)

- **Bane 8** gikk i 55 grader og var alt for bratt. Tegningen dreies nå
  20 grader mot klokka før massene legges ut (`vri=20` i `BANER[8]`), og
  banen går i 41 grader.
- **Bane 9** er ny og har ingen egen tegning. `BANER[9]["kilder"]` henter
  masser fra tegning 7 og 8 om hverandre, dreier massene fra tegning 8
  som i bane 8, strekker dem litt ulikt bortover og gir hver en jevn
  tilfeldig deformasjon (`deformer()`, frø per masse), så formene er nye
  men i samme stil. Plassert fritt som bane 8, med `lib/baneoppsett9.lua`.
  `level9.lua` er `level8.lua` med banenummeret byttet (de var identiske
  fra før, bortsett fra nummeret).
- Spawnhøyden i fri plassering holder nå også fremste del av marken
  innenfor 200 px fall, ikke bare bakerste.

## Bane 5-9 som grotter (2026-09-28, gjeldende)

Mathias ville at bane 5-9 skulle ligne mer på bane 4, med is, hopp nær
det marken klarer, en isdal marken må gli slapp gjennom, og tak som i
bane 3, men organisk, som en hule nedover. Etter en skisse fra ham ble
alle fem laget på nytt av `Util/baner/hule.py`. Sidene over om bane 5-9
fra før denne datoen er historikk.

    python3 Util/baner/hule.py 7 --sjekk   # bare målinger
    python3 Util/baner/hule.py 7           # skriver level7/*.png,
                                           # lib/shapedefs7.lua og lib/baneoppsett7.lua

- **Banen beskrives som partier** i `bane5()` til `bane9()` nederst i fila:
  `bakke(lengde, grader, bue)`, `hopp(bort, ned)`,
  `soyletrapp(antall, bredde, gap, ned, is_paa)`,
  `isdal(bredde, dybde, ut, klaring)`, og `tak_over(lengde, klaring,
  drypp)` / `is_over(lengde)` for strekningen som kommer etterpå.
- **Massene** lages rundt gulvlinja: et steinbånd under rulleflata, søyler
  som smalner nedover, taksteiner med drypp, og overheng over isdalene.
  Konturene rundes (Chaikin) og får rolige bølger, og males i stilen fra
  bane 4 (`lag_bane.mal`). Fargene går fra bane 4 sin brune jord i bane 5
  mot grå stein i bane 9 (`palett()`).
- **Is** males på toppen av gulvet i is-strekningene og under
  overhengene, med fargene målt i bane 4. Kollisjonsklossene der får
  `pe_fixture_id = "is"` og friksjon 0,05, som isen i bane 4.
- **Flisene** (4 stk.) legges fritt langs grotta. Hver flis blir så bred
  som høyden tillater (gulv, det som er over og stein under), og neste
  starter 350 px før. Hver verdenspiksel tegnes bare i den første flisa
  som dekker den. Får ikke banen plass, kortes siste bakke inn.
- **Målet** virker som i bane 1-4: kameraet stopper 900 px (1800
  enheter) før slutten av gulvet (`kamera.x_maks`/`y_maks` i
  `lib/baneoppsettN.lua`, brukt i `camera:setBounds`), og marken ruller
  videre ut av skjermen til høyre før den treffer `mal2`, 150 px før
  slutten. `python3 Util/baner/hule.py N --oppsett` skriver bare
  oppsettfila på nytt.
- **`levelN.lua`** for 5-9 er samme fil som `level8.lua` med nummeret
  byttet (bane 6 bruker fortsatt bakgrunnsbildene uten `1` foran). Alt
  som er banespesifikt ligger i `lib/baneoppsettN.lua`.

### Bane 4 målt, og hva grottene bygger på

- Rulleflatene i bane 4 heller 13-31 grader (median 24, sjelden over 41).
  Grottene bruker 16-30.
- Første hopp i bane 4 er omtrent det marken klarer: 30 graders tilløp,
  520 px bort og 265 px ned. `--sjekk` viser hvert hopp i prosent av det,
  og stopper over 102 %.
- Isdalen i bane 4 er en V under et overheng med 10-50 px åpning, og
  utgangen er lavere enn inngangen. Grottene bruker 42-55 px klaring.
- Tak i bane 3 gir 44-400 px åpning. Grottene bruker 230-460, trangest
  nederst.

| Bane | Hopp (maks-hopp) | Søyler | Tak | Isdaler |
|---|---|---|---|---|
| 5 | 3 (1) | - | 3, 380-460 px | - |
| 6 | 2 (1) | 3 med is | 1, 340 px | - |
| 7 | 2 (1) | 2 med is | 1, 320 px | 1 |
| 8 | 2 (1) | 3 med is | 2, 270-330 px | 1 |
| 9 | 2 (2) | 2 med is | 2, 230-260 px | 2 |

## Controls, banenummer og minispill (2026-09-28)

- **Controls** (`lib/kontroller.lua`) forklarer styringen på et
  steinpanel: slipp = ring som ruller, hold = strekker seg ut,
  dobbelttrykk = slapp, ett trykk = stram igjen. Vises fra en ny stein på
  startskjermen (`controlsknapp.png` -> `scenes/kontroller.lua`) og fra
  en ny knapp øverst i pausemenyen. Pausemenyen er selv en overlay, så
  forklaringen er en gruppe oppå, ikke en egen scene.
- **Banenummeret** (`lib/banenummer.lua`) bruker nummersteinene fra
  banevalget (`steinN.png`): stor midt på skjermen i starten, så liten
  øverst til venstre, på høyde med livene. Kalles fra alle ni banefilene
  rett etter mørket.
- **Games** (`scenes/minispill.lua`) har tre idrettsøvelser med rekord:
  - 100 m (`scenes/mini_100m.lua`): nedtelling og tyvstart, nedoverløype
    med to istunneler og en sprekk.
  - Lengdehopp (`scenes/mini_lengdehopp.lua`): tilløpsbakke og kant, hold
    rett før kanten, tre hopp målt fra kanten.
  - Høydehopp (`scenes/mini_hoydehopp.lua`): tilløp og hoppkant, lista
    stilles med "Bar up" / "Bar down", 5 cm om gangen, med tre forsøk per
    høyde.
- **Ekte markfysikk i minispillene (samme dag, etter ønske fra Mathias).**
  `lib/markfysikk.lua` bygger marken nøyaktig som i banefilene (ni
  deler, samme former, motorledd +30 / -50 / -130, grenser 0-38 grader,
  dobbelttrykk = slapp). Knekk er ikke med. Øvelsene er laget etter
  målinger i en kopi av fysikken i Box2D 2.3 (pybox2d, samme motor som
  Solar2D):
  - Marken kommer seg ikke frem på flat bakke. Den ruller bare nedover,
    og ruller fortest når man lar den være. Rytmiske trykk og holding
    bremser den.
  - `isCollideConnected = true` i banefilene virker ikke (egenskapen kan
    bare leses i Solar2D), så nabodelene kolliderer ikke.
  - Lengdehopp (26 graders tilløp, 250 px fall): passivt ca. 530 px,
    strekk ca. 40 px før kanten ca. 600 px, for tidlig eller sent
    430-470.
  - Høydehopp (35 grader, bue R 450 opp til 45 grader, lista 200 px
    etter kanten): passivt ca. 40 px over kanten, godt timet strekk
    100-330 px. Resultatene spriker med timingen, som hoppene i banene.
  - 100 m (20 grader, istunneler med 40-45 px klaring): ringen står fast
    i tunnelen og kommer ikke løs. Slapp 200-300 px før tunnelen glir
    gjennom, og stram etterpå. Det gir ca. 21-24 s.
- **Flate øvelser (2026-09-29, Mathias: "100m skal bare være en liten
  bakke i begynnelsen ... så må man finne teknikken for å kunne bevege seg
  bortover").** Målt i kopien av fysikken:
  - Marken kommer seg frem på flat bakke med ett kort trykk per
    omdreining når hodet er bak i ringen (del5-vinkelen 250-295 grader),
    ca. 110 px/s, også etter 60 s. Uten trykk stopper den, og andre
    rytmer bremser. Fra helt stillestående er det vanskelig å komme i
    gang igjen.
  - 100 m: bakke 200 px (22 grader), så flatt. 35 px = 1 m. Passivt ca.
    37 m, med teknikken ca. 30 s.
  - Lengdehopp: bakke 1600 px til toppfart, 300 px flatt, strek og
    sandgrop i samme høyde. Hold ca. 0,5 s når hodet er nede foran, rett
    før streken: opptil ca. 370 px (7,4 m). Passivt 0 m.
  - Høydehopp: bakke 400 px, lista 900 px ut på flaten. Hold når hodet er
    oppe foran: opptil ca. 145 px (2,9 m) over bakken ved lista. Lista er
    en fysisk kropp (34 x 12 px) som ligger løst på en knagg; knaggen
    kolliderer bare med lista (filter), og lista regnes som revet når den
    har flyttet seg mer enn 6-10 px eller vridd seg over 12 grader.
  Rekordene lagres som "100m_fysikk", "lengdehopp_fysikk" og
  "hoydehopp_fysikk", så tider fra den første utgaven (uten ekte fysikk)
  ikke henger igjen.
- Felles for minispillene er `lib/minisport.lua`: bakgrunn, terreng med
  fysikk (stein friksjon 3, is 0,05, som i banene), kamera, trykkflate,
  knapper og rekorder (GGData "minispill").
- **Kameraet i minispillene er det samme som i banene** (`sport.kamera`):
  `lib/perspective.lua`, demping 10, kamera og ytre gruppe skalert 0,6
  hver, fokus på `mark.punkt` (sveiset til marken som i banene). Et eget
  kamera som fulgte én del av marken, svingte når marken rullet som ring.
- Nye knapper, Controls-steinen og bakgrunnene `meny_bg.jpg` og
  `arena_bg.jpg` lages av `Util/knapper/lag_knapper.py`, i samme stil som
  de gamle.

## Oppdateringer: "What's new" og varsel (2026-09-29)

- **`lib/nyheter.lua`** har en kort endringslogg for spillerne. Nyeste
  oppføring øverst, med nummer. `scenes/menu.lua` kaller
  `visHvisNy( sceneGroup )` i `show did`, og det som er nytt siden sist
  vises én gang på et steinpanel. Hva som er sett, lagres med GGData
  "nyheter". Nye spillere ser bare den nyeste oppføringen.
- **`lib/oppdatering.lua`** (startet fra `main.lua`) henter
  `https://thurbohnek.github.io/Roller/versjon.txt` 20 s etter start og
  så hvert andre minutt. Er ID-en en annen enn den i
  `lib/byggversjon.lua`, vises en liten steinlapp nede til venstre:
  "Update ready! Reload the page to play it." Trykk skjuler den.
  Tiden måles med en `enterFrame`-lytter, ikke med timere:
  `timer.cancel( eventTimer )` med `eventTimer = nil` (i gotomenu,
  pausemenu1 og dodmenu1) stopper alle timere i Solar2D, og stoppet
  den første utgaven av sjekken.
- Byggingen (`.github/workflows/build-html5.yml`) skriver commit-ID-en
  inn i `lib/byggversjon.lua` før bygget og i `versjon.txt` etterpå. I
  repoet står det "lokal", og da sjekkes det ikke.
- `Util/build-html5.sh` prøver Solar2D-nedlastingen på nytt hvis GitHub
  svarer med feil. Et bygg feilet 2026-09-29 fordi nedlastingen ga 92
  byte.

## Ny grafisk stil, fase 1 (2026-10-28)

Backup før redesignet: grenen `backup-for-redesign-2026-10-28` på GitHub.

Stilen er en blanding av lys eng (bane 1-2) og varm jordhule (bane 3-9 og
menyene, som ligger i markens hjem under bakken). Valgt av Mathias etter
skisser av tre stiler.

- **`lib/ui.lua`** er det felles grafiske systemet: farger (`ui.F`),
  knappefarger (`ui.KNAPP`), skrifta Fredoka (`Fredoka-*.ttf`, lisens i
  `OFL-Fredoka.txt`), `ui.tekst`, `ui.tittel`, `ui.knapp`, `ui.rundKnapp`,
  `ui.pille`, `ui.panel`, `ui.hinne`, `ui.ikon`, `ui.bakgrunn`, `ui.inn`
  og `ui.sprett`. Alt nytt grensesnitt bygges med disse.
- **`Util/grafikk/lag_ui.py`** tegner ikonene i `ui/` (128 px, vist i 64
  eller mindre), `pauseknapp.png` og bakgrunnene `ui/hjem_bg.jpg` og
  `ui/banevalg_bg.jpg`. Bakgrunnene er 1200 x 720 enheter med innholdet
  (960 x 540) i midten, så de dekker 4:3 til 20:9 uten skalering.
  Rommene i hjemmet og stoppene i banevalget står både i skriptet og i
  Lua-scenene, og må endres begge steder.
- **Scener:** `scenes/hjem.lua` (ny meny; `gotomenu` går hit),
  `scenes/banevalg.lua` (erstatter rutenettet i `chooselevel`;
  `gotochooselevel` går hit), `scenes/fullfort.lua` (overlay når målet
  nås, i stedet for `gotonextlevel` direkte), og nye utgaver av
  `pausemenu1`, `dodmenu1`, `adoffer`, `innstillinger` og `minispill`.
  Spillereglene er de samme: å forlate en bane fra pause eller død koster
  ett forsøk (`lib/navigasjon.lua` `forlatBane`).
- **Under spill:** `lib/hud.lua` lager en gruppe i banegruppa som regner
  seg tilbake fra 0,6-skaleringen hvert bilde. Banepille øverst til
  venstre, forsøk (`lib/liv.lua`) og pauseknapp øverst til høyre.
  Banefilene kaller `hud.pauseKnapp( knapp1 )`; `camera:add( knapp1, 2 )`
  er kommentert bort i bane 1 og 5-9.
- **`lib/framgang.lua`**: dråper (pengene), reddede unger per bane,
  fullførte baner og daglig gave (20, 30, 40, 60, 80, 100, 150 dråper,
  dag 1-7 på rad). `lm.unlockNextLevel()` registrerer fullført bane.
- **`lib/lasting.lua`**: lasteskjerm for `gotomenu`, `gotoretry`,
  `gotolevel1`, `gotochooselevel` og `gotonextlevel`.
- `build.settings` holder `Util/`, `*.md` og `*.py` utenfor spillet.

**Rettet underveis:** en ny spiller fikk krasj første gang et mål ble
nådd, fordi `levelInfo.locked` bare ble laget av det gamle banevalget.

**Ikke brukt lenger** (slettes når fase 2 er ferdig): `scenes/menu.lua`,
`scenes/chooselevel.lua`, `scenes/kontroller.lua` og de gamle
knappebildene (`pausemenu*.png`, `knapp_*.png`, `*knapp.png` unntatt
`pauseknapp.png`).

## Ny grafisk stil, fase 2 og 3 (2026-10-28)

**Banegrafikken** lages av verktøy i `Util/grafikk/` (kjøres med en
Python som har PIL, numpy, scipy og lupa, her `python3.13`):

- `lag_baner.py [N ...] [--ny-maske]` maler `levelN/1-4.png` på nytt.
  Formen hentes fra `Util/grafikk/masker/levelN_K.png` (0 luft, 1 bakke,
  2 is), som ble laget fra de gamle flisbildene og kollisjonsformene i
  `lib/shapedefs*.lua`: bakke er det som både var tegnet og ligger
  innenfor 12 px av kollisjonen, pluss selve kollisjonen; is er der
  kollisjonen har friksjon under 1 (is = 0,05). Pynt uten kollisjon er
  tatt bort, så det man ser er det man kolliderer med. Bane 1-2: gress og
  lys jord. Bane 3-9: lyskant på toppen og jord som blir kaldere og
  mørkere nedover. Lages bane 5-9 på nytt med `hule.py`, kjør
  `lag_baner.py N --ny-maske` etterpå. Bane 1 sine fliser var lagret i
  dobbel størrelse og er nå 3840x2351 som de andre (visningen er lik).
- `lag_bakgrunn.py` lager `background/baneN_1/2/3.png` (stripene i lag
  3-5, samme bånd for grotta som før) og `baneN_bunn.jpg` (lag 6).
  Banefilene peker på disse; de gamle `back_cave*`/`dirt1` er slettet.
- `lag_mark.py` lager marken (`hale.png`, `del1.png`, `hode.png` i roten
  er standarddrakten) og alle drakter i `mark/<drakt>/` og hatter i
  `mark/hatt_<navn>.png`. Samme visningsstørrelse som før; fysikken er
  ikke rørt.
- `lag_samling.py` lager `lib/samleN.lua`: en "kule" følger toppen av
  bakken fra startpunktet til målet (hopper over kløfter og fall), og
  dråpene legges langs veien med 330 enheters mellomrom, ungene litt
  høyere ved 30, 62 og 90 % av veien. Posisjonene er regnet fra sentrum
  av flis 1, så de følger teststart. `--vis` lager et kontrollbilde.
- `lib/morke.lua`: ingen mørke i bane 1-2, svakere i resten.

**Samling i banen:** `lib/samling.lua`, kalt fra banefilene rett etter
`morke`. Ingen fysikk: hvert bilde måles avstanden fra leddene i marken
til tingene i nærheten. Dråper lagres fortløpende (til disk høyst én gang
i sekundet), unger med en gang. HUD-raden under banenavnet viser dråper
fra runden og de tre ungeplassene. `scenes/fullfort.lua` viser dråpene
fra runden og gir 25 dråper første gang en bane klares
(`framgang.taBonus`).

**Butikken:** `lib/oppgradering.lua` (data, priser, valg) og
`scenes/butikk.lua`. Evnene endrer ikke fysikken: magnet (dråper fanges
1,6/2,2 ganger lenger unna), flaks (1/6 eller 1/3 av dråpene teller
dobbelt) og radar (pil ved marken mot nærmeste unge som mangler). Drakt
og hatt brukes i banene (`oppgradering.drakt( "hale.png" )`,
`oppgradering.settPaaHatt( camera, del9 )`) og i Worm athletics
(`lib/markfysikk.lua`).

**Oppdrag:** `lib/oppdrag.lua` trekker tre oppdrag per uke (mandag, likt
for alle), og spillet melder hendelser (`draape`, `unge`, `bane`,
`sport`, `gave`). `scenes/oppdrag.lua` viser dem og deler ut dråpene.
Hjemmet viser et rødt merke når et oppdrag er klart.

**Gjenstår:** Worm athletics har fortsatt de gamle bakkefargene (marken
er ny). De gamle scenene og knappebildene som er nevnt over er ikke
slettet ennå.

## Mørket i hulen (2026-09-28)

`lib/morke.lua` legger et mørkt lag over banen, tettere for hver bane
(`M.STYRKE`, 0 i bane 1 til 0,66 i bane 9). Hver banefil kaller
`require( "lib.morke" ).lag( N, punkt )` rett etter
`camera:layer(2):toFront()`.

- **Laget ligger nederst i kameraets lag 2.** Lag 2 er skjermfast
  (`parallaxRatio = 0`) og foran resten av banen, så mørket dekker alt
  unntatt pauseknappen (øverst i lag 2) og livtelleren (rett i
  scenegruppa).
- **`morke.png`** er 1024 px, vises 4000 skjermenheter bredt og har et
  klart felt ut til 170 enheter som glir over i fullt mørke ved 430.
  Bildet flyttes til `punkt` (som følger marken) hvert bilde. Skalaen
  regnes ut på nytt hvert bilde med `contentToLocal`, fordi både
  `camera` og `grp` er skalert.
- Lytteren fjerner seg selv når banen rives ned, så den kan ikke lekke
  over i neste bane.

## Kjente feil (utover det som allerede er fikset, se `TIL-ORJAN.md`)

1. ~~Delte kollisjonsformer~~ **Bane 1-4 løst 2026-09-14, bane 5, 6 og 7
   løst, bane 8 og 9 fortsatt åpent.** Bane 8 og 9 deler kunst med bane
   7 og bruker fortsatt `lib.shapedefs`, altså bane 1 sine former, mot
   helt annen kunst. `lib/shapedefs.lua` har bare ett sett former
   ("1"-"4"), sporet fra level1 sine bilder, men ble likevel brukt av
   ALLE baner — stemte bare for bane 1. Ørjan sendte en nyere versjon
   av spillet med egne, riktig sporede formsett for bane 2-4
   (`lib/shapedefs2.lua`/`shapedefs3.lua`/`shapedefs4.lua`, hentet inn
   sammen med nye bakke-bilder som formene faktisk hører sammen med).
   Bane 5-9 venter fortsatt på egne formsett i PhysicsEditor, ikke noe
   AI kan gjøre uten kildebildene i riktig verktøy.
2. **Plassholder-grafikk.** level5-9 deler fortsatt identiske
   banestykke-bilder (level1-4 har hver sine egne, ekte bilder siden
   2026-09-14). (Også i `TIL-ORJAN.md`.) Venter på ny grafikk for
   resten.
3. ~~"Neste bane"-knappen er hardkodet til level 2~~ **Fikset 2026-09-10,
   utvidet 2026-09-15.** Ørjan tok ikke stilling til denne spesifikt,
   men mest nærliggende var å la level2.lua-level9.lua gjøre som
   `level1.lua` alltid gjorde riktig: `goto2`-funksjonen viste
   `gotochooselevel` (tilbake til banevalg) i stedet for det
   hardkodede, buggede `showOverlay("gotolevel2")`. `gotolevel2.lua`
   mistet dermed sin eneste referanse og ble flyttet til `dod-kode/`.
   Mathias ba 2026-09-15 om at man i stedet skal gå automatisk videre
   til neste bane når man klarer en. `goto2` viser nå den nye
   `scenes/gotonextlevel.lua` i stedet for `gotochooselevel` direkte,
   den nye splashen går videre til neste bane (`lm.anotherLevel()`) og
   faller selv tilbake til `gotochooselevel` når siste bane er
   fullført. Ikke testet i faktisk nettleser ennå.
4. ~~"Retry" fra pausemenyen går alltid til bane 1~~ **Fikset
   2026-09-10, i to omganger.** Ørjan bekreftet at retry skal starte
   banen du faktisk var på. Første forsøk brukte
   `composer.getSceneName("current")`, som viste seg å krasje
   nettleseren hardt (Chrome-feilen "kan ikke åpne denne siden", ikke
   engang vår egen røde feilboks) hver eneste gang, testet av Mathias
   på telefon. Mistanke: kalt fra et overlay (pausemenu1/dodmenu1)
   returnerer den trolig overlayets eget navn, ikke banen under, og å
   gotoScene til et scenenavn som samtidig kjører som overlay er nok
   alvorlig nok til å krasje WASM-motoren i stedet for å gi en
   fangbar Lua-feil. Byttet til en mer robust løsning: hver
   `levelN.lua` setter `lm.currentLevel = N` selv, tidlig i
   `scene:create`, og retry bruker `"level" .. lm.currentLevel`
   direkte i stedet for å spørre Composer.

   Testet av Mathias/Ørjan, krasjet fortsatt, denne gangen et uhåndtert
   "attempt to compare nil with number" fra selve motoren. Årsak:
   `composer.removeScene( destination )` (fiksen for slow-motion,
   se punkt under) ble kalt helt uten `pcall` på banen som fortsatt
   var den aktive scenen, mens pausemeny/dødsmeny lå som overlay oppå
   den. Composer støtter ikke å rive ned en scene mens dens egen
   overlay fortsatt vises.

   Første forsøk på å fikse det (`composer.hideOverlay()` rett før
   `removeScene()`, i samme funksjon) løste det IKKE, krasjet fortsatt
   med samme feilmelding ved retry etter en knekk-død (se punkt 5).
   **Fikset på nytt 2026-09-10**, denne gangen med en strukturell
   endring i stedet for å prøve å rekkefølge kallene riktigere: en ny
   mellomscene `scenes/gotoretry.lua` (samme mønster som
   `scenes/gotolevel1.lua`, se `TIL-ORJAN.md`) gjør at banen som skal
   restartes ALDRI rives ned mens dens egen meny fortsatt vises som
   overlay oppå den. Pausemeny/dødsmeny sin `resume()` gjør nå bare en
   helt vanlig `gotoScene("scenes.gotoretry", ...)` (Composer skjuler
   overlayen trygt for dette selv), og selve `removeScene()` +
   `gotoScene()` til gjeldende bane skjer først når mellomscenen er
   den aktive, uten overlay oppå seg. Rettet samtidig samme (hittil
   ubekreftede) latente bug i `gotolevel1.lua` sin egen `goto()`, som
   manglet en tilsvarende `removeScene()`.

   `gotoretry`-omveien virket (bekreftet: en ANNEN feilmelding kom nå
   i stedet, se under). **Fikset på nytt 2026-09-10, ny separat bug**:
   `level1.lua` (kun bane 1) har en "kjøletid"-effekt per kroppsdel
   (`onLocalCollision1`-`onLocalCollision9`): slår av delens egen
   kollisjonslytter ved landing, viser en støv-sprite i 1 sekund, slår
   lytteren på igjen når `transition.to()` sitt `onComplete` fyrer.
   `transition.to()` avbrytes ikke av at scenen skjules, så et retry
   midt i den ventetiden fikk `onComplete` til å fyre mot en kroppsdel
   som allerede var revet ned, krasj: "attempt to call method
   'addEventListener' (a nil value)". Fikset med `transition.cancel()`
   i `scene:hide` sin "did"-fase, i alle ni banefiler (kun `level1.lua`
   kan faktisk krasje slik, resten fikk den som forsiktighetsregel).

   Samme krasj kom likevel igjen. **Fikset på nytt 2026-09-10**:
   `transition.cancel()` i `scene:hide` kom for sent, den fasen skjer
   først når HELE gotoretry-overgangen (500ms fade) er ferdig, og en
   ventende støveffekt kunne fyre av `onComplete` midt i de 500ms'ene.
   Flyttet `transition.cancel()` til helt øverst i `resume()` i
   pausemeny/dødsmeny, altså i samme øyeblikk retry trykkes. La i
   tillegg til en `.stage`-sjekk (fjernede Corona-objekter har
   `.stage == nil`) rundt selve `addEventListener`-kallet i alle ni
   `del1`-`del9`-blokkene i `level1.lua`, som ekstra sikring uansett
   tidsvindu. Ikke testet i faktisk nettleser ennå.
5. ~~Marken skal kunne "knekke"~~ **Var faktisk allerede kodet, bare
   avslått. Fikset 2026-09-10.** Den forrige vurderingen her, at
   9-leddet-ormen manglet knekk-mekanikk helt, var feil. Mathias
   forklarte (fra Ørjan) hvordan den skal virke: hver kroppsdel har,
   i tillegg til sin egen physics body, et eget "knott"-kollisjonsobjekt
   weldet fast oppå, og når to NABO-knotter kolliderer (marken bøyd for
   hardt), skal motor-jointene mellom delene fjernes, blod-spriten vises,
   og dødsmenyen aktiveres. Fant at akkurat dette står ferdig implementert
   i `knekk(event)` i alle ni banefiler (knott1/knott2 opp til knott8/knott9,
   fjerner riktig `pivot_jointN`, spawner blod, kaller `goto` som viser
   `scenes.dodmenu1` etter 3 sekunder) — men selve
   `Runtime:addEventListener("collision", knekk)`-linja som faktisk kobler
   funksjonen til kollisjoner var kommentert bort i alle ni filer, så
   mekanikken kjørte aldri. Skrudd på. Opprydningen i `scene:hide` fjernet
   allerede lytteren riktig ved sceneskifte, så ingen ekstra opprydning
   trengtes.

   **Fungerte fortsatt ikke i bane 1.** `level1.lua` manglet i tillegg
   selve `knott1`-`knott9`-fysikkobjektene (usynlige sensorer weldet på
   hver kroppsdel) som `level2.lua`-`level9.lua` har, uten dem kunne
   ikke kollisjonssjekken i `knekk()` noensinne bli sann i bane 1.
   Kopiert inn fra `level2.lua` (kroppen er identisk mellom filene).
   Se `TIL-ORJAN.md`. Ikke testet i faktisk nettleser ennå.
6. **Dobbeltklikk for å gjøre marken slapp virket ikke.** Fant koden
   (`trykk_knapp` i `level1.lua`), den brukte `event.numTaps == 2` fra
   Runtime "tap"-eventet, som ikke ser ut til å synkroniseres pålitelig
   med HTML5-eksportens museklikk. I tillegg satte "touch ended"-fasen
   alltid motorene på igjen uansett, så selv om dobbeltklikket ble
   oppdaget ville neste berøring slått dem på igjen momentant.
   **Fikset 2026-09-10:** dobbeltklikk oppdages nå selv, ved å måle tid
   mellom to "began"-faser (300 ms vindu), og "ended" lar motorene være
   av når marken er slapp. Samme fiks i `level2.lua`-`level9.lua` også
   (delte nøyaktig samme buggede kode), ikke bare `level1.lua`.

   **Fulgt opp 2026-09-15:** samme 300ms-vindu-sjekk gjaldt begge veier,
   altså dobbeltklikk krevdes også for å gjøre marken stram igjen, ikke
   bare for å gjøre den slapp. Mathias: skal bare trenge ett klikk for
   å bli stram igjen. Endret til at ett enkelt klikk umiddelbart gjør
   marken stram når den allerede er slapp (ingen tidssjekk i det
   tilfellet), dobbeltklikk kreves fortsatt for å gjøre den slapp i
   utgangspunktet. Alle ni banefiler.
7. **Utilsiktede globale variabler, bekreftet mot Solar2D sin egen
   dokumentasjon (2026-09-10).** Solar2D advarer eksplisitt: fjernes
   ikke Runtime-lyttere, fortsetter de å kjøre og lekker minne, siden
   Runtime-eventet er globalt. Fant flere funksjoner skrevet uten
   `local` (utilsiktet globale) i banefilene: `trykk_knapp` (alle ni
   baner), `kill` (bane 2-9, aldri kalt noe sted), `lock`/`goto`
   (`menu.lua`). **Fikset**, men `trykk_knapp` krevde ekstra
   forsiktighet: `pausemenu1.lua`/`dodmenu1.lua` prøvde å fjerne den
   som om den var global, på tvers av filer. Løst ved å gjøre
   `trykk_knapp` fil-scoped i hver banefil (synlig for både
   `scene:create` og `scene:hide` som egen `local`), og fjerne de
   virkningsløse cross-fil-forsøkene i pausemeny/dødsmeny (opprydningen
   skjer nå riktig i banens egen `scene:hide`, tvunget gjennom av
   `composer.removeScene()`-fiksen fra samme dag). Oppdaget samtidig at
   `onCollision`/`onCollision1`/`knekk` **allerede var** korrekt lokale
   i banefilene, og at pausemeny/dødsmeny sine forsøk på å fjerne DEM
   på tvers av filer **aldri har fungert** (refererte en udefinert
   global) — trolig en medvirkende årsak til slow-motion-bugen (punkt
   nedenfor), siden lyttere som ikke fjernes hoper seg opp nøyaktig
   slik Solar2D sin dokumentasjon advarer om. Disse virkningsløse
   linjene er også fjernet.
8. **"Klarer man banen går man ikke videre, det klikker bare" (funnet
   2026-09-15).** Alvorlig, sannsynligvis like gammel som spillet selv:
   `onCollision1` (mål-nådd-sjekken) i alle ni `levelN.lua` inneholdt
   `Runtime:removeEventListener(collision1)` — `collision1` er en
   udefinert global (skulle vært selve funksjonsnavnet
   `onCollision1`), så kallet kastet en Lua-feil hver gang målet ble
   nådd. `main.lua` sin `Runtime:addEventListener("unhandledError",
   ...)` fanger nettopp denne typen feil og skriver den bare til
   konsollen (undertrykker Solar2D sin egen synlige feilboks), så
   spilleren så ingenting skje. `del4.isSensor = false`,
   `lm.unlockNextLevel()` og `goto2()` (viser "neste bane") stod alle
   etter denne linja og ble dermed aldri kjørt. **Fikset**: byttet til
   riktig kall, `Runtime:removeEventListener("collision",
   onCollision1)`, i alle ni banefiler. Se `TIL-ORJAN.md` for
   fullstendig forklaring, inkludert hvorfor dette trolig også forklarer
   observerte "feilmeldinger" ved banefullføring uavhengig av antall
   liv igjen.
9. **Samme feilklasse, to til, funnet 2026-09-15 med `luacheck`** (som
   fanger feil variabelnavn/global-bruk, i motsetning til `luac -p` som
   bare sjekker syntaks — se `TIL-ORJAN.md` for hvordan den ble kjørt
   mot denne kodebasen, som bruker `goto` som funksjonsnavn):
   - `onCollision`/`onCollision1`/`onCollision2` var `local function`
     inni `scene:create`, mens `goSomewhere`/`goto`/`goto1`/`goto2`
     (fil-nivå, kjøres når banen lastes) refererte dem i sine egne
     `Runtime:removeEventListener()`-kall. Siden Lua avgjør
     variabel-referanser ved hvor i kildekoden de STÅR, ikke når koden
     kjører, pekte de referansene alltid på udefinerte globaler (alltid
     nil), ikke de faktiske lytterne — fjernet ingenting hver gang
     spilleren forlot banen (pause/død/fullført), nøyaktig den typen
     Runtime-lytter-lekkasje Solar2D advarer mot i punkt 7 over.
   - `eventTimer` (kroppsdel-knekk sin 3-sekunders forsinkede
     dødsskjerm-timer) var `local`, mens `pausemenu1.lua`/
     `dodmenu1.lua`/`gotomenu.lua` alle prøver å avbryte akkurat den med
     `timer.cancel(eventTimer)` når spilleren forlater banen på annen
     måte. Samme problem, denne gangen på tvers av FILER: de tre andre
     filenes kall traff alltid en egen, alltid udefinert global, aldri
     banens faktiske timer, så en ventende knekk-dødstimer kunne fyre
     av `goto()` flere sekunder etter at spilleren allerede hadde
     forlatt banen.

   **Fikset**: `onCollision`/`onCollision1`/`onCollision2`
   forhåndsdeklarert på fil-nivå (samme mønster som `trykk_knapp` i
   punkt 7), `eventTimer` gjort til bevisst global (`_G.eventTimer`,
   samme mønster som `_G.camera`/`_G.grp`). Alle ni banefiler. Bekreftet
   med `luacheck` at begge varselklassene er borte etter fiksen. Se
   `TIL-ORJAN.md` for hvilke andre `luacheck`-funn som ble sjekket og
   vurdert ufarlige (`scaleFactor`, `rot`, `reff`, `angel`, `punktsant`,
   `stovteller1-9`, `last`).
10. **Dødssonen tok slutt før banen gjorde (funnet 2026-09-15).**
    `dod`-objektet, som er det eneste som utløser dødsmenyen når man
    faller, er ETT rektangel på 70000x50 rotert 31,48 grader, altså én
    lang, men endelig, diagonal linje under banen. Regnet ut at den
    slutter ved x = 28409, mens siste flis slutter ved x = 30380 og
    målet (`mal2`) står ved x = 31000: de siste ~2600 enhetene av hver
    bane, nøyaktig der man er når man holder på å fullføre, hadde ingen
    dødssone i det hele tatt. Falt man av bakken der, falt marken videre
    i det uendelige uten at dødsmenyen kom (meldt av Mathias for bane 2,
    men gjelder alle ni). **Fikset** med en `enterFrame`-sjekk i alle ni
    banefiler: finner flisa marken er over og utløser vanlig død
    (`goto()`) om den har falt under underkanten av den flisa, eller er
    kommet en flisbredde utenfor første/siste flis. `dod` er urørt, den
    tar fortsatt de vanlige tilfellene raskere. Et første forsøk med én
    felles skrå linje under alle flisene ble målt mot den ekte
    bakke-kunsten og forkastet: den lå 160-170 enheter OVER bakken på
    slutten av bane 1 og 3 (en rett linje gjennom flis-sentrene skjærer
    opp i flisene i venstre halvdel av hver flis), altså død uten grunn.
    Per-flis-grensen er verifisert kolonne for kolonne mot alle 36
    bakke-bildene: minste klaring til bakken er 864 enheter, positiv
    overalt.

11. **Reklame-/kjøpsskjermen sendte spilleren til feil bane, eller til
    en bane som ikke finnes (funnet 2026-09-15).** `scenes/adoffer.lua`
    sender spilleren tilbake i banen via `scenes.gotoretry`, som starter
    `lm.currentLevel`. Den settes av hver `levelN.lua` når banen åpnes.
    Men liv-sjekken som ble lagt inn i `selectLevel()`
    (`lib/ogt_levelmanager.lua`) tidligere samme dag returnerte til
    `scenes.adoffer` FØR linja `k.currentLevel = event.target.levelNum`.
    Valgte man bane 4 med 0 liv og så reklame eller kjøpte forsøk, havnet
    man derfor i den banen man spilte sist. Rett etter appstart, der
    `k.currentLevel` fortsatt står på startverdien 0 (`ogt_lmdata.lua`),
    ble målet `scenes.level0`, som ikke finnes, og man fikk den røde
    feilboksen fra `pcall`-innpakningen. **Fikset** ved å flytte
    `k.currentLevel`/`k.displayText` opp FØR liv-sjekken, så valget
    huskes uansett hvilken vei `selectLevel()` går ut.

12. **Innholdsflaten er 960 x 540, ikke 540 x 960 (fallgruve, ikke en
    feil i spillet).** `config.lua` sier `width = 540, height = 960`,
    men `build.settings` har `orientation.default = "landscapeRight"`,
    og Corona bytter om innholdsflaten i landskap. Ved kjøring er
    `display.contentWidth` = 960 og `display.contentHeight` = 540.
    Leser man tallene rett ut av `config.lua` og legger noe på y = 700,
    havner det utenfor skjermen. Det skjedde med første utgave av
    kjøpspakkene på `scenes/adoffer.lua` 2026-09-15: to av tre pakker og
    "fortsett uten" var usynlige. Bekreftet ved måling på et skjermbilde
    fra Mathias: knappene var 956 piksler brede der 520 enheter skulle
    bli det (1,835 px/enhet), synlig flate 1393 x 642 enheter, og
    forskyvningen på 51 enheter er `display.screenOriginY` for
    letterbox-kanten (540 + 2 x 51 = 642). **Regel:** bruk alltid
    `display.contentWidth`/`display.contentHeight`, aldri tallene fra
    `config.lua`. Skal noe dekke hele den synlige flaten inkludert
    letterbox-kantene, bruk
    `display.viewableContentWidth - display.screenOriginX * 2` (samme
    uttrykk som `gotoretry.lua` bruker, verifisert mot målingen over).

## Anbefalt ryddeplan

1. ~~Slett trygt~~ **Gjort, flyttet i stedet for slettet (2026-09-10),
   og Ørjan har bekreftet at dette er riktig fremgangsmåte** ("ta vare
   på død kode på den måten det er gjort til nå"): de 31 bekreftet
   ubrukte filene (`pausemenu2.lua`-`pausemenu9.lua`,
   `dodmenu2.lua`-`dodmenu9.lua`, `gotolevel3.lua`-`gotolevel9.lua`,
   `menu1.lua`, `menu backup.lua`, `options.lua`, `brett.lua`, `play.lua`,
   `hoydehopp.lua`, `game.lua`, `livddadas.lua`) ligger i `dod-kode/`
   i stedet for prosjektroten, se `dod-kode/README.md` for hvor hver kom
   fra. Ingenting av dette gjorde noe i det hele tatt, spillet fungerer
   identisk.
2. **"Retry"- og "neste bane"-bugene er begge fikset** (punkt 3 og 4
   over). Ingen kjente åpne spillbarhets-bugs igjen, kun de to som
   venter på nytt innhold fra Ørjan (delte kollisjonsformer,
   plassholder-grafikk, punkt 1 og 2 over).
3. **Vurder å slå sammen** de 9 nesten-identiske `levelN.lua`-filene til én
   parameterisert fil som leser banenummer fra en tabell (bilder,
   kollisjonsformer, startposisjon), i stedet for kopiert kode. Stor jobb,
   men ville gjort det mulig å faktisk fylle inn manglende bane-innhold ett
   sted i stedet for ni.
4. Fjern feilsøkings-`checkpoint()`-kallene og `pcall`-innpakningene som ble
   lagt til under HTML5-portingen (se "Husk før dette regnes som ferdig"
   øverst i `TIL-ORJAN.md`) når spillet er stabilt.
5. **Fjernet ca 1170 linjer utkommentert dødkode (2026-09-10)**, fra
   `level1.lua`-`level9.lua`, `menu.lua`, `liv.lua` og `mark.lua`.
   Dette var gamle, forlatte forsøk skrevet inn som `--[[ ... ]]`-
   blokker (aldri kjørende kode). Verifisert med et eget skript som
   følger Lua sin faktiske kommentar-syntaks (en `--[[`-blokk avsluttes
   av den FØRSTE `]]` den finner, uansett hva som står etter) i stedet
   for en enklere, upresis metode som først ga feil svar og nesten
   fjernet ekte, kjørende kode ved en feiltagelse — fanget opp før noe
   ble skrevet til disk. Lisens-/changelog-kommentarene i
   `ogt_levelmanager.lua`/`ogt_lmdata.lua`/`perspective.lua` (også
   `--[[ ]]`-blokker, men ekte dokumentasjon, ikke dødkode) er bevisst
   IKKE rørt. Hver fil er syntaks-sjekket med `luac -p` og diffet mot
   forrige versjon for å bekrefte at kun linjer ble fjernet, aldri
   endret eller lagt til.
6. **Merket `camera`/`grp` som bevisste globaler (2026-09-10)**, med
   `_G.`-prefiks på definisjonsstedet i `level1.lua`-`level9.lua` og
   `menu.lua`, per Solar2D sin egen anbefaling om å gjøre tiltenkte
   globaler eksplisitte. Disse to kan IKKE gjøres til vanlige lokale
   variabler slik `trykk_knapp` ble (punkt 7 i "Kjente feil"):
   `lib/liv.lua` sin `liv.hent()` (viser livstall/-ikon, kalt fra alle
   ni baner) skriver `grp:insert(...)` direkte og har ingen annen måte
   å nå banens visningsgruppe på. `pausemenu1.lua`/`dodmenu1.lua` og
   `gotoX`-filene har sin egen, selvstendige `grp`/`camera` som ikke er
   bekreftet delt med noe annet (lavere prioritet, ikke rørt ennå).
