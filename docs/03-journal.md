# Journal de décisions

> 🟡 Document vivant. Chaque décision structurante est datée ici, du plus récent au plus ancien.

## 2026-06-10 — Étape 3 validée : création manuelle d'objectif + tâche

- Décision : insérer une étape manuelle avant Foundation Models pour valider UI + SwiftData sans
  dépendre du LLM.
- Ajout `ManualGoalDraft` : validation pure et testable des champs, construction `Goal` + une
  `PlanTask`, `TaskType` optionnel, rythme `.once` pour la première version manuelle.
- Ajout `ManualGoalFormView` : formulaire macOS avec objectif, deadline optionnelle, tâche,
  type, durée totale, durée de session, priorité, note/raisonnement.
- Intégration dans `ContentView` via **Créer un objectif manuel**.
- TDD : RED confirmé (`ManualGoalDraft` absent), puis GREEN avec `ManualGoalDraftTests`.
- Validation réelle : `xcodebuild ... build` → **BUILD SUCCEEDED** ; `xcodebuild ... test` →
  **TEST SUCCEEDED**.
- Nettoyage : suppression du test UI de contenu template/fragile ; les tests UI de lancement
  restent actifs, la logique métier est couverte par les tests unitaires.

## 2026-06-10 — Étape 2 implémentée : EventKit + créneaux libres

- Cadrage validé : EventKit est **lecture seule** ; aucun événement calendrier n'est copié dans
  SwiftData. L'app transforme les `EKEvent` en `CalendarEvent` interne.
- Ajout du calcul pur `FreeSlotCalculator` + `SchedulingRules` + `FreeSlot` : retire les événements
  occupés des fenêtres de travail configurées (`Settings`) et filtre les créneaux trop courts.
- TDD effectué : RED sur `FreeSlotCalculatorTests` (types absents), puis GREEN après implémentation.
  Cas couverts : journée vide, événement au milieu, événements qui se chevauchent, jour non
  travaillé, créneau trop court.
- Ajout `CalendarService` (EventKit) : demande `requestFullAccessToEvents()`, lit les événements
  sur une plage, expose un statut lisible.
- Ajout `CalendarDebugView` : bouton **Calendrier** dans `ContentView`, permission, lecture
  d'aujourd'hui, liste événements, liste créneaux libres.
- Config macOS : `NSCalendarsFullAccessUsageDescription` + fallback `NSCalendarsUsageDescription`
  dans l'Info.plist généré ; entitlement sandbox
  `com.apple.security.personal-information.calendars` dans `DayPlanner.entitlements`.
- Validation réelle : `xcodebuild ... build` → **BUILD SUCCEEDED** ; `xcodebuild ... test` →
  **TEST SUCCEEDED** ; bundle vérifié (`Info.plist` + entitlements codesign).
- Validation manuelle Antoine : permission Calendrier acceptée, bouton **Lire aujourd'hui** OK.
  Avec calendrier vide, l'app affiche `9:00 - 19:00` et `10h 0 min`, conforme aux `Settings`
  par défaut.
- Note Xcode : un message `debugserver died with signal SIGKILL` observé à 20:39 correspond au
  `debugserver` bloqué qui a été tué via SSH pour débloquer les tests UI ; ce n'est pas une erreur
  produit DayPlanner.

## 2026-06-10 — Étape 1 validée : setup macOS + modèles SwiftData

- Sur la branche `setup-xcode-project`, remplacement du template SwiftData `Item` par les vrais
  modèles du domaine : `Goal`, `PlanTask`, `Block`, `TaskType`, `Settings` + types support
  (`Rhythm`, `Frequency`, statuts, priorité).
- Décision technique : l'entité métier « Task » est nommée **`PlanTask`** dans le code pour
  éviter le conflit avec `Swift.Task` (async/await). Docs mises à jour.
- Correction SwiftData/Swift 6 : `Rhythm` n'est **pas persisté directement** comme struct
  `Codable` ; `PlanTask` persiste des primitives (`rhythmSessionDuration`, `frequencyKind`,
  `frequencyValue`) et expose `rhythm` comme propriété calculée. Évite le warning/erreur
  `Main actor-isolated conformance ... Encodable`.
- `ContentView` temporaire sert de vue de validation étape 1 : création d'un Goal de test,
  TaskType dynamique, PlanTask, Block, Settings par défaut.
- Validation réelle côté Mac/Xcode : `xcodebuild ... build` → **BUILD SUCCEEDED** ;
  `xcodebuild ... test` → **TEST SUCCEEDED** ; validation manuelle Antoine → app fonctionne.
- Étape 1 du plan MVP marquée **✅ terminée** dans `05-plan-mvp.md`.

## 2026-06-08 — Plateforme : macOS d'abord (inversion de priorité)

- **Développement et usage V1 sur macOS d'abord**, iOS ensuite. Raison (Antoine) : la **limite
  de 7 jours** du provisioning d'un compte développeur **gratuit** force à réinstaller une app
  iOS sur iPhone physique chaque semaine. Sur **macOS**, pas de cette limite → usage perso
  quotidien sans friction.
- Vérifié : `FoundationModels` (Apple Intelligence), EventKit, SwiftUI, App Intents sont **tous
  disponibles sur macOS 26 (Tahoe) / Apple Silicon**. Le pari technique central tient sur Mac.
- Nuance Siri : « Dis Siri » diffère sur Mac, mais les **Raccourcis** fonctionnent (impact
  étape 6 uniquement, pas sur le cœur).

## 2026-06-08 — Plan de dev MVP (7 étapes)

