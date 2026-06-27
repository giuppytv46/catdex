# CatDex — Game Design Document v1.0

## 1. Visione del progetto

CatDex è un gioco mobile rilassante da collezione, ispirato alla filosofia di Pokémon GO, ma dedicato ai gatti reali.

Il giocatore esplora il mondo, fotografa gatti reali e l’intelligenza artificiale li trasforma in collezionabili digitali.

L’obiettivo non è solo riconoscere la razza, ma creare una collezione personale fatta di razze, colori, pattern, varianti rare, eventi stagionali e caratteristiche uniche.

## 2. Nome del gioco

Nome ufficiale: CatDex

## 3. Piattaforme

CatDex deve essere sviluppato per:

* Android
* iOS

Il codice deve essere unico e multipiattaforma.

Tecnologia consigliata:

* Flutter
* Supabase
* OpenAI Vision
* Google Maps / Mapbox
* Firebase per notifiche
* AdMob
* Google Play Billing
* Apple In-App Purchases

## 4. Target

CatDex è pensato per:

* amanti dei gatti
* giocatori casual
* utenti mobile
* persone che amano collezionare
* utenti social
* pubblico internazionale

Il tono deve essere leggero, giovane, cartoon, rilassante e accessibile.

## 5. Stile del gioco

CatDex deve avere uno stile:

* cartoon
* colorato
* moderno
* mobile game
* morbido
* amichevole
* rilassante
* non competitivo in modo aggressivo

Riferimenti di atmosfera:

* Pokémon GO
* Animal Crossing
* Pokémon TCG Pocket
* Brawl Stars per energia visiva
* Duolingo per semplicità e retention

## 6. Core Loop

Il ciclo principale del gioco è:

1. Il giocatore apre l’app.
2. Vede missioni giornaliere, livello e progressi.
3. Trova un gatto reale.
4. Scatta o carica una foto.
5. L’AI analizza il gatto.
6. Il gioco genera una scheda collezionabile.
7. Il gatto viene aggiunto al CatDex.
8. Il giocatore riceve XP, badge o ricompense.
9. Il giocatore può condividere la cattura o mostrarla agli amici.
10. Il giocatore torna a cercare nuovi gatti.

## 7. Elementi identificati dall’AI

Ogni foto deve produrre:

* razza probabile
* livello di confidenza
* colore del mantello
* pattern del mantello
* colore degli occhi
* tratti fisici particolari
* possibile personalità
* rarità
* variante speciale
* città, regione e paese
* data e ora della scoperta

Se la razza non è certa, l’app deve classificare il gatto come Domestic Cat e valorizzare colore, pattern e caratteristiche.

## 8. CatDex

Il CatDex è il bestiario principale.

Deve contenere almeno 100 entry iniziali.

Non devono essere solo razze pure. Il sistema deve includere:

* razze ufficiali
* gatti domestici
* varianti di colore
* varianti di pattern
* varianti rare
* varianti evento
* varianti shiny

Esempio:

* European Shorthair — Tabby Green Eyes
* Domestic Black Cat — Yellow Eyes
* Maine Coon — Silver Fluffy
* Siamese — Blue Eyes
* Tuxedo Cat — Classic Variant
* Calico Cat — Lucky Variant
* Black Cat — Midnight Variant
* White Cat — Albino Variant
* Any Breed — Shiny Variant
* Any Breed — Halloween Variant

## 9. Rarità

Ogni scoperta deve avere una rarità.

Livelli:

* Common
* Uncommon
* Rare
* Epic
* Legendary
* Mythic

La rarità dipende da:

* razza
* colore
* pattern
* occhi
* variante speciale
* evento attivo
* probabilità casuale controllata

## 10. Varianti speciali

Ogni gatto può avere una variante.

Varianti iniziali:

* Normal
* Shiny
* Golden
* Albino
* Melanistic
* Heterochromia
* Midnight
* Lucky
* Event Edition

Le varianti devono avere:

* bordo carta speciale
* animazione diversa
* XP bonus
* badge dedicato
* effetto visivo al momento dello sblocco

## 11. Personalità

Ogni gatto può ricevere una personalità generata dall’AI o dal sistema.

Esempi:

* Sleepy
* Curious
* Boss
* Friendly
* Royal
* Mischievous
* Silly
* Mysterious
* Brave
* Lazy

