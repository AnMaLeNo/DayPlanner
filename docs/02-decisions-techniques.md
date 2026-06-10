# Décisions techniques & questions ouvertes

> 🟡 Document vivant — c'est ici que la réflexion technique se concentre. Chaque décision
> tranchée est aussi datée dans [`03-journal.md`](03-journal.md).

## Stack cible

| Brique | Techno | Rôle | Statut |
|---|---|---|---|
| UI | SwiftUI | Planning quotidien | ✅ Acté |
| Calendrier | EventKit | Lecture des événements | ✅ Acté |
| Voix | Siri / App Intents | Ajout tâches + préférences | ✅ Acté (à cadrer) |
| Compréhension | Apple Intelligence / Foundation Models | Extraction & sous-tâches | 🟡 À valider |
| Persistance | **SwiftData** | Stockage tâches / objectifs / planning | ✅ Acté |

## Points de vigilance identifiés

### 1. Foundation Models on-device
- Framework `FoundationModels` (Apple Intelligence) : dispo **iPhone 15 Pro+** et **iOS 26**
  (le LLM on-device, ~3 Mds de paramètres, tourne sur le Neural Engine, **données privées,
  rien dans le cloud** → idéal pour lire mails/CV sans fuite).
- Extraction structurée via `@Generable` / `@Guide` : faisable pour sortir un objet typé
  (tâche, deadline, type, durée, sous-tâches).
- ⚠️ Qualité sur demandes **vagues** + qualité du **raisonnement de déduction** (déduire le
  quoi/comment/rythme) à valider tôt par un prototype — c'est le pari central du produit.
- ✅ **Acté :** cible **iPhone 15 Pro+ / iOS 26** + **MacBook M5 16 Go**. On **assume** la
  restriction matérielle (pas de fallback : projet perso, on vise les appareils récents).

### 2. Siri ↔ App Intents — découpage acté
- ✅ **Option A retenue** (2026-06-08) : l'App Intent sert à **ouvrir l'app sur l'écran
  d'ajout** ; la **saisie du texte libre se fait dans l'app** (champ + dictée native iOS), puis
  l'app envoie ce texte au LLM. Simple et robuste — on ne se bat pas contre les limites de Siri
  sur la dictée libre arbitraire.
- "Dis Siri, ouvre DayPlanner pour ajouter une tâche" → app au premier plan, écran d'ajout prêt.
- Évolution possible (plus tard) : option B = App Intent avec paramètre texte rempli par dictée
  Siri, traité en arrière-plan sans ouvrir l'app (plus fluide, plus fragile).

### 3. Le LLM a un « devoir de déduction » (cœur intelligent)
- À partir d'un objectif, le LLM doit déduire **le quoi** (sous-tâches/étapes à faire en amont),
  **le comment**, et **le rythme** (ex. 1h de LeetCode tous les 2 jours d'ici l'entretien ;
  ski le 10 nov → acheter vêtements, vérifier matériel, réserver…).
- À terme, il se nourrit du **contexte utilisateur** (mails, CV, candidatures) pour mieux
  déduire — *statut MVP à trancher* (voir 01-vision § questions ouvertes).
