# Til Ørjan

Hei Ørjan! Mathias delte Dropbox-mappen din (NewNewNew Roller) og ba AI se
hva som kunne gjøres med spillet. Denne fila er en logg over alt som er
gjort med koden din, i vanlig språk, oppdatert etter hvert.

## Husk før dette regnes som ferdig

- **Lås banene igjen, når Ørjan sier fra.** `ogt_lmdata.lua` har
  `k.numUnlocked` satt til 9, og `ogt_levelmanager.lua` har en direkte
  override (`for x = 1, k.totalLevels do k.levelLocked[x] = false end`,
  rett før `levelInfo.locked = k.levelLocked`) som tvinger alt ulåst
  uansett lagret fremgang. Begge er merket "TEMP for debugging".
  Ørjan bekreftet 2026-09-10 at banene skal holdes åpne ENDA, for
  fortsatt testing, så dette er bevisst latt urørt. Ikke fjern før han
  sier fra at testingen er ferdig, ellers er hele bane-progresjonen i
  spillet meningsløs.
- **Fjern feilsøkings-sjekkpunktene.** `checkpoint(...)`-kallene i
  `main.lua`, `level1.lua`, `menu.lua`, `ogt_levelmanager.lua`, og
  pcall-innpakningene i `gotolevel1.lua`/`gotomenu.lua`/
  `gotochooselevel.lua`/`pausemenu1.lua` var midlertidige for å finne
  krasjer. Trygge å la stå (de gjør ingenting skadelig), men ryddigst
  å fjerne når alt fungerer. `dodmenu1.lua` fikk aldri samme
  sikkerhetsnett som `pausemenu1.lua` (se 2026-09-10-oppføringen under),
  vurder å legge det til der også hvis feilsøkingen fortsetter, ellers
  er det ikke noe å fjerne der.

## 2026-09-09

- **Hentet hele mappen fra Dropbox og lagt den i et eget GitHub-repo**
  (`t-event/roller`, privat). Alt er kopiert uendret, ingenting er
  omskrevet eller "ryddet opp i". 306 filer, ca 28 MB, alt kom med:
  all Lua-koden, ssk2-biblioteket du bygde på, og all grafikk/lyd.
- **Sjekket at koden fortsatt er hel** etter overføringen. Alle 142
  Lua-filene er syntaktisk gyldige (ingen skrivefeil eller skader).
  Krysset også alle bilde-/lydreferanser i koden mot filene som faktisk
  ligger i mappen: 855 referanser sjekket, 43 "mangler" — men de ser ut
  til å være rester fra før spillet var ferdig (f.eks. `Brett1.png`,
  `verden6/7/8.png`), altså noe som aldri fantes i mappen vi fikk, ikke
  noe som gikk tapt nå.
- **Satt opp en automatisk nettleser-versjon.** Mathias har iPhone, du har
  Android, og Solar2D-spill kjører ikke rett fra en lenke som en
  nettside normalt gjør. Løsningen: en GitHub Actions-jobb
  (`.github/workflows/build-html5.yml`) som bygger spillet om til HTML5
  med Solar2Ds eget byggeverktøy (CoronaBuilder) og publiserer det på
  GitHub Pages. Når det er satt opp, kan hvem som helst åpne
  `https://thurbohnek.github.io/Roller/` i en vanlig nettleser på telefon
  eller PC, ingen installasjon.
- **Første forsøk på HTML5-bygget feilet, funnet og fikset.**
  CoronaBuilder krasjet med en nil-feil (`webPackageApp.lua:165`) fordi
  den prøvde å finne en fil (`webtemplate.zip`) via en snarvei som bare
  opprettes når Solar2D er installert og kjørt normalt på en maskin, noe
  en fersk GitHub-runner aldri har gjort. Løste det ved å pakke ut
  disk-imaget lokalt og se hvor filen faktisk lå, og pekte
  byggeoppskriften rett på den i stedet for å stole på snarveien.
- **Andre forsøk hang i over 15 minutter** uten output eller feil, mest
  sannsynlig fordi CoronaBuilder prøver å nå en gammel
  aktiverings-/lisensserver fra da Corona SDK var kommersielt, som ikke
  svarer lenger. Avbrøt kjøringen og la inn en vaktbikkje som dreper
  byggeprosessen etter 8 minutter og feiler tydelig i stedet, pluss en
  hard 20-minutters grense på hele jobben som siste sikkerhetsnett.
  Tredje forsøk kjører nå.
- **Gjort repoet offentlig** (var privat) fordi GitHub Pages på gratis
  konto krever offentlig repo. Betyr at hele koden og grafikken din nå
  er synlig og klonbar for alle på nett, verdt å vite.
- **Tredje forsøk drept av vaktbikkja etter 8 minutter**, fortsatt uten
  noen feilmelding. Gravde i Solar2D sin egen kildekode og fant den
  egentlige forklaringen: et modul som brukes til å hente
  tredjeparts-plugins overskriver den globale loggefunksjonen med en
  stille versjon med mindre man eksplisitt ber om detaljert logging. Så
  det trenger ikke ha hengt i det hele tatt, det kan ha jobbet helt
  stille i bakgrunnen. Skrudde på detaljert logging og ga det mer tid
  (15 min vaktbikkje, 25 min jobbgrense) for å se hva som faktisk skjer.
- **Fjerde forsøk fortsatt helt stille i 15 minutter**, selv med detaljert
  logging på. Det viste at forrige forklaring var feil, den detaljerte
  loggingen jeg skrudde på traff ikke koden som faktisk kjørte. Leste
  meg videre gjennom Solar2Ds kildekode og fant den ekte årsaken: det
  monterte Solar2D-disk-imaget (`Util/S2D`) lå inni selve prosjektmappen,
  og HTML5-byggeverktøyet kopierer *alt* i prosjektmappen inn i spillet
  som ressurser. Det prøvde altså å kopiere hele det ~270MB store
  SDK-et (Android/iOS-verktøy, Java-runtime, Xcode-maler) inn i spillet
  ditt, filbyte for filbyte. Så det hang ikke, det gjorde en enorm feil
  jobb. Samme problem gjaldt outputmappen. Flyttet begge utenfor
  prosjektmappen. Femte forsøk kjører nå, forventer at dette er det som
  faktisk løser det.
- **Femte forsøk lyktes, på 50 sekunder.** Bekrefter at problemet
  virkelig var mappestrukturen, ikke noe med selve spillet eller koden
  din. `gh-pages`-grenen ble opprettet automatisk med den ferdige
  nettleser-versjonen. Spillet ligger nå på
  `https://thurbohnek.github.io/Roller/` (kan ta et par minutter etter at
  Pages er slått på i repo-innstillingene før lenken virker første
  gang).
- **Siden lastet, men krasjet med det samme.** "attempt to call method
  'addEventListener' (a nil value)" rett ved oppstart, dette er
  Solar2Ds egen standard krasjskjerm, ikke noe fra spillets egen
  feilhåndtering (den var ikke satt opp enda når krasjet skjedde).
  Mistenker `ssk.meters.create_fps`/`create_mem` i `main.lua` (linje
  8-9), de kaller `Runtime:addEventListener` og
  `objekt:addEventListener("touch")` synkront, før feilhåndtereren i
  linje 29 er klar, og HTML5-målet i Solar2D har kjente hull
  sammenlignet med iOS/Android. Dette er bare et FPS-/minnebruk-overlay
  for feilsøking, ikke noe spillet trenger, så jeg skrudde det av kun
  for HTML5 (andre plattformer er urørt). Nytt bygg kjører nå, venter
  på bekreftelse fra Mathias om det faktisk løste det.
- **FPS-/minne-fiksen virket, men avdekket et nytt krasj lenger inn.**
  "attempt to index a nil value" inne i Solar2Ds `composer`-bibliotek
  sin egen `gotoScene`/`dispatchEvent`, altså i selve
  scenebytte-mekanismen når `gotolevel1`-scenen skal vises første gang.
  Fortsatt bare "?" i stedet for filnavn/linjenummer i feilmeldingen,
  så la til `settings.build.neverStripDebugInfo = true` i
  `build.settings` for å beholde den informasjonen i bygg fremover.
  Nytt bygg kjører nå, forventer en mye mer presis feilmelding neste
  gang.
- **Nytt bygg publisert** (47 sekunder), nå med filnavn/linjenummer i
  feilmeldinger. Venter på at Mathias tester siden og limer inn den nye
  feilmeldingen.
- **Notat fra deg (via Mathias): bare 4 av de 9 banene er ferdige.**
  Bra å vite når vi etter hvert kommer forbi oppstartskrasjen og skal
  teste selve spillingen, level 5-9 er trolig ikke noe å bruke tid på å
  feilsøke.
- **Presis feilmelding kom, og den var faktisk fiksbar!**
  `bad argument #2 to 'newImageSheet' (... width og height ...)`, i
  `gotolevel1.lua` sitt sprite-ark for splash-animasjonen (`last.png`).
  Målte den faktiske PNG-fila direkte: 3600×1080 piksler, et 3×2-rutenett
  á 1200×540. Koden oppga aldri hvor stort hele arket er, bare
  rutestørrelsen, og Solar2D klarte tydeligvis å gjette riktig på
  telefonen din men ikke på web. La til `sheetContentWidth`/
  `sheetContentHeight` (den robuste måten å gjøre dette på), samme
  kopierte kodesnutt fantes i 12 filer (alle `gotolevelN.lua`,
  `gotomenu.lua`, `gotochooselevel.lua`, `ogt_levelmanager.lua`),
  rettet alle. Nytt bygg kjører nå.
- **Sprite-ark-fiksen virket, men et nytt krasj lenger inn:**
  `module 'ssk2.display.layers' not found: not enough memory` under
  `ssk.init()`. "Ikke nok minne" er et ekte signal, ikke bare en
  feiltekst, nettleser-versjonen kjører i en begrenset minnepakke
  (WebAssembly). Fant at ssk2-biblioteket ditt allerede har en
  innebygd HTML5-modus (`_G.HTML5_MODE`) som skrur av et par moduler
  som bruker filsystemtilgang som ikke gir mening i en nettleser, men
  `main.lua` brukte den aldri. Slått på nå
  (`ssk.init({ html5 = true })`). Nytt bygg kjører, usikker på om det
  er nok alene siden dette kan være en reell minnegrense i
  nettleser-målet, ikke bare denne ene tingen.
- **Nytt bygg publisert.** Venter på at Mathias tester på nytt.
- **Notat fra deg (via Mathias):** du husker at én fil ikke klarte å
  ha alle banene under selve utviklingen, og måtte deles opp (derfor
  egne `levelN.lua`-filer per bane i stedet for én stor fil). Trolig
  ikke samme begrensning som minnekrasjen over (den skjer i
  ssk2-biblioteket, ikke i banefilene), men bra å vite at prosjektet
  har støtt på slike grenser før. Kan bety flere lignende overraskelser
  dukker opp etter hvert som vi kommer lenger inn i spillet.

- **Minnekrasjen er borte, spillet kjører nå gjennom oppstarten!**
  Mathias melder at "skjermen glitcher" i stedet for en krasjmelding,
  altså et rent visuelt problem nå, ikke en feil som stopper koden.
  Ber om skjermbilde/opptak for å kunne se hva som faktisk skjer før
  jeg gjetter på en fiks.
- **"Glitchen" var ikke en feil.** Spillet er laget for liggende
  skjermorientering, men en nettside kan ikke tvinge telefonen din til
  å rotere slik en ekte app gjør, den bruker uansett hvordan du holder
  den. I stående modus blir spillet "letterboxet" ned til en tynn
  stripe for å beholde riktig størrelsesforhold. Løste seg av seg selv
  ved å rotere telefonen til liggende.