La personalità serve a rendere ogni gatto più memorabile.

## 12. Nomi generati

Ogni gatto scoperto riceve un nome automatico.

Esempi:

* Mochi
* Luna
* Shadow
* Biscuit
* Miso
* Pixel
* Whiskers
* Neko
* Salem
* Milo

Il giocatore deve poter modificare il nome.

## 13. Progressione

Il giocatore guadagna XP tramite:

* nuova scoperta
* nuova razza
* variante rara
* evento stagionale
* missione giornaliera
* achievement
* streak giornaliera

Livelli:

* da 1 a 100

Il livello deve essere mostrato in modo molto visibile nella home e nel profilo.

## 14. Missioni giornaliere

Esempi:

* Scopri 1 gatto
* Scopri 3 gatti
* Trova un gatto Common
* Trova un gatto Rare
* Scopri un gatto in una nuova città
* Completa una scansione oggi
* Condividi una cattura

Le missioni devono dare XP e ricompense.

## 15. Achievement

Achievement iniziali:

* First Cat
* Cat Lover
* 10 Discoveries
* 50 Discoveries
* 100 Discoveries
* First Rare
* First Shiny
* First Legendary
* World Explorer
* Night Hunter
* Event Collector
* Social Cat

## 16. Eventi stagionali

CatDex deve supportare eventi stagionali.

Esempi:

* Halloween Cats
* Christmas Cats
* Summer Cats
* Valentine Cats
* Spring Festival
* Black Cat Week

Gli eventi possono aggiungere:

* varianti esclusive
* badge temporanei
* missioni speciali
* ricompense evento
* grafiche speciali

## 17. Componente social

CatDex deve avere una componente social rilassata, non aggressiva.

Funzioni future:

* profilo pubblico
* aggiunta amici
* vedere le ultime scoperte degli amici
* condividere carte
* classifiche leggere
* like alle scoperte
* album condivisibili

Niente PvP aggressivo nella prima versione.

## 18. Mappa

La mappa deve mostrare:

* scoperte personali
* città della scoperta
* storico catture
* marker colorati
* zone visitate

La privacy è fondamentale.

Le coordinate precise non devono essere pubbliche di default.

## 19. Monetizzazione

Modello freemium.

Utente gratuito:

* scansioni giornaliere limitate
* pubblicità
* accesso base al CatDex
* missioni base

Premium:

* niente pubblicità
* scansioni illimitate o molto aumentate
* badge premium
* statistiche avanzate
* temi speciali
* profilo premium

Prezzi iniziali:

* 2,99€ al mese
* 19,99€ all’anno

Pubblicità:

* AdMob
* rewarded ads
* niente pubblicità troppo invasive

Rewarded ads possibili:

* scansione extra
* boost XP temporaneo
* ricompensa giornaliera
* radar gatto raro

## 20. Tone of Voice

CatDex deve parlare in modo:

* simpatico
* giovane
* rilassante
* positivo
* internazionale
* mai troppo tecnico

Esempi:

* “Nuovo gatto scoperto!”
* “Che cattura adorabile!”
* “Questo micio è raro!”
* “Il tuo CatDex cresce!”
* “Hai trovato una variante speciale!”

## 21. Obiettivo MVP

La prima versione giocabile deve includere:

* login
* profilo utente
* fotocamera/upload
* AI analysis
* salvataggio scoperta
* CatDex
* XP
* livelli
* rarità
* varianti base
* città della scoperta
* home da gioco mobile
* UI cartoon
* Android/iOS ready

## 22. Obiettivo v1.0 pubblicabile

La prima versione pubblicabile deve includere:

* onboarding
* login
* privacy policy
* CatDex 100+ entry
* AI stabile
* GPS città/regione/paese
* XP e livelli
* missioni giornaliere
* achievement
* profilo
* AdMob base
* premium architecture
* build Android
* build iOS
* App Store / Play Store compliance

## 23. Visione a lungo termine

CatDex deve diventare il gioco mobile rilassante per chi ama fotografare e collezionare gatti.

Non deve essere solo un riconoscitore AI.

Deve essere un gioco da aprire ogni giorno per scoprire, collezionare, condividere e completare il proprio mondo di gatti.
