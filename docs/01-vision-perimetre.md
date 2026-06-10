# Vision & Périmètre

> 🟡 Document vivant. Mis à jour au fil de la réflexion.

## Le problème

Un calendrier montre ce qui est **déjà prévu**. Une todo-list montre ce qu'il **faut faire**.
Aucun des deux ne **construit la journée**. L'utilisateur sait quoi faire mais perd du temps à
décider :

- *quand* faire chaque chose ;
- dans *quel ordre* ;
- *combien de temps* y consacrer ;
- comment *réadapter* quand les préférences ou les imprévus changent.

## La cible

Personnes jonglant avec tâches + RDV + projets + deadlines : étudiants, freelances, salariés,
entrepreneurs. (À affiner : on optimise pour qui en priorité dans le MVP ? → voir questions.)

> **Contexte du projet : projet personnel.** (acté 2026-06-08)

## La proposition de valeur

L'app croise **deux flux** :

1. **Ce qui est prévu** → calendrier (EventKit).
2. **Ce qu'il faut faire** → tâches ajoutées via Siri/App Intents ou dans l'app.

Puis : comprend la demande (Apple Intelligence) → extrait *tâche / deadline / type / durée* →
trouve les créneaux libres → priorise → **génère un planning réaliste**, modifiable, et **explique
ses choix**.

## Ce qui rend le projet original

- Transforme des **intentions vagues** en **blocs de temps concrets**.
- **Devoir de déduction** : à partir d'un objectif, le LLM déduit *ce qui doit être fait en
  amont* (le **quoi**), *comment* le faire, et *à quel rythme*. Ex. : « entretien full-stack »
  → LeetCode + révision backend + frontend + system design + mock interview, étalés ; « ski le
  10 novembre » → acheter vêtements, vérifier matériel, réserver, etc. Le LLM se nourrit
  (à terme) du contexte de l'utilisateur (mails, CV, candidatures…) pour déduire.
- Découpe un objectif en **progression multi-jours**.
- **Apprend les préférences** ("pas de LeetCode le matin") et les réapplique aux tâches du même
  type.
- **Explique** le planning ("pourquoi maintenant").

## Périmètre MVP (V1)

✅ **Dans le périmètre**

- Lecture du calendrier (EventKit).
- Ajout de tâches via Siri / App Intents.
- Compréhension + **déduction** des tâches via Apple Intelligence / Foundation Models
  (déduire le quoi/comment/rythme à partir d'un objectif).
- **Planning multi-jours** (étaler une progression sur plusieurs jours d'ici la deadline).
  *(acté 2026-06-08)*
- Génération du planning (SwiftUI).
- Correction manuelle du planning par l'utilisateur.

❌ **Hors périmètre V1** (plus tard)

- **Apprentissage des préférences** ("pas de LeetCode le matin") → **V2**. *(acté 2026-06-08)*
- **Sources externes (mails, Slack, CV, candidatures)** → **V2/V3**. *(acté 2026-06-08)* En V1,
  le LLM déduit **uniquement** à partir de ce que l'utilisateur formule (voix/texte). Raison :
  iOS n'expose **aucune API publique** pour lire la boîte Mail ; intégrer Gmail/IMAP (OAuth,
  parsing) serait un projet dans le projet. On garde l'intelligence de déduction sans la
  complexité d'intégration.
- (À trancher plus tard : notifications, sync iCloud, widgets…)

## Plateformes cibles *(acté 2026-06-08)*

**Plateforme de développement prioritaire : macOS d'abord.** *(acté 2026-06-08)*
Pour un premier usage **personnel**, développer/utiliser sur macOS évite la **limite de 7 jours**
du provisioning gratuit d'Apple : une app installée sur un iPhone physique avec un compte
développeur **gratuit** expire au bout de 7 jours et doit être réinstallée. Sur macOS, cette
limite **n'existe pas** → Antoine peut utiliser l'app au quotidien sans réinstallation.

- **macOS 26 « Tahoe »** sur **MacBook M5 16 Go** (Apple Silicon) — cible de dev/usage V1.
  `FoundationModels`, EventKit, SwiftUI, App Intents y sont tous disponibles. Aucun blocage du
  pari technique central (LLM on-device dispo sur Mac Apple Silicon).
- **iPhone 15 Pro+ / iOS 26** — cible secondaire, viendra ensuite (mêmes API).
- Nuance : **Siri/App Intents** diffère légèrement sur Mac (pas de « Dis Siri » identique, mais
  les **Raccourcis** fonctionnent). Sans impact sur le cœur ; vu à l'étape 6 du plan.

## Questions ouvertes (vision/périmètre)

- [ ] **Mails / CV / candidatures comme source de contexte** : dans le MVP ou plus tard ? La
      vision « devoir de déduction » s'en nourrit fortement, mais ça alourdit beaucoup le V1.
- [ ] Pour qui optimise-t-on **en priorité** dans le MVP (un persona unique aide à trancher) ?

### Décisions actées (vision/périmètre)

- [x] Contexte : **projet personnel**.
- [x] Plateformes : **iPhone 15 Pro+ / iOS 26**, + **MacBook M5 16 Go**.
- [x] Périmètre temporel : **multi-jours dès le MVP**.
- [x] Apprentissage des préférences : **repoussé en V2**.
- [x] Sources externes (mails/CV/candidatures) : **V2/V3** ; V1 déduit à partir de la
      voix/texte uniquement.
