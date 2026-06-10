# Plan de développement — MVP

> 🟡 Document vivant. Découpage du MVP en étapes ordonnées, avec sous-tâches concrètes et
> critères de fin (**DoD** = *Definition of Done*, « c'est fini quand… »).

## Principe de séquencement

Du plus **fondamental** au plus **visible**, en **dérisquant tôt** la partie la plus incertaine
(le LLM, étape 3). On ne construit l'UI qu'une fois la mécanique en place.

```
1. Setup projet + modèle SwiftData
2. EventKit (lire calendrier → créneaux libres)
3. Prototype Foundation Models (objectif → tâches)   ← dérisquage central
4. Algo de placement (tâches → blocs sans conflit)
5. UI SwiftUI (afficher + corriger)
6. App Intent Siri (entrée vocale, option A)
7. Réglages + polish
```

Chaque étape est **testable seule** avant de passer à la suivante.

---

## Étape 1 — Setup projet + modèle SwiftData

**But :** poser les fondations techniques et le modèle de données défini dans `04-modele-donnees.md`.

**Sous-tâches**
- [ ] Créer le projet Xcode (app **macOS**, cible **macOS 26 Tahoe**, SwiftUI, SwiftData
      activé). *(Dev macOS d'abord — voir `01-vision` : évite la limite 7 j du provisioning iOS
      gratuit. Portage iOS ensuite, mêmes API.)*
- [ ] Configurer le repo Git (`.gitignore` Xcode, commit initial).
- [ ] Définir les `@Model` SwiftData : `Goal`, `Task`, `Block`, `TaskType`, `Settings`.
- [ ] Définir les types support : enums `GoalStatus`, `TaskStatus`, `BlockStatus`, `Priority` ;
      struct `Rhythm { sessionDuration, frequency }` + enum `Frequency`.
- [ ] Déclarer les `@Relationship` (Goal→Tasks, Task→Blocks, Task→TaskType) + suppression en
      cascade.
- [ ] Initialiser un `Settings` par défaut au premier lancement (valeurs par défaut V1).
- [ ] Écrire quelques objets de test (seed) pour visualiser des données.

**DoD — c'est fini quand…**
- L'app compile et se lance sur le simulateur iOS 26.
- On peut créer/lire/supprimer un `Goal` avec ses `Task` et `Block` en mémoire SwiftData.
- Supprimer un `Goal` supprime bien ses `Task` et `Block` (pas d'orphelins).
- Le `Settings` par défaut existe au premier lancement.

---

## Étape 2 — EventKit : lire le calendrier → créneaux libres

**But :** obtenir les **trous** réels de la journée/semaine, matière première de l'algo.

**Sous-tâches**
- [ ] Ajouter la permission calendrier (`NSCalendarsUsageDescription` dans Info.plist).
- [ ] Demander l'autorisation EventKit au runtime + gérer le refus proprement.
- [ ] Lire les événements sur une plage de dates (ex. aujourd'hui → deadline).
- [ ] Écrire une fonction `freeSlots(in:range, settings:)` qui calcule les créneaux libres :
      événements occupés + hors heures de travail + jours non travaillés = exclus.
- [ ] Renvoyer une liste de créneaux libres `[(start, end)]` exploitable par l'algo.

**DoD — c'est fini quand…**
- L'app obtient l'autorisation et lit les vrais événements du calendrier de test.
- `freeSlots(...)` renvoie des créneaux corrects sur des cas testés (journée vide, journée
  pleine, événements qui se chevauchent, hors heures de travail).
- Le calendrier n'est **jamais** copié dans SwiftData (lecture seule confirmée).

---

## Étape 3 — Prototype Foundation Models : objectif → tâches  *(dérisquage central)*

**But :** valider **tôt** le pari du produit : le LLM on-device déduit correctement les tâches,
durées, rythmes et explications à partir d'un objectif formulé librement.

**Sous-tâches**
- [ ] Intégrer le framework `FoundationModels` ; vérifier la disponibilité (device/OS).
- [ ] Définir les types `@Generable` / `@Guide` pour la sortie structurée :
      `Goal.title`, liste de `Task` (title, type, estimatedDuration, rhythm, priority, reasoning).
- [ ] Écrire le prompt de **déduction** : à partir de `rawInput`, déduire le quoi/comment/rythme
      + expliquer. Inclure la **liste des `TaskType` existants** pour réutilisation.
- [ ] Implémenter la logique TaskType : réutiliser un type existant ou en créer un nouveau.
- [ ] Banc de test : ~10 phrases variées (entretien full-stack, site naturopathe, gestion de
      stock, ski le 10 nov, tâche ponctuelle « appeler le dentiste », objectif sans deadline…).
- [ ] Évaluer la qualité : les tâches déduites sont-elles pertinentes ? rythmes réalistes ?

**DoD — c'est fini quand…**
- Pour les ~10 phrases de test, le LLM renvoie un objet structuré **valide** (pas de crash, pas
  de champ manquant).
- Sur une majorité de cas, les tâches/durées/rythmes sont **jugés réalistes** par Antoine.
- Le mécanisme TaskType (réutilise/crée) fonctionne (pas de doublons évidents).
- ⚠️ **Point de décision :** si la qualité est insuffisante, on réévalue ici (prompt, ou repli).

---

## Étape 4 — Algo de placement : tâches → blocs sans conflit

**But :** transformer les `Task` (avec rythme) en `Block` posés dans les créneaux libres, sans
chevauchement, en respectant les `Settings`, étalés jusqu'à la deadline.

**Sous-tâches**
- [ ] Écrire le moteur `schedule(tasks:, freeSlots:, settings:) -> [Block]`.
- [ ] Décliner le `Rhythm` en nombre de sessions à placer (ex. 1h tous les 2 jours d'ici la
      deadline → N sessions).
- [ ] Placer chaque session dans un créneau libre compatible (durée, heures, pause entre blocs,
      max focus/jour).
- [ ] Gérer la **priorité** (tâches haute priorité placées en premier).
- [ ] Gérer le cas « pas assez de place » (deadline trop proche) → signaler à l'utilisateur.
- [ ] Définir la règle d'**étalement multi-jours** (question ouverte : uniforme vs dense près de
      l'échéance — *à trancher*).
- [ ] Tests unitaires sur l'algo (cas limites : 0 créneau, deadline dépassée, journée saturée).

**DoD — c'est fini quand…**
- À partir de tâches + créneaux libres, l'algo produit des `Block` **sans aucun chevauchement**.
- Les contraintes des `Settings` sont respectées (heures, durée bloc, pause, focus max, jours).
- Le cas « impossible à caser » est détecté et remonté (pas de placement silencieux faux).
- Les tests unitaires passent.

---

## Étape 5 — UI SwiftUI : afficher + corriger

**But :** rendre le planning visible et **modifiable** par l'utilisateur (il garde le contrôle).

**Sous-tâches**
- [ ] Vue **planning** (jour + multi-jours) affichant les `Block` dans une timeline.
- [ ] Afficher pour chaque bloc : titre de la tâche, horaire, et accès au **reasoning** (le
      « pourquoi »).
- [ ] Vue **liste des objectifs** (Goals) avec leur progression (blocs faits / total).
- [ ] Marquer un bloc comme **fait / sauté**.
- [ ] **Déplacer** un bloc (drag ou édition d'horaire) → mise à jour SwiftData.
- [ ] Écran d'**ajout d'objectif** (champ texte + dictée native) → déclenche la déduction LLM.
- [ ] États vides / chargement / erreurs (pas d'autorisation calendrier, LLM indispo…).

**DoD — c'est fini quand…**
- L'utilisateur voit son planning multi-jours généré, avec le « pourquoi » de chaque bloc.
- Il peut ajouter un objectif au texte → l'app déduit → place → affiche, bout en bout.
- Il peut cocher, sauter et déplacer un bloc, et ça persiste.

---

## Étape 6 — App Intent Siri (entrée vocale, option A)

**But :** permettre « Dis Siri, ouvre DayPlanner pour ajouter une tâche » → app au premier plan
sur l'écran d'ajout (option A actée).

**Sous-tâches**
- [ ] Définir l'`AppIntent` qui ouvre l'app sur l'écran d'ajout d'objectif.
- [ ] Exposer l'intent à Siri / Raccourcis (`AppShortcutsProvider`, phrases déclencheuses).
- [ ] Vérifier le flux complet : voix → app ouverte → saisie/dictée → déduction LLM.

**DoD — c'est fini quand…**
- « Dis Siri, ouvre DayPlanner pour ajouter une tâche » ouvre bien l'app sur l'écran d'ajout.
- Le raccourci apparaît dans l'app Raccourcis.

---

## Étape 7 — Réglages + polish

**But :** rendre les contraintes configurables et finaliser le MVP.

**Sous-tâches**
- [ ] Écran **Réglages** éditant les `Settings` (heures, durées, pause, jours, focus max).
- [ ] Re-générer / re-placer le planning quand les réglages changent.
- [ ] Vérifier le fonctionnement sur **MacBook M5** (cible Mac).
- [ ] Passe de finition UI (lisibilité, accessibilité de base).
- [ ] Relecture des permissions et messages d'erreur.

**DoD — c'est fini quand…**
- L'utilisateur modifie ses contraintes et le planning s'y conforme.
- L'app tourne sur iPhone 15 Pro+ **et** MacBook M5.
- Le parcours complet (ajout vocal → déduction → planning → correction → réglages) fonctionne.

---

## Vue d'ensemble des dépendances

```
1 Setup ──▶ 2 EventKit ──┐
        └─▶ 3 LLM ───────┼─▶ 4 Algo ──▶ 5 UI ──▶ 6 Siri ──▶ 7 Réglages/polish
                         ┘
```
- 2 et 3 peuvent se faire en parallèle après 1.
- 4 a besoin de 2 (créneaux) **et** 3 (tâches).
- 5 a besoin de 4. 6 et 7 viennent enrichir une app déjà fonctionnelle.

## Question ouverte (héritée)

- [ ] Règle exacte d'**étalement multi-jours** d'ici la deadline (à trancher en étape 4).