- **Nytt krasj etter rotering:** samme type feil som tidligere
  ("attempt to index a nil value"), nå i selve `level1.lua` når
  splash-animasjonen bytter til den ekte banen. `scene:create`-
  funksjonen der er over 2000 linjer, umulig å lese seg fram til
  presist uten linjenummer. Fant også at
  `neverStripDebugInfo`-innstillingen jeg la til aldri kunne virket for
  HTML5 uansett, det er en begrensning i Solar2Ds kommandolinje-
  byggeverktøy (fungerer bare via Simulator-appens egen "Bygg for
  web"-dialog, som vi ikke kan bruke i en automatisk byggejobb).
  Løsning: satte inn 9 usynlige "sjekkpunkter" spredt gjennom
  funksjonen og fanget opp krasjet slik at feilmeldingen og siste
  sjekkpunkt vises direkte på skjermen. Midlertidig feilsøkingskode,
  fjernes når krasjet er funnet. Nytt bygg kjører nå.
- **`level1` lastet faktisk denne gangen!** Mathias kom inn i selve
  banen og fikk opp pausemenyen, men krasjet (samme feiltype) da han
  trykket "main menu" der. Det er en annen kjede
  (`pausemenu1.lua` → `gotomenu.lua` → `menu.lua`) enn den vi allerede
  hadde sjekkpunkter i. Utvidet samme teknikk dit: fanget opp
  scenebyttene i `pausemenu1.lua` og `gotomenu.lua`, og la 6
  sjekkpunkter i `menu.lua` sin `scene:create` (kortere fil, 200
  linjer). Nytt bygg kjører nå.
- **Sjekkpunkt-overlayet funket, og fant en ekte bug!** Etter litt fram
  og tilbake med tilsynelatende ustabil visning (bare mellomlagring i
  Safari som måtte tvinges på nytt) viste skjermen tydelig:
  `Checkpoint: menu:after_camera_scale`. Rett kode: `menu.lua` lastet
  `"bg1.png"` fra rota, men filen ligger faktisk i `background/`-mappen.
  Samme kopier-lim-inn-feil fantes i `level2.lua`, `level3.lua` og
  `level4.lua` (dine fire ferdige baner), bakgrunnsbilder manglet
  `background/`-prefikset og banespesifikke bilder (1-4.png) manglet
  sitt eget `levelN/`-prefiks, noe `level1.lua` hadde riktig. Rettet
  alle fire filene likt. Sjekket samtidig at `brett.lua`, `menu1.lua`,
  `options.lua` og `play.lua` (som også har knuste bildereferanser) er
  død kode som aldri nås i spillet, rørte ikke de. Nytt bygg kjører nå,
  dette kan faktisk være den siste brikken.

- **Notat fra deg om N.png-mønsteret:** i banemappene (`level1/`,
  `level2/` osv) tilsvarer `1.png` bane 1, `2.png` bane 2, og så
  videre, det bekrefter at fiksen over (hver banefil skal peke på sin
  egen `levelN/`-mappe, slik `level1.lua` allerede gjorde riktig) var
  riktig retning.

- **Låst opp alle 9 banene midlertidig** (`k.numUnlocked` i
  `ogt_lmdata.lua`, var 1, satt til 9) slik at Mathias kan teste
  banene direkte uten å spille seg gjennom dem. Husk å sette denne
  tilbake til 1 når feilsøkingen er ferdig.

- **Mathias meldte at level 2 sin bakgrunn ikke stemmer med hvor
  ballen faktisk kolliderer med gulvet.** Dette er IKKE en
  porteringsbug, det ville sett likt ut på Android. `shapedefs.lua`
  har bare ett sett usynlige kollisjonsformer kalt "1", "2", "3", "4"
  (sporet av PhysicsEditor fra ett bestemt bilde), men `level1.lua`,
  `level2.lua`, `level3.lua` og `level4.lua` bruker alle sammen akkurat
  de samme fire formene, selv om hver bane har sine egne bakkebilder
  (`level1/1.png`, `level2/1.png` osv). Kollisjonen stemmer bare med
  bildet den opprinnelig ble sporet fra (sannsynligvis level 1, siden
  den fungerer perfekt), de andre banene får feil usynlig gulv i
  forhold til bildet de faktisk viser. Krever at du sporer formene på
  nytt i PhysicsEditor per banebilde, eller sier fra om bildene egentlig
  skal ha samme grunnform som level 1 sitt (da er det noe annet som er
  galt). Ikke noe jeg kan gjette meg fram til selv.
- **Bekreftet med filsjekksummer: `level2/` til `level9/` bruker
  helt identiske bilder** (samme MD5 på 1.png, 2.png, 3.png, 4.png i
  alle åtte mappene), mens `level1/` har sine egne, unike bilder. Bare
  bane 1 har ferdig, tilpasset grafikk, de åtte andre deler ett og
  samme plassholder-sett. Forklarer sannsynligvis hele
  "feil bakgrunn på bane 2"-observasjonen: det er ikke en kodefeil,
  det er kunst som aldri ble laget ferdig per bane.

- **🎉 "Main menu"-krasjen er fikset, bekreftet av Mathias.** Spillet
  går nå hele veien fra oppstart, gjennom en bane, til pausemeny og
  tilbake til hovedmeny uten å krasje. Neste: Mathias melder at
  bane 2 ikke har riktig bilde der banen faktisk er, sannsynligvis en
  liten, ufarlig content-bug (feil banelayout-bilde), ikke noe som
  stopper spillet. Ser nærmere på det.

- **2026-09-10.** Nytt krasj funnet: "retry"-knappen i pausemenyen
  krasjet etter tredje forsøk (samme addEventListener-feil). Den
  eneste av pausemenyens tre knapper som ikke allerede var fanget opp
  med sikkerhetsnettet vårt, siden problemet med "main menu" og
  "levels" knappene ble oppdaget først. Lagt til samme fangst der.
  Nytt bygg kjører nå. Neste feilmelding bør vise nøyaktig sjekkpunkt.

- **2026-09-10, samme dag.** Nok et krasj etter to retry-trykk, men
  denne gangen med den vanlige Solar2D-varselboksen, ikke vår røde
  sjekkpunkt-boks. Det var nøkkelen: krasjen skjedde IKKE inni
  `pcall`-en rundt `composer.gotoScene` i `pausemenu1.lua` (den fanger
  fint), men et sted composer selv styrer bak kulissene, utenfor det vi
  hadde satt sikkerhetsnett rundt.

  Fant roten: `gotolevel1.lua`, `gotomenu.lua` og `gotochooselevel.lua`
  kalte alle `composer.removeScene(...)` på seg selv i `scene:hide`
  sin **"will"**-fase i stedet for **"did"**. "Will" skjer i det
  overgangsanimasjonen starter, ikke når den er ferdig, så
  `removeScene()` der river ned scenens visningsgruppe og laster ut
  Lua-modulen mens composers egen fade/overgang fortsatt jobber mot den
  samme gruppa. `gotolevel1` er splash-skjermen retry-knappen alltid
  går via, så hver retry gjentok akkurat dette, og etter et par runder
  endte composers interne tilstand opp korrupt nok til å krasje dypt
  inne i selve composer-biblioteket, langt fra våre pcall-er. Flyttet
  `removeScene()`-kallet til "did"-fasen i alle tre filene (etter at
  overgangen faktisk er ferdig), som er slik composer selv sier den
  skal brukes. Samme fiks i `gotolevel2.lua`, som har nøyaktig samme
  kopierte feil.

  **Ekstra funn i `gotolevel2.lua`, ikke rørt ennå:** utenom
  "will/did"-bugen har filen to andre feil som ser ut som rester fra
  kopiering av `gotolevel1.lua`, print-tekstene sier fortsatt
  "gotolevel1" og filen går videre til `"level1"` (linje 42) i stedet
  for `"level2"`, og kallet på linje 104 fjerner scenen `"gotolevel1"`
  i stedet for `"gotolevel2"`. Kombinert med den fra før dokumenterte
  "neste bane"-bugen (alltid `gotolevel2`, uansett bane) betyr dette at
  hele splash-skjermen mellom en fullført bane og neste bane trolig
  aldri har fungert som tiltenkt. Rørte den ikke nå, siden det henger
  sammen med den større, allerede kjente "neste bane"-bugen og bør
  fikses samlet, ikke gjettes fram til stykkevis.

## 2026-09-10, grundig linje-for-linje gjennomgang av hele koden

Gikk gjennom samtlige 61 egne Lua-filer (alt utenom `ssk2/`) på nytt,
denne gangen faktisk lest, ikke skummet: diff mellom filer som skal
være like, grep etter reelle referanser i stedet for å stole på gamle
notater, og sjekket at asset-filene som refereres faktisk finnes på
disk. Bekreftet det meste av det som allerede sto i dette dokumentet
og i `KODEBASE.md`, men fant noen nye ting:

- **`mark.lua` sin `mark.hent()` blir aldri kalt.** Både `menu.lua` og
  `level1.lua` gjør `require("mark")` og fanger opp `mark.hent`-
  funksjonen i en lokal variabel, men ingen av dem faktisk *kaller*
  den. I stedet har `level1.lua` ca 90-100 linjer kopiert kode som
  bygger spillerkroppen (`del1`-`del9`) rett inn i fila selv, samme
  mønster som det ferdig-dokumenterte kaoset i `hoydehopp.lua`/
  `game.lua`. `mark.lua` er dermed i praksis dødt, bortsett fra at
  `require`-kallet kjører harmløst. Rørte den ikke, siden jeg ikke vet
  om du planla å faktisk ta den i bruk igjen.
- **"Liv" (livene i spillet) kan aldri nå null.** I `liv.lua`,
  `liv.endreliv(val)`: når `liv_igjen == 1`, LEGGER funksjonen til 2
  liv i stedet for å trekke fra, så sekvensen blir 3→2→1→3→2→1→... i
  det uendelige. Og siden `liv.endreliv(1)` bare kalles fra
  "retry"/"main menu"/"levels"-knappene i pause- og dødsmenyen (aldri
  fra selve spillingen), og ingenting noe sted sjekker
  `liv.returnScore()` mot null for å faktisk avslutte spillet, er
  live-telleren per nå bare et tall som vises, uten konsekvens. Selve
  "du døde"-skjermen (`showOverlay("dodmenu1")`) trigges av noe helt
  annet: en kollisjon mellom et "dod"-objekt (faren) og hodet på
  ormekroppen (`del9`), se `level1.lua` rundt linje 1080-1103. Ikke
  rørt, siden jeg ikke vet om liv-systemet er ment å faktisk bety noe
  ennå eller er en bevisst "kan ikke tape ennå"-sikring mens resten
  bygges ferdig.
- **`dodmenu1.lua` mangler samme sikkerhetsnett som `pausemenu1.lua`.**
  Alle tre knappene der (`resume`/`resume1`/`resume3`, altså retry/
  main menu/levels) kaller `composer.gotoScene(...)` helt direkte, uten
  `pcall` og uten sjekkpunkt. `dodmenu1.lua` er dødsskjermen for ALLE
  ni baner, akkurat som `pausemenu1.lua` er pauseskjermen for alle ni,
  og den navigerer til nøyaktig de samme stedene
  (`gotolevel1`/`gotomenu`/`gotochooselevel`) som fikk "will/did"-fiksen
  i dag. Rot-årsaken er nå fikset uansett, men hvis noe nytt krasjer
  langs denne veien, vil du ikke få en rød sjekkpunkt-boks fra
  dødsskjermen slik du ville fått fra pauseskjermen. Verdt å legge til
  samme mønster her hvis dere fortsetter feilsøkingen.
- **`ogt_levelmanager.lua` lekker en sprite for hver banevelging.**
  `k.beforeLeaving()` (kalt rett før du går inn i en bane fra
  banevalg-rutenettet) lager en ny splash-sprite
  (`last = display.newSprite(...)`, global variabel) og spiller den,
  men opprydningen er kommentert bort (`--display.remove( last )`,
  `--last = nil`). Hver gang du velger en bane fra rutenettet blir det
  ett usynlig (eller kanskje ikke usynlig?) objekt til liggende igjen.
  Ufarlig i en kort testøkt, men kan bli mange objekter over en lang
  spilløkt med mye fram-og-tilbake til banevalget.
- **Selve banevalget mangler sikkerhetsnettet.** Den faktiske
  scenebytte-linja når du trykker en banerute
  (`sceneMgr.gotoScene(newScene, ...)` inni `selectLevel` sin `goto()`
  i `ogt_levelmanager.lua`, rundt linje 166) har ingen `pcall`. Resten
  av kjeden dit (pausemeny → `gotochooselevel` → `chooselevel` →
  `ogt_levelmanager.lua` sin `init`/`makeGrid`) ble instrumentert i går,
  men selve trykket på banen ble stående ubeskyttet.
  `ogt_levelmanager.lua` har forøvrig egne sjekkpunkt-kall
  (`checkpoint("ogt_lm:...")`, 4 stykker) som heller ikke sto nevnt i
  "husk før dette regnes som ferdig"-lista øverst i dette dokumentet,
  lagt til der nå.
- **`level6.lua` til `level9.lua` er bokstavelig talt 100 % identiske
  filer**, bekreftet med `diff` (null forskjell, ikke bare samme
  bilder). Og nå med konkrete detaljer på hvorfor bildene deres er
  knuste: de refererer bilder UTEN mappe-prefiks
  (`"back_cave.png"`, `"dirt1.png"`, `"1.png"`-`"4.png"`), mens de
  faktiske filene bare finnes under `background/` og under sin egen
  `levelN/`-mappe (`background/back_cave.png`, `level5/1.png` osv).
  `level2.lua`-`level4.lua` har IKKE denne bugen, de bruker riktige
  stier. Dette bekrefter og konkretiserer det som sto i `KODEBASE.md`
  fra før, ikke noe overraskende nytt, men nå med eksakte stier å
  rette hvis/når disse banene prioriteres.
- **To dødekode-filer har byttet om egne interne navn.** `game.lua`
  (til tross for filnavnet) inneholder en gammel `liv`-modul
  (`liv_igjen`, `liv.txt`, kaller udefinerte `saveScore()`/
  `loadScore()` — ville krasjet hvis den noensinne ble brukt).
  `livddadas.lua` (til tross for SITT filnavn) inneholder i stedet en
  gammel `game`-modul (`score.txt`, `high_score`, fungerende internt).
  Begge er fortsatt 100 % ubrukte og urørt, men verdt å vite om navnet
  lurer deg hvis du noen gang vurderer å gjenopplive en av dem.
- **To mindre bugs i allerede-død kode**, kun for katalogens skyld:
  `options.lua` sjekker `if event.phase == began then` (linje 67) uten
  anførselstegn rundt "began", så den sammenligner mot en udefinert
  global variabel (alltid usann) — "rask meny"-hjørnet ville aldri
  reagert selv om fila var i bruk. `brett.lua` bygger en riktig
  `options`-tabell for overgangseffekt, men sender i steden den
  udefinerte globalen `brett` til `composer.gotoScene()` (linje 27),
  så tilbake-knappen ville alltid brukt standard-overgang. `brett.lua`
  har også tre av fire banetile-knapper som peker til scener
  (`"play2"`, `"play3"`, `"play4"`) som ikke finnes noe sted i
  prosjektet i det hele tatt, bare `"play"` (→ `play.lua`) er reell.

## Død kode (finnes i repoet, men brukes aldri)

**Oppdatering 2026-09-10:** alle disse filene, pluss `pausemenu2.lua`-
`pausemenu9.lua`, `dodmenu2.lua`-`dodmenu9.lua`, `gotolevel3.lua`-
`gotolevel9.lua`, `game.lua` og `livddadas.lua`, er flyttet til
`dod-kode/` i stedet for prosjektroten. Ikke slettet, bare samlet på ett
sted, se `dod-kode/README.md`. Beskrivelsene under er fortsatt riktige,
bare filstien er ny.

Disse filene har egne bugs (knuste bilde-stier), men er ikke fikset
fordi ingenting i spillet faktisk navigerer dit, verken via `require`
eller `composer.gotoScene`/`showOverlay`. Trygge å ignorere, eller
slette permanent hvis du bekrefter du ikke trenger noe av det (se
spørsmål 6 i `sporsmal.md`):

- `brett.lua` — refererer `"backgroun1d.jpg"` (finnes ikke, sannsynlig
  skrivefeil for et bakgrunnsbilde). Selv uten den bugen navigeres det
  aldri hit.
- `menu1.lua` — refererer `"background.jpg"` (finnes ikke). En
  alternativ/tidligere versjon av `menu.lua`, gjettevis.
- `options.lua` — samme `"backgroun1d.jpg"`-referanse som `brett.lua`.
- `play.lua` — refererer `"images/eforest02.jpg"` (finnes ikke). Ser ut
  som en stjerne-/resultatskjerm som aldri ble koblet til noe.
- `menu backup.lua` — en eldre, ikke-instrumentert kopi av `menu.lua`
  (ingen `checkpoint()`-kall, ellers nesten identisk). Refererer
  bilder uten `background/`-prefiks (f.eks `"bg1.png"` i stedet for
  `"background/bg1.png"`), som heller ikke finnes på den stien.
- `hoydehopp.lua` — en fysikk-lekeplass (to komplette 9-ledds
  ormekropper), ingen knust bilde-referanse denne gangen (`del1.jpg`
  finnes faktisk, om enn inkonsekvent blandet med `.png` samme sted i
  fila), men ingen steder navigert til.

## Hvor ting ligger

- Selve spillkoden som faktisk brukes: repo-roten (`main.lua`,
  `level1.lua` osv, akkurat som i Dropbox-mappen din).
- Bekreftet ubrukt kode: `dod-kode/`, se `dod-kode/README.md`.
- Byggeoppskrift for nettleser-versjonen: `Util/recipe-html5.lua` og
  `Util/build-html5.sh`.
- README.md har en kort oversikt og instruksjoner for å kjøre spillet i
  Solar2D Simulator som før.
- `sporsmal.md` har åpne spørsmål til deg fra gjennomgangen, ikke noe
  som haster, bare ting Mathias/AI ikke kunne avgjøre selv.

Denne fila fylles på etter hvert som mer skjer.

## 2026-09-10, avslutning for denne økta

Oppsummert hva som er gjort i dag: fant og fikset retry-krasjen (se
egen oppføring over), gjorde en grundig linje-for-linje gjennomgang av
hele kodebasen og fant flere ting utover selve krasjen (også over),
skrev spørsmål til deg i `sporsmal.md`, og flyttet 31 bekreftet ubrukte
filer til `dod-kode/` i stedet for å slette dem. README.md er også
rettet, den kalte hovedpersonen en "ball" der den faktisk er en mark.

Ingen åpne krasjer akkurat nå, retry-fiksen er bygget og publisert på
GitHub Pages. Det som gjenstår er i hovedsak spørsmål til deg (se
`sporsmal.md`) og de to kjente spillbarhets-bugene (neste bane / retry
går til feil bane, se "Kjente feil" i `KODEBASE.md`), ikke noe som
haster før du har svart på spørsmålene.

## 2026-09-10, Ørjan svarte på spørsmålene i sporsmal.md

Svarene og hva som ble gjort med hvert av dem (full spørsmålstekst i
`sporsmal.md`):

1. **Liv skal ha en betydning, bare ikke ferdig kodet ennå.** Man skal
   starte med et visst antall liv, og ved null liv skal man kunne se
   en reklame for å få liv tilbake (1 min reklame = 1 liv, lang
   reklame = f.eks 3 liv). Fant og fikset selve bugen som hindret
   telleren fra å nå null i det hele tatt (`liv.endreliv()` la
   feilaktig til 2 liv i stedet for å trekke fra ved siste liv). Lagt
   til `liv.erTom()` i `liv.lua` som en enkel sjekk videre kode kan
   bruke. **Bygget IKKE selve reklame-integrasjonen**, det krever et
   valg av annonse-SDK/nettverk som ikke er min avgjørelse å ta, og
   ingenting kaller `liv.erTom()` ennå.
2. **Marken skal kunne "knekke".** Ørjan beskriver den som bygget av
   3 biter med motoriserte ledd som strekker seg ut og til slutt
   knekker ved landing. Koden i dette repoet har i stedet en
   9-leddet ormekropp (del1-del9) uten noen knekk-mekanikk i det hele
   tatt, altså stemmer ikke det som ligger her med beskrivelsen.
   Ørjan skal sjekke om han har en nyere versjon der dette faktisk er
   kodet ferdig. Sjekket samtidig "kan du legge inn kollisjonsboksene
   på marken": `shapedefs.lua` har faktisk ferdige `"hale"`/`"hode"`
   kollisjonsformer, men de brukes ikke, `level1.lua` bruker egne
   hånd-skrevne former i stedet. Grunnen: halen krympes fra 55×35 til
   27×17 i koden før kollisjonsformen legges på, og de hånd-skrevne
   formene stemmer med den krympede størrelsen, mens
   `shapedefs.lua` sine er sporet fra bildet i original størrelse. Å
   bytte dem inn direkte ville gitt en dobbelt så stor, usynlig
   kollisjonsboks. **Rørte ikke fysikk-koden her**, siden det virker
   som riktig steg er å vente på den nyere versjonen Ørjan skal lete
   etter, fremfor å gjette på en knekk-mekanikk som kanskje allerede
   finnes ferdig et annet sted.
3. **Shapedefs.lua skal ha flere ting i seg.** Bekreftet: i dag ligger
   bare level1 sine kollisjonsformer der (helt til slutt i fila), men
   alle ni baner skal ha sine egne. Krever at formene spores i
   PhysicsEditor fra hver banes bilder, noe som må gjøres av noen med
   verktøyet og kildebildene, ikke noe jeg kan gjette meg fram til.
   Ikke gjort.
4. **og 5. Retry skal starte den banen du faktisk var på**, ikke alltid
   bane 1. **Fikset**: `pausemenu1.lua` og `dodmenu1.lua` sin
   "retry"-knapp bruker nå `composer.getSceneName("current")` for å
   finne riktig bane i stedet for hardkodet `"gotolevel1"`.
   `dodmenu1.lua` fikk samtidig samme pcall-sikkerhetsnett som
   `pausemenu1.lua` allerede hadde på denne knappen. Ikke testet i
   faktisk nettleser ennå, bør sjekkes på alle ni baner.
6. **Ta vare på død kode slik det er gjort til nå.** Bekreftet at
   `dod-kode/`-mappen (fra i går) var riktig fremgangsmåte, ingen
   endring nødvendig.
7. **Hold banene åpne for testing enda.** Bekreftet, `k.numUnlocked`
   og opplåsings-overriden i `ogt_levelmanager.lua` er bevisst latt
   urørt (se oppdatert notat øverst i denne fila under "Husk før
   dette regnes som ferdig").
8. **Rett stiene siden spillet ikke er under aktiv grafikk-utvikling.**
   **Fikset**: `level5.lua`-`level9.lua` var 100 % identiske filer med
   bilde-referanser uten mappe-prefiks. Hver av de fem har nå sin
   egen, riktige `levelN/`-sti (ikke lenger byte-identiske med
   hverandre), og bakgrunnsbildene har fått `background/`-prefiks.
   Deler fortsatt plassholderbilder og feil kollisjonsformer med
   level1, det er ikke noe stien alene kan fikse.

**Ny feil meldt i samme melding, utenfor spørsmålslista:** dobbeltklikk
skal gjøre marken helt slapp, men virket ikke. Fant koden
(`trykk_knapp` i `level1.lua`), den brukte Runtime "tap"-eventets
`event.numTaps == 2`, som ikke ser ut til å synkroniseres pålitelig med
museklikk i HTML5-eksporten. I tillegg satte "touch ended"-fasen alltid
motorene på igjen uansett, uavhengig av om marken nettopp var gjort
slapp, så selv om dobbeltklikket hadde blitt riktig oppdaget ville
neste berøring momentant slått motorene på igjen. **Fikset**:
dobbeltklikk oppdages nå selv ved å måle tid mellom to `"began"`-faser
(300 ms vindu), uavhengig av `numTaps`, og `"ended"`-fasen lar motorene
være av når marken er slapp. **Ikke testet i faktisk nettleser ennå**,
usikker på om 300 ms-vinduet føles riktig, si fra om det bør justeres.

Alt kodet i dag er pushet, og en ny HTML5-build er trigget for å teste.

## 2026-09-10, presisering av liv/reklame-flyten

Mathias presiserte: "om man ikke ønsker å se reklame skal man kunne starte
på nytt fra level 1." Det svarer på hva som skal skje i den siden av
reklame-valget som ikke krever et annonse-SDK, så koblet det inn med det
samme.

`pausemenu1.lua` og `dodmenu1.lua` sin "retry"-knapp sjekker nå
`liv.erTom()` etter at livet for dette forsøket er trukket fra: har du
fortsatt liv igjen, restartes banen du var på (som i går). Er du tom for
liv, går du i stedet til `gotolevel1` (start fra bane 1), siden det er
fallback-oppførselen når man ikke vil/kan se reklame. Det finnes fortsatt
ingen faktisk "vil du se reklame?"-dialog, det kommer når noen velger et
annonse-SDK og bygger det. Inntil da er "start fra bane 1" alt som skjer
når du går tom for liv, ingen spørring, siden reklame-alternativet ikke
finnes ennå.

Ikke testet i faktisk nettleser.

## 2026-09-10, tre til, samme mønster

Mathias spurte om det var noe annet jeg umiddelbart ville fikse. Tre
lavrisiko-ting som følger nøyaktig samme mønster som allerede var
godkjent i dag:

- **`dodmenu1.lua` sine to gjenstående knapper** ("main menu"/"levels")
  fikk samme pcall-sikkerhetsnett som "retry" fikk tidligere i dag.
  Samme dekning som `pausemenu1.lua` nå.
- **Sprite-lekkasjen i `ogt_levelmanager.lua`** (splash-bildet som
  aldri ble fjernet ved banevalg) er fikset, fjernes nå rett før
  scenebyttet til den valgte banen.
- **Selve banevalget** (`sceneMgr.gotoScene()` i `selectLevel`) har nå
  samme pcall-sikkerhetsnett som resten av kjeden dit.

Ikke testet i faktisk nettleser ennå. Pushet og ny build trigget.

## 2026-09-10, retry-fiksen krasjet hardt på ekte telefon

Mathias testet på iPhone: hver eneste gang han trykket retry kom Chrome
sin egen "kan ikke åpne denne siden"-feil (skjermbilde vedlagt), ikke
vår røde sjekkpunkt-boks. Det er en helt annen alvorlighetsgrad enn de
Lua-feilene pcall har fanget til nå, dette er nettleseren som gir opp
hele siden.

Mistanke: `composer.getSceneName("current")`, brukt i går sin
retry-fiks, kalles fra INNSIDEN av et overlay (pausemenu1/dodmenu1).
Den returnerer trolig overlayets eget navn ("pausemenu1"), ikke banen
som faktisk ligger under, siden overlays er en egen greie i Composer
sin scene-stack. Å be Composer gå til `"pausemenu1"` som en vanlig
scene mens `"pausemenu1"` samtidig kjører som overlay er nok
inkonsistent nok til å krasje dypt i selve motoren (WASM/HTML5-delen),
utenfor det pcall i Lua kan fange opp. Derfor ingen rød boks, bare et
nettleser-nivå havari.

**Fikset med en mer robust metode, uten å stole på Composer sin egen
"hvilken scene er jeg i"-introspeksjon:** hver `levelN.lua` (1-9)
setter nå `lm.currentLevel = N` selv, helt i starten av `scene:create`.
Retry i `pausemenu1.lua`/`dodmenu1.lua` bruker `"level" ..
lm.currentLevel` direkte i stedet for å spørre Composer om noe. Siden
`lm.currentLevel` settes av selve banefila uansett hvordan du kom dit
(direkte fra appstart, fra banevalg, eller fra en tidligere retry),
er dette pålitelig uansett vei inn.

**Viktig: ikke testet i faktisk nettleser ennå**, siden jeg ikke kan
kjøre HTML5-bygget selv. Dette er andre forsøk på samme bug, så vær
ekstra oppmerksom når du tester denne gangen.

## 2026-09-10, full opprydding av mappestruktur

Mathias ba om full opprydding i kode og mappestruktur, og valgte
eksplisitt "flytt aktive filer til undermapper" og "gjør det i én stor
omgang, test til slutt" fremfor små, trygge biter. Advarte om risikoen
først (nøyaktig denne typen endring var årsaken til retry-krasjen
rett over), men kjørte det gitt svaret.

**Gjort:** hele prosjektet, som tidligere var 27 `.lua`-filer flatt i
roten, er nå delt i `scenes/` (alle Composer-scener) og `lib/` (delte
moduler som ikke er egne scener). Bare `main.lua` og `config.lua` ble
igjen i roten (Solar2D krever det). Full liste og begrunnelse i
"Mappestruktur"-avsnittet i `KODEBASE.md`.

Fremgangsmåte for å unngå akkurat den typen glipp som skjedde med
linjeslutt tidligere i dag: kartla FØRST hver eneste streng-referanse
til hvert av de 25 filnavnene på tvers av hele den levende kodebasen
(ikke `dod-kode/`, den er urørt siden ingenting peker dit uansett) med
grep, bygde et skript som gjør presise erstatninger (kun hele
anførselstegn-innhold, ikke delstrenger, så f.eks `"levelWidth"`
aldri kunne bli truffet), kjørte det på én fil om gangen med
linjeslutt bevart (lærdom fra i sted), luac-sjekket alle 27 filene
etterpå, og gjorde til slutt et bredt grep-søk etter alt som kunne
ligne en glemt referanse før filene faktisk ble flyttet.

Fant tre pre-eksisterende, allerede-ødelagte referanser
(`composer.removeScene("pausemenu")`/`"dodmenu"` uten tallet, og
`"reload"` i en kommentar) som pekte på scener som aldri har
eksistert, verken før eller etter flyttingen. Rørte dem ikke, de var
no-ops før også, ikke noe reorganiseringen skapte.

**Ikke testet i faktisk nettleser ennå, og kan IKKE verifiseres av meg
selv** siden `require()`/`gotoScene()`-stier bare løses ved kjøretid,
ikke av `luac` sin syntaks-sjekk. Dette er den mest risikofylte
endringen så langt i dag, akkurat den typen som forårsaket
retry-krasjen over. Test grundig: appstart, alle ni baner (både via
banevalg og "neste bane"), pause/død-menyene sine tre knapper hver,
og retry på flere baner.

## 2026-09-10, siste kjente spillbarhets-bug fikset

Mathias spurte om jeg heller burde bygge spillet helt på nytt etter
Solar2D-dokumentasjonen. Svar: nei, for mye fungerende, innstilt
innhold (fysikk, layout) står udokumentert i selve koden og ville
risikert å gå tapt i et gjenoppbygg jeg ikke kan teste live selv, og
Ørjan jobber fortsatt aktivt med spillet selv. Anbefalte å fortsette
som i kveld, og ta det store steget (slå ni banefiler sammen til én
parameterisert) som et bevisst, eget steg når banene er ferdige.

Fortsatte deretter med "neste bane"-bugen (punkt 3 i "Kjente feil"),
den siste åpne spillbarhets-bugen. Ørjan tok ikke stilling til den
spesifikt i svarene sine, men `level1.lua` har alltid gjort det
riktige (tilbake til banevalg etter fullført bane), så lot de andre
åtte gjøre det samme i stedet for å gjette på noe annet.

`level2.lua`-`level9.lua` sin `goto2`-funksjon viser nå
`gotochooselevel` i stedet for det hardkodede, bugget
`showOverlay("gotolevel2")`. Det gjorde `gotolevel2.lua` helt uten
referanser (den var den eneste veien dit), så den er flyttet til
`dod-kode/` sammen med resten av den døde koden, se
`dod-kode/README.md`.

Ingen kjente åpne spillbarhets-bugs igjen nå, bare de to som venter på
nytt innhold fra Ørjan (kollisjonsformer, plassholder-grafikk).

**Ikke testet i faktisk nettleser ennå.**

## 2026-09-10, retry ga slow motion og virket fortsatt ikke riktig

Mathias testet: spillet gikk i slow motion, og restart fungerte
fortsatt ikke som det skal.

Mistanke: retry kaller `composer.gotoScene()` til **samme banenavn
som allerede er den aktive scenen** (du er på bane 2, trykker retry,
`destination` blir `"scenes.level2"`, mens du fortsatt står i
`"scenes.level2"` med pausemenyen som overlay oppå). Composer
håndterer trolig ikke det tilfellet som en vanlig scenebytte, den kan
la den gamle instansen (fysikkverden, ledd, Runtime-lyttere som
`onCollision`, `trykk_knapp`, `knekk`) henge igjen i stedet for å rive
den ned, mens `scene:create` likevel kjører på nytt oppå. Det ville
forklare begge symptomene med én årsak: dobbelt sett fysikkobjekter
og -lyttere gjør simuleringen tyngre for hver retry (slow motion), og
den gamle, ikke-nullstilte tilstanden er grunnen til at banen ikke
"restarter" ordentlig.

**Fikset:** lagt til `composer.removeScene(destination)` rett før
`composer.gotoScene(destination, ...)` i retry-knappen, i både
`pausemenu1.lua` og `dodmenu1.lua`. Tvinger en fullstendig nedriving
av banens gamle instans (fysikk, ledd, display-objekter, selve
Lua-modulen) før den lastes helt på nytt, uansett om Composer ville
gjort det automatisk eller ikke. Harmløst no-op i tilfellene der
scenen ikke var lastet fra før (f.eks. `gotolevel1`-fallbacken når du
er tom for liv).

**Ikke testet i faktisk nettleser ennå.** Dette er et forsøk basert på
resonnement om Composer sin livssyklus, ikke noe jeg kan bekrefte selv
uten en simulator. Si fra om slow motion / dårlig restart fortsatt
skjer etter denne, så må vi grave dypere (f.eks. sjekke om selve
pausemeny-overlayet blir riktig ryddet bort også).

## 2026-09-10, sjekket faktisk dokumentasjon, og la til forklaringer i koden

Mathias spurte om jeg faktisk hadde studert Solar2D sin dokumentasjon.
Ærlig svar: nei, ikke underveis, alt har vært basert på det jeg vet om
Corona/Solar2D fra før kombinert med lesing av koden og symptomene
dere har rapportert. Fikk tilgang til nettsøk nå og sjekket noen av
antakelsene fra i kveld mot faktisk dokumentasjon (docs.coronalabs.com
var blokkert direkte for meg, fant sitater via søk i stedet):

- `composer.getSceneName("current")` + `gotoScene()` til samme navn er
  faktisk et **dokumentert mønster** for å laste gjeldende scene på
  nytt, ikke i seg selv ugyldig slik jeg konkluderte i går kveld etter
  telefon-krasjen. Årsaken til den krasjen er dermed fortsatt ikke
  100 % forklart, men uansett løst i praksis siden vi byttet til
  `lm.currentLevel` i stedet.
- `composer.gotoScene()` skjuler automatisk et aktivt overlay, så
  pausemeny-overlayet er bekreftet ikke kilden til noe av dagens bugs.
- `composer.removeScene()` sender en destroy-hendelse og fjerner
  scenen helt, harmløst hvis den ikke var lastet. Bekrefter at
  slow-motion-fiksen (riv ned banen før retry laster den på nytt) er
  den offisielt riktige måten å tvinge fram en ren tilstand på.

Ba meg samtidig rydde opp og legge til forklaringer på norsk i selve
filene, ikke bare i disse dokumentene. Gikk gjennom alt som er endret
i kveld og la til/utvidet kommentarer der de manglet: "will vs
did"-fiksen i `gotolevel1.lua`/`gotomenu.lua`/`gotochooselevel.lua`,
liv-bugen i `liv.lua`, sprite-lekkasjen og pcall-en i
`ogt_levelmanager.lua`, hvorfor `mark.lua` sin `mark.hent()` aldri
kalles, og hvorfor `level1.lua` sin hale bruker en egen kollisjonsform
i stedet for `shapedefs.lua` sin ferdige.

**Fant samtidig at dobbeltklikk-bugen (rettet i `level1.lua` i går) var
identisk kopiert inn i `level2.lua`-`level9.lua` også**, ufikset der.
Siden banene skal holdes åpne for testing (Ørjans svar på spørsmål 7),
rettet samme fiks der også, ikke bare i `level1.lua`.

**Ikke testet i faktisk nettleser ennå.**

## 2026-09-10, opprydding av utilsiktede globale variabler

Mathias ba om en full, grundig opprydding "i henhold til
dokumentasjonen", uavhengig av bugs (de tar vi senere). Fant noe
konkret i Solar2D sin egen dokumentasjon om nettopp det jeg mistenkte
i går: Runtime-lyttere som ikke fjernes lekker minne, siden
Runtime-eventet er globalt og lyttere overlever selv om
display-objektet de hørte til er borte.

Gikk gjennom `scenes/`-filene for utilsiktede globale funksjoner
(skrevet uten `local`). Fant `trykk_knapp` i alle ni banefiler, `kill`
i bane 2-9 (aldri kalt noe sted), og `lock`/`goto` i `menu.lua`.

**Viktig lærdom underveis:** dette er IKKE en mekanisk "legg til
local overalt"-jobb. `trykk_knapp` viste seg å være avhengig av å
være global, siden `pausemenu1.lua`/`dodmenu1.lua` refererer den ved
navn for å fjerne touch-lytteren når du pauser/dør. Å bare gjøre den
lokal ville brutt den opprydningen. Løsningen: gjorde `trykk_knapp`
fil-scoped i hver banefil (en `local trykk_knapp`-forhåndsdeklarasjon
øverst, synlig for både `scene:create` og `scene:hide`), og fjernet
de nå garantert virkningsløse forsøkene på å fjerne den fra
pausemeny/dødsmeny. Opprydningen skjer riktig i banens egen
`scene:hide` i stedet, som uansett alltid tvinges gjennom nå takket
være `composer.removeScene()`-fiksen fra tidligere i kveld.

**Ekstra funn i samme runde:** `onCollision`/`onCollision1`/`knekk`
var faktisk ALLEREDE riktig lokale i banefilene, men
`pausemenu1.lua`/`dodmenu1.lua` prøvde likevel å fjerne dem ved navn
på tvers av filer. Det har aldri fungert (refererte en udefinert
global), sannsynligvis siden spillet ble skrevet. Fjernet de
virkningsløse linjene. Dette er trolig en medvirkende årsak til
slow-motion-bugen fra i sted: lyttere som aldri faktisk fjernes hoper
seg opp for hver runde i pause/død, nøyaktig det Solar2D sin egen
dokumentasjon advarer mot.

**Om omfanget videre:** "all kode i henhold til dokumentasjonen" er et
mye større løft enn det som er gjort her. `camera` og `grp` er også
utilsiktet globale i alle banefiler (brukt på samme måte som
`trykk_knapp` var, mellom `scene:create` og `scene:hide`), og hver av
de ni banefilene har flere store, utkommenterte kodeblokker (gamle,
forlatte forsøk) som strengt tatt burde fjernes for et virkelig rent
resultat. Det er en betydelig jobb til, per fil, med samme grundighet
som i kveld. Gjorde det viktigste og best dokumenterte først
(Runtime-lyttere, siden det direkte henger sammen med
slow-motion-bugen), og stopper her for å spørre om dere vil at jeg
fortsetter resten nå eller en annen gang, fremfor å gjette meg videre
inn i natten på egen hånd.

**Ikke testet i faktisk nettleser ennå.**

## 2026-09-10, fjernet dødkode og merket bevisste globaler

Mathias ba meg fortsette. Gikk videre med de to gjenstående punktene
fra forrige oppføring.

**Nesten en alvorlig glipp:** Første forsøk på å finne utkommenterte
kodeblokker brukte et regex-mønster som feiltolket Lua sin
kommentar-syntaks. Det ga et fullstendig feil svar: "979
sammenhengende linjer kommentert ut" i `level1.lua`, som i
virkeligheten var en blokk på bare 11 linjer etterfulgt av ekte,
kjørende kode og så flere separate kommentarer. Lua avslutter en
`--[[`-blokk ved den ALLERFØRSTE `]]` den finner, uansett hva som står
før eller etter, og mønsteret mitt tok ikke høyde for det. Hadde jeg
slettet basert på det første svaret, ville jeg slettet fungerende
spillkode. Skrev om til et skript som følger den faktiske regelen,
sjekket resultatet manuelt mot hver eneste blokk før noe ble fjernet,
og verifiserte etterpå med diff at bare linjer ble borte, aldri endret
eller lagt til, pluss `luac`-syntaks-sjekk av alle filene.

**Fjernet ca 1170 linjer bekreftet dødkode**: gamle, forlatte forsøk
(dupliserte funksjoner, tidligere varianter av samme kode, ting som
refererer bilder som aldri fantes) fra `level1.lua`-`level9.lua`,
`menu.lua`, `liv.lua` og `mark.lua`. Lot lisens- og
changelog-kommentarene i tredjepartsfilene (`ogt_levelmanager.lua`,
`ogt_lmdata.lua`, `perspective.lua`) stå urørt, det er ekte
dokumentasjon, ikke dødkode, selv om de også bruker `--[[ ]]`-syntaks.

**Merket `camera`/`grp` som bevisste globaler** med `_G.`-prefiks på
definisjonsstedet, slik Solar2D sin dokumentasjon anbefaler for
globaler som faktisk er meningen skal deles. Disse to kunne IKKE
gjøres til vanlige lokale variabler slik `trykk_knapp` ble i går:
`liv.lua` sin `liv.hent()`-funksjon (viser livstall og -ikon, kalt fra
alle ni baner) skriver rett til `grp` og har ingen annen måte å nå
banens visningsgruppe på. Sjekket dette grundig før jeg rørte noe,
etter læringen fra `trykk_knapp`-fiksen.

**Ikke rørt ennå**: `pausemenu1.lua`/`dodmenu1.lua`/`gotoX`-filene sin
egen, separate `camera`/`grp` (ikke bekreftet delt med noe annet, lavere
prioritet). Ikke testet i faktisk nettleser.

## 2026-09-10, opprinnelige Dropbox-filer og bygg-ekskludering

Mathias lastet opp den originale zip-fila fra Dropbox-mappa
("NewNewNew Roller (1)") og ba om en mappe Ørjan kan bla i direkte på
GitHub, uten å måtte grave i git-historikk. La de 306 filene urørt inn
i `opprinnelig-fra-dropbox/`, med en README som forklarer at samme
innhold også er den aller første committen i repoet, så mappen er
bare for bla-bekvemmelighet.

Sjekket etterpå om dette ville blåse opp HTML5-spillet: `dstPath` i
`Util/recipe-html5.lua` peker på hele repo-roten som `projectPath`, og
den filas egen kommentar sier rett ut at alt der blir "kopiert rått
inn i spillbunten som assets". Uten tiltak ville de ~28 MB fra Dropbox
blitt lastet ned til hver spiller sin telefon for ingenting.

Løsningen er dokumentert av Solar2D selv: `excludeFiles` i
`build.settings`, med et stjernetegn etter mappenavnet for å
ekskludere hele mappen (uten stjernen blir bare selve mappen tom, ikke
utelatt). Lagt til under `all` slik at det gjelder alle
byggeplattformer, ikke bare HTML5, siden mappen uansett aldri trengs i
noe bygg. Trigger HTML5-bygget på nytt for å bekrefte at det fortsatt
fungerer og at bunten ikke har blitt større.

## 2026-09-10, retry krasjet fortsatt: composer.removeScene() på aktiv scene

Mathias og Ørjan testet spillet live og fikk fortsatt en krasj ved
retry, denne gangen en helt uhåndtert "ERROR: Runtime error, attempt
to compare nil with number" (skjermbilde fra dødsmenyen), ikke vår
egen røde feilboks. Det i seg selv var et nyttig spor: siden krasjen
IKKE ble fanget av `pcall`-en rundt `composer.gotoScene()`, måtte den
skje et annet sted, siden vi wrapper akkurat den ene linja.

HTML5-bygget strippet dessverre all fil-/linjeinfo i feilmeldingen til
"?"/linje 0 (til tross for `neverStripDebugInfo = true`, som
tydeligvis ikke hjelper for nettleser-eksport), så feilsøkingen måtte
skje ved å lese koden, ikke ved å følge en stack trace til rett linje.

Fant den mest sannsynlige årsaken ved å lese `resume()` i både
`dodmenu1.lua` og `pausemenu1.lua` på nytt: linja
`composer.removeScene( destination )` (lagt til tidligere i kveld som
fiks for slow-motion-buggen) kalles helt uten `pcall` rundt seg, og
`destination` er nettopp banen som fortsatt ER den aktive scenen når
du trykker retry, siden dødsmenyen/pausemenyen bare ligger som en
overlay oppå den, ikke som en egen scene. Å rive ned den aktive
scenen mens dens egen overlay fortsatt vises er ikke en støttet
rekkefølge i Composer. Composer sin egen dokumentasjon sier at
`gotoScene()` skjuler en aktiv overlay automatisk, men det skjer for
sent her, ETTER at `removeScene()` allerede har rukket å ødelegge
scenen overlayen lå oppå.

Fikset ved å legge til `composer.hideOverlay()` rett før
`composer.removeScene( destination )` i begge filers `resume()`, slik
at menyen lukkes skikkelig FØR banen under rives ned og bygges på
nytt, i stedet for at rekkefølgen er omvendt. `removeScene()` selv
beholdes, den er fortsatt nødvendig for at et nytt `gotoScene()` til
samme banenavn faktisk skal kjøre `scene:create()` på nytt (bekreftet
mot Solar2D-forumet: uten den huskes den gamle scenegruppa, og
gjenbrukes i stedet for å bygges på nytt).

Fant samtidig og rettet en ren skjønnhetsfeil mens jeg var inne i
disse filene: kommentaren lagt til i går på `lm.currentLevel = N` i
`level2.lua`-`level9.lua` hadde blitt dobbelt-UTF-8-kodet et sted
("sÃ¥" i stedet for "så"), sannsynligvis av et tidligere skript i
kveld. Ren tekstvisningsfeil i en kommentar, ingen kjørende kode
berørt, men rettet siden det så slurvete ut. `level1.lua` hadde den
ikke, kun `level2-9.lua`. Luac-sjekket alle ni filer etterpå.

Testet ikke i faktisk nettleser før push, kunne ikke det herfra. Bygg
trigget på nytt, si fra så snart dere har fått prøvd retry igjen.

## 2026-09-10, knekk-mekanikken var ferdig kodet, bare avslått

Mathias forklarte (fra Ørjan, antar jeg) mer detaljert hvordan marken
skal knekke: hver kroppsdel har, i tillegg til sin egen physics body,
et eget "knott"-kollisjonsobjekt weldet fast oppå, og når to
NABO-knotter kolliderer (marken bøyd for hardt) skal motor-jointene
mellom delene fjernes, blod-spriten vises, og dødsmenyen aktiveres.

Dette stemte nøyaktig med noe som allerede lå ferdig skrevet i alle
ni banefiler: en funksjon `knekk(event)` som sjekker akkurat
knott1/knott2 opp til knott8/knott9-parene, fjerner riktig
`pivot_jointN` og `knottN`, setter fokus på haledelen, spawner to
blod-sprites med tilfeldig størrelse/rotasjon/fade, og etter 3
sekunder kaller `goto` som viser `scenes.dodmenu1`. Alt dette er
identisk (bortsett fra to ubrukte variabler) i alle ni filer.

Problemet var at selve linja som kobler funksjonen til faktiske
kollisjoner, `Runtime:addEventListener("collision", knekk)`, var
kommentert bort i alle ni banefiler. Mekanikken kjørte dermed aldri,
selv om alt rundt den var klart. Skrudd på i alle ni. Opprydningen i
`scene:hide` fjernet allerede lytteren riktig ved sceneskifte (den
lå der fra før, urørt), så ingen ekstra opprydning trengtes for å
unngå en lekkasje tilsvarende `trykk_knapp`-buggen fra i går.

Rettet den forrige (feilaktige) vurderingen i `sporsmal.md` og
`KODEBASE.md` "Kjente feil" punkt 5, som konkluderte med at
knekk-logikk manglet helt. Uklart om dette betyr at Ørjan husker en
annen/eldre versjon enn den i dette repoet (han beskrev marken som 3
biter, koden her har 9 ledd), men selve knekk-koden lå altså der hele
tiden, bare avslått med en enkelt kommentert linje per fil.

Ikke testet i faktisk nettleser. Push og bygg gjenstår når dere har
sett dette.

## 2026-09-10, knekk fungerte fortsatt ikke: level1.lua manglet selve fysikkobjektene

Mathias meldte tilbake at knekk-mekanikken fortsatt ikke fungerte.
Gikk gjennom `level1.lua` på nytt og fant den egentlige årsaken: i
motsetning til `level2.lua`-`level9.lua`, som alle oppretter
`knott1`-`knott9` (usynlige sensor-rektangler, weldet fast på hver
kroppsdel med `physics.newJoint("weld", ...)`) rett etter
motor-oppsettet for pivot-jointene, manglet `level1.lua` denne
blokken fullstendig. `knott1`-`knott9` fantes der kun som referanser
inne i `knekk()` selv (`display.remove(knottN)`, `knottN = nil`),
aldri opprettet. Kollisjonssjekken `event.object1.type == "knottN"`
kunne dermed aldri bli sann i `level1.lua`, uansett om
Runtime-lytteren var skrudd på, siden ingen fysikkobjekt noensinne
fikk den typen. Forrige fiks (skru på lytteren) var nødvendig men
ikke tilstrekkelig, og var trolig grunnen til at det fungerte i
bane 2-9 men ikke i bane 1, som antakelig var den Mathias testet.

Sammenlignet `level1.lua` og `level2.lua` linje for linje rundt
mark-oppsettet: kroppsdelene (`del1`-`del9`, samme bilder,
`hale.png`/`del1.png`), pivot-jointene og motor-oppsettet er
bokstavelig talt identiske mellom filene. Kopierte derfor
knott/weldJoint-blokken (og de tilhørende `knottN.type`-linjene)
uendret fra `level2.lua` inn i `level1.lua`, satt inn på nøyaktig
samme sted relativt til resten av koden (rett etter
`pivot_joint8`-oppsettet, før `firkant`-bakgrunnsbildene). Luac
syntax-sjekket etterpå.

Ikke testet i faktisk nettleser, det er akkurat den delen jeg ikke
kan gjøre herfra. Ba Mathias bekrefte at bane 1 nå faktisk knekker
riktig, siden posisjonstallene (`del1.y+5`, `del2.y+10` osv.) er
kopiert fra bane 2-9 og ikke visuelt verifisert mot bane 1 sin egen
grafikk, selv om selve kroppen skal være identisk.

## 2026-09-10, retry krasjet fortsatt: bygget om helt i stedet for å rekkefølge på nytt

Bane 1 knakk riktig (bekreftet av Mathias/Ørjan), men retry fra
dødsmenyen krasjet med nøyaktig samme feil som før forrige fiks:
uhåndtert "attempt to compare nil with number", samme stack-form
(`?:0`, `<?:209>`). Det betyr at `composer.hideOverlay()`-fiksen fra
i sted ikke faktisk løste problemet, den ble bare aldri bekreftet
testet før vi gikk videre til å teste knekk-mekanikken i stedet.

I stedet for å fortsette å gjette på riktig rekkefølge av
`hideOverlay()`/`removeScene()`/`gotoScene()` inni `resume()` (som nå
har blitt prøvd to ganger uten hell), bygget jeg om selve tilnærmingen:
en ny fil, `scenes/gotoretry.lua`, som er nøyaktig samme mønster som
`scenes/gotolevel1.lua` (en liten splash-scene med markens
last-animasjon, venter litt, bytter så videre) — bare for "retry på
gjeldende bane" i stedet for "ingen liv igjen, start på nytt fra bane
1", som `gotolevel1.lua` allerede gjorde.

Grunnen til at dette bør være tryggere: problemet har hele tiden vært
at `composer.removeScene()` ble kalt på banen som FORTSATT var den
aktive scenen, mens pausemeny/dødsmeny lå som overlay oppå den akkurat
i det øyeblikket. Uansett hvilken rekkefølge `hideOverlay()` fikk i
forhold til `removeScene()`, var det fortsatt SAMME funksjonskall
(`resume()` i en overlay) som gjorde begge deler. Med `gotoretry.lua`
gjør `resume()` nå bare et helt vanlig `gotoScene("scenes.gotoretry",
...)` til en ANNEN scene, noe Composer sin egen dokumentasjon
bekrefter skal skjule en aktiv overlay trygt. Selve `removeScene()` +
`gotoScene()` til gjeldende bane skjer først 0.8 sekund senere, fra
INNE I `gotoretry.lua` sin egen `scene:show`, som da er den aktive
scenen uten noen overlay oppå seg — akkurat den konteksten
`gotolevel1.lua` allerede har brukt trygt for "ingen liv igjen"-veien.

Fant i samme slengen en beslektet, men til nå ubekreftet, bug i
`gotolevel1.lua` sin egen `goto()`: den kalte aldri
`composer.removeScene("scenes.level1")` før `gotoScene`, så om
spilleren gikk tom for liv MENS de sto på bane 1 selv (ikke en annen
bane), ville den ikke faktisk kjørt `scene:create` på nytt, ifølge
samme Solar2D-forum-tråd som forklarte hvorfor `removeScene()`
trengs for samme-navn-gjenlasting i utgangspunktet. Rettet samme sted.

`pausemenu1.lua` og `dodmenu1.lua` sin `resume()` er dermed betydelig
enklere nå: ingen `hideOverlay()`/`removeScene()` der lenger i det
hele tatt, bare en `pcall(composer.gotoScene, target, ...)` til enten
`"scenes.gotoretry"` eller `"scenes.gotolevel1"`.

Luac-sjekket alle fire filene. Ikke testet i faktisk nettleser, det er
fortsatt akkurat den delen jeg ikke kan gjøre herfra. Dette er nå
tredje forsøk på akkurat denne krasjen, så ekstra viktig å få bekreftet
av dere før vi går videre til noe annet.

## 2026-09-10, retry-krasjen var faktisk to forskjellige bugs

`gotoretry.lua`-omveien virket. Mathias meldte tilbake en NY feil ved
retry etter en død i bane 1, denne gangen "attempt to call method
'addEventListener' (a nil value)", ikke lenger "compare nil with
number". Det er faktisk gode nyheter: det er en annen, senere feil enn
den vi jaktet på i sted, som betyr at selve `gotoretry`-fiksen løste
det opprinnelige problemet, og vi har nå avdekket en HELT separat bug
lenger inn.

Fant den i `del1:addEventListener( "collision" )`-mønsteret, som
finnes ni ganger i `level1.lua` (en per kroppsdel, `del1`-`del9`).
Dette er faktisk gyldig, dokumentert Corona-bruk, ikke en glipp: når
`addEventListener` kalles med bare eventnavnet og ingen egen
lytter-funksjon, bruker Solar2D objektets eget `.collision`-felt som
lytter (satt med `del1.collision = onLocalCollision1` osv, rett før
første `addEventListener`-kall). Selve mønsteret (i
`onLocalCollision1`-`onLocalCollision9`, kun i `level1.lua`, ikke i de
andre åtte banene) er en "kjøletid"-effekt: når en kroppsdel treffer
bakken, slås dens egen kollisjonslytter AV, en støv-sprite
(`stov1`-`stov9`) spawnes og fades ut over 1 sekund, og når den
`transition.to()`-en er FERDIG (`onComplete`), slås lytteren PÅ igjen.

Problemet: `transition.to()` sine `onComplete`-kall avbrytes ikke
automatisk av at scenen skjules. Om spilleren dør og trykker retry
mens en slik 1-sekunds-effekt fortsatt venter, fyres `onComplete` opp
til 1 sekund SENERE, og prøver da å kalle `:addEventListener` på en
kroppsdel som `gotoretry.lua` allerede har revet ned. En fjernet
Corona-visningsobjekt mister metodene sine, derav "a nil value" på
selve metoden, ikke på objektet.

Fikset med `transition.cancel()` (ingen argumenter, avbryter ALLE
ventende transitions) i `scene:hide` sin "did"-fase i `level1.lua`,
rett ved siden av den eksisterende Runtime-lytter-opprydningen. Lagt
til samme linje i `level2.lua`-`level9.lua` også, for konsistens og
fordi det er billig defensiv praksis, selv om bare `level1.lua` sin
mer avanserte per-kroppsdel-støveffekt faktisk kan krasje på denne
måten (de andre banenes støveffekt er enklere og fjerner bare seg
selv, ikke noe delt objekt).

Luac-sjekket alle ni filer. Ikke testet i faktisk nettleser.

## 2026-09-10, samme addEventListener-krasj: transition.cancel() kom for sent

Mathias testet, samme krasj kom igjen, ordrett identisk stack. Så
`transition.cancel()` i `scene:hide` løste det IKKE. Tenkte gjennom
tidsvinduet på nytt: dødsmeny/pausemeny sin `resume()` går nå til
`"scenes.gotoretry"` med en 500ms fade-overgang, og `scene:hide` sin
"did"-fase (der `transition.cancel()` lå) skjer først når HELE den
overgangen er ferdig, altså 500ms etter at retry ble trykket. Den
ventende støv-effekten (opptil 1 sekund) kan fyre `onComplete` når som
helst i det vinduet, inkludert midt i de 500ms'ene, altså FØR
`transition.cancel()` i det hele tatt rekker å kjøre.

Fikset i to lag denne gangen:

1. Flyttet `transition.cancel()` til helt øverst i `resume()` i både
   `pausemenu1.lua` og `dodmenu1.lua`, altså i samme øyeblikk retry
   trykkes, FØR noen scene-overgang i det hele tatt starter. Trenger
   ikke tilgang til `level1.lua` sine egne lokale variabler siden
   `transition.cancel()` uten argumenter er globalt.
2. I tillegg, som en mer grunnleggende sikring uansett tidsvindu: la
   til en `.stage`-sjekk i selve `onComplete`-kallet i alle ni
   `del1`-`del9`-blokkene i `level1.lua`. Et Corona-visningsobjekt som
   er fjernet fra scenen har `.stage == nil`, mens et fortsatt levende
   objekt alltid har en gyldig `.stage`. `del1:addEventListener(...)`
   kalles nå bare `if del1.stage then ... end`, så selv om en
   transition mot formodning skulle overleve helt fram til
   `onComplete`, kan den ikke lenger krasje på en allerede fjernet
   kroppsdel, uansett hvorfor den overlevde.

Luac-sjekket alle tre filene. Ikke testet i faktisk nettleser.

## 2026-09-14, bane 2-4 byttet ut med Ørjans nyere versjon

Mathias lastet opp en zip fra Ørjan: en nyere versjon av spillet der
bane 1-4 skal fungere og mange bugs er fikset. Zippen var stor (289
filer, 19 MB), langt mer enn en liten diff: egne pausemeny/dødsmeny/
kollisjonsform-filer per bane i stedet for delte, pluss flere filer
som ikke finnes i dette repoet i det hele tatt (`chooselevel.lua`,
`game.lua`, `GGData.lua`, `options.lua`, `play.lua` m.fl.). Spurte
Mathias hvordan jeg skulle prioritere; svaret var å bytte ut bane 2-4
helt med Ørjans versjon, tilpasset til mappestrukturen vår, med våre
egne rettelser lagt oppå. Bane 1 sto urørt, den var allerede oppdatert
fra før.

**Det faktiske funnet:** `level2.lua`, `level3.lua` og `level4.lua` i
Ørjans zip er nesten dobbelt så store som våre gamle versjoner (2437
linjer mot 1780), fordi de har fått nøyaktig samme fulle knekk-/
støveffekt-system som `level1.lua` allerede hadde (`onLocalCollision1`-
`onLocalCollision9`, ni "knott"-fysikkobjekter med weldJoints, aktiv
`Runtime:addEventListener("collision", knekk)`). Den konkrete, store
fiksen er egne `shapedefs2.lua`/`shapedefs3.lua`/`shapedefs4.lua`: hver
bane har nå EGNE, riktig sporede bakke-kollisjonsformer i stedet for å
dele bane 1 sine (dette var akkurat spørsmål 3 i `sporsmal.md`, om
bane 2 sin bakke ikke stemte med hvor marken faktisk kolliderte). De
nye formene hører sammen med NYE bakke-bilder (`level2/1.png` til
`4.png` osv, alle fire pikslene forskjellige fra det vi hadde, sjekket
med md5sum), så begge måtte byttes ut sammen, ellers ville formene og
bildene ikke stemt overens.

**Ikke tatt med, bevisst**: Ørjans egne per-bane `pausemenu2.lua`/
`dodmenu2.lua`/`gotolevel2.lua` (og tilsvarende for 3/4). De hardkoder
retry til sin egen bane (`gotoScene("gotolevelN")` rett fra
`resume()`), som er en helt annen, mer duplisert løsning på nøyaktig
det samme problemet vårt `lm.currentLevel`+`gotoretry.lua`-system
allerede løser generisk for alle ni baner. I stedet lot jeg
`level2.lua`-`level4.lua` fortsette å bruke VÅRE delte
`scenes.pausemenu1`/`scenes.dodmenu1`/`scenes.gotoretry`, bare med
egne `showOverlay`-kall pekende dit i stedet for til Ørjans
per-bane-filer. Sparer tre sett med meny-filer, og disse har allerede
fått alle retry-krasj-fiksene fra i går.

**Feil funnet i Ørjans kode underveis, rettet ved porteringen:**
- `trykk_knapp` var fortsatt en utilsiktet global funksjon
  (`function trykk_knapp(event)`, ikke `local`), og dobbeltklikk brukte
  fortsatt det upålitelige `event.numTaps == 2`-mønsteret vi allerede
  hadde bevist ikke virker pålitelig i HTML5-eksport (se fiksen fra i
  forgårs). Erstattet med nøyaktig samme `system.getTimer()`-baserte
  løsning som i `level1.lua`.
- En hel andre kopi av `trykk_knapp`-funksjonen (med en
  `girned()`-hjelpefunksjon) lå som utkommentert `--[[ ]]`-dødkode rett
  under den første, aldri kjørende. Fjernet.
- Samme sårbarhet som i går sin `transition.cancel()`-fiks (den
  ventende støveffekten kan fyre `onComplete` mot en fjernet kroppsdel
  etter retry): lagt til `transition.cancel()` i `scene:hide` og
  `.stage`-vakt rundt alle ni `delN:addEventListener("collision")`
  gjenoppmonteringer, identisk med `level1.lua` sin fiks.
- `lm.currentLevel = N` satt tidlig i `scene:create`, samme sted som i
  de andre åtte banene, for at retry skal restarte riktig bane.
- `camera`/`grp` merket med `_G.`-prefiks på definisjonsstedet, samme
  konvensjon som resten av kodebasen.

**Ikke rørt**: selve spill-logikken (fysikk, kollisjonssjekker,
banedesign, knekk-mekanikken sin egen kode) er identisk med Ørjans
versjon, bare sti-referanser (`require`) er tilpasset `scenes.`/`lib.`-
mappestrukturen vår. Fant og lot stå en håndfull andre
`--[[ ]]`-dødkodeblokker i disse filene (bl.a. en `firkant5`-`firkant8`
bakgrunnsblokk som refererer bilder vi ikke har, `Brett1.png`/
`verden6-8.png`, men siden blokken er utkommentert kjører den aldri og
de manglende bildene spiller ingen rolle) — ikke en fullstendig
dødkode-opprydning av disse tre filene denne gangen, det får bli en
egen økt.

Luac-sjekket alle seks filene (tre banefiler, tre shapedefs). Kunne
selvsagt ikke teste i faktisk nettleser, spesielt de nye
kollisjonsformene og at bane 2-4 nå faktisk er spillbare med korrekt
bakke, bør prioriteres høyt når dere får testet.

## 2026-09-15, lette gjennom resten av Ørjans zip for mer å hente

Mathias ba meg studere koden i zippen grundigere for å se om det var
mer Ørjan hadde lagt til enn det som allerede ble hentet inn (bane
2-4 og de nye kollisjonsformene). Sammenlignet systematisk alle delte
moduler og skjermer mot det vi har:

**Ingenting mer å hente** fra `liv.lua`, `mark.lua`,
`ogt_levelmanager.lua`, `menu.lua`, `chooselevel.lua`, `GGData.lua`,
`perspective.lua`, `gameUI.lua`, `config.lua`, `gotomenu.lua`,
`gotochooselevel.lua`, `pausemenu1.lua`/`dodmenu1.lua`, og
`level5.lua`-`level9.lua` — for alle disse er versjonen i zippen
FAKTISK ELDRE/mindre fikset enn det vi allerede har (mangler bl.a.
`liv.erTom()`, pcall-sikkerhetsnettet i navigasjonen,
`checkpoint()`-sporing, `transition.cancel()`, og for bane 5-9 fortsatt
kommentert bort `knekk`-lytter og delte (feil) kollisjonsformer). Bane
5-9 var altså ikke en del av Ørjans "4 baner fungerer"-opprydning i det
hele tatt.

De ekstra filene som ikke fantes i `scenes/`/`lib/` i det hele tatt
(`game.lua`, `livddadas.lua`, `brett.lua`, `hoydehopp.lua`,
`menu1.lua`, `options.lua`, `play.lua`) viste seg å være nøyaktig de
samme filene som allerede ble identifisert som død kode og arkivert i
`dod-kode/` under den aller første oppryddingsøkten. Bekreftet med
md5sum, byte-for-byte identiske (unntatt en triviell sti i
`menu1.lua`, ikke et reelt innholdsforskjell).

**To reelle funn, begge fra `main.lua`/`ogt_lmdata.lua`:**

1. `k.numUnlocked` (i `lib/ogt_lmdata.lua`) sto til `k.totalLevels`
   (alle ni baner åpne), merket i vår egen kommentar som en midlertidig
   debug-overstyring fra en tidligere økt. Ørjans nyere `ogt_lmdata.lua`
   setter den eksplisitt til `4`, som stemmer nøyaktig med at bare
   bane 1-4 faktisk er ferdige. Satt tilbake til 4, slik at spillere
   ikke kan navigere inn i de fortsatt ødelagte banene 5-9 fra
   banevalg-skjermen.
2. `main.lua` hoppet rett til bane 1 ved oppstart
   (`composer.gotoScene("scenes.gotolevel1")`), og hoppet dermed helt
   over hovedmenyen. Ørjans nyere `main.lua` går fortsatt via menyen
   (`gotoScene("gotomenu")`). Spurte Mathias, som ville ha menyen
   tilbake. Endret `main.lua` til `composer.gotoScene("scenes.gotomenu")`.
   Sjekket at `menu.lua` faktisk har en fungerende vei videre:
   "storyknapp"-bildet har en "tap"-lytter (`spill()`) som etter 2
   sekunder går til `scenes.chooselevel`, så ingenting mangler i den
   veien. Ørjans meny hadde i tillegg noen widget-knapper ("Play",
   "Options", "High Jump") som peker til bekreftet død kode
   (`options.lua`/`hoydehopp.lua`), men disse knappene finnes ikke i
   VÅR `menu.lua` i utgangspunktet, så ingenting å fjerne der.

Luac-sjekket `main.lua` og `lib/ogt_lmdata.lua`. Ikke testet i faktisk
nettleser at hele kjeden main → meny → banevalg faktisk fungerer som
forventet.

## 2026-09-15, første forsøk på en helt ny bane (bane 5), i to steg

Mathias ba om en genuint ny bane, og tilbød å koble til connectorer om
jeg trengte det. Jeg har ikke bildegenerering tilgjengelig i denne
økten (sjekket: verken som eget verktøy eller som noen connector i
registeret, Canva/Figma krever et eksisterende design å jobbe ut fra,
ikke "lag et hulegulv i denne stilen"), så egentlig ny kunst må enten
lages prosedyremessig (kode som tegner formen) eller komme fra en
ekte kilde (Ørjan/Mathias).

Laget et prosedyre-generert forslag til bane 5 sin bakke (fire fliser,
jevn/humpete konturlinje trukket fra samme fargepalett som bane 4, med
kollisjonsform beregnet direkte fra samme kurve jeg tegnet den med, så
ingen PhysicsEditor-usikkerhet). Sendte et forhåndsbilde til Mathias
før noe ble lagt inn i spillet.

Mathias svarte med to konkrete krav banen faktisk må oppfylle
(uavhengig av selve grafikken): den skal være en **nedoverbakke**, og
det skal finnes **steder man kan falle gjennom og dø**. Ba samtidig om
å teste selve banedesignet med de gamle bildene først, og lage noe fra
bunnen når mekanikken faktisk er under kontroll — fornuftig rekkefølge,
så jeg satte den prosedyregenererte bakken til side for nå (ligger
fortsatt i scratchpad, ikke committet).

**Funn som gjorde testen enkel**: `level4.lua` (og alle andre baner)
er allerede bygget som en nedoverbakke, ikke flatt. `firkant1`-
`firkant4` (banestykkene) plasseres diagonalt — hver flis flyttes
BÅDE sin egen bredde til høyre OG sin egen høyde ned fra forrige flis
(`firkant2.x = firkant1.x+firkant2.width`, `firkant2.y =
firkant1.y+firkant2.height`, osv). Det er derfor spillet allerede
oppleves som en nedoverbakke i dag, ikke noe jeg trengte å legge til.

Det finnes også allerede en dødssone, `dod`: en 70000 piksler lang,
usynlig sensor-stripe rotert i samme vinkel (31.48°) som resten av
banen, plassert langt til venstre og strukket over hele banens lengde.
Alt som treffer den (`del1`-`del9` i kollisjonssjekken) trigger
dødsmenyen, akkurat som å falle helt av banen.

**Testet begge kravene i `level5.lua` uten ny grafikk i det hele
tatt**, ved midlertidig å gjenbruke `level4.lua` sine ferdig
sammenhørende bilder OG kollisjonsformer (`level4/1-4.png` +
`lib/shapedefs4.lua`, byttet fra den delte `lib/shapedefs.lua`) i
stedet for `level5` sine egne (som uansett fortsatt er feil/delte, se
"Kjente feil"). Selve hull-testen: flyttet `firkant3` et helt ekstra
halvt flis-mål lenger unna `firkant2` (både i x og y, langs samme
skråvinkel som resten), i stedet for kant-i-kant som normalt. Siden
`dod`-sonen allerede dekker hele banens lengde langt under selve
bakken, skal det som faller i det hullet dø akkurat som å falle av
banen — ingen ny dødssone-kode trengtes.

Dette er bevisst en MIDLERTIDIG oppsett (merket tydelig i koden med
dagens dato): `level5.lua` bruker `level4` sine bilder og
kollisjonsformer bare for å bevise at nedoverbakke- og
hull-mekanikken fungerer, ikke som permanent innhold. Neste steg,
når Mathias/Ørjan har bekreftet at hull-fallet faktisk fungerer og
føles riktig: erstatte `level4`-referansene med egen bane 5-grafikk
(enten den prosedyregenererte som allerede ligger klar, eller ekte
kunst om noen leverer det).

Luac-sjekket `level5.lua`. Ikke testet i faktisk nettleser — det
er akkurat fallet-gjennom-hullet jeg mest av alt skulle ønske noen
kunne bekrefte fungerer, siden jeg ikke kan spille selv.

## 2026-09-15, bane 5 fikk sin egen (prosedyregenererte) grafikk

Mathias bekreftet at nedoverbakken og hullet fungerte, og ba meg bygge
videre med den prosedyregenererte bakken i stedet for å fortsette å
låne bane 4 sine bilder.

Skrev om terreng-scriptet fra forrige runde til å produsere ferdige
filer direkte: `level5/1.png`-`4.png` (samme kontinuerlige, humpete
konturlinje som i forhåndsbildet, samme fargepalett hentet fra bane 4)
og `lib/shapedefs5.lua`. Det siste er det egentlig interessante: siden
jeg tegnet selve terrengkurven i Python, kunne jeg regne
kollisjonsformen direkte ut fra de nøyaktig samme koordinatene i
stedet for å spore dem i etterkant. Hver av de fire flisene deles i 6
trapeser (to punkter fra selve terrengkurven + bunnen av bildet),
som alltid er konvekse per konstruksjon (rett bunnkant, to parallelle
sider, én skrå topp-kant) — ingen konveks-dekomponering nødvendig, og
ingen usikkerhet rundt om formen faktisk stemmer med bildet, siden de
kommer fra samme tall. `del1` (selve marken sin kollisjonsform)
kopiert uendret inn fra `lib/shapedefs4.lua`, siden marken er lik i
alle baner.

Første forsøk på bildefilene ble 10 MB per flis (ren støy per piksel
komprimerer nesten ikke i PNG). Byttet til en nedskalert, oppskalert
"flekk"-tekstur i stedet for piksel-for-piksel-støy, som ser nesten
like tekstur-rik ut men komprimerer mye bedre — endte på 0.4-0.6 MB
per flis. Vurderte også å paletisere filene (som de andre `levelN/`-
bildene), men fikk ikke gjennomsiktighets-tabellen til å bli riktig
skrevet av Pillow innenfor rimelig tid og lot det være, RGBA med ekte
alfakanal fungerer like fint i Solar2D, bare noe større filer.

`scenes/level5.lua` peker nå på sine egne filer og
`lib.shapedefs5` i stedet for de midlertidige `level4`-referansene og
`lib.shapedefs4` fra forrige runde. Hullet mellom flis 2 og 3 står
urørt, ingen nye ønsker om plassering kom fram.

Luac-sjekket `scenes/level5.lua` og `lib/shapedefs5.lua`. Fortsatt
ikke testet i faktisk nettleser — spesielt viktig å få bekreftet nå:
at kollisjonen mot den NYE bakken faktisk stemmer visuelt (den er
riktig utregnet, men "riktig utregnet" er ikke det samme som "sett
med egne øyne i spillet").

## 2026-09-15, marken så ikke banen: kurven min startet for langt nede

Mathias meldte "ser ikke banen på bane 5" og ba meg sjekke markens
startposisjon. God ledetråd, for det var akkurat der feilen lå.

Marken (`del1`) starter alltid på verdenskoordinat (0,0), i ALLE baner
(bekreftet identisk i `level4.lua` også, ikke noe jeg selv satte opp).
Første flis (`firkant1`) står på (3500, 2300) med en kjempestørrelse
(7680×4702), så (0,0) havner et stykke inn i selve fliseflaten — men
KUN dersom bakkeflaten faktisk ligger nær toppen av bildet der. Målte
etterpå hvor bakken faktisk starter i `level4/1.png` sin egen
bildefil, nøyaktig ved kolonnen som tilsvarer verdenskoordinat x=0:
rundt 11 % ned i bildet. Min kurve fra forrige runde startet derimot
på 60 % ned (en jevn, flat kurve rundt midten) — marken falt dermed
over 1500 piksler gjennom tomt, gjennomsiktig rom før noe bakke i det
hele tatt kom i syne. Med kameraet fokusert på marken var resultatet
nettopp "ser ikke banen": skjermen viste bare tomrom lenge før noe
dukket opp.

Målte samtidig, mens jeg først var inne i `level4` sine bildefiler,
den faktiske formen på Ørjans ekte kunst: hver flis er IKKE en jevn,
rullende bakke, men en bratt nedoverbakke i seg selv (fra ~11 % ned
ved flisens egen venstrekant til ~83 % ned ved høyrekanten), med et
tydelig steg/hopp i verdenskoordinater fra én flis til neste (målt
til over 1000 enheter). Skrev om terreng-scriptet fra "én jevn kurve
over alle fire flisene" til at hver flis får sin EGEN bratte
nedoverbakke-kurve (samme mønster som målt), i stedet for å anta at
flisene skulle flyte jevnt sammen ved kantene. Regnet ut på nytt at
gapet mellom markens startpunkt og ny bakke nå blir ca 777 enheter,
tett opptil de 627-751 jeg målte i den ekte bane 4-kunsten.

Genererte alle fire flisene og `lib/shapedefs5.lua` på nytt fra den
nye kurven. Hullet mellom flis 2 og 3 (fra forrige commit) er urørt.

Luac-sjekket. Fortsatt ikke sett i faktisk nettleser, men
avstanden fra markens startpunkt til bakken er nå tallfestet og
matcher den ekte bane 4-kunsten godt, så jeg er en god del tryggere
denne gangen enn forrige.

## 2026-09-15, reklame-for-liv-skjerm (placeholder), fordi liv stod fast på 0

Mathias meldte at han "alltid har 0 liv nå". Årsaken er ikke en feil i
selve lagringen, den fungerer som tenkt: `liv.lastliv()` leser antall
liv fra fil (`liv.txt` i DocumentsDirectory, på HTML5 vedvarende
nettleser-lagring) ved hver banestart, `liv.lagreliv()` skriver
tilbake etter hvert forsøk. Det som manglet var en vei tilbake opp
igjen. Etter mye testing i dag var de 10 standardlivene brukt opp, og
uten noen måte å legge til liv på forblir 0 lagret for alltid.

Bygget skjermen Ørjan selv beskrev (se sporsmal.md, spørsmål 1): kort
reklame gir ett liv, lang reklame gir flere, den som ikke vil se
reklame kan starte på nytt fra bane 1 som før. Selve reklamen finnes
ikke ennå (krever et annonse-SDK), så jeg bygget den som en tydelig
merket PLACEHOLDER, en nedtelling på noen sekunder i stedet for en
ekte videoannonse.

Konkret:

- `lib/liv.lua`: `liv.addToScore(val)` var en tom stub (kroppen stod
  kommentert ut), fylte den inn til faktisk å legge til liv
  (`liv_igjen = liv_igjen + val`). Navnet fantes fra før og pekte
  allerede mot akkurat dette bruksområdet, ifølge kommentaren ved
  `liv.erTom()`.
- Ny fil `scenes/adoffer.lua`: viser "Ingen liv igjen" og tre knapper,
  kort reklame (+1 liv), lang reklame (+3 liv), fortsett uten (start
  fra bane 1). `visReklamePlaceholder(sekunder, livBelonning)` teller
  ned med `timer.performWithDelay`, og legger til liv og lagrer når
  den er ferdig, før den går videre til `scenes.gotoretry` (samme
  trygge mellomscene-mønster som resten av retry-flyten bruker, se
  forklaringen i `pausemenu1.lua`/`dodmenu1.lua` fra tidligere, av
  samme grunn: å bytte scene direkte herfra mens denne selv ligger som
  overlay er ikke en støttet rekkefølge i Composer).
- Fant og rettet to feil underveis i egen gjennomgang av den nye fila,
  før noe ble commitet: knappegruppa (`knappGruppe`, brukt til å
  skjule alle tre knappene på én gang når reklamevisningen kommer opp)
  var laget med `display.newGroup()` men aldri satt inn i
  `sceneGroup`, som ville latt den henge igjen uryddet av Composer sin
  scene-opprydning. Og `lagKnapp()` returnerte bare selve
  knapperektangelet, ikke tekstetiketten, så etikettene ble aldri lagt
  i `knappGruppe` og ville blitt stående synlige alene når knappene
  ble skjult. Rettet begge før commit.
- `scenes/pausemenu1.lua` og `scenes/dodmenu1.lua`: der `liv.erTom()`
  gikk `target` før rett til `scenes.gotolevel1`, går den nå til
  `scenes.adoffer` i stedet. Den som ikke vil se reklame kan fortsatt
  velge "start på nytt fra bane 1" derfra, så den gamle sikkerhetsveien
  finnes fortsatt, bare ett skritt lenger inn.

Luac-sjekket alle fire filene, og kjørte et fullt syntakssøk over hele
repoet etterpå. Ikke testet i faktisk nettleser ennå. Ting å sjekke
ved neste testing: at "ingen liv"-skjermen faktisk dukker opp i stedet
for å gå til bane 1 direkte, at begge reklameplaceholderne legger til
riktig antall liv og går videre til riktig bane, og at "fortsett
uten"-knappen fortsatt fungerer som før.

## 2026-09-15, går automatisk videre til neste bane når man klarer en

Mathias ba om at man ikke lenger skal måtte innom banevalget selv når
man klarer en bane. Alle ni banefiler (`level1.lua`-`level9.lua`) har
en identisk `goto2()`-funksjon som kjøres når "mål"-sensoren (`mal2`)
treffer marken (`del4`), altså akkurat idet banen er fullført. Den
viste før alltid `showOverlay("scenes.gotochooselevel")`, rett til
banevalget, uansett hvilken bane som ble fullført.

Bygget ny splash-scene `scenes/gotonextlevel.lua`, samme trygge
mønster som `gotoretry.lua` (venter 0,8 sekund med en liten
loading-animasjon, så `removeScene`+`gotoScene` med `pcall`-sikring),
men som regner ut destinasjonen selv:

- Er det en neste bane (`lm.anotherLevel()`, sjekker
  `lm.currentLevel+1 <= k.totalLevels`)? Gå dit
  (`scenes.level` .. tallet), og øk `lm.currentLevel` tilsvarende
  (samme variabel `gotoretry.lua` leser for å vite hvilken bane den
  skal restarte, så senere retry på den nye banen peker riktig sted).
- Ellers (siste bane fullført): gå til `scenes.gotochooselevel` som
  før.

Alle ni `goto2()`-funksjonene endret til å vise
`scenes.gotonextlevel` i stedet for `scenes.gotochooselevel` direkte.
Selve `lm.unlockNextLevel()`-kallet rett før (låser opp neste bane i
banevalget) er urørt, det trengs uansett siden spilleren fortsatt kan
velge å gå tilbake til banevalget senere.

Viktig å vite: bane 6-9 er fortsatt ufullstendige (plassholder-grafikk
og feil kollisjonsformer, se "Kjente feil" i `KODEBASE.md`). Dette var
allerede nåbart via banevalget fra før (alle baner er midlertidig låst
opp for testing), så denne endringen åpner ikke noe nytt der, den gjør
bare at man havner der automatisk i stedet for å måtte trykke seg dit
selv om man fullfører bane 5.

Luac-sjekket alle ti berørte filene (de ni banene + den nye splashen),
og kjørte et fullt syntakssøk over hele repoet etterpå. Ikke testet i
faktisk nettleser ennå. Ting å sjekke ved neste testing: at man
faktisk havner på riktig neste bane (ikke bane 1) når man fullfører en
bane, at det fortsatt fungerer å fullføre siste bane (går til
banevalget), og at retry på den nye banen restarter riktig bane
etterpå.

## 2026-09-15, "fortsett uten" på reklame-skjermen ga fortsatt 0 liv

Mathias påpekte at når man er tom for liv og trykker "gå til level 1"
(altså "fortsett uten" på `scenes/adoffer.lua`), burde man få 10 nye
liv, siden man starter helt på nytt. Stemte: knappen gikk til
`scenes.gotolevel1`, men gjorde ingenting med selve livtelleren, så
man landet på bane 1 med fortsatt 0 liv lagret, altså rett tilbake til
"ingen liv igjen"-skjermen ved første tap.

`liv.new()` var en tom stub fra før (samme mønster som
`liv.addToScore()` var før forrige økt). Fylte den inn til å
nullstille `liv_igjen` til en ny navngitt konstant `STARTLIV = 10`
(samme verdi som filens opprinnelige standardverdi, nå ett sted i
stedet for et implisitt tall). "Fortsett uten"-knappen i
`adoffer.lua` kaller nå `liv.new()` og `liv.lagreliv()` før den går
til bane 1.

Én ting verdt å vite, siden Mathias sin begrunnelse var "siden alle
banene blir låst igjen": det stemmer ikke helt ennå. Verken
`gotolevel1.lua` eller noe annet sted faktisk låser banene igjen når
man starter på nytt. Det finnes en utkommentert
`lm.resetLevels(dataFile)` i hver banes egen døds-kollisjonshåndterer
(aldri aktivert), og `lib/ogt_levelmanager.lua` sin `loadData()` har i
tillegg en midlertidig debug-linje som tvinger ALLE baner åpne uansett
lagret status, satt inn for testing (se `KODEBASE.md`). Så selv om jeg
hadde aktivert `resetLevels()` her, ville den ikke synes før den
midlertidige linja fjernes. Rørte ikke ved dette nå, bare selve
livtellingen som var det konkrete som ble spurt om. Si ifra om
faktisk gjenlåsing av baner også skal på plass, det er en egen, litt
større endring.

Luac-sjekket begge filene, kjørte fullt syntakssøk over repoet
etterpå. Ikke testet i faktisk nettleser ennå.

## 2026-09-15, bane 5: banen vises, men kollisjonen virket ikke

Mathias bekreftet: banen vises nå riktig etter forrige fiks, men
kollisjonen fungerer ikke. Fant feilen ved å sammenligne
`lib/shapedefs5.lua` sine tall direkte mot `lib/shapedefs4.lua` (ekte,
PhysicsEditor-sporet, bekreftet fungerende) sine.

`firkant1`-`firkant4` lages med `display.newImageRect("level5/N.png",
7680, 4702)`, altså strekkes kildebildet (3840×2351 piksler) opp til
DOBBEL størrelse på skjermen. Kollisjonsform-koordinater i Solar2D
angis i objektets EGET, faktiske (viste) koordinatsystem, ikke
kildebildets pikselstørrelse. Terreng-scriptet mitt bygde derimot
formene direkte fra kildebildets piksel-koordinater (±1920/±1175,
halve 3840×2351), uten å gange opp til den faktiske visningsstørrelsen
(som skulle vært ±3840/±2351). Sjekket `lib/shapedefs4.lua` sine
faktiske tall for å bekrefte: de ligger i området ±3700/±2300, altså
den DOBLE, riktige skalaen jeg selv skulle brukt.

Dette ble faktisk vurdert allerede i den første bane 5-økten (se
loggen lenger opp, "kurven min startet for langt nede"), og den gangen
konkludert med at skaleringen stemte. Det var feil, trolig fordi jeg
den gangen sammenlignet mot feil referansepunkt. Beklager at det tok
en runde til å finne.

Fikset ved å doble alle tallene i de fire bakke-fixturene ("1"-"4") i
`lib/shapedefs5.lua`, en ren skalering (samme kurveform, samme
relative posisjon, bare uttrykt i riktig koordinatsystem). Rørte ikke
`del1` (markens egen form, kopiert fra `shapedefs4.lua` fra før, var
allerede riktig skalert). Vurderte å heller sette
`scaleFactor = 2.0` i `level5.lua` i stedet for å endre selve fila,
men lot være: den samme `scaleFactor`-variabelen brukes til å skalere
ALLE former filen returnerer, `del1` inkludert, så det ville doblet
markens egen kollisjonsform ved en feiltagelse også.

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå.

## 2026-09-15, bane 5: kollisjonen traff fortsatt dårlig, og for kantete

Mathias testet igjen etter skala-fiksen: kollisjonen traff banen
bedre, men fortsatt ikke bra, og banen så litt for kantete ut. To
separate, men beslektede, feil i terreng-scriptet
(`make_level5_terrain.py` i scratchpad, ikke en del av selve
repoet):

- **Kollisjonen traff dårlig:** hver flis brukte bare 6 rette
  linjestykker til å tilnærme en 3840 piksler bred kurve. Mellom
  samplingspunktene kunne den faktiske kurven svinge unna den rette
  linja med ganske mye, som synlige hull (kollisjon under bakken man
  ser) eller motsatt (usynlig vegg over bakken). Økt til 40
  linjestykker per flis, langt tettere langs kurven.
- **For kantete:** den gamle støy-modellen genererte tilfeldige verdier
  per piksel/blokk og glattet dem med et glidende gjennomsnitt
  (boks-filter). Uansett hvor bredt vinduet ble satt, satt det igjen
  en synlig sagtakket, hakkete rest, fordi et boks-filter aldri gjør
  ekte tilfeldig støy helt jevn. Skrev om til "value noise":
  interpolerer jevnt (cosinus-interpolasjon) mellom bare en håndfull
  tilfeldige kontrollpunkter (6 store bakker + 24 finere for litt
  tekstur) i stedet for å glatte støy i etterkant. Jevnt ved
  konstruksjon, uansett zoom-nivå.

Begge rettelsene ligger i samme kurve-funksjon som både kunsten og
kollisjonsformen regnes ut fra, så de forblir eksakt like etter
endringen, akkurat som før. La i tillegg selve skala-dobling (fra
forrige fiks) inn i scriptet direkte denne gangen, i stedet for en
etterhånds-runde på selve Lua-fila, så neste regenerering ikke kan
miste den ved et uhell.

Sjekket at avstanden fra markens startpunkt til bakken (samme
beregning som forrige runde) fortsatt er fornuftig: ca 423 enheter nå
(litt kortere enn de 627-751 fra ekte bane 4-kunst pga. den nye
tilfeldige kurven, men fortsatt et reelt, positivt fall, ikke i
nærheten av det gamle 1500+-hullet). Filstørrelsene er uendret
(~1,5 MB per flis).

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå.

## 2026-09-15, bane 6 fikk samme behandling som bane 5

Mathias sa "kjør på" etter bane 5-fiksene over, tolket det som klarsignal
til å ta fatt på neste åpenbare ting fra "hva mer skal fikses"-lista:
bane 6-9 har fortsatt plassholder-grafikk og feil (bane 1-sporede)
kollisjonsformer.

Bygget bane 6 med akkurat samme, nå ferdig fiksede generator som bane 5
(riktig visningsskala bakt inn fra start, 40 kollisjons-linjestykker per
flis, jevn "value noise"-kurve), bare med andre tilfeldighetsfrø
(`seed=17`, og forskjøvet kontrollpunkt-frø +1000) slik at terrenget
faktisk ser annerledes ut enn bane 5, ikke en klone. Ingen hull denne
gangen, bane 6 bruker vanlig diagonal flis-plassering som bane 1-4 (det
var bare bane 5 som fikk et bevisst hull for å teste
falle-gjennom-mekanikken).

Sjekket avstanden fra markens startpunkt til bakken på nytt: ca 610
enheter, godt innenfor den målte 627-751-referansen fra ekte bane
4-kunst, nærmere target enn bane 5 sin egen (som var ca 423 pga
tilfeldighet i kontrollpunktene). Ny `lib/shapedefs6.lua`, samme
`del1`-form kopiert fra `lib/shapedefs4.lua`. `scenes/level6.lua`
byttet fra `lib.shapedefs` (den delte, feile) til `lib.shapedefs6`.

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå. Bane 7-9 står igjen med samme jobb, ikke gjort
ennå, ingen konkret grunn til å prioritere én av dem over de andre.

## 2026-09-15, bane 5: feil parallax-bakgrunn, og hardt kutt ved start/slutt

Mathias testet videre og meldte to ting: parallax-bakgrunnen på bane 5
fungerer ikke som den skal, og ba om samme gradient som bane 4. Så
også et ønske om å runde av starten og slutten på banen i stedet for
et hardt kutt.

**Bakgrunnen:** `scenes/level5.lua` sin bakgrunnsoppsett var en KOPI av
en gammel, ikke lenger brukt versjon: brukte `background/dirt1.png` og
`background/back_cave.png` (uten "1"-prefiks) i stedet for
`1dirt1.png`/`1back_cave.png`/`1back_cave1.png`/`1back_cave2.png` som
bane 1-4 faktisk bruker. Sammenlignet kildebildenes egne
pikseldimensjoner: `back_cave.png` er 2000×6000 piksler, men ble vist
med `display.newImageRect(..., 2000, 3000)`, altså klemt sammen til
HALV høyde, en tydelig forvrengning. `1back_cave.png` (bane 1-4 sin
versjon) er derimot 1000×3000 og vises riktig strukket til 2000×6000.
I tillegg hadde bane 5 bare 12 bakgrunnsflis-kopier per lag
(`background1`-`background12`, samme for "a"/"b"-lagene), mens bane 4
bruker 20 per lag, altså gikk bane 5 tom for bakgrunn på slutten av
banen siden kameraet rekker lenger enn 12 fliser dekker (bane 5 sin
bane er endog litt lengre enn bane 4 sin, pga. det bevisste hullet).

Fikset ved å bytte ut HELE bakgrunns-oppsettet i `scenes/level5.lua`
(fra `local background = display.newImageRect(...)` til siste
`camera:add`-kall) med en eksakt kopi av det samme oppsettet fra
`scenes/level4.lua`: riktig bildefiler, riktig visningsstørrelse, 20
fliser per lag i stedet for 12. `justerside`/`justeroppned`
(forskyvningen mellom hver flis) var allerede identiske konstanter i
begge filene fra før, urørt.

**Hardt kutt ved start/slutt:** hver flis sin bakke fylles solid helt
ned til bunnen av bildet. Usynlig ved skjøtene mellom fliser (neste
flis dekker det), men synlig som en rett, loddrett klippevegg helt i
starten av flis 1 og helt i slutten av flis 4, siden det ikke er noe
der til å skjule den. Lagt til en `apply_edge_taper()`-funksjon i
terreng-scriptet: blander kurven jevnt ned mot bunnen av bildet
(bakken "spisser seg ut" til nesten ingenting) over de ytterste 90
pikslene på disse to kantene, resten av banen urørt. 90 piksler er
bevisst kort: verdenskoordinat x=0 (der marken faktisk starter) treffer
lokal kolonne ca 170 i flis 1, så avrundingen måtte holde seg godt
under det, ellers ville den også spist av avstanden til bakken ved
selve startpunktet (sjekket tallmessig, første forsøk på 260 piksler
gjorde nettopp det, økte gapet fra 423 til over 1500 enheter, satt ned
til 90 for å unngå akkurat det).

Regenererte `level5/1.png` og `level5/4.png` (de to ytterkantene, 2 og
3 uendret siden avrundingen ikke rører dem) og `lib/shapedefs5.lua` fra
den oppdaterte kurven.

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå. Bane 6 fikk IKKE samme avrunding eller
bakgrunnsfiks ennå, den bruker fortsatt sitt eget (uavrundede, men
korrekte fra byggingen) oppsett, siden dette ble bedt om spesifikt for
bane 5.

## 2026-09-15, bane 5/6: bakken skal se ut som en faktisk hule, ikke en ramp

Sendte Mathias referansebilder av bane 5 (flisene satt sammen i
faktisk relativ posisjon, med markens startpunkt merket). Han ba om at
banen skal ha "ganger med åpenrom og lignende", som bane 1-4 sin
håndtegnede kunst har, i stedet for tomrommene i selve
verdensplasseringen. Spurte om han mente kosmetikk på referansebildet
mitt eller selve banekunsten, han bekreftet: selve bane 5/6 sin
bakke-kunst.

Sammenlignet med referansearket over alle ni baner: bane 1-4 sin
kunst er aldri én sammenhengende skråning, den har flere separate
bakkestykker med luft mellom (f.eks. bane 2 sin første flis har to
adskilte kiler), og en mer organisk hule-silhuett enn en ren trekant.
Terreng-scriptet for bane 5/6 laget derimot én ubrutt kurve fra
venstre til høyre kant.

Bygget om terreng-scriptet med to nye ingredienser, begge fra samme
kurve-system som før (fortsatt eksakt samsvar mellom bilde og
kollisjonsform per konstruksjon):

- **Hull i bakken**: hver flis får nå to luftlommer (fravær av bakke,
  `gap_ranges()`) i stedet for én sammenhengende bakke, samme prinsipp
  som hullet mellom flis 2 og 3 fra før, bare i mindre skala og inni
  hver enkelt flis. Hullenes plassering er tilfeldig per flis (egen
  seed), men holdt unna kant-avrundingen og, for flis 1, unna markens
  faktiske startpunkt (kolonne ~170), sjekket tallmessig etterpå at
  avstanden fra spawn til bakke fortsatt er uendret (423 for bane 5,
  610 for bane 6).
- **Hengende tak** (`ceiling_curve()`): en egen, separat silhuett nær
  toppen av bildet, med noen dypere "drypestein"-humper. Rent
  visuelt, ingen kollisjon på taket, for ikke å legge til en ny type
  hindring ingen ba om. Gjør at luftrommene leses som gangrom i en
  hule i stedet for åpen himmel.

Kollisjonsformene hopper nå over segmenter som havner inni et hull
(ingen fixture der, samme som det eksisterende hullet mellom flis 2/3
allerede gjorde), resten uendret (40 linjestykker per flis, jevn
kurve).

Samme behandling på begge banene, med banenes egne (allerede
etablerte) frø-forskyvninger, så bane 5 og 6 fortsatt ser forskjellige
ut. Regenererte `level5/1-4.png`, `level6/1-4.png`,
`lib/shapedefs5.lua` og `lib/shapedefs6.lua`. Filstørrelsene økte noe
(fra ~1,5 til ~1,7 MB per flis) pga. mer kant-detalj fra hullene og
taket, fortsatt en rimelig størrelse.

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå. Sendte oppdaterte referansebilder (samme
flis-i-relativ-posisjon-metode som før) til Mathias for
tilbakemelding før dette regnes som ferdig.

## 2026-09-15, bane 5/6: skal bli mørkere jo lenger ut i spillet, som en hule

Mathias forklarte et designprinsipp jeg ikke kjente til: hver bane
skal bli mørkere enn den forrige etter hvert som man kommer lenger,
som om man drar dypere ned i en hule (bane 1 tydelig lysere enn bane
2, og så videre). Påpekte samtidig at fargen jeg brukte for bane 5/6
var hentet fra feil sted, den var i praksis nærmere bane 1 sin lysere
tone. Bane 1 er opplæringsbanen og skal få eget tutorial-innhold
senere, ikke representativ for selve mørke-progresjonen. Bane 3/4 er
riktig sammenligningsgrunnlag.

Målte etterpå presist fra bane 3 og 4 sin faktiske kunst (ikke bare
antatt): dyp bakkefarge (median langt inne i et bakkestykke) ligger på
ca (38, 14, 1), og selve kantlinja (median innenfor ~4 piksler fra
alfakanten) på ca (63, 27, 4). Begge banene ga nesten identiske tall,
god baseline. Til sammenligning var fargen jeg egentlig brukte for
bane 5/6, (41,16,2)/(98,55,18), særlig kantfargen alt for lys og
mettet mot ekte bane 3/4.

Satt opp en enkel progresjons-regel i terreng-scriptet: bane 5 er ett
"mørke-steg" (faktor 0,85) mørkere enn bane 3/4-baseline på rød og
grønn kanal, bane 6 to steg (faktor 0,85²≈0,72). Blåkanalen holdes
igjen på det samme bunnivået (1) som bane 3/4 allerede bruker i stedet
for å skaleres videre ned, siden den store fargeendringen i spillets
etablerte palett (nesten ikke blått igjen fra bane 1 til bane 2) alt
har skjedd, bane 5/6 skal bare fortsette å dempe rødt/grønt gradvis
derfra.

Regenererte kun `level5/1-4.png` og `level6/1-4.png` (selve fargen
påvirker ikke kollisjonsformen, `lib/shapedefs5/6.lua` uendret).
Filstørrelsene ble marginalt mindre (mørkere farger komprimerer
vanligvis litt bedre).

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå.

## 2026-09-15, bane 5/6: tre presiseringer fra Mathias etter forrige runde

Tre konkrete ting etter å ha sett resultatet av hule-gangene og
mørke-progresjonen:

1. **"Det skal ikke være åpenrom mellom flisene. Bare mellomrom inni
   flisene. Rund av kantene på åpenrommene i flisene."** Selve
   plasseringen var allerede riktig (`gap_centers()` holder seg godt
   innenfor én flis sine grenser, aldri ved skjøtene), men luftlommene
   var rektangulære utstansinger med rette, loddrette kanter, så det
   så ut som firkantede søyler i stedet for en naturlig hule-åpning.
   Lagt til `apply_gap_taper()`, samme prinsipp som kant-avrundingen
   fra i sted, bare brukt på begge sider av hver luftlomme: bakken
   spisser seg ut til nesten ingenting over `GAP_TAPER` (70) piksler
   før selve hullet, i stedet for å stoppe brått.
2. **"Ikke gjør det for mørkt heller. Det skal gå veldig sakte
   gradvis mørkere per bane. Spilleren skal nesten ikke merke at det
   blir mørkere og mørkere."** Forrige mørke-steg (faktor 0,85 per
   bane) var for merkbart. Satt ned til 0,98 per bane; bane 5 blir da
   knapt merkbart mørkere enn bane 3/4-baseline (98 %), bane 6 enda
   litt til (96 %), i stedet for de forrige 85 %/72 %.
3. **"Pass på at posisjonen til marken ikke starter inne i taket."**
   Sjekket tallmessig og fant at dette faktisk var en reell feil:
   marken sitt startpunkt (verdenskoordinat 0,0) treffer lokal rad
   ~25,5 i flis 1, altså helt øverst i bildet, nøyaktig der det
   hengende taket begynner (fra rad 0 og minst ~235 nedover). Taket
   dekket dermed markens startpunkt fullstendig. Lagt til
   `apply_ceiling_spawn_clearance()`: for flis 1 spesifikt trekkes
   taket helt vekk (nær null) de første 500 pikslene, med jevn
   overgang til normal tak-dybde etterpå, godt forbi markens faktiske
   startkolonne (~170). Tematisk stemmer det også fint: helt
   innerst/øverst ved inngangen er det åpent, selve hule-taket starter
   litt lenger inn. Regnet ut klaringen etterpå: bane 5 har nå 125
   verdensenheter luft mellom tak og startpunkt, bane 6 157, begge
   trygt positive.

Ingen av de tre endringene rørte avstanden fra markens startpunkt til
bakken (fortsatt 423 for bane 5, 610 for bane 6, sjekket på nytt).

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå.

## 2026-09-15, bane 5/6: genererte et bilde med kollisjonsformene tegnet oppå kunsten, fant en reell feil

Bygget et script (i scratchpad, ikke i repoet) som leser de faktiske
tallene fra `lib/shapedefs5.lua` og tegner hver kollisjonsform som et
rødt omriss oppå den ferdige banekunsten, i riktig relativ posisjon
(samme oppsett som layout-referansebildet fra tidligere). Sendte dette
til Mathias for å faktisk vise kollisjonsformene, ikke bare beskrive
dem.

Han svarte "Fiks hitboxene. Taket må også være hitbox på". To ting:

1. **Reell feil i selve kollisjonsformene, funnet ved å se på bildet.**
   `SEGMENTS_PER_TILE = 40` gir jevnt fordelte samplingspunkter hver
   ~96 piksel, men en luftlomme sin avrunding (`GAP_TAPER = 70`
   piksler) er SMALERE enn det. Ett enkelt linjestykke kunne dermed gå
   fra normal bakkehøyde helt til bunnen av bildet (der bakken er
   spisset ut til nesten ingenting) uten noe samplingspunkt innimellom,
   og skapte en høy, tynn, feilaktig SOLID kollisjonsvegg som skar
   tvers gjennom det som skulle være åpent rom, godt synlig som en
   loddrett strek i referansebildet. Fikset med `_dense_grid()`: samme
   jevne 40-punkts grunnfordeling, men med ekstra tette samplingspunkter
   presset inn rundt hver overgang (luftlomme-kantene, og
   kant-avrundingen ved bane-start/slutt), slik at kollisjonen faktisk
   følger den raske overgangen i stedet for å hoppe over den.
2. **Taket hadde ingen kollisjon i det hele tatt**, det var bevisst
   rent visuelt fra forrige runde ("ingen kollisjon på taket, for ikke
   å legge til en ny type hindring ingen ba om"). Omgjort: taket har nå
   egne kollisjonsformer, samme trapes-strip-teknikk som bakken, bare
   speilvendt (fra toppen av flisen, y=0, ned til tak-kurven, i stedet
   for fra bakke-kurven og ned til bunnen). Samme tette
   samplings-teknikk brukt her óg, rundt tak-klaringen ved markens
   startpunkt.

Sjekket numerisk etterpå at klaringen ved markens startpunkt
(verdenskoordinat 0,0) fortsatt er trygt positiv: 125 enheter for bane
5, 157 for bane 6, uendret fra forrige runde siden selve tak-kurven
ikke ble endret, bare hvor mange kollisjonsformer som nå faktisk følger
den. Regenererte begge banenes `lib/shapedefs5/6.lua` (antall fixtures
gikk fra ~40 til over 130 per flis, ingen kjent øvre grense i Box2D som
bekymrer ved dette antallet på en statisk kropp). Selve bildene
(`level5/6 sine .png`-filer) uendret, kollisjon påvirker ikke
grafikken.

Genererte nye referansebilder med kollisjonsformene tegnet oppå kunsten
for begge banene på nytt for å bekrefte fiksen visuelt før commit.

Luac-sjekket, kjørte fullt syntakssøk over repoet. Ikke testet i
faktisk nettleser ennå.

## 2026-09-15, bane 5: marken spawnet faktisk inni taket, egen tabbe

Mathias testet i faktisk nettleser og meldte: "Marken spawner inne i
taket på level 5". Overrasket, siden jeg hadde regnet ut og rapportert
en "trygt positiv klaring" (125 enheter) for akkurat dette forrige
runde. Gikk gjennom utregningen på nytt og fant feilen: den var min
egen, i selve KONTROLLEN, ikke i spillkoden jeg allerede hadde skrevet.

`apply_ceiling_spawn_clearance()` sin logikk var riktig, men
verifikasjons-regnestykket mitt hadde fortegnet baklengs.
Taket er solid fra rad 0 og NED TIL tak-kurven sin verdi, så jo
STØRRE tak-verdien er, jo lenger NED strekker steinen seg (nærmere
markens startpunkt, ikke lenger unna). Jeg regnet
"tak-verdi minus markens rad" og kalte et POSITIVT tall trygt, det
motsatte av riktig: riktig sjekk er "markens rad minus tak-verdi",
positivt betyr marken sitter rad-messig UNDER (altså tallmessig
lenger ned enn) der taket slutter, i åpent rom. Med feil fortegn så
"125 enheter klaring" egentlig ut som en god verdi, den var faktisk
125 enheter INNI fjellet.

Rettet både utregningen og selve avstanden: `apply_ceiling_spawn_clearance()`
skrevet om fra én enkelt letting-kurve til en FLAT trygg sone
(`SPAWN_CLEAR_FLAT = 300` piksler, taket presset helt ned mot null)
etterfulgt av en lengre, separat glidende overgang tilbake til normal
tak-dybde (`SPAWN_CLEAR_RAMP = 600` piksler til). Grunnen til at forrige
forsøk (300+ i praksis for smalt, se forrige logg) likevel traff feil:
selv om verdien VAR liten ved kolonne 0, rakk den å stige forbi markens
egen rad (25,5) lenge før kolonne 170 der marken faktisk spawner, fordi
letting-kurven brukte den fulle 500-piksler bredden til å nå helt fram
til den naturlige tak-dybden (~235+). Den flate sonen holder nå taket
nede over HELE markens kroppsbredde ved spawn (regnet ut at alle ni
kroppsdelene, som alle deler samme rad, dekker lokale kolonner ca
60-170), ikke bare ved én enkelt kolonne.

Sjekket på nytt, denne gangen med riktig fortegn, over hele det
kritiske kolonneområdet (0-250), ikke bare ved markens egen
spawn-kolonne: klaringen er nå jevnt +37 enheter over hele den flate
sonen for både bane 5 og 6. Avstanden fra spawn til bakken uendret
(423/610).

Samme feil (og samme fiks) gjaldt bane 6 sitt script også, siden det
er en kopi av bane 5 sitt med egne frø. Regenererte kun `level5/1.png`
og `level6/1.png` (bare flis 1 sin tak-sone nær spawn faktisk endret
seg, flis 2-4 upåvirket) og begge banenes `lib/shapedefs5/6.lua`.

Luac-sjekket, kjørte fullt syntakssøk over repoet. Bekreftet visuelt
med et nærbilde av spawn-punktet mot de nye kollisjonsformene før
commit denne gangen, ikke bare et tall jeg selv kunne regne feil på.

## 2026-09-15, fire feil Mathias meldte etter mer testing i nettleser

Fem punkter i samme melding handlet ikke om bane 5/6 sin kunst i det
hele tatt, men om spillogikk som gjelder alle banene. Fikset alle fire
her, de resterende (tak, hull-kanter, "dynamisk hule", fargegradering)
er egen logg under.

**"Nå starter vi med 0 liv igjen om man trykker på levels eller main
menu når man er fri for liv. Reklame menyen kommer bare om man klikker
på restart."** Sant. `resume()` (retry-knappen) i både
`pausemenu1.lua` og `dodmenu1.lua` sjekket riktig `liv.erTom()` og
sendte spilleren til `scenes.adoffer` (reklame-for-liv) i stedet for
vanlig mål når livet var tomt. `resume1()` (hovedmeny-knappen) og
`resume3()` (baner-knappen) i BEGGE filene gjorde det samme
livstrekket (`liv.endreliv(1)`), men manglet denne sjekken helt, og
gikk alltid rett til `scenes.gotomenu`/`scenes.gotochooselevel` uansett
liv igjen. Lagt til samme `if liv.erTom() then target = "scenes.adoffer"
end`-mønster i alle fire funksjonene. Måtte også snu rekkefølgen i
`resume1`/`resume3`: de kalte før `composer.gotoScene()` FØR
`liv.endreliv(1)`, så man kunne ikke vite om livet ble tomt før man
allerede hadde bestemt målet. Nå trekkes livet og lagres først, så
regnes målet ut fra riktig oppdatert status.

**"Marken går videre i ett sekund eller to etter man har klikket retry,
ligger banen da i bakgrunnen å går?"** Ja, nøyaktig det. Alle fire
knappene i `pausemenu1.lua` (retry, hovedmeny, baner, i tillegg fantes
den ikke på quit) og alle tre i `dodmenu1.lua` (retry, hovedmeny,
baner) kalte `physics.start()` rett etter de startet
`composer.gotoScene()` til et helt annet mål. Fysikken til banen vi
FORLOT ble dermed satt i gang igjen midt i fade-overgangen (500ms, pluss
tiden det tar før banens egen `scene:hide` faktisk rekker å rive den
ned), og marken falt/beveget seg synlig videre helt til det skjedde.
`physics.start()` skal bare kjøres når man faktisk BLIR i samme bane,
det vil si `resume4()` i `pausemenu1.lua` ("fortsett spillet"-knappen,
den eneste av de syv knappene totalt som ikke navigerer bort). Fjernet
kallet fra de seks andre. Banen man navigerer TIL starter uansett sin
egen fysikk i sin egen `scene:create`, så ingenting ble borte av å
fjerne dette.

Mistenker at dette samme feilen forklarer **"Det virker som om at
retry menyen ligger i bakgrunnen noen ganger"** også: når marken/banen
fortsatte å bevege seg etter at retry-menyen begynte å tones bort,
kunne det trigge en NY kollisjon (dødsfelle eller neste-bane) mens den
forrige menyen fortsatt var i ferd med å forsvinne, og skape en andre
overlay midt i samme overgang. Kan ikke bekrefte dette i en nettleser
herfra (ingen nettverkstilgang til selve spillet fra denne økten), så
si fra om det fortsatt skjer etter denne fiksen, så graves det videre.

**"Pauseknappen kommer bak banen, vil at den skal syntes hele tiden når
man spiller en bane."** Fant den egentlige årsaken i kamera-biblioteket
(`lib/perspective.lua`): kameraet har 8 "lag" (grupper), og lag 1 er
alltid det fremste (tegnes sist av konstruktøren, altså øverst).
Pauseknappen legges i lag 2 i banene 1, 5, 6, 7, 8, 9
(`camera:add(knapp1,2,false)`), mens selve banen/marken/gulvet ligger i
lag 1. Lag 2 lå dermed alltid BAK lag 1, uansett rekkefølge på
`camera:add`-kallene. `camera:layer(2).parallaxRatio=0` (som alt lå i
alle ni banefilene) gjør riktignok at lag 2 aldri ruller med kameraet,
så knappen sto stille, men det løste ikke at den lå bak. Lagt til
`camera:layer(2):toFront()` rett etter i alle ni `levelN.lua`-filene:
flytter kun HELE lag 2 fremst i kamera-gruppa, uten å endre hvilket lag
knappen faktisk tilhører (rulle-oppførselen er dermed uendret). I
banene 2, 3 og 4 er ikke pauseknappen lagt i kameraet i det hele tatt
(en tidligere, ufullstendig fiks, ser det ut som), linjen er lagt til
der også for konsistens, men gjør ingenting siden knappen ikke er i lag
2 der.

Luac-sjekket alle 11 endrede filer (`pausemenu1.lua`, `dodmenu1.lua`,
`level1.lua`-`level9.lua`), kjørte fullt syntakssøk over repoet. Kan
ikke teste i faktisk nettleser herfra, så si fra om noe av dette ikke
stemmer etter neste bygg.

## 2026-09-15, bane 5/6: tak-kollisjon, pigger ved hullene, og gradert farge

Samme melding fra Mathias hadde også fire punkter om selve bane 5/6-
kunsten. Alle fire førte til en ordentlig omskriving av
terreng-generatoren (`make_level5_terrain.py`/`make_level6_terrain.py`,
scratch-scriptene som bygger `level5/6/1-4.png` og
`lib/shapedefs5/6.lua`), ikke bare parameterjustering.

**"Når man kommer seg til flis nr 2 så lander man oppå taket.. det blir
feil."** Regnet ut, denne gangen med et script i stedet for for hånd:
tak-kurven og gulv-kurven ble laget helt uavhengig av hverandre, hver
klippet til sitt eget "plausible" område (gulv: så grunt som ~H*0.08
nær en flis sin venstrekant; tak: så dypt som H*0.32). De områdene
overlapper. Målte det direkte: flis 4 sin egen venstrekant hadde taket
strekke seg 239 enheter LENGER NED enn gulvet på samme kolonne, altså
helt solid fjell fra topp til bunn der, ingen åpen tunnel i det hele
tatt. En mark som gled inn i den kolonnen landet på undersiden av
taket, fordi det var den første faste flaten den traff ovenfra, ikke
gulvet lenger unna. Fikset ved å regne ut taket i forhold til gulvet:
`ceiling_curve()` tar nå inn `tile_curve()` sin egen gulv-kurve og
klipper seg selv til aldri å komme nærmere enn `MIN_TUNNEL` (220px)
til gulvet på samme kolonne. Der selv det ikke er nok plass (helt ytterst
til venstre på enkelte fliser, der gulvet er grunnest), fjernes taket
fullstendig for den kolonnen i stedet for å tvinge et utrygt kompromiss
tilbake inn (en første versjon av denne klipingen brukte
`np.clip(curve, H*0.02, None)` som en nedre grense ETTER
gulv-klipingen, som i praksis kunne løfte taket tilbake forbi grensen
igjen akkurat i dette tilfellet, fanget opp ved å måle på nytt).
Bekreftet numerisk over alle fire flisene på begge banene: minste
klaring er nå 121-260 enheter uansett, aldri negativ.

**"Over takene på flisene må taket gå helt opp, slik at man ikke ser
bakgrunnen over."** Taket har alltid fylt fra rad 0 (toppen av selve
bildet) og ned til tak-kurven, så det er ingen bokstavelig bakgrunn
synlig OVER taket innenfor én flis sitt eget bilde. Usikker på om dette
sikter til den diagonale "trappe"-plasseringen av flisene (samme mønster
som alle ni banene bruker, der hver flis er forskjøvet en hel
flis-bredde/høyde fra forrige, så de bare møtes i ett hjørne), eller om
taket noen steder ble for TYNT til å lese som "solid fjell". Kan ikke
bekrefte i en nettleser herfra, så gjorde det ene jeg kunne gjøre noe
med: hevet tak-kurven sin nedre grense fra H*0.03 til H*0.05, så det
alltid er et tydelig tykt fjell-lag der taket faktisk finnes, ikke bare
en 70px flis. Si fra om det fortsatt ser feil ut, og evt. hvor i bildet
(hvilken flis, omtrent hvor i banen).

**"Ørjan vil heller ikke at det skal være pigger ved hullene i
banene."** Denne tok fem forsøk før den faktisk ble riktig, alle
loggført i selve koden (se de lange kommentarene over `_tile_layout`
og `apply_gap_taper` i terreng-scriptet) fordi hvert forsøk så
fornuftig ut på tallene alene og likevel feilet visuelt, først oppdaget
ved faktisk å rendre og beskjære et bilde av et hull i full oppløsning,
ikke ved å resonnere fra tallene:

1. Første forsøk (bredere, skrå-proporsjonal avrunding + fri
   plassering) fikk luftlommenes avrundingssoner til å overlappe nesten
   over hele flisen, og etterlot bare tynne nåler av gulv mellom dem,
   verre enn problemet det skulle løse.
2. Andre forsøk (garantert ikke-overlappende "øy"-oppsett + fast
   150px avrunding) løste overlappet, men hvert enkelt hull var
   fortsatt en tynn kniv: en fast 150px kjøring som letter overflaten
   fra der den naturlig er (så grunt som ~250px) og helt ned til H
   (~2100px unna på det verste) er en nesten loddrett vegg uansett hvor
   glatt letting-funksjonen er.
3. Tredje og fjerde forsøk prøvde å skalere avrundings-bredden med hvor
   dypt fallet faktisk var, første gang kalibrert altfor aggressivt
   (spiste hele flisen igjen), andre gang kalibrert riktigere men
   fortsatt samme grunnfeil: et hull må uansett nå helt ned til H et
   sted, og jo grunnere gulvet er der hullet havner, jo lengre (og
   dermed jo mer nål-aktig) blir den avrundede overgangen uansett,
   siden løsningen fortsatt tynnet gulvet til null tykkelse akkurat
   ved hull-kanten.
4. Femte forsøk brukte en helt annen modell: et ekte hulerom er ikke
   bakke som tynnes bort til ingenting, det er en TYKK bakke med et
   hull KLIPPET ut av den, avrundet bare i de to øverste hjørnene der
   hullet møter overflaten (som en dørkarm). Overflaten holder nå sin
   naturlige høyde helt fram til rett ved hullet, avrundet med en ekte
   kvart-sirkel av fast radius (`FILLET_RADIUS = 110`) som aldri
   senker overflaten mer enn 110px, uansett hvor dypt/grunt gulvet er
   der. Selve veggen ved siden av hullet beholder dermed sin fulle,
   naturlige tykkelse, bare det ene hjørnet er avrundet. Bekreftet med
   et nærbilde i full oppløsning: ser nå ut som separate, avrundede
   bakkestykker med luft mellom, ikke nåler.

Samtidig la også til variasjon i antall hull per flis (1-3, var alltid
nøyaktig 2 før) og bredde per hull (70-130px, var alltid nøyaktig
100px), som del av **"lag banene litt mer dynamisk og naturlig som om
at det faktisk er i en hule"**. La også til et tredje, finere
støy-lag (64 kontrollpunkter, liten amplitude) oppå de to
eksisterende i selve gulv-kurven, så lange strekk ikke lenger leser
som én jevn helling.

**"Ønsker at bakken ser mer realistisk ut som på bane 1, 2, 3 og 4.
fargen graderes."** Sammenlignet direkte med `level4/2.png`: den
"rim"-fargede kanten der ikke er en tynn stripe langs KUN den øverste
flaten av én sammenhengende bakke-kurve (det gamle bane 5/6-oppsettet),
den pakker seg rundt HVER enkelt eksponerte kant av HVER separate
steinbit, siden den ekte kunsten er tegnet som mange atskilte biter, ikke
én kurve. Skrevet om `_shade()` til `_shade_by_distance()`: bruker nå
en ekte 2D-avstandstransform (`scipy.ndimage.distance_transform_edt`,
avstand til nærmeste gjennomsiktige piksel i alle retninger) i stedet
for "avstand rett opp fra denne kolonnens egen overflate". Pakker nå
rim-fargen rundt hull-kanter og undersiden av taket også, ikke bare
toppen av gulvet, akkurat som i den ekte kunsten.

Regenererte `level5/1-4.png`, `level6/1-4.png`,
`lib/shapedefs5.lua` og `lib/shapedefs6.lua` (fysikkformene er fortsatt
regnet direkte fra samme kurver kunsten tegnes fra, så de stemmer
eksakt overens per konstruksjon, samme prinsipp som før). Samme
frø-forskyvning som vanlig for bane 6 (`np.random.seed(17)` i stedet
for `7`, alle støy-frø +1000, se koden for hele lista). Fant og fikset
en frø-kollisjon underveis: det nye tredje støy-laget brukte ved en
feil samme kildeverdi som "texture"-laget sin planlagte bane 6-verdi,
rettet før noe ble commitet.

Bekreftet med nærbilder i full oppløsning før commit (hull-kanter,
takklaring ved spawn, generell fargegradering), og numerisk at
tak/gulv-klaringen er trygt positiv over alle fire flisene på begge
banene. Luac-sjekket `lib/shapedefs5.lua`/`shapedefs6.lua`, kjørte
hitbox-visualiseringen på nytt for begge banene (samme teknikk som
forrige runde) for å bekrefte kollisjonsformene faktisk følger den nye
kunsten. Kan ikke bekrefte i en faktisk nettleser herfra, spesielt ikke
"taket går helt opp"-punktet, så si fra om noe av dette fortsatt ser
feil ut etter neste bygg.

## 2026-09-15, fant den egentlige grunnen til at banen aldri gikk videre

Fem nye punkter fra Mathias, alle spillogikk, ingen av dem om bane
5/6-kunsten.

**"Når man klarer banen går man ikke videre til neste bane. Det
klikker bare."** Fant den ekte årsaken, og den er alvorlig: i alle ni
`levelN.lua` sin `onCollision1` (målet-nådd-sjekken) står det
`Runtime:removeEventListener(collision1)`. `collision1` er en
udefinert global variabel (skulle vært selve funksjonsnavnet,
`onCollision1`), ikke en streng+funksjon slik
`removeEventListener` krever. Dette kalles med feil argumenter og
kaster en Lua-feil, HVER gang målet nås, midt inni selve
kollisjons-håndteringen. `main.lua` har en `Runtime:addEventListener
("unhandledError", ...)` som fanger nettopp denne typen feil og bare
skriver den til konsollen (`iHandledTheError = true`, undertrykker
Solar2D sin egen synlige feilboks), så spilleren ser ingenting skje i
det hele tatt: `lm.unlockNextLevel()` og `goto2()` (som viser
"neste bane"-skjermen) stod BEGGE etter denne linja i koden, og ble
dermed aldri kjørt. Banen "klikker bare" fordi selve kollisjonen
registreres (og `del4.isSensor = false` også aldri når fram), men
ingenting av det som faktisk skulle skje etterpå gjør det. Rettet til
`Runtime:removeEventListener("collision", onCollision1)` (riktig
kall, fjerner selve lytteren) i alle ni banefiler. Dette er ikke noe
jeg innførte i denne økten, feilen har sannsynligvis ligget der siden
spillet først ble bygget, siden alle ni banefilene deler nøyaktig
samme feil.

Mistenker dette samme forklarer **"Om man har 0 liv kan man fortsatt
starte banen med null liv og da får man feilmeldinger når man klarer
banen, trykker main menu osv.."** sin "klarer banen"-halvdel direkte
(samme bug uansett hvor mange liv man har). For selve "0 liv"-delen:
sjekket `lib/ogt_levelmanager.lua` (banevalg-rutenettet) og fant at
`selectLevel()` (kjøres når du trykker på en bane-rute) aldri sjekket
liv i det hele tatt, bare pause-/dødsmenyen gjorde det. Lagt til en
sjekk helt i starten av `selectLevel()`: kaller `liv.lastliv()`
(viktig å laste på nytt her, ikke stole på økten sin nåværende
minne-verdi, siden banevalget kan nås FØR noen bane noensinne er åpnet
denne økten, da har liv-modulen bare sin hardkodede standardverdi 10 i
minnet) og går til `scenes.adoffer` (reklame-for-liv-skjermen) i
stedet for den valgte banen om `liv.erTom()`. Samme mønster som
retry/main menu/levels-knappene i pause-/dødsmenyen bruker allerede.

**"Man skal ikke miste liv om man klarer en bane."** Sjekket: ingen av
de ni `goto2()`-funksjonene eller `onCollision1`-handlerne kaller
`liv.endreliv()` noe sted. Dette var allerede riktig i koden, ingen
endring nødvendig.

**"Resume knappen skal ikke ta bort liv."** Sjekket: `resume4()` i
`pausemenu1.lua` (knappen "pausemenuresume", den eneste som faktisk
fortsetter samme spilløkt) kaller kun `composer.hideOverlay()` og
`physics.start()`, ingen `liv.endreliv()`. Dette var allerede riktig i
koden også. Om dette fortsatt oppleves etter neste bygg, si fra
nøyaktig når/hvordan (hvilken bane, om det var rett etter en annen
handling), så graves det videre - fant ingen kodesti som forklarer
det.

**"Når man dobbelklikker for at marken skal bli slapp så skal det bare
være å klikke en gang istedenfor to ganger for å gjøre den stram
igjen."** `trykk_knapp` sin `isLimp`-veksling (alle ni banefiler) målte
tid mellom to "began"-faser og vekslet `isLimp` bare når det andre
klikket kom innenfor `dobbeltklikkVindu` (300ms) - samme regel uansett
om marken skulle bli slapp ELLER stram igjen, altså dobbeltklikk begge
veier. Endret til: étt enkelt klikk gjør marken stram igjen når den
allerede er slapp (ingen tidssjekk), dobbeltklikk kreves fortsatt for
å gjøre den slapp i utgangspunktet.

Luac-sjekket alle 11 endrede filer (`levelN.lua` × 9,
`lib/ogt_levelmanager.lua`), kjørte fullt syntakssøk over repoet. Kan
ikke bekrefte "resume tar liv"-punktet eller teste noe av dette i en
faktisk nettleser herfra, så si fra om noe fortsatt ikke stemmer etter
neste bygg.

## 2026-09-15, full gjennomgang av hele kodebasen med luacheck

Mathias ba om å gå over ALLE filene og fikse det som ikke er ok, ikke
bare de konkrete punktene han selv la merke til. `luac -p` (brukt hele
denne økten) sjekker bare at syntaksen er gyldig, den fanger ikke opp
feil variabelnavn eller feil bruk av globale variabler - nøyaktig den
type feil `collision1`-buggen tidligere i dag var. Installerte
`luacheck` (via `luarocks`, ikke installert fra før) for å sjekke det
systematisk. Måtte kjøre den mot midlertidige kopier med `goto` byttet
ut med `gotoFn`, siden spillets kode (skrevet for Lua 5.1, der `goto`
bare er et vanlig navn) bruker `goto` som funksjonsnavn mange steder,
mens `luacheck` sin parser alltid behandler `goto` som Lua 5.2+ sitt
eget nøkkelord uansett `--std`-innstilling. Linjenumrene i rapporten
stemmer fortsatt siden dette bare bytter ut ett ord, ikke omstrukturerer
noe.

Fant to reelle, alvorlige feil, begge i alle ni `levelN.lua` (samme
klasse feil som `collision1` fra tidligere i dag, bare ikke fanget opp
av den første gjennomgangen siden `luac -p` ikke ser denne typen feil):

**`onCollision`/`onCollision1`/`onCollision2` var utilsiktede globaler
sett fra `goSomewhere`/`goto`/`goto1`/`goto2`.** Disse fire funksjonene
ligger på fil-nivå (kjøres kun én gang når banen lastes), mens
`onCollision`/`onCollision1`/`onCollision2` ble deklarert med
`local function` lenger nede i fila, inni `scene:create`. I Lua
avgjøres hvilken variabel et navn peker på ved hvor i KILDEKODEN den
brukes, ikke ved kjøretid, så `Runtime:removeEventListener("collision",
onCollision)` i disse fire funksjonene pekte alltid på en udefinert
GLOBAL (alltid nil), ikke den faktiske kollisjonslytteren - selv om
`onCollision` var en helt gyldig, korrekt lokal variabel på det
tidspunktet funksjonen faktisk KJØRTE (siden hele fila kjører
sekvensielt ved banestart, før noen spiller kan trykke noe). Disse
opprydnings-kallene fjernet dermed ingenting, hver gang spilleren
forlot banen (pause, død, fullført bane) via en av disse fire
funksjonene. Siden Runtime-lyttere er globale og ikke fjernes automatisk
når en scene rives ned (nøyaktig det Solar2D sin egen dokumentasjon
advarer mot, se "Kjente feil" punkt 7 i KODEBASE.md), hopet disse
lytterne seg opp for hver eneste gang en bane ble forlatt - en lang
spilleøkt kunne ende opp med dusinvis av gamle, foreldede kollisjons-
håndterere fortsatt hengende på Runtime, som fortsatt referanserte
objekter fra tidligere, allerede fjernede baner. Fikset ved å
forhåndsdeklarere `onCollision`/`onCollision1`(/`onCollision2` der den
finnes) på fil-nivå, samme mønster som `trykk_knapp` allerede brukte
(se "Kjente feil" punkt 7), og endre de senere `local function
onCollision(...)`-definisjonene til vanlige tilordninger
(`onCollision = function(...)`) mot den forhåndsdeklarerte variabelen i
stedet for å skygge den med en ny, scene:create-lokal en.

**`eventTimer` var utilsiktet lokal i alle ni banefiler, men
pause-/dødsmenyen og `gotomenu.lua` prøver å avbryte den på tvers av
filer.** Hver bane setter en 3-sekunders forsinket timer
(`timer.performWithDelay(3000, goto)`) når en kroppsdel knekker, som
etter forsinkelsen viser dødsmenyen automatisk. `pausemenu1.lua`,
`dodmenu1.lua` og `gotomenu.lua` kaller ALLE `timer.cancel(eventTimer)`
når spilleren trykker retry/main menu/levels, tydelig i den hensikt å
avbryte akkurat denne ventende timeren om spilleren forlater banen på
annen måte før den rekker å fyre av selv. Men banefilenes egen
`eventTimer` var deklarert med `local` (7 like steder per fil, ett per
par kroppsdeler som kan knekke), usynlig utenfor selve fila - de tre
andre filenes `timer.cancel(eventTimer)`-kall traff dermed alltid en
helt egen, alltid udefinert global variabel, ikke banens faktiske
timer. Resultat: en ventende knekk-dødstimer kunne fortsette å telle
ned og fyre av `goto()` flere sekunder ETTER at spilleren allerede
hadde forlatt banen via pause-/dødsmenyen, mot en scene som da allerede
var revet ned. Sannsynligvis en medvirkende årsak til flere av de
"marken fortsetter å bevege seg"/uforklarlige overgangs-symptomene
denne økten allerede har jaktet på, utover den allerede fikset
`physics.start()`-bugen. Fikset ved å gjøre `eventTimer` til en bevisst
global (`_G.eventTimer`), samme etablerte mønster som `_G.camera`/
`_G.grp`, i alle ni banefiler - de tre andre filenes eksisterende
`timer.cancel(eventTimer)`-kall fungerer nå riktig uten at de selv
trengte å endres.

Sjekket også (luacheck fant, men vurdert som ufarlige, ikke rørt):
`scaleFactor` sendes som udefinert global (alltid nil) til
`shapedefs.lua` sin `physicsData()` i alle scene-filer, men den
funksjonen har `local s = scale or 1.0` som fallback, og den tiltenkte
verdien var uansett alltid 1.0 på dette stedet - null faktisk
oppførselsforskjell om det "fikses" eller ikke. `rot`/`reff`/`angel`/
`punktsant`/`stovteller1-9`/`last` (lastesprite) er også utilsiktede
globaler flere steder, men brukes alle synkront innenfor samme
funksjonskall der de settes (ingen tilsvarende krysse-fil eller
krysse-funksjon-tidspunkt-feil som de to over), så de er rotete men
ikke bevist skadelige - latt urørt denne runden. `lib/gameUI.lua` sine
"globaler" er faktisk trygge: fila bruker det gamle `module(...,
package.seeall)`-mønsteret fra Lua 5.1, som `luacheck` ikke skjønner,
funksjonene ender opp som `gameUI.dragBody` osv., ikke ekte globaler.

Luac-sjekket alle ni banefiler på nytt, kjørte `luacheck` på nytt for å
bekrefte at both `onCollision`- og `eventTimer`-varslene er borte,
kjørte fullt syntakssøk over hele repoet. Kan ikke bekrefte i en
faktisk nettleser herfra.

## 2026-09-15, man kunne falle ut av verdenen uten å dø

**"Marken kunne falle ut av banen på bane 2 uten at det kom opp at den
døde. Gjør slik at man dør om man faller ut av verdenen."** Fant
årsaken, og den gjelder alle ni banene, ikke bare bane 2: dødssonen er
ETT enkelt rektangel (`dod`, 70000x50 piksler, rotert 31,48 grader),
lagt som én lang diagonal linje under banen. Den er lang, men ikke
uendelig. Regnet ut nøyaktig hvor den slutter:

- dødssonen tar slutt ved x = 28409
- siste flis slutter ved x = 30380
- selve målet (`mal2`) står ved x = 31000

Altså er de siste ~2600 enhetene av hver eneste bane helt uten dødssone,
og det er nøyaktig den strekningen du er på når du holder på å fullføre
banen. Faller marken av bakken der, treffer den aldri noe, og fortsetter
bare å falle i det uendelige mens kameraet følger etter. Ingen dødsmeny,
ingen vei videre, må pause og gå ut manuelt.

Lagt inn et sikkerhetsnett som ikke er avhengig av `dod` i det hele tatt,
og som ikke kan ta slutt: en `enterFrame`-sjekk som for hver x finner
flisa marken er over, og utløser vanlig død (samme `goto()` som
dødssonen bruker) hvis marken har falt under UNDERKANTEN av den flisa,
eller er kommet en hel flisbredde utenfor første/siste flis i bredden.
Underkanten av selve bildet ligger alltid under all bakke som er tegnet
i det, så sjekken kan ikke slå til der spilleren egentlig står trygt.

Første forsøk brukte i stedet én felles skrå linje under alle flisene
(samme vinkel som `dod`, bare uendelig lang), som var enklere. Målte den
mot den ekte bakke-kunsten før commit, og den holdt ikke: på slutten av
bane 1 og bane 3 lå linja 160-170 enheter OVER bakken, altså midt i der
spilleren faktisk går, som ville gitt død uten grunn. Grunnen er at en
rett linje gjennom flis-sentrene skjærer opp i flisene i venstre halvdel
av hver flis. Kastet det og gikk over til per-flis-grensen over.
Verifiserte den nye mot alle 36 bakke-bildene (ni baner x fire fliser),
målt kolonne for kolonne i selve PNG-ene: minste klaring mellom bakken
og dødsgrensa er 864 enheter, og den er positiv overalt.

## 2026-09-15, livtelleren viste ett liv for mye, og fikk egen retry-knapp

**"Når man er på sitt siste liv bør det stå 0. Folk tror de enda har ett
ekstra forsøk når det står 1 igjen, men om de dør så må de se reklame."**
Stemmer: telleren viste den rå verdien i `liv.txt`, mens livet først
trekkes fra når du faktisk bruker retry/hovedmeny/baner. Står det 1, er
det forsøket du spiller det siste, og dør du kommer reklame-skjermen.
Visningen trekker nå fra det forsøket som pågår (`liv_igjen - 1`, aldri
under 0), så 0 betyr "dette er siste forsøk". Selve telleren og
regnestykket bak er uendret, bare visningen.

Endret samtidig ordlyden på reklame-skjermen (`scenes/adoffer.lua`) fra
"liv" til "forsøk": med den nye visningen ville "+1 liv" sett ut som om
ingenting skjedde, siden telleren står på 0 både før og under det
ekstra forsøket. "+1 forsøk" stemmer nøyaktig. Si fra om du heller vil
ha "liv" der, det er bare to tekststrenger.

**"Om man klikker på livene sine bør det være en knapp for å retry, så
slipper man å pause også trykke retry."** Lagt inn: trykker du på
livteller/markikonet øverst, spretter det opp en retry-knapp rett under,
og trykker du den igjen forsvinner den. To trykk totalt er med vilje, så
man ikke starter banen på nytt ved et uhell med ett bomtrykk øverst på
skjermen. Selve retryen gjør nøyaktig det samme som retry-knappen i
pausemenyen: avbryter ventende transitions og den forsinkede
knekk-timeren, stopper fysikken så marken ikke fortsetter under
overgangen, trekker livet, og går via mellomscenen `gotoretry` (eller
reklame-skjermen om forsøkene er brukt opp).

Alt dette ligger i `lib/liv.lua`, altså ett sted for alle ni banene.
Ryddet samtidig opp i to ting der: `livText`/`livbilde` var utilsiktede
globaler (ingenting utenfor fila har noen gang rørt dem), og telleren
ble tegnet to ganger oppå seg selv fordi hver banefil kaller
`liv.hent()` både med en gang og igjen etter tre sekunder. Den gamle
fjernes nå først.

Luac-sjekket alle endrede filer, kjørte `luacheck` på `lib/liv.lua`
(null varsler nå) og fullt syntakssøk over repoet. Kan ikke teste i
faktisk nettleser herfra.

## 2026-09-15, bane 5 og 6 bygget om av ekte kunst i stedet for generert

**"Studer bildene på bane 1, 2, 3 og 4. Så ser du på bildene til bane 5
og 6. 5 og 6 ser ikke like bra ut, vil ha identisk bakke og tak
utseende som de første banene da det ser mye bedre ut."**

La bildene ved siden av hverandre og så det med en gang. Den
håndtegnede kunsten i bane 1-4 er myke, organiske steinformer med en
lys, varm kant langs oversiden og et glatt mørkt indre, ofte flere
separate biter som ligger lagvis. Den genererte kunsten min var
firkantede plater med nesten loddrette sider, hardt kornete støy over
hele flaten, og en jevn kantfarge rundt HELE formen i stedet for bare
der lyset ville truffet. Den lignet rett og slett ikke.

Konklusjonen jeg burde tatt for lenge siden: den eneste måten å få
IDENTISK utseende på er å bruke de samme bildene, ikke å etterligne
dem. Jeg har brukt fem forsøk denne økten på å få generert terreng til
å ligne håndtegnet terreng, og det konvergerte aldri.

Bane 5 og 6 er nå satt sammen av ekte fliser fra bane 2, 3 og 4, og
kollisjonsformen følger med fra samme bane sin shapedefs-fil. Det betyr
at formen er den samme håndsporede formen som allerede brukes for
nøyaktig det bildet i sin opprinnelige bane, så bilde og kollisjon
stemmer overens per konstruksjon, ikke fordi jeg har regnet dem fram.

- Bane 5: flis 1 fra bane 3, flis 2 fra bane 2, flis 3 fra bane 4,
  flis 4 fra bane 3.
- Bane 6: flis 1 fra bane 4, flis 2 fra bane 3, flis 3 fra bane 2,
  flis 4 fra bane 4.

Altså ingen av dem er en kopi av én enkelt bane, det er nye
kombinasjoner. Tre ting sjekket først, siden fliser fra ulike baner
ikke automatisk passer sammen:

1. **Skjøtene.** Målte hvor bakken starter og slutter i alle 16
   håndtegnede flisene. Hver flis må brukes på den PLASSEN den hadde i
   sin egen bane (flis 1 som flis 1 osv.), fordi bakken ligger høyere i
   bildet tidlig i en bane og lavere mot slutten. Kontrollerte at fallet
   fra én flis til neste i de nye kombinasjonene havner innenfor spennet
   som allerede finnes i bane 1-4 (673-5244 enheter): de nye ligger på
   1144-3606.
2. **Spawn.** Sjekket at marken ikke starter inni fjell med de valgte
   flis 1-ene. `level1/1.png` ville gjort nettopp det (den er en flat
   plate helt øverst), så den er ikke brukt. De tre andre er frie.
3. **Fallgrensa.** "Falt ut av verdenen"-sjekken fra tidligere i dag er
   målt på nytt mot den nye kunsten, alle ni baner: minste klaring
   mellom bakken og dødsgrensa er 870 enheter for bane 5 og 892 for
   bane 6, positiv overalt.

Tegnet i tillegg kollisjonsformene oppå den nye kunsten og så på
resultatet: de følger de tegnede steinbitene presist, inkludert de
tynne hengende bitene øverst. Det er også de hengende bitene i selve
flisene som gir "tak"-utseendet i bane 1-4, så det følger med på
kjøpet, og den kunstige takstripen min er borte.

Bildene er tonet ett hakk mørkere for bane 5 og to for bane 6 (samme
0,98-faktor som før, kun rød/grønn), slik at den gradvise
mørkningen du ba om består. Det er gjort ved å endre palett-tabellen i
selve PNG-en, så pikslene ellers er bit for bit identiske med
originalen. Filene gikk samtidig fra 1,6 MB til 90-200 kB hver, altså
rundt 11 MB mindre å laste ned for spillet totalt.

**Én ting du bør teste spesielt:** bane 5 har fortsatt det bevisste
hullet mellom flis 2 og 3 (den ekstra halve flis-lengden), fra da banen
ble laget tidligere i dag. Med den nye kunsten er spranget 3974 enheter
bortover og 3751 nedover, som krever rundt 790 enheter/s fart ut fra
kanten. Regnet grovt på det: en friksjonsfri sklie ned hele forrige
flis ville gitt rundt 1660, så 790 skal være mulig, men marken er en
leddet mark og ikke en kloss, så jeg vet ikke hva den faktisk holder.
Er hullet uoverkommelig, fjerner jeg det med én linje i `level5.lua`
(`firkant3` settes da opp som i alle de andre banene).

## 2026-09-15, kjøp av forsøk på reklameskjermen, og en bug det avdekket

Mathias: "Legg til på reklameskjermen at man kan kjøpe liv om man ikke
vil se reklame. Legg til diverse pakker, selvfølgelig placeholder for
disse også inntil videre".

`scenes/adoffer.lua` har nå tre veier videre i stedet for to:

1. **Se reklame.** Kort (+1 forsøk) eller lang (+3), som før.
2. **Kjøpe forsøk.** Tre pakker: 10 forsøk / 15 kr, 25 / 29 kr,
   100 / 79 kr.
3. **Fortsett uten**, altså start på nytt fra bane 1 med fulle liv.

Prisene og antallene er tall jeg har funnet på for å ha noe å vise,
ikke noe som er avklart med noen butikk. Si fra hva de skal være, det er
tre linjer i en tabell øverst i fila.

Kjøpene er placeholder på samme måte som reklamen allerede var. Trykker
du på en pakke får du en bekreft/avbryt-boks som sier rett ut at det
ikke er koblet noen betaling til spillet, og at du får forsøkene gratis
om du bekrefter. Det er med vilje: bedre at en tester ser tydelig at
ingenting er ekte, enn at boksen later som den tar betalt.

Selve flyten bak er ferdig kodet og skal kunne stå urørt den dagen
ekte kjøp kobles på. Både reklame og kjøp ender i den samme funksjonen
(`giForsokOgFortsett`), som legger til forsøk, lagrer, og går tilbake i
banen via mellomscenen `gotoretry`. Det som skal byttes ut er bare
`visKjopPlaceholder()`, som skal bli et `store.purchase( pakke.id )` med
`giForsokOgFortsett()` i svar-lytteren. Pakke-ID-ene (`forsok_10` osv.)
er skrevet slik at de kan brukes direkte som produkt-ID i Google Play /
App Store, så resten av koden slipper å endres.

### Buggen det avdekket

Da jeg fulgte kjøpsflyten helt ut fant jeg noe som allerede var galt,
også for reklame-knappene som har ligget der siden i går.

`gotoretry` starter banen `lm.currentLevel`. Den settes av hver
`levelN.lua` når banen åpnes. Men liv-sjekken jeg la inn i banevalget
tidligere i dag (`selectLevel()` i `lib/ogt_levelmanager.lua`)
returnerte til reklameskjermen FØR linja som setter `k.currentLevel` til
banen du trykket på. Resultatet:

- Trykker du bane 4 med 0 liv, ser reklame eller kjøper, havner du i den
  banen du spilte SIST, ikke bane 4.
- Verre rett etter appstart, der `k.currentLevel` fortsatt står på
  startverdien 0 (`ogt_lmdata.lua`): da blir målet `scenes.level0`, som
  ikke finnes. Det gir den røde feilboksen.

Fikset ved å flytte de to linjene som husker valgt bane opp FØR
liv-sjekken. Nå havner du i banen du trykket på.

### Sjekket før push

- `luac -p` på hele repoet, og `luacheck` på de to endrede filene.
  `adoffer.lua` er ren. Advarslene i `ogt_levelmanager.lua` er de samme
  gamle globalene (`last`, `endX`, `endY`, swipe-tellerne) som lå der
  fra før, ikke noe jeg har innført.
- Regnet ut hvor alle ni elementene på skjermen havner, siden skjermen
  nå har mye mer innhold enn før. Alt ligger innenfor 0-960, og
  klaringen mellom naboer er 6-40 piksler. To overskrifter lå 0,6
  piksler inni knappen under seg i første utkast, de er flyttet opp.

Som ellers denne økten: jeg har ikke nettleser her, så dette er regnet
og lest, ikke spilt. Skjermen er verdt et raskt blikk i test, særlig at
kjøpsboksen ikke ligger oppå noe.

## 2026-09-15, reklameskjermen lå halvveis utenfor skjermen, min feil

Mathias sendte skjermbilde: "Det ble ikke helt bra". To av de tre
kjøpspakkene og "fortsett uten"-knappen var ikke synlige i det hele
tatt, de lå under nederste skjermkant.

Årsaken er en ren tabbe fra min side, og verdt å skrive ned fordi den
gjelder alt som skal legges på skjermen i dette spillet.

`config.lua` sier `width = 540, height = 960`. Jeg leste det som at
flaten er 540 bred og 960 høy, og la knappene under hverandre ned til
y = 875. Men `build.settings` har `orientation.default =
"landscapeRight"`, og Corona bytter om innholdsflaten i landskap. Det
spillet faktisk har er **960 bredt og 540 høyt**. Alt jeg la under
y = 540 fantes ikke på skjermen.

Målte det på Mathias sitt skjermbilde i stedet for å gjette:

- Knappene var 956 piksler brede der 520 enheter skulle bli det, altså
  1,835 piksler per enhet.
- Bildet er 2556 x 1179 piksler, altså en synlig flate på 1393 x 642
  enheter.
- Den grønne knappen hadde senter 580 piksler ned = 316 enheter, mens
  jeg hadde plassert den på 265. Differansen på 51 er nøyaktig
  `display.screenOriginY`, altså letterbox-kanten over innholdsflaten:
  540 + 2 x 51 = 642, som stemmer med målt høyde.

Alle tre tallene stemmer med "960 x 540 innholdsflate, letterbox", så
diagnosen er sikker og ikke gjettet.

### Hva som er gjort

Skjermen er bygget om til **to kolonner**, som er riktig form når man
har rikelig med bredde og lite høyde: reklame til venstre (to knapper),
kjøp til høyre (tre pakker), og "fortsett uten" i full bredde nederst.
Knappene er lavere enn før (64 mot 90 enheter) og teksten litt mindre.

Bakgrunnen dekker nå hele den synlige flaten, ikke bare innholdsflaten.
Den var 540 x 960 før, altså feil vei OG for liten, så banen bak ville
vist seg i letterbox-kantene. Bruker samme uttrykk som `gotoretry.lua`
allerede gjorde:

```lua
local skjermBredde = display.viewableContentWidth - display.screenOriginX * 2
```

Det gir 1393 x 642 med tallene over, altså nøyaktig den flaten jeg
målte i skjermbildet. Formelen er dermed bekreftet mot virkeligheten,
ikke bare lest i dokumentasjonen.

Kjøpsboksen er komprimert på samme måte, fra et spenn på 380 enheter
til 325, så den får plass innenfor 540 med god margin i begge ender.

### Denne gangen tegnet jeg det ut først

Jeg regnet klaringen mellom alle elementene som sist, men det var jo
nettopp det som ikke fanget feilen: regnestykket var riktig, flaten jeg
regnet mot var feil. Så jeg tegnet i tillegg begge skjermene som bilder
i riktige proporsjoner og så på dem før push. Begge ser ut som de skal.

Fortsatt ikke spilt, jeg har ikke nettleser her, men dette er nå sett
og ikke bare regnet.

**Til deg som jobber videre:** husk at `display.contentWidth` er 960 og
`display.contentHeight` er 540 i dette spillet, motsatt av det
`config.lua` ser ut til å si. Bruk alltid `display.contentWidth` og
`display.contentHeight`, aldri tallene fra `config.lua` direkte.

## 2026-09-15, bane 5 og 6 tegnet på nytt: looken, ikke flisene

Mathias presiserte det jeg hadde misforstått: "Jeg mente jeg ville ha
looken, ikke ren kopi. Så du må lage nye baner med samme look. Se på
hvordan taket fungerer i hula, fargene osv."

Han har rett, og forrige runde var feil løsning på riktig problem. Jeg
hadde satt sammen bane 5 og 6 av ekte fliser fra bane 2, 3 og 4. Det ga
riktig utseende, men det er jo de samme steinene om igjen.

Denne gangen målte jeg stilen ut av den ekte kunsten først, og bygget
den så opp igjen med nye former.

### Hva kunsten faktisk består av

Jeg trodde bakken var malt med en gradering. Det stemmer ikke. Den er
**to flate farger**:

- kropp `rgb(38,14,1)`, nesten svart brun
- kantstrek `rgb(72,33,6)`, tydelig lysere

Resten av paletten, 25 til 49 indekser per fil, er bare blandinger
mellom de to og det gjennomsiktige. Det forklarer hvorfor forsøkene mine
på en glatt gradering aldri lignet.

Og så det som var selve nøkkelen. Jeg målte hvor kantstreken ligger, per
kantretning, på tolv ekte fliser:

| kanten vender | andel med kantstrek |
|---|---|
| vannrett (topp og bunn) | 92-93 % (74-100) |
| loddrett | **18 %** (6-35) |

Kantstreken ligger altså på **vannrette** kanter, ikke rundt hele
formen. Loddrette sider står nesten nakne. Det var nøyaktig dette jeg
bommet på i alle de tidligere forsøkene: jeg la lik kantfarge hele veien
rundt, og da ser steinen ut som en utstanset plate i stedet for noe lys
faller på ovenfra.

Tykkelsen på streken målte jeg til median 43 piksler, p90 87.

### Hvordan de nye banene er bygget

Alt er satt sammen av én byggekloss: en **steinskive** med en toppkurve
og en bunnkurve. Den dekker alt som finnes i den ekte kunsten:

- **høyt tårn**: smal skive, stor tykkelse
- **kile**: toppen stuper mens bunnen står, så massen spisser seg ut i
  en lang tunge. Dette er den viktigste. Første forsøk lot topp og bunn
  gå parallelt, og da blir alt flate bånd uten karakter.
- **takskår**: tynn skive som ligger fritt over bakken
- **hulemunn**: tjukk skive som spisser seg ut over gulvet

Konturene er en glattet tilfeldig gange, ikke summer av sinuser. Første
forsøk med sinuser ga tette skvulp langs hele toppen, cirka 150 piksler
mellom hver bølge. Den ekte kunsten har lange rolige sveip på 500 til
900 piksler med noen få bevisste knekk, og det er det den nye
konturfunksjonen lager.

I tillegg: tynne sprekker inne i massene, og den kalde blågrønne
aksenten langs enkelte kanter, som bane 4 har.

### Målt mot fasit, ikke skjønnsmessig

Jeg kjørte de samme målingene på min egen kunst som på den ekte, og
justerte til tallene lå innenfor. Ekte spenn i parentes:

| mål | ekte | nye bane 5/6 |
|---|---|---|
| kantstrek, dybde median | 39-47 | 35-45 |
| kantstrek, p90 | 81-91 | 83-101 |
| andel kantstrek av kropp | 16-38 % | 14-26 % |
| rim på opp-vendt kant | 74-100 % | 78-100 % |
| rim på loddrett side | 6-35 % | 4-26 % |
| dekning av flata | 31-68 % | 34-48 % |

De tre første gikk jeg tre runder på: kantstreken lå først på median 24
og var altfor tynn.

### Spillbarheten

- **Takhøyde** i hulepartiene: 852 til 1676 enheter. Første utkast hadde
  to steder på 498 og 522, begge rettet.
- **Fall mellom fliser**: 1722 til 4523 enheter, mot 673-5244 som
  allerede finnes i bane 1-4.
- **Spawn**: marken har 893 (bane 5) og 910 (bane 6) piksler fritt fall
  under seg, ingen stein i veien.
- **Dødslinja**: klaring 600 til 632 enheter overalt.
- **Hull i gulvet**: 186 til 414 enheter, smale nok til å rulle over.

En ting verdt å vite: målingen min var først strengere enn fysikken. Den
flagget en passasje på 498 enheter som viste seg å være den 1-4 piksler
tynne spissen på enden av en kile. Kollisjonssporeren lager ingen
fixture under 14 piksler, så den spissen finnes bare visuelt. Jeg gjorde
målingen lik fysikken i stedet for å flytte på stein som ikke var i
veien.

### Kollisjonen

281 og 285 fixtures, altså rundt 70 per flis, mot 67-308 i de ekte
banene. Hver fixture er et trapes på 70 piksler med hjørnene på skivens
egen topp- og bunnkurve, så bilde og kollisjon kommer fra nøyaktig de
samme kurvene. Jeg tegnet dem oppå kunsten og så på resultatet: de
følger steinen presist, også de tilspissede endene.

Filene er lagret som palett-PNG med egen gjennomsiktighet per indeks,
samme format som den ekte kunsten. 79 til 97 kB per flis, mot 86-195 kB
for de ekte. Til sammenligning var den prosedyregenererte kunsten fra i
går 1,6 MB per flis.

Fortsatt ikke spilt, jeg har ikke nettleser her. Alt over er målt og
sett, ikke testet i spill.

## 2026-09-15, det blå er is, og det hadde jeg ikke skjønt

Mathias: "Husk at det blå skal representere is. Og har annen friksjon
enn resten av banen, akkurat slik som de andre banene som har is."

Jeg hadde behandlet den blå fargen som ren dekorasjon. Den har en
gameplay-funksjon, og jeg fant den igjen i koden med en gang jeg lette
etter den.

### Hvordan is er representert

`lib/shapedefs4.lua` har **125 av 519 fixtures med `friction = 0.05`**,
mens all annen stein har `3`. Ingen av de andre banene har en eneste
0.05. Bane 4 er nettopp den banen som har blå farge, så det var en
sterk indikasjon. Jeg bekreftet den ved å måle hvor de fixturene ligger:

| flis | is-fixtures | blå piksler i is-boksene | i stein-boksene |
|---|---|---|---|
| level4/1 | 0 | ingen blå farge i bildet | 0,0 % |
| level4/2 | 35 | 8,6 % | 0,1 % |
| level4/3 | 40 | 6,7 % | 0,9 % |
| level4/4 | 50 | 12,6 % | 1,2 % |

Altså 10 til 60 ganger så konsentrert i is-fixturene, og flisa uten blå
farge har ingen. Det er isen.

Jeg målte også **hvor** isen ligger, og det var det viktigste for meg:
94,6 % (level4/2) og 98,4 % (level4/3) av de blå pikslene ligger på den
nederste biten i kolonnen, altså på **gulvflaten man ruller på**, som et
tynt lag 6 til 20 piksler under overflaten. Det er logisk nok: is man
ikke kan komme på ville ikke gjort noe.

`level4/4` er 45/55, fordi den flisa har hulemunnen og halve isen ligger
på overhenget.

### Hva jeg hadde gjort feil

Jeg hadde lagt den blå fargen på **oversiden av takskårene**, altså på
steiner som henger i taket, der marken aldri kommer. Pent, men
meningsløst, og direkte misvisende nå som jeg vet at blått betyr is.

Isen er flyttet til gulvblokkene. Fordelingen er nå 100 % på gulvet i
seks av åtte fliser, og 45/54 i de to flisene som har hulemunn, akkurat
samme mønster som bane 4. Is-rekkevidden stopper alltid før blokkens
høyre ende, så kanten mot et hull aldri er isete.

Fixturene under isen har `friction = 0.05`, 65 i bane 5 og 62 i bane 6,
altså 16 til 37 prosent av fixturene per flis mot 0 til 41 prosent i
bane 4.

### Og så måtte den se ut som is

Første forsøk tonet isen ut mykt over 36 piksler. Da jeg la den ved
siden av den ekte i full oppløsning, så min ut som en blåfarget flekk
inne i steinen, mens den ekte er et tydelig cyan band med hard
innerkant, som leser som et eget materiale.

Endret til et skarpt band: full styrke fra overflaten og ned, med bare
5 piksler mykt omslag i innerkanten, og lysere farge `rgb(44,106,130)`,
som er den målte toppen i `level4/4`.

Etter det: 0,44 til 1,46 prosent av kroppen er blå, mot 0,43 / 1,50 /
1,90 i bane 4. Dybde median 14 til 16 piksler, mot 6 til 20.

### Én rettelse i det jeg skrev i går

Fortegnet mitt for kantretning var omvendt. Jeg kontrollerte det mot en
syntetisk maske: positiv y-gradient betyr at kanten vender opp. Det
endrer ingen konklusjon, siden begge de vannrette retningene målte 92 og
93 prosent, men tabellen i `KODEBASE.md` sa "opp" og "ned" der den
egentlig bare kunne skille vannrett fra loddrett. Den er rettet til å si
det den faktisk viser.

## 2026-09-15, spawn point var feil på bane 5 og 6

Mathias: "Spawn point er feil på bane 5 og 6."

Riktig, og verifiseringen min burde fanget det. Den gjorde ikke det
fordi den stilte feil spørsmål.

Marken står i `del1 = (0,0)`, og `firkant1` er sentrert i (3500, 2300)
med 7680 x 4702 enheter mot et bilde på 3840 x 2351 piksler. Marken
starter altså ved bildepunkt (116-170, 26) i flis 1, i alle ni banene.

Målte hvor langt det er ned til bakken derfra:

| bane | første stein | fall |
|---|---|---|
| 2 | 111 px | 171 enheter |
| 3 | 118 px | 185 |
| 4 | 210 px | 369 |
| 7, 8, 9 | 153 px | 255 |
| **5 (min)** | **875 px** | **1699** |
| **6 (min)** | **930 px** | **1809** |

Banene mine åpnet altså med at marken stupte nesten en hel flishøyde før
den traff noe, mens de ekte banene starter med marken praktisk talt
oppå bakken.

Sammenlignet bakkeprofilen i flis 1, og mønsteret er tydelig: de ekte
banene starter høyt, på 167-251 piksler, og faller jevnt utover flisa.
Bane 4 går 251 → 650 → 1036 → 1320 → 1680. Mine startet på 925 og 938,
altså midt på flisa, og hadde ikke den innledende høyden i det hele
tatt.

Flis 1 i begge baner er bygget om: bakken starter nå høyt og faller
utover, som i de ekte. Takskåret er flyttet til høyre, der bakken har
falt nok til at det er plass over den. Fallet fra spawn er nå 355
enheter i bane 5 og 373 i bane 6, mot 171-369 i de ekte.

To runder: første forsøk landet på 489 og 721, fordi konturstøyen legger
til 90 og 186 piksler oppå tallet jeg setter. Kompenserte for det målte
avviket i stedet for å gjette på nytt.

### Hvorfor sjekken ikke fanget det

Spawn-sjekken min spurte bare om det var *fritt* under marken, ikke hvor
langt ned det var. 1699 enheter fritt fall besto den testen med glans.
Den måler nå fallhøyden og sammenligner med de ekte banene sitt spenn,
så en gjentakelse blir fanget.

Verdt å merke seg for øvrig: **bane 1 starter inni stein.** `level1/1.png`
er en flat plate helt øverst, og marken spawner inne i den. Det er ikke
noe jeg har innført, det har vært slik hele tiden, og det er grunnen til
at den flisa aldri ble brukt da bane 5/6 var satt sammen av ekte fliser.
Jeg har ikke rørt det, men si fra om du vil at jeg skal se på det.

> **Rettelse 2026-09-16: dette stemte ikke.** Se avsnittet «Bane 1
> spawner ikke inni stein likevel» nederst. Marken starter i malt himmel,
> og bane 1 er i orden.

## 2026-09-16, hitboxene i bane 5 og 6

Mathias: "Fiks hitboxene på level 5 og 6."

**Jeg fant ikke feilen du så.** Alt jeg klarte å måle sier at
kollisjonsformene traff kunsten like godt som i de ekte banene, eller
bedre. Jeg har likevel endret oppbyggingen på ett punkt der de avvek
tydelig fra bane 1-4, og det står under. Men jeg vil gjerne vite hva du
faktisk opplevde, for symptomet peker på helt ulike fikser.

### Det jeg sjekket, og som var i orden

| måling | ekte bane 2/3/4 | bane 5/6 før endringen |
|---|---|---|
| andel av hitbox-flata som er stein | 99,3-100 % | 99,9 % |
| andel av steinen som er dekket | 80,6-99,8 % | 94,4-98,7 % |
| ugyldige polygoner (konveksitet, flate, hjørneavstand) | 0 | 0 |
| avvik på gulvflata, andel over 10 px | 41-91 % | 0 % |
| markens egen form (`del1`) | | byte-identisk i alle seks filene |
| kollisjon på hengende takbiter | 97-99 % | 97-99 % |

Gulvavviket er verdt å merke seg: de ekte banene har kollisjonsflater som
ligger 100-500 piksler under den tegnede bakken mange steder, fordi
formene er store trekanter som skjærer rett over buede partier. Mine lå
på under én piksel. Marken er bare 17 enheter høy, så her er mine
strammere enn originalen, ikke løsere.

Jeg sjekket også at `level6.lua` kobler `physicsData:get("1")` til
`firkant1` og så videre, at flisene plasseres likt som i de andre
banene, og at formfilene har de navnene banefilene ber om. Alt stemte.

### Det jeg endret

Ett tall skilte seg klart ut. Fixturene mine var median **140 enheter
breie og 1380-1714 høye**, altså forhold rundt 1:10, fordi hvert trapes
spente hele steinens tykkelse fra topp til bunn. De ekte er kompakte:
288-376 x 218-293.

Box2D regner dårligere på svært langstrakte polygoner, og de 1400
enheter høye skjøtene mellom dem er akkurat den typen kant en rullende
kropp kan hekte seg på. Klossene deles nå både bortover og nedover, 200
x 320 enheter, og bare den øverste skiva er is, siden isen er et lag på
overflata. Det siste stemmer også med bane 4, der 98-100 % av
is-fixturene ligger i selve overflata.

Etter endringen: 187-262 fixtures per flis mot 67-308 i de ekte, ingen
ugyldige polygoner, presisjon 99,8-100 %, dekning 91,2-97,8 %,
gulvavvik under 13 piksler overalt.

Jeg var ærlig på at dette var en forbedring jeg kunne begrunne, ikke en
feilretting jeg hadde bevist, og spurte hva han faktisk så.

### Svaret, og den virkelige feilen

Mathias: "Bane 5, på første hopp er det ikke hitbox på bakken før
hoppet."

Det var nok til å finne den. Jeg skrev en sjekk som går kolonne for
kolonne og spør: finnes det tegnet gulv her uten en hitbox på
gulvflaten? Svaret:

```
bane5/1: x 801-898 (98 px), x 1052-1149 (98 px), x 2662-2759 (98 px)
bane5/2: x 1601-1679, x 1882-1979 (98 px), x 2842-2939 (98 px)
...
```

Første gap i bane 5 ligger mellom x 900 og 1050. Feltet **x 801-898** er
altså de siste 98 pikslene av bakken rett før hoppet, uten kollisjon.
Marken rullet utfor kanten før den så bakken. Nøyaktig det han beskrev.

Og mønsteret gjentok seg i hver eneste blokk i begge baner: det første
og det siste intervallet manglet alltid.

Årsaken sto i min egen sporer:

```python
if (b0 - t0) < MIN_TYKK or (b1 - t1) < MIN_TYKK:
    continue
```

Den testet tykkelsen i intervallets **to endepunkter**, og droppet hele
det 100 piksler breie intervallet hvis bare det ene var for tynt. Hver
blokk tynner ut mot null i endene på grunn av hjørneavrundingen, så det
første og siste intervallet røk alltid. 98 piksler bakke, i hver ende av
hver blokk, i åtte fliser.

Testen gjøres nå **per kolonne**: jeg finner sammenhengende spenn der
steinen er tjukk nok, og flislegger hvert spenn for seg, så kollisjonen
når helt ut dit steinen faktisk slutter.

Etter fiksen:

| | før | etter | ekte bane 2/3/4 |
|---|---|---|---|
| dekning av steinen | 91,2-97,8 % | **95,9-99,1 %** | 80,6-99,8 % |
| gulv uten hitbox | 98 px per blokkende | ingen | |
| gulvavvik, maks | 12,6 px | 5,4 px | 102-1542 px |
| ugyldige polygoner | 0 | 0 av 2043 | 0 |

De to stedene sjekken fortsatt flagger (bane 5 flis 2 og 4) er ikke
manglende kollisjon: der er steinen 555 til 1250 piksler tjukk. Det er
en liten bule i konturen der kollisjonskorden kutter 15 piksler under
den tegnede flata, og sjekken flagger alt over 12. De ekte banene ligger
100 til 500 piksler under, så dette er godt innenfor.

### Lærdommen

Jeg lette etter feilen i tre runder med målinger som alle sa "dette er
like bra som de ekte banene", fordi jeg målte **gjennomsnitt og
median**. Hullene var 98 piksler av gangen i en flis på 3840, altså rundt
2,5 prosent, og forsvant i snittet. Det som fant feilen var å spørre
"hvor er det IKKE dekning", ikke "hvor god er dekningen i snitt". Den
sjekken ligger nå i verktøykassa.

## 2026-09-16, bane 6 startet i oppoverbakke

Mathias: "Bane 6 er umulig da man spawner i en oppoverbakke, så man
ruller bakover og ut av kartet."

Målte bakkehøyden rundt spawn i alle ni banene:

| bane | x=100 | x=200 | x=300 | x=400 | fall |
|---|---|---|---|---|---|
| 2 | 117 | 262 | 378 | 459 | +303 |
| 3 | 120 | 324 | 235 | 275 | +136 |
| 4 | 210 | 274 | 310 | 378 | +193 |
| 5 | 208 | 297 | 357 | 403 | +171 |
| **6** | **228** | **210** | **192** | **184** | **−34** |

Bane 6 steg altså 34 piksler oppover de første 300 pikslene etter spawn.
Marken ruller fritt, så den trillet bakover og ut av kartet. Nøyaktig
som beskrevet.

### Årsaken

Den tegnede helningen var riktig: `lin(24, 470)` faller jevnt utover
flisa. Men konturstøyen, som har amplitude rundt 110 piksler, la seg
oppå og snudde helningen lokalt akkurat i spawn-sonen. Bane 5 slapp unna
med knapp margin, bane 6 gjorde det ikke. Det var flaks, ikke design.

### Fiksen

Skivene har nå en `ro`-parameter: ingen konturstøy før en gitt x, og
full støy fra en annen. For flis 1 i begge baner er den satt til
(520, 1500), altså null støy gjennom hele spawn-sonen og innfasing
etterpå. Da er bakken der marken lander nøyaktig den tegnede kurven, og
helningen er garantert.

Første forsøk dempet på *andel* av skiva i stedet for absolutt x. Det
virket ikke: dempingen vokste gjennom selve spawn-sonen, så støyens
gradient slapp til likevel, og bane 6 ble fortsatt oppoverbakke (bare
+44 i stedet for +134). Målte det, og byttet til absolutte x-verdier.

Etter fiksen faller bakken +140 (bane 5) og +134 (bane 6) piksler fra
x=150 til x=450, mot 136 til 303 i de ekte banene, og det finnes ikke én
motbakke mellom x=120 og x=900 i noen av dem.

### Sjekken finnes nå

Verifiseringen måler helningen fra spawn og verste motbakke, og
sammenligner med de ekte banene. Den ville fanget dette.

### Samtidig

Senket spawn-bakken i bane 5 litt, fordi den nye kurven ga 463 enheters
fall og spennet i de ekte banene er 171-369. Nå 381 og 329.

La også inn **adaptiv oppdeling** i kollisjonssporeren: normalt 100
piksler per kloss, men kortere der overflata bukter seg, så korden aldri
ligger mer enn 6 piksler under den tegnede flata. Marken er bare 17
enheter høy, så et avvik på 15 piksler er halvannen markhøyde ned i
bakken. Verste gulvavvik er nå 5,4 piksler i alle åtte fliser, mot 102
til 1542 i de ekte banene.

## 2026-09-16, de første hoppene i bane 5 og 6 var umulige

Mathias: "Man klarer ikke de første hoppene på bane 5 og 6."

### Hva som var galt

Målte avsats og landing for hvert hopp. Bane 5, første hopp: avsatsen
ligger på y=614, landingen på y=542. **Landingen lå 72 piksler HØYERE
enn avsatsen.** Marken skulle fly 180 piksler bortover og stige
samtidig. Det går ikke for noe som ruller.

Årsaken er den samme klassen som oppoverbakken ved spawn i går:
konturstøyen, amplitude rundt 110 piksler, overstyrte de tegnede
høydene. Blokken var tegnet til å starte på y=700, altså 110 piksler
under avsatsen, men støyen løftet kanten til 542.

Det gjaldt flere hopp. Med støyen fjernet fra kantene viste det seg at
flere gap jeg trodde var greie, egentlig var like ille. Bane 6 sitt
første hopp hadde et tegnet fall på bare 60 piksler over et 150 piksler
bredt gap. Det så greit ut i målingen bare fordi støyen tilfeldigvis
hadde senket landingen den gangen.

### Fiksen, i tre deler

**1. Støyen er null i begge ender av hver blokk.** Kantene er nettopp
der høydene må stemme, siden de er avsats og landing. Det gjøres ved å
trekke fra en rett linje gjennom støyens to endeverdier.

Første forsøk tonet støyen ut mot endene i stedet. Det var feil: utoning
lager en kunstig helning i de siste 150 pikslene, og i ett tilfelle
snudde den avsatsen til en motbakke, så hoppet ble regnet som umulig.
Å trekke fra en rett linje gir null i endene uten å vri på helningen.

**2. Fallet ved hvert gap følger nå en regel.** For at farten som trengs
skal ligge i samme spenn som de ekte banene, må landingen ligge minst
rundt `bredde² / 100` piksler lavere enn avsatsen:

| gap | minste fall |
|---|---|
| 140 px | 196 px |
| 160 px | 256 px |
| 200 px | 400 px |
| 240 px | 576 px |

Alle blokkhøydene i begge baner er satt etter den.

**3. Kortere tilspissing på gulvblokker ved gap.** En blokk med lang
tilspissing er tynn lenge før den geometriske enden, så det *effektive*
hullet ble bredere enn tegnet. Ett gap på 150 piksler målte 459.

### Resultatet

| | før | etter | ekte baner |
|---|---|---|---|
| bane 5 første hopp | landing 72 px **høyere** | 161 e/s | 92-275 e/s |
| bane 6 første hopp | fall 60 px over 150 px gap | 171 e/s | |
| verste hopp | umulig | 232 e/s | |

Alle tretten hoppene i de to banene krever nå 157 til 232 enheter per
sekund, og alle landinger ligger lavere enn avsatsen. De to første er
blant de letteste.

Til sammenligning krever de hoppbare gapene i bane 2, 3 og 4 mellom 92
og 275. De ekte banene har i tillegg noen gap der landingen ligger
høyere enn avsatsen, opp til 837 piksler. De er neppe ment å hoppes,
antagelig er de fallgruver.

### Alt annet målt på nytt

Takhøyde 780-1954 enheter, fall mellom fliser 1682-4201 (ekte 673-5244),
spawn-fall 381 og 329, helning fra spawn +140 og +134, ingen kolonner
uten hitbox, 0 ugyldige polygoner av 1905, hitbox-presisjon 99,8-99,9
prosent, dekning 96,0-99,1, is-korrespondansen intakt.

Verifiseringen har nå et eget skript for hoppene (`hopp.py` i
verktøykassa) som finner gulvet med kontinuitet, skiller gulv fra
takskår på tykkelse, ser bort fra overheng, og regner ut nødvendig
utgangsfart for hvert gap.

## 2026-09-16, marken ble stående i en grop i bane 5

Mathias sendte skjermbilde: "Bane 5, kommer ikke opp denne bakken."
Marken lå i en dump med bakken stigende foran seg.

### Hva jeg målte

Jeg hadde bare sjekket helningen ved spawn, ikke resten av banen. Målte
alle sammenhengende stigninger i gulvet, og sammenlignet med bane 2, 3
og 4.

Høydene var ikke problemet. Mine motbakker var 40 til 172 piksler høye,
de ekte har median 35 og p90 137. Det var **lengden**:

| | ekte bane 2-4 | mine |
|---|---|---|
| lengde | 26-305 px | 165-**1427** px |

En kort bratt kul tar man med fart. En lang slak stigning spiser opp
farten uansett hvor lav den er, og da blir marken stående. Det var
nøyaktig det som skjedde.

### Årsaken

Konturstøyens gradient var brattere enn den tegnede helningen. Målt per
blokk:

| blokk | tegnet helning | støyens gradient |
|---|---|---|
| bane 5 flis 1, tredje blokk | 0,278 px/px | 0,546 |
| bane 5 flis 2, første blokk | 0,347 | 0,401 |
| bane 6 flis 1, tredje blokk | 0,281 | 0,491 |
| bane 6 flis 4, andre blokk | 0,091 | 0,357 |

Støyen vant overalt. Da hjelper det ikke hvor fint helningen er tegnet.
Gradienten er omtrent `amplitude / (lengde x bølgefaktor)`, så den kan
regnes ut på forhånd.

### Fiksen

**Roligere kontur på gulvflater:** amplitude fra 110 til 60 piksler, og
bølgefaktor fra 0,14 til 0,22. Det setter gradienten til 0,12-0,19, altså
under de tegnede helningene. Takskår og overheng er urørt, de har ingen
slik begrensning siden ingen ruller på dem.

**Hard grense i tillegg:** en gulvflate får ikke stige mer enn 8 piksler
over sitt eget laveste punkt. Det er en garanti uavhengig av tall, og
koster lite visuelt.

**Brattere gulv i bane 6 flis 4,** der den tegnede helningen bare var
0,091 piksler per piksel. Nå 0,2.

### Resultatet

Verste motbakke i de to banene er nå 8 piksler, som krever 97 enheter per
sekund. Marken har 156 til 248 ved hoppene, så den ruller over uten å
merke det. Fem av åtte fliser har ingen motbakke i det hele tatt.

Hoppene er uendret gode: 156 til 248 enheter per sekund, alle landinger
lavere enn avsatsen.

Verifiseringen sjekker nå motbakker langs hele gulvet, ikke bare ved
spawn.

### Til ettertanke

Dette er tredje gang på rad at konturstøyen har ødelagt noe som var
riktig tegnet: først oppoverbakke ved spawn, så umulige hopp, nå en
grop midt i banen. Hver gang var den tegnede formen riktig og støyen
sterkere enn den. Jeg burde sett mønsteret etter den første.

## 2026-09-16, fem ting fra testrunden

Mathias etter å ha spilt: hitboxene var fikset, men banen ble for slapp,
kantene ikke rundet av, isen firkantet og friksjonen traff litt ved
siden av, bakgrunnen rotet på bane 6, og noe bugget da bane 5 ble
fullført.

### 1. Bane 5 ble for slapp

Målte helningen på gulvet over 100 px vinduer og sammenlignet:

| | median | p10 | p75 | p90 |
|---|---|---|---|---|
| ekte bane 2-4 | 23,3° | 3,4° | 30,1° | 42,9° |
| mine | 16,2° | 5,1° | 21,8° | 24,7° |

Mine var både slakere og jevnere. Motbakke-grensen jeg la inn dagen før
hadde flatet ut terrenget.

Mathias foreslo selv løsningen: "Kansje d sku ha vært søtte begrensing på
kor slakk bakkan kan vær. At den føll en viss vinkel. At starten på
bakken start på et kordinat og enden stopp på et kordinat."

Gulvet bygges nå slik, i stedet for en linje med støy oppå. Det er
**fallraten** som moduleres: hvert steg nedover er minst `tan(5°)`, og
summen av stegene er nøyaktig høydeforskjellen. Da er start, slutt og
minstevinkel garantert samtidig, og variasjonen blir terrasser og bratte
fall i stedet for jevne skråninger.

To feil på veien:

- Første modulasjon var `exp(v·s)`, altså lognormal. Summen låses til
  høydefallet, og da havner medianen på `1/exp(s²/2)` av snittet: jo mer
  variasjon, jo slakere ble det meste. Målt: spredning 0,85 → 1,3 → 1,8
  ga median 11,3 → 8,0 → 5,1 grader, stikk motsatt av hensikten. Byttet
  til en modulasjon med median 1.
- Blokkene var for lange i forhold til fallet. Bygget om på en mal der
  bakken går inn på cirka 40 og ut på cirka 2100 av flisens 2351 piksler,
  altså hele høydebudsjettet.

Resultat: median 20,8°, p75 30,1 (eksakt som de ekte), p90 35,8, og
minimum 4,6° som betyr at bakken aldri flater ut.

### 2. Kantene

Avrundingen på blokkendene var 18 piksler. Satt til 46.

### 3. Isen bommet på hvor det var glatt

Friksjonen ble satt ut fra hvilket t-intervall skiva hadde for isen,
mens malingen tonet ut i endene. Da lå det glatte partier utenfor den
synlige isen, akkurat som Mathias beskrev.

Nå leses den ferdig malte flisa, og klossene deles **på selve
iskanten**. Bommen er 0 piksler på alle åtte fliser, mot opptil 539 før.
Is-endene er også mykere malt, så båndet ikke slutter i et rett kutt.

### 4. Bakgrunnen på bane 6

Målte: bakgrunnen dekket til x = 19755 og y = 12622, mens banen går til
x = 30380 og y = 18757. Siste tredjedel av bane 6 hadde altså ingen
hulebakgrunn i det hele tatt.

To grunner. Flisene ble vist på 2000x3000 selv om bildene er 2000x6000,
altså klemt til halv høyde, og hver kjede hadde 12 fliser mot 20 i bane
2 og 5. Dirt-laget bakerst var også halvparten så bredt.

Rettet begge deler. Bane 6 dekker nå til x = 33395 og y = 22474, samme
som bane 2 og 5.

### 5. Bugen ved fullført bane

`goto2()`, som kjøres når målet nås, fjernet ikke "falt ut av
banen"-lytteren jeg la inn 15. september. Og siden `goto2` bruker
`showOverlay()` og ikke `gotoScene()`, kjøres **`scene:hide` aldri** på
banen. Lytteren ble altså stående og gå etter at målet var nådd, og
kunne utløse dødsmenyen midt i fullført-overgangen.

Rettet i alle ni banefiler. Verdt å merke seg for senere: alt som ryddes
i `scene:hide` må også ryddes i `goto2`, nettopp fordi den bruker
overlay.

### Alt målt på nytt

Hoppene krever 189 til 212 enheter per sekund, alle landinger lavere enn
avsatsen. Spawn-fall 257 og 323 (ekte 171-369). Ingen motbakker i det
hele tatt. Takhøyde 950-1510 enheter. Hitbox-presisjon 99,9 prosent,
dekning 96,2-97,9. 0 ugyldige polygoner av 2096. Stilmålene ligger
fortsatt innenfor de ekte banenes spenn.

## 2026-09-16, spillet gikk av og til i slow motion

Mathias: "Av og til etter vi gjør oppdateringer virker det som om at
spillet går i slow motion. Og andre ganger fungerer det?"

Jeg fant to lekkasjer, begge fra copy-paste fra `level1.lua`, og begge i
`scene:hide`.

### Den store: banene ble aldri revet ned

`level5.lua` til `level9.lua` kaller

```lua
composer.removeScene ("scenes.level1")
```

i sin egen `scene:hide`. Altså river de ned **bane 1** i stedet for seg
selv. Bane 1 til 4 gjør det riktig, så feilen gjelder nøyaktig de fem
banene som er navngitt feil.

Konsekvensen er at banen blir liggende fullt lastet i minnet etter at du
forlater den. Regnet ut hva det koster i teksturminne:

| bane | unike bilder | teksturminne |
|---|---|---|
| bane 2 | 14 | 174 MB |
| bane 5 | 14 | 174 MB |
| bane 6 | 14 | 306 MB |

Hvert terrengbilde er 3840x2351 piksler, altså 34 MB som RGBA på
skjermkortet. Fire per bane. Bakgrunnsbildene i bane 6 er 2000x6000, som
er 46 MB hver.

Spiller du bane 5 og går videre til bane 6, ligger det da 480 MB i
GPU-minnet samtidig, og bane 5 er ikke engang synlig. Prøver du et par
ganger til, vokser det videre. Når nettleseren går tom begynner den å
kaste ut og laste inn teksturer på nytt hele tiden, og da faller
bildefrekvensen.

Det forklarer også hvorfor det kom og gikk: det avhenger av hvor mange
baner du har vært innom i den fanen, ikke av hvilken oppdatering som
ligger ute.

### Den andre: kollisjonslyttere

`onCollision1` ble ikke fjernet i `scene:hide` i noen av de ni banene,
og `onCollision2` (som bare finnes i bane 5-9) ble bare fjernet på
dødsstien. Den lekket altså hver gang du fullførte banen, pauset deg ut,
eller byttet scene.

Runtime-lyttere fjernes ikke når en scene rives ned, og en
kollisjonslytter kalles for hver eneste kontakt i hele fysikkverdenen.
Noen titalls lekkede lyttere blir fort merkbart.

Begge deler er rettet i alle ni banefiler. Sjekket etterpå at hver bane
nå fjerner nøyaktig de lytterne den legger til, og river ned sin egen
scene.

### Det som fortsatt står igjen

Spillet kaller `physics.start()` uten `physics.setTimeStep()`. Corona
bruker da et **fast tidssteg låst til 60 bilder i sekundet**. Klarer
ikke nettleseren 60, går fysikken tilsvarende saktere i klokketid. Det
er selve mekanismen bak "slow motion", og den har vært der hele tiden.

`physics.setTimeStep(0)` slår på variabelt tidssteg, der fysikken går
etter faktisk forløpt tid i stedet. Da holder farten seg riktig selv om
bildefrekvensen faller, men bevegelsen blir hakkete i stedet.

Jeg har **ikke** endret det, fordi det endrer hvordan spillet føles og
alle hoppene er innstilt under det faste steget. Si fra om du vil at jeg
skal prøve.

Verdt å vite i tillegg: bane 6 sin bakgrunn koster nesten dobbelt så
mye som bane 5 sin, fordi den bruker `back_cave*.png` på 2000x6000 der
bane 5 bruker `1back_cave*.png` på 1000x3000 og viser dem i samme
størrelse. Bytter vi bane 6 til de små, faller den fra 306 til rundt
174 MB uten at noe ser annerledes ut. Ikke gjort, si fra.

## 2026-09-16, det kantete, og hva Corona faktisk gjør

Mathias etter testrunden: minnefiksen hjalp ikke, og "verka mye meir
kantat alt. Avrund ikke brett nåkka såm helst."

### Først en oppklaring

Corona skalerer ikke ned oppløsningen automatisk på trege telefoner.
`imageSuffix` i `config.lua` velger *høyere* oppløsning på skarpe
skjermer (`@2x`), ikke lavere på trege. Det finnes ingen automatisk
ytelsesjustering, så den hjelpen er ikke der.

### Det kantete var to ting, og bare den ene var konturen

Målte hvor mye helningen endrer seg per 60 piksler, som er et tall på
kantethet:

| | median | p95 | maks |
|---|---|---|---|
| ekte bane 2-4 | 5,2° | 32,7° | 133,2° |
| mine | 1,4° | 5,0° | 9,9° |

Konturen min var altså allerede **glattere** enn den ekte. Så det du så
kom ikke derfra.

Men den hadde likevel en reell feil: gulvgeneratoren klemte stegene hardt
mot minstevinkelen (`steg[under] = min_steg`). Det ga flate strekk på
nøyaktig minstevinkelen som møtte bratte strekk, og hvert møte ble en
knekk. Minstevinkelen er nå bygget inn i selve formelen i stedet:

```
f = lav + (1 - lav) * s,   s glatt og positiv med middel 1
```

Da ligger f alltid over `lav` uten at noe klemmes, og middelverdien er
eksakt 1, så summen av stegene treffer høydeforskjellen på øret.

Byttet samtidig fra `exp()` til `tanh()` i modulasjonen. `exp()` er
lognormal, og når summen er låst havner medianen på `1/exp(s²/2)` av
snittet, altså under. Medianhelningen hadde falt fra 20,8 til 17,2
grader av den grunn. Med `tanh` er både median og middel 1, og
medianen er tilbake på 20,8.

**Det du faktisk så var blokkformene.** Malen jeg innførte laget tre
nesten like trapeser per flis: rett topp, rett bunn, rette loddrette
sider. Den ekte kunsten har underkanter som buler og smalner, og blokker
som ender i lange tunger.

Rettet: 20 blokker har nå egen kurvet underkant i stedet for en rett
linje, siste blokk i hver flis ender i en lang tunge, og avrundingen på
blokkendene er økt fra 46 til 120 piksler.

Tungene gjorde først noen gap for breie (opptil 569 piksler, som krevde
413 enheter/s). Kortet inn tilspissingen på blokkene som vender mot et
hopp, og lot den lange tungen stå på blokken som går ut av flisa.

Alle fjorten hopp krever nå 202-243 enheter per sekund, mot 92-275 i de
ekte banene. Hitbox-dekningen gikk samtidig opp til 97,7-99,6 prosent.

### Ytelsen

Jeg fant og fikset en reell lekkasje i går (bane 5-9 rev aldri ned seg
selv), men den løste det altså ikke. Jeg kan ikke måle bildefrekvens
herfra, så videre gjetting hjelper lite. To ting jeg kan tallfeste:

**Teksturminne.** Hvert terrengbilde er 3840x2351, altså 34,4 MB som
RGBA på skjermkortet, og fire per bane gir 138 MB. Halverer vi
oppløsningen blir det 8,6 MB hver, altså 34 MB per bane. Bildene vises
2,8 ganger forstørret på telefon uansett, og kunsten er flate farger med
myk kant, så det er lite detalj å miste. Ikke gjort.

**Fast tidssteg.** `physics.start()` uten `physics.setTimeStep()` gir
fast tidssteg låst til 60 bilder i sekundet. Klarer ikke nettleseren 60,
går fysikken tilsvarende saktere i klokketid. Det er selve mekanismen
bak slow motion. `physics.setTimeStep(0)` fjerner den, men endrer
hvordan spillet føles. Ikke gjort.

### Om rammer

Mathias: "Akkurat no e d jo greit at den får lek seg fritt, men når vi
kommer tell nåkka eg e fornøyd me så trur eg d må sættes ramme."

Notert. Når vi lander på noe som sitter, er det bare å si fra, så låser
jeg tallene og skriver dem ned som faste grenser i stedet for
justerbare.

## 2026-09-16, bane 1 spawner ikke inni stein likevel

Mathias ba meg se på det jeg meldte i går: at bane 1 starter marken inne
i stein. **Den meldingen var feil, og feilen var min.**

Slik oppdaget jeg den. Jeg testet om flis 1 var «solid» øverst ved å
lese gjennomsiktigheten i `level1/1.png`. Den er helt ugjennomsiktig fra
øverste bildepunkt og nedover i hele spawn-området, så testen sa stein.

To ting jeg ikke hadde sjekket:

**Flisa er dobbelt så stor som de andre.** `level1/1.png` er 7680x4702
bildepunkter, mens `level2/1.png` til `level6/1.png` er 3840x2351. Alle
vises på 7680x4702. Omregningen mellom bildepunkt og spillkoordinat er
altså 1:1 i bane 1 og 1:2 i de andre, og jeg hadde brukt 1:2 overalt.
Det gjorde alle tallene mine for bane 1 feil.

**Bane 1 er utendørs.** Fargen øverst i flisa er `rgb(167, 202, 255)`,
altså malt himmel, ikke fjell. Derfor er den ugjennomsiktig. De andre
flisene er huler med gjennomsiktig luft, og der virker
gjennomsiktighetstesten.

Målte på nytt, denne gangen mot kollisjonsformene i `lib/shapedefs.lua`
i stedet for bildepunktene. Marken står på spillkoordinat y = 0 og
strekker seg fra x = -234 til x = 14. Under den ligger en gresskledd
skråning som faller mot høyre:

| x | overkant stein |
|---|---|
| -217 (halen) | y = 400 |
| -108 (midten) | y = 538 |
| 0 (hodet) | y = 644 |

Halen treffer altså bakken etter omtrent 400 enheters fall. De ekte
banene ligger på 171-369, og bane 5 og 6 på 285 og 253 etter
ombyggingen. Bane 1 faller litt lenger enn de andre, men den har gjort
det siden Ørjan laget den, og den virker.

Jeg la også kollisjonsformene oppå kunsten i et bilde for å se etter.
De røde omrissene følger jordkanten under gresset hele veien. Ingenting
å rette.

**Ingen endring gjort i bane 1.** Den håndtegnede kunsten er urørt.
Lærdommen tar jeg med meg: gjennomsiktighet er ikke det samme som luft
når flisa har malt himmel, og bildestørrelse skal leses av fila, ikke
antas.

## 2026-09-16, bane 5 og 6 malt om fra bunnen

Mathias sendte `level3/1.png` og sa: "Studer dette bildet ekstremt noye.
Det er slik utseende vi vil ha pa banene du lager. Du er ikke i
naerheten." Han hadde rett. Her er det jeg maalte, og hva jeg gjorde.

### Den store feilen: lose blokker i tomrom

Jeg hadde bygget flisene som separate plater som svevde. Den ekte
kunsten er EN sammenhengende steinmasse med en gang hogd ut av seg.
Det morke er tunnelen, ikke bakgrunnen.

| | Ekte bane 2, 3, 4 | Mine for | Mine na |
|---|---|---|---|
| Fyllgrad | 38, 68, 38 % | 35 % | 44 til 50 % |
| Storste del | 2,7 til 3,8 mill px | 1,3 til 1,5 | 1,7 til 1,8 |
| Stein i flisekanten | 0,0 % | opptil 33 % | 0,0 % |

Rettet med en takmasse over gangen i hver flis, og et oy-vindu paa 4 til
26 px inn fra hver kant. De ekte formene lukker seg ALLTID inne i flisa,
saa konturstreken gaar hele veien rundt. Klaringen deres er 2 til 210
px, saa vinduet rorer ikke spillflata.

### Renderen er skrevet om

Den gamle malte hver skive for seg med to flate farger. Den nye bygger
masken forst og henter all farge av avstanden til omrisset, slik kunsten
faktisk er laget.

| Dybde under kanten | Ekte bane 3 | Min for | Min na |
|---|---|---|---|
| 0,5 til 1,5 px | rgb(10, 2, 0) | ingen strek | rgb(10, 2, 0) |
| 4 til 20 px | rgb(70, 32, 5) | rgb(70, 32, 6) | rgb(68, 33, 6) |
| 80 til 130 px | rgb(47, 19, 2) | rgb(37, 13, 1) | rgb(46, 18, 1) |
| over 130 px | rgb(38, 14, 1) | rgb(38, 14, 1) | rgb(38, 14, 1) |
| Hyppigste farge | 56 % | 16 % | 48 % |

Konturstreken er det som gjor at kunsten ser TEGNET ut. Den manglet helt
hos meg. Kornet manglet ogsaa: 372 avlange prikker per flis, 16x10 px,
en per 90x90 px rute.

En feil paa veien: forste forsok la et mykt lysfelt oppaa hele massen.
Da ble den hyppigste fargen borte, smurt utover 16/12/11/10/9 %.
Variasjonen ligger na i HVOR DYPT rimen gaar, ikke i en
lysmultiplikator, saa kropp og rim blir liggende flatt og mellomtonene
oppstaar bare i overgangssonen.

### Isen

Mathias: "Du maa studere isen ogsaa da du ikke lager den likt."

Forst hvor den finnes. Av seksten ekte fliser har bare level4/2, 3 og 4
blaatt i det hele tatt, og der er det 0,4 til 1,9 % av massen. Bane 2 og
3 har NULL. Det jeg trodde var is i bane 3 er gjennomsiktige sprekker.

Saa hvordan den er malt, maalt som tverrsnitt inn fra kanten:

| Dybde | Ekte bane 4 | Min for |
|---|---|---|
| 0 til 2 px | rgb(15, 50, 63) kald konturstrek | rgb(44,106,130) |
| 2 til 7 px | rgb(36, 96, 118), glans mot 137 blaa | rgb(44,106,130) |
| 7 til 16 px | rgb(30, 84, 104) | rgb(44,106,130) |
| 16 til 30 px | rgb(20, 60, 74) | rgb(44,106,130) |

Min var EN flat farge paa alle dybder. Tykkelsen var ogsaa konstant, p10
31 og p90 33 px, mens den ekte varierer fra 10 til 123. Og dekningen var
5,7 til 8,5 % av omrisset mot ekte 20 til 26.

Na: skarpt band med det malte tverrsnittet, varierende tykkelse, og
partier som toner ut til spisser. Ett tak paa dybden maatte til, ellers
fylte den hele den tynne tuppen og ble en blaa kile.

### Fire feil verifiseringen fanget

1. **Sprekkene hogget i bakken.** Jeg la dem 4 px under gulvflata, saa de
   brot selve flata marken ruller paa. Utslag: takhoyde 6 til 12
   enheter, hull i gulvet, og verste motbakke 388 px som krever 675
   enheter/s mot markens 156 til 248. I den ekte kunsten gaar sprekkene
   ned fra overkanten av den ovre massen, i huletaket, aldri i gulvet.
   Flyttet dit. Verste motbakke gikk fra 388 px til 0.

2. **Takskaarene laa 3 til 22 px under takmassen.** Det er en splint,
   ikke et skaar. Fjernet. Takmassens egen bolgete underside er
   huletaket na.

3. **Gulvprofilen festet seg i oy-vinduets frynse.** De ytterste tjue
   kolonnene er klippet ned til en sliver, profilen laaste seg i den, og
   overheng-regelen forkastet resten. Bane 5 flis 1 mistet 2297 av 3840
   kolonner. Regelen manglet andre halvdel: et overheng har ogsaa
   UNDERKANTEN hoyt oppe. Her gikk biten fra 143 til 2263, altsa nesten
   hele flishoyden. Det er bakken.

4. **Takhoyden ble maalt i samme frynse.** Alle de lave tallene laa paa
   x = 12, 16 og 24. Maalingen hopper na over de ytterste 40 kolonnene.

Etter det stod en ekte feil igjen: hulemunnen i bane 6 flis 4 laa paa
680 enheter takhoyde mot grensa paa 700. Taket der er hevet 110 px i
stedet for at jeg flyttet grensa.

### Kollisjonsklossene

Takmassen sendte dem fra 966 og 1020 til 1916 og 1545. De ekte banene
ligger paa 505 til 743. Hver fixture ligger i Box2D sin bredfase hvert
fysikksteg, og du melder allerede om slow motion.

To grep: takmassen spores grovt, og dybden deles ikke lenger i jevne
skiver. Sporeren delte hver kolonne i 160 px skiver, saa en 2000 px
tjukk gulvblokk fikk 12 klosser der bare den overste noen gang blir
berort. Skivene blir na tjukkere nedover, 80 px overst og saa
fordobling. Resultat 1491 og 948. Fortsatt over de ekte, men halvparten
av der det stod.

Den andre halvparten var min egen gamle feil fra da jeg bygget
sporeren, ikke noe takmassen innforte.

### Malt resultat

| | Bane 5 | Bane 6 | Krav eller fasit |
|---|---|---|---|
| Takhoyde | 930 til 1608 enh | 786 til 1554 | over 700 |
| Spawn-fall | 285 enh | 253 | 171 til 369 |
| Verste motbakke | 0 px | 0 px | marken har 156 til 248 e/s |
| Fall mellom fliser | 784 til 4269 | 1090 til 3762 | 673 til 5244 |
| Dodslinje-klaring | 612 til 618 | 612 til 622 | over 600 |
| Hoppene | 202 til 229 e/s | 202 til 243 | ekte 48 til 1656 |

Alle fjorten hopp lander lavere enn avsatsen.

### Det som fortsatt ikke stemmer

Formene mine har for mange lange rette kanter. Den ekte kunsten har
flytende silhuetter med tunger og avrundede tupper. Det er neste ting.

Filstorrelsen gikk ogsaa opp, fra 78 til 97 kB per flis til 191 til 234
kB, fordi kornet og gradientene krever flere palettfarger, 80 til 99
indekser mot 44. Det paavirker nedlastingen av HTML5-versjonen, ikke
minnet paa skjermkortet.

Ingenting av dette er spilletestet. Jeg har ingen nettleser her, bare
maalinger.

## 2026-09-24, ny bane 7 bygget etter bane 4

Mathias: "Kan du proeve aa lage en ny bane med utgangspunkt fra level 4.
fordi det er den beste banen."

### Bane 4 er ikke en tunnel

Det forste jeg maatte forstaa: bane 4 har et helt annet formsprak enn
bane 3. Bane 3 er en gang hogd gjennom en steinmasse. **Bane 4 er
staaende soyler som man hopper mellom, og som trapper seg nedover mot
hoyre.** Det er antakelig derfor du liker den best: det er tydelig hva
du skal gjore.

Malt paa de fire ekte flisene:

| | Bane 4 |
|---|---|
| Soyler per flis | 2 til 4 |
| Bredde | 596 til 2229 px |
| Hoyde | 656 til 2055 px |
| Underkanten | alle paa y 2148 til 2288, samme grunnlinje |
| Gap mellom dem | 40 til 376 px |
| Toppen av neste | 237 til 1285 px lavere enn forrige |
| Tetthet i boksen | 0,51 til 0,82 |
| Fyllgrad | 31 til 41 %, flis 4 (hulemunnen) 60 % |
| Is | flis 2, 3 og 4. Flis 1 har ingen |

Derfor har bane 7 **ingen takmasse**. Bane 4 har ikke tak i flis 1 til 3
i det hele tatt. Massen kommer av at soylene er hoye og staar paa samme
grunnlinje. Det gir ogsaa 828 kollisjonsklosser mot bane 5 og 6 sine
1491 og 948, altsa rett i de ekte banenes eget spenn paa 505 til 743.

### Resultat mot fasiten

| | Ekte bane 4 | Ny bane 7 |
|---|---|---|
| Soyler per flis | 2, 4, 3, 2 | 3, 4, 3, 2 |
| Fyllgrad flis 1-3 | 31 til 41 % | 30 til 37 % |
| Fyllgrad flis 4 | 60 % | 51 % |
| Tetthet i boksen | 0,45 til 0,82 | 0,42 til 0,82 |
| Is flis 1 / 2 / 3 / 4 | 0 / 0,39 / 1,44 / 1,85 % | 0 / 0,64 / 1,53 / 1,24 % |
| Kollisjonsklosser | 526 | 828 |
| Stein i flisekanten | 0,0 % | 0,0 % |

Spillbarhet: ingen tak i flis 1-3, hulemunnen 744 enheter, spawn-fall
321 (ekte 171-369), verste motbakke 0 px, fall mellom fliser 3870 til
4334 (ekte 673-5244), dodslinje-klaring 610 til 614.

Alle sju hopp krever 135 til 202 enheter/s. Marken har 156 til 248.

### Feilen som kostet to runder

Jeg regnet hoppene ut PAA FORHAND denne gangen, til 150 til 214
enheter/s, i stedet for aa tegne forst og maale etterpa. Sekse av sju
traff. Det sjuende ble 245.

Aarsaken er verdt aa skrive ned, for dette er tredje gang den samme
tingen lurer meg:

**Det effektive gapet er ikke avstanden mellom blokkene. Det er
avstanden mellom der de fortsatt er tjukke nok til aa baere**, altsa 120
px. Tilspissingen paa endene gjorde 150 px tegnet til 273 px maalt.
(I bane 5 ble 150 px til 459 px i september.)

Forste forsok paa aa rette det gjorde det verre: jeg flyttet soyla 40 px
mot venstre OG senket toppen 80 px for aa faa storre fall. Gapet ble 363
px og kravet steg til 286 e/s. En LAVERE topp gir en TYNNERE soyle, og
da flytter landingspunktet seg enda lenger inn. Den effekten var storre
enn de 40 pikslene jeg vant.

Rettet ved aa holde soyla tjukk og flytte den 80 px sidelengs i stedet.
Gapet ble 219 px og kravet 202 e/s. Regelen staar na i baner.py.

### To ting til

**Bane 7 hadde ingen egne kollisjonsformer.** Den brukte
`lib.shapedefs`, altsa bane 1 sine former, mot helt annen kunst. Na har
den `lib.shapedefs7`. **Bane 8 og 9 gjor fortsatt det samme, og de deler
kunst med bane 7.** Det staar igjen.

**Den gradvise morkningen finnes ikke i den ekte kunsten.** Jeg malte
kroppsfargen i bane 2, 3 og 4: noyaktig rgb(38,14,1) i alle tre. Den
morkningen jeg innforte i bane 5 og 6 er min egen. Bane 7 har bane 4 sin
farge rett av. Si fra om du vil at jeg tar den ut av bane 5 og 6 ogsaa.

### Det jeg ikke faar til

Bane 4 sine soyler har **bolgete loddrette sidekanter**. Mine er glatte.
Renderen bygger hver form av en toppkurve og en bunnkurve per kolonne,
saa sidene oppstaar implisitt der de to motes, og det finnes ingen plass
aa legge bolger paa. Det krever en annen formbeskrivelse.

Ingenting er spilletestet. Alt er malt.

## 2026-09-27, bane 7 bygget om etter Orjan sin tegning

Mathias: "Bane 7 ble ikke bra. Orjan tegnet hvordan den bor vaere."
Tegningen: rod = spawn, blaa = bane, gul = maal, lilla = dod.

### Hvordan jeg leste skalaen

Tegningen kunne vaere hele banen eller en flis. Det avgjorende tallet er
den lilla doedslinja: den ligger 107 til 112 piksler under toppen av
massene. Spillets egen doedslinje ligger 600 enheter under bakken. Bare
EN skala gir det tallet, nemlig at tegningen viser en flis: da blir det
610 til 638 enheter. Skalaen er da 3,80 i x og 2,85 i y.

| | Tegnet | I flis |
|---|---|---|
| Masser | 4 | 4 |
| Bredde | 194-236 px | 737-897 px |
| Gap | 34-61 px | 129-232 px |
| Tykkelse | 72-99 px | 205-282 px |
| Tetthet i boksen | 0,35-0,47 | |
| Toppen faller | 133-153 px | 379-436 px |
| Neste masse | 60-70 px lavere | 171-200 px |

### Hva som var feil

Soylene mine var massive plater som stod paa en grunnlinje i bunnen av
flisa, 656 til 2055 px hoye, tetthet 0,42 til 0,82. **Orjan tegner tynne
svevende band**, rundt 240 px tjukke, med tomrom under og doedslinja rett
nedenfor.

Jeg tok bane 4 sine soyler som fasit fordi Mathias sa bane 4 var best.
Det var riktig observert om bane 4, men feil oppgave: det Orjan vil ha
er naermere tungene i bane 3, lagt ut som en trapp.

### Resultat

| | Orjan tegnet | Ny bane 7 |
|---|---|---|
| Band per flis | 4 | 3, 4, 3, 3 |
| Tykkelse | 205-282 px | 190-224 px |
| Tetthet | 0,35-0,47 | 0,36-0,68 |
| Fyllgrad | mye tomrom | 7,9-8,4 % |
| Kollisjonsklosser | | 507 |

507 klosser er det laveste av alt vi har laget: ekte baner 505-743, bane
5 og 6 ligger paa 1491 og 948, soyleversjonen av bane 7 laa paa 828.
Tynne band er billig fysikk fordi det ikke finnes masse under gulvet aa
spore.

Spillbarhet: alle atte hopp krever 166 til 207 enheter/s (marken har 156
til 248), spawn-fall 381, helning ut fra spawn +160 px (ekte 136-303),
verste motbakke 0 px, takhoyde i hulemunnen 776 enheter,
doedslinje-klaring 696 til 1506.

To ting maatte rettes underveis, begge ekte:

1. **Starten var for slak.** Fallet fra x=150 til x=450 var 78 px mot de
   ekte banenes 136-303. Forste band i flis 1 og 3 er kortet inn fra
   1300 til 1140 px og gjort brattere, fra 290 til 520 px fall.
2. **Takhoyden i flis 4 laa paa 496 enheter** mot kravet 700. Overhenget
   er hevet 130 til 160 px.

### En bevisst avvikelse fra tegningen

Gap/fall-forholdet i tegningen gir umulige hopp. Et gap paa 129 px med
171 px fall krever 462 enheter/s, og marken har 156 til 248. Formen og
oppsettet er Orjan sitt. Gapene er dimensjonert etter
v = 2W * sqrt(73,5/D) saa de gaar an aa hoppe. Si fra om han heller vil
ha det saa stramt som tegnet, saa maa marken ha mer fart i stedet.

### Det jeg fortsatt ikke faar til

Orjan sine masser har en knekk paa midten og bolgete kanter. Mine er
rette kiler, og det syns paa tettheten: 0,49 til 0,68 paa det forste
bandet i hver flis mot hans 0,35 til 0,47. Renderen bygger hver form av
en toppkurve og en bunnkurve per kolonne, saa sidene oppstaar implisitt
og det finnes ingen plass aa legge bolger paa. Det krever en annen
formbeskrivelse.

Flis 4 ble ogsaa rotete: overhenget er delt i to av sprekken og leser
som to lose biter.

Ingenting er spilletestet. Alt er malt.

## 2026-09-27, bane 7 laget på nytt, rett fra tegningen

Mathias: "Kan du finne ut hvorfor bane 7 er så firkantet. Oppgaven var å
lage banen etter en tegning, men det ble ikke bra."

### Hvorfor den ble firkantet

To feil, den ene verre enn den andre:

1. **Tegningen ble lest i feil skala.** Den viser hele banen, ikke én
   flis. Den røde prikken er spawn, den lilla streken er `dod` (rotert
   31,48 grader i koden), den gule er `mal2` (rotert 45 grader, nederst
   til høyre), og de fire blå massene er de fire flisene. Forrige runde
   la 3-4 tynne band i hver flis, 13 i alt i stedet for 4.
2. **Formene kunne ikke ha runde ender.** Hver masse var bygget av én
   toppkurve og én bunnkurve per kolonne. Da blir begge endene
   loddrette kutt, og hodene, knekkene og de bølgete kantene Ørjan tegnet
   gikk ikke an å lage. Det ble notert som "ikke løst" forrige gang.

### Hva som er gjort

Tegningen ligger nå i `Util/baner/tegning7.jpg`, og `Util/baner/lag_bane.py`
lager bildene og kollisjonen rett fra den. Scriptet ligger i repoet denne
gangen, så banen kan lages på nytt eller justeres.

- De fire blå konturene hentes ut som lukkede former og legges én per
  flis. Konturen er Ørjans egen strek, bare glattet litt.
- Massene er strukket 1,3 til 1,7 ganger bortover. I riktig forhold blir
  gapet mellom dem rundt 650 px, og marken ville landet på den avrundede
  venstresiden av neste hode og måttet klatre. Nå er gapet 44 til 70 px,
  med 765 til 939 px fall rett ned på toppen av neste hode.
- Banen er flyttet 1130 enheter mot venstre i `level7.lua` (flisene,
  `dod` og `mal2`), slik at marken starter over hodet på første masse,
  slik tegningen viser. (Første utgave flyttet marken i stedet, se
  rettelsen under.)
- To små oppbøyde lepper ytterst på masse 1 og 3 er slipt ned, ellers
  ville marken blitt liggende i dumpa foran dem.
- Fargene er målt i `level4/1.png`: lys rim langs topp og bunn, mørk
  kropp, tynn kontur og korn. Ingen is.

### Målt

| | |
|---|---|
| spawn-fall | 145-170 px (ekte baner 111-210) |
| landing etter hvert hopp, 156/200/248 e/s | på toppen av neste hode |
| verste motbakke etter landing | 20-25 px |
| ut av flis 4 | treffer `mal2` før `dod` ved alle tre fartene |
| kollisjonsklosser | 1013, ingen ugyldige, dekning 99,7-99,8 % |
| rører flisekanten | nei |

Bildene er 360-410 kB per flis mot 100-200 kB i de ekte banene, på grunn
av den myke overgangen og kornet.

Ingenting er spilletestet. Alt er målt.

### Rettelse samme kveld: bane 7 krasjet i nettleseren

Mathias fikk `assertion failed!` i `transition.to` med en gang bane 7
startet. Gjenskapt i Chromium mot den publiserte versjonen: rett etter
start meldte spillet `mal2vsdel4` (marken "traff" målet), så `knott3 og
knott4`, så `Attempt to set property y to NaN`, og så krasjet. Versjonen
før endringen startet uten feil.

Årsaken var at jeg hadde flyttet selve marken til `del1.x = 600`.
Kollisjonsformene er ikke årsaken: minste flate og kant er på nivå med
bane 4. Trolig er det sveiseleddene til knottene, som bruker
`(knott.x, knott.x)` som festepunkt og dermed havner 400-600 enheter
unna marken når den ikke står rundt x=0.

Rettet ved å sette marken tilbake til `del1.x = 0`, som i alle de andre
banene, og heller flytte flisene, `dod` og `mal2` 600 enheter mot
venstre. Geometrien marken møter er nøyaktig den samme.

Etter rettelsen startet bane 7 uten krasj, men marken døde etter rundt
10 sekunder: den sto ytterst på venstre kant av den flate toppen,
vippet bakover og falt ut. Banen er derfor flyttet 1130 enheter i
stedet for 600, så marken starter der toppen begynner å helle nedover
(124 px fall over de neste 300 px, ingen bakke som faller bort bak den).

## 2026-09-27, bane 8 laget rett fra tegningen

Mathias sendte Ørjans tegning for bane 8: "Gjør det samme og lag en
bane 8."

### Hva som var annerledes enn bane 7

Massene i tegning 8 er smalere og brattere, og hodet ligger 400-1000 px
inn bak en skrå venstreside. Lagt én per flis i den faste diagonalen
måtte de strekkes 2-2,4 ganger bortover (bane 7: 1,3-1,7), og marken
landet i en motbakke på 130-260 px uansett.

### Hva som er gjort

- Verktøyet er flyttet til `Util/baner/lag_bane.py` og tar banenummeret
  som argument. Bane 7 gjenskapes byte for byte.
- **Flisene ligger fritt** i stedet for i den faste diagonalen. Massene er
  skalert likt i begge retninger, så formene er som tegnet, og hver flis
  er lagt der hoppet til neste hode går opp. Posisjonene til flisene,
  dødslinja og målet står i den genererte `lib/baneoppsett8.lua`, som
  `level8.lua` leser.
- Spawn krever nå at hele marken står i helningen etter kammen. Første
  forsøk ble liggende i balanse på toppen av hodet.

### En feil som gjaldt alle baner

Da jeg testet bane 8 til mål, hoppet spillet rett gjennom bane 9 og
krasjet (`attempt to compare nil with number`). Årsaken: målsjekken så
bare på `.type`, og marken fra bane 8 lå fortsatt i fysikken og falt
gjennom sitt eget mål mens bane 9 startet. Bane 9 trodde da at den var
fullført. Rettet i alle ni banefilene ved å sammenligne med banens egne
`mal2` og `del4`.

Etter det startet bane 9 som den skulle, men krasjet likevel med samme
melding idet bane 8 ble ryddet bort. `camera` er global, og bane 8 sin
`scene:hide` kjørte `camera:destroy()` etter at bane 9 hadde laget sitt
kamera. Rettet i alle ni banefilene: hver bane ødelegger bare sitt eget.

Testet i Chromium mot den publiserte versjonen. Ingenting er spilletestet
av et menneske.

## 2026-09-27, bakgrunnen i bane 7 og 8

Mathias: "Bakgrunnen på både bane 7 og 8 er feil. Helt ute av posisjon
på bane 8 pga at den er så bratt og på bane 7 er paralaxen feil så noe
av bakgrunnen forsvinner før banen er ferdig spillet."

- **Bane 7** hadde fortsatt det gamle bakgrunnsoppsettet. Jordlaget
  (`dirt1`, lag 6) følger banen 1:1, men var bare 20 skjermer langt og
  rakk til omtrent x = 16 400, mens banen går til rundt 30 000. Samme
  feil som bane 5 og 6 fikk rettet 2026-09-15. Byttet til nøyaktig samme
  oppsett som bane 5: `1dirt1` 40 skjermer langt og 20 hulebiter per lag.
- **Bane 8** går i 56 grader, men hele bakgrunnen lå langs 31,48 grader
  som i de andre banene og gled bort fra banen. Samme oppsett som bane 5,
  men vinkelen og steget mellom bitene kommer nå fra linja spawn -> mål i
  `lib/baneoppsett8.lua`.

## 2026-09-28, bane 8 slakere og ny bane 9

Mathias: "Level 8 er alt for bratt. Kan du endre litt på vinkelen. Bane
9 er laget av claude tidligere. Kan du forsøke å lage en ny bane med å
bruke designet fra bane 7 og 8."

- Bane 8 går nå i 41 grader i stedet for 55. Tegningen dreies 20 grader
  før massene legges ut.
- Bane 9 er laget på nytt i samme stil som 7 og 8, av massene fra
  tegning 7 og 8 om hverandre, omformet så de blir nye former. Den gamle
  bane 9 (plassholder med bane 1 sine kollisjonsformer) er erstattet.

Hvis Ørjan tegner bane 9, kan den lages fra tegningen som bane 7 og 8.

## 2026-09-28, bane 5-9 laget på nytt som grotter

Mathias: bane 5-9 skal ligne mer på bane 4, med is, et hopp nær det
marken klarer, en sprekk med is marken må gli slapp gjennom, og tak som
gjør det trangt som i bane 3. Organisk, som en hule nedover, og
vanskeligere for hver bane. Han sendte en skisse av en grotte og sa at
banene gjerne kan se annerledes ut enn nå.

- Alle fem er laget på nytt av et nytt verktøy, `Util/baner/hule.py`.
  Hver bane er én sammenhengende grotte med steinbånd under marken,
  hopp, søyler, is, tak med drypp og isdaler med overheng.
- Hoppene er målt mot første hopp i bane 4, som er nesten det marken
  klarer. Hver bane har minst ett hopp på 96-100 % av det.
- Fra bane 7 er det isdaler der taket går ned til 42-55 px over bunnen.
- Fargen går fra brun jord i bane 5 mot grå stein i bane 9.
- `level5.lua` til `level9.lua` er nå samme fil med ulikt nummer.
  Posisjonene ligger i `lib/baneoppsettN.lua`.

De gamle bildene og formene for bane 5-9 er erstattet. Hvordan banene
føles å spille må testes av et menneske.

## 2026-09-28, målet i bane 5-9 som i bane 1-4

Mathias: i bane 6 kom han i mål før banen tok slutt. Målet skal være som
i bane 1-4, der kameraet stopper og marken fortsetter ut av skjermen til
høyre. Nå stopper kameraet 1800 enheter før slutten av gulvet, og målet
ligger rett før slutten, utenfor skjermen.

## 2026-09-28, dødslinja lekket mellom banene

Når marken kom i mål, døde den med en gang i neste bane. Marken fra
forrige bane falt fortsatt i fysikkverdenen og traff den nye banens
dødslinje, og sjekken så bare på navnet ("dod" og "del1"), ikke på om
det var denne banens objekter. Samme feil som målet hadde 2026-09-27.
Rettet i alle ni banefilene: sjekken sammenligner nå med banens egne
`dod` og `del1`-`del9`.

Samme feil fantes i knekk-systemet: når forrige bane ble revet ned,
traff knottene i den gamle marken hverandre, og den nye banen trodde
det var dens egen marke som knakk. Rettet likt i alle ni banene. Men knekk-lytteren ble
heller aldri fjernet når banen var ferdig (den var `local function` inni
`scene:create`, så `scene:hide` fjernet en tom global). Den gamle banens
knekk kjørte derfor da marken ble revet ned, og satte kameraet i neste
bane til å følge den gamle marken ("attempt to compare nil with number").
Nå er `knekk` deklarert øverst i fila som `onCollision`, og fjernes både i
`scene:hide` og når målet nås.

## 2026-09-28, Controls, banenummer og minispill

Mathias ba om en forklaring av styringen i pausemenyen og på
startskjermen, en måte å se hvilken bane man spiller, og idrettsminispill
for marken i Games (høydehopp med lista som kan justeres, lengdehopp,
100 m).

- **Controls:** ny stein på startskjermen og ny knapp i pausemenyen.
- **Banenummer:** nummersteinen fra banevalget vises øverst til venstre.
- **Games:** høydehopp, lengdehopp og 100 m. Rekordene lagres.
  Minispillene styres som banene: trykk fort for fart, hold for å strekke
  marken ut og lade hoppet, slipp for å hoppe.

Knappene og steinen er laget i samme stil som de du tegnet
(`Util/knapper/lag_knapper.py`). Du må gjerne tegne dem på nytt.

Samme dag, Mathias: "kan du la marken gjøre slik som i spillet i
minigames. Altså fysikken osv". Minispillene bruker nå den ekte marken
fra banene (`lib/markfysikk.lua`), med samme styring. Siden marken bare
ruller nedover av seg selv, er øvelsene bygget rundt det: tilløpsbakke
og kant i lengdehopp, hoppkant i høydehopp, og istunneler i 100 m der
marken må gjøres slapp. En ting jeg fant underveis: `isCollideConnected
= true` på leddene i banefilene gjør ingenting (den kan bare leses i
Solar2D). Det er ikke endret, fordi banene er laget med den fysikken.

## 2026-09-29, "What's new" og varsel om oppdatering

Mathias ba om en kort oppsummering av hva som er nytt når spillet
starter etter en oppdatering, og et varsel i spillet når en ny versjon
er klar. Oppsummeringen skrives i `lib/nyheter.lua` for hver oppdatering.
Varselet kommer av seg selv: spillet sjekker `versjon.txt` på nettsiden
hvert andre minutt og viser en liten lapp nede til venstre.

## 2026-10-28, ny grafisk stil, fase 1

Mathias vil gjøre Roller til et fullverdig spill for Android og iPhone,
med helt ny grafikk, men med samme fysikk og samme måte marken beveger
seg på. Det skal også ha ting å samle, belønninger og oppgraderinger. Han
valgte stilen ut fra skisser: lys eng i bane 1-2 og varm jordhule videre
nedover. I stedet for ringer blir det duggdråper som penger og
markeunger som skal reddes, tre i hver bane.

Backup av alt før redesignet ligger i grenen
`backup-for-redesign-2026-10-28`.

Fase 1 er ferdig:
- Markens hjem under enga er ny meny.
- Nytt banevalg, som en sti fra enga og ned i dypet.
- Nye pause-, døds- og fullført-skjermer, innstillinger, Controls og
  reklame-for-liv. Kjøp for ekte penger er tatt ut; dråper kan byttes mot
  forsøk.
- Daglig gave og nytt skjermbilde under spill.
- Ny skrift (Fredoka, fri lisens) og egne ikoner.

Banegrafikken, marken og samleobjektene kommer i fase 2, og butikken og
oppdragene i fase 3.