- Rédaction de [`05-plan-mvp.md`](05-plan-mvp.md) : découpage en **7 étapes** ordonnées, avec
  sous-tâches concrètes et **DoD** (« c'est fini quand… ») pour chacune.
- Séquencement : 1) Setup + SwiftData → 2) EventKit → 3) Prototype Foundation Models
  (**dérisquage central**) → 4) Algo de placement → 5) UI SwiftUI → 6) App Intent Siri →
  7) Réglages + polish.
- Logique : dérisquer tôt l'incertitude majeure (le LLM), garder l'UI pour quand la mécanique
  tourne. 2 et 3 parallélisables après 1 ; 4 dépend de 2 + 3.

## 2026-06-08 — Modèle de données : affinage (rhythm, TaskType, priority)

- **`rhythm`** = **structure** `{ sessionDuration, frequency }` (ex. 1h / tous les 2 jours), pas
  une chaîne de texte → l'algo peut la calculer pour étaler les Blocks. Texte d'affichage dérivé.
- **`type` de Task** = **vocabulaire dynamique** : nouvelle entité `TaskType`. Le LLM lit les
  types existants, en réutilise un si pertinent (évite les doublons), sinon en crée un. Concilie
  flexibilité + base stable pour les préférences V2. (Idée d'Antoine.)
- **`priority`** = échelle **haute / moyenne / basse**.
- Entités finales : `Goal`, `Task`, `Block`, `TaskType`, `Settings`.

## 2026-06-08 — Modèle de données (Goal → Task → Block)

- Structure à **3 niveaux** validée : `Goal` (objectif formulé) → `Task` (déduite par le LLM) →
  `Block` (créneau placé par l'algo). Une Task génère N Blocks (gère multi-jours + ponctuel).
- `Goal` = `id`, `rawInput` (phrase brute), `title` (**généré par le LLM**), `deadline`
  (**optionnelle**), `createdAt`, `status`.
- `estimatedDuration` / `rhythm` / `priority` / `reasoning` portés par la **Task** (pas le Goal).
- `Block` = `id`, `start`, `end` (posés par l'algo), `status`.
- `Settings` = contraintes configurables (heures, durée bloc, pause, jours, focus max).
- Le **calendrier (EventKit)** reste externe en lecture seule, **non persisté**.
- Concept de **relation** un-à-plusieurs expliqué à Antoine (appartient à / possède plusieurs).
- Détails : voir [`04-modele-donnees.md`](04-modele-donnees.md).

## 2026-06-08 — Siri, moteur de placement & persistance

- **Siri / App Intents** : **option A** retenue — l'App Intent ouvre l'app sur l'écran d'ajout ;
  la saisie du texte libre (+ dictée native) se fait dans l'app, qui transmet ensuite au LLM.
  Robuste, sans lutter contre les limites de Siri. Option B (texte dicté en arrière-plan)
  gardée pour plus tard.
- **Moteur de placement** : **valeurs par défaut raisonnables + entièrement configurables**.
  Défauts proposés V1 : heures 09–19, bloc 25 min–2 h, pause 10 min, lun–ven, max 6 h focus/j.
- **Persistance** : **SwiftData** (standard Apple moderne).

## 2026-06-08 — Sources externes tranchées (mails/CV → V2/V3)

- **Mails / CV / candidatures** comme source de contexte : **repoussés en V2/V3**. En **V1**, le
  LLM déduit **uniquement** à partir de ce que l'utilisateur formule à la voix/au texte.
- Justification technique : iOS n'expose **aucune API publique** pour lire la boîte Mail de
  l'utilisateur ; passer par Gmail/IMAP (OAuth + parsing) serait un projet à part entière. On
  préserve l'intelligence de déduction sans la complexité d'intégration.

## 2026-06-08 — Premières décisions de cadrage

- **Contexte** : projet **personnel**.
- **Plateformes** : iPhone **15 Pro+ / iOS 26** + **MacBook M5 16 Go**. Restriction matérielle
  de Foundation Models **assumée**, pas de fallback.
- **Périmètre temporel** : planning **multi-jours** dès le MVP (la déduction "entretien dans
  1 mois" impose d'étaler une progression).
- **Préférences** ("pas de LeetCode le matin") : repoussées en **V2**.
- **Répartition LLM / algo clarifiée** (suite à un échange avec Antoine) : le **LLM** porte
  toute l'intelligence — il a un *devoir de déduction* : à partir d'un objectif il déduit le
  **quoi** (étapes en amont), le **comment** et le **rythme**, et il **explique**. L'**algo
  d'ordonnancement** ne fait que **placer** ces blocs dans les trous réels du calendrier sans
  chevauchement (horaires exacts). On ne demande jamais au LLM de calculer les horaires
  minute par minute.
- **Point ouvert majeur soulevé** : la vision d'Antoine veut que le LLM se nourrisse des
  **mails / CV / candidatures** pour déduire le contexte → plus puissant mais bien plus
  ambitieux que le V1 d'origine. Statut MVP **à trancher**.

## 2026-06-08 — Mise en place du cadrage

- Création de la structure de documentation du projet (`README.md` + `docs/`).
- Description originale figée dans `00-description-originale.md`.
- Vision/périmètre et décisions techniques initialisés à partir de la description.
- Aucune décision technique tranchée pour l'instant : phase de réflexion ouverte.
- Points de vigilance posés : Foundation Models on-device (restriction matérielle), découpage
  Siri/App Intents avec texte libre, mémorisation des préférences, séparation nette
  LLM (comprendre) vs algo d'ordonnancement (placer).