- ✅ **Répartition actée des rôles :**
  - **LLM** → comprendre l'objectif + déduire quoi/comment/rythme + **expliquer**. C'est ici
    que vit toute l'intelligence du produit.
  - **Algo d'ordonnancement** → **placer** les blocs ainsi définis dans les **trous réels** du
    calendrier sans chevauchement (calcul d'horaires fiable). On ne demande PAS au LLM de
    calculer des horaires minute par minute (il hallucine les conflits).
  - Frontière nette : le LLM décide *quoi/quand-en-gros/à-quel-rythme*, l'algo garantit
    *les horaires exacts sans conflit*.

### 4. Préférences (V2)
- Apprentissage des préférences ("pas de LeetCode le matin") **repoussé en V2** (acté).
- Quand on y reviendra : commencer par des **règles explicites** simples et lisibles
  (ex. `type=leetcode → fenêtre=soir`) avant tout apprentissage flou.

### 5. Moteur d'ordonnancement (l'algo de placement)
- Croiser créneaux libres (EventKit) + blocs déduits par le LLM + (V2) préférences → planning.
- C'est du **placement sous contraintes**, pas de l'IA.
- ✅ **Acté (2026-06-08) :** **valeurs par défaut raisonnables + entièrement configurables**
  (réglages utilisateur). Proposition de défauts V1 (à raffiner) :

  | Contrainte | Défaut proposé | Configurable |
  |---|---|---|
  | Heures de travail | 09:00 – 19:00 | ✅ |
  | Durée d'un bloc | 25 min – 2 h | ✅ |
  | Pause entre 2 blocs | 10 min | ✅ |
  | Jours travaillés | Lun → Ven | ✅ |
  | Nb max d'heures "focus" / jour | 6 h | ✅ |

- À cadrer plus tard : règle d'**étalement multi-jours** d'ici la deadline (réparti
  uniformément ? plus dense en approchant l'échéance ?).

## Architecture pressentie (à débattre)

````
┌─────────────┐   texte libre   ┌──────────────────────────┐
│ Siri / App  │ ───────────────▶│ Foundation Models (LLM)   │  comprendre l'objectif
│ Intents     │                 │ + DÉDUIRE quoi/comment/   │  + déduire les étapes
└─────────────┘                 │   rythme + EXPLIQUER       │  + le rythme réaliste
                                 └──────────┬───────────────┘
                                            │ Objectif → [blocs à caser]
                                            │ {titre, type, durée, rythme, deadline}
                                            ▼
┌─────────────┐   trous réels   ┌──────────────────────────┐
│ EventKit    │ ───────────────▶│ Moteur d'ordonnancement    │  ← (V2) Préférences
│ (calendrier)│   (créneaux     │ (algo : PLACER sans        │
└─────────────┘    libres)      │  conflit, horaires exacts) │
                                 └──────────┬───────────────┘
                                            │ Planning multi-jours
                                            ▼
                                   ┌─────────────────┐
                                   │ SwiftUI         │  afficher + corriger
                                   └─────────────────┘

LLM = l'intelligence (quoi/comment/rythme/pourquoi)
Algo = la fiabilité (horaires exacts, zéro chevauchement)
````

## Décisions actées

- **2026-06-08** — Plateformes : iPhone 15 Pro+ / iOS 26 + MacBook M5 16 Go ; restriction
  matérielle assumée (pas de fallback).
- **2026-06-08** — Périmètre temporel : planning **multi-jours** dès le MVP.
- **2026-06-08** — Préférences : **V2** (hors MVP).
- **2026-06-08** — **Répartition LLM / algo** : le LLM déduit quoi/comment/rythme + explique ;
  l'algo place les blocs sans conflit. Frontière nette.
- **2026-06-08** — **Siri** : option A (App Intent ouvre l'app sur l'écran d'ajout ; saisie +
  dictée dans l'app).
- **2026-06-08** — **Moteur de placement** : valeurs par défaut raisonnables + configurables.
- **2026-06-08** — **Persistance** : **SwiftData**.

## Questions ouvertes (synthèse)

- [ ] Règle exacte d'**étalement multi-jours** d'ici la deadline (uniforme vs plus dense près
      de l'échéance) ?

### Décidées
- [x] Device cible & iOS min → 15 Pro+ / iOS 26 + MacBook M5.
- [x] Fallback si Apple Intelligence indisponible → non, assumé.
- [x] Mails / CV / candidatures → V2/V3 ; V1 déduit à partir de la voix/texte uniquement.
- [x] Découpage Siri → **option A** (app au premier plan, saisie/dictée dans l'app).
- [x] Contraintes du moteur → défauts raisonnables + configurables.
- [x] Persistance → **SwiftData**.
