# Modèle de données

> 🟡 Document vivant. Définit les entités persistées (SwiftData) et leurs relations.
> C'est la **fondation** : tout le reste (algo, UI, LLM) se construit dessus.

## Vue d'ensemble : 3 niveaux

La structure repose sur **3 niveaux** reliés, qui séparent proprement ce que produit le LLM de
ce que produit l'algo :

```
Goal  (Objectif formulé par l'utilisateur)
 └─ PlanTask  (Tâche DÉDUITE par le LLM)  ──référence──▶  TaskType (vocabulaire dynamique)
     └─ Block  (Créneau PLACÉ par l'algo dans le calendrier)

Settings  (contraintes configurables du moteur de placement)
```

> Note technique Swift : l'entité métier « Task » est nommée **`PlanTask`** dans le code pour
> éviter le conflit avec `Swift.Task` (concurrence async/await). Dans les docs produit, on peut
> continuer à parler de « tâche ».

- **Goal** : ce que l'utilisateur formule à la voix/texte. Ex. « préparer un entretien
  full-stack dans 1 mois ».
- **Task** : ce que le **LLM déduit** qu'il faut faire pour atteindre le Goal. Ex. LeetCode,
  révision backend, system design… Chaque Task a sa durée, son rythme, sa priorité.
- **Block** : les morceaux concrets **placés par l'algo** dans des créneaux libres réels. Une
  Task « LeetCode, 1h tous les 2 jours » génère **plusieurs** Blocks.

### Exemple concret

```
Goal: "Préparer entretien full-stack"  (deadline: dans 1 mois)
 ├── Task: "Faire du LeetCode"   (8h total, 1h tous les 2 jours)
 │    ├── Block: mardi 18h–19h
 │    ├── Block: jeudi 18h–19h
 │    └── Block: samedi 18h–19h
 ├── Task: "Réviser le backend"  (6h total, 2h/semaine)
 │    ├── Block: lundi 14h–16h
 │    └── Block: mercredi 14h–16h
 └── Task: "System design"       (3h total, 1h/semaine)
      └── Block: vendredi 10h–12h
```

Pourquoi 3 niveaux : c'est ce qui permet le **multi-jours** (1 Task → N Blocks étalés) et qui
sépare nettement la production du **LLM** (Goal → Tasks) de celle de l'**algo** (Tasks → Blocks).

## Notion de relation (rappel)

Une **relation** = un lien entre deux entités, vu des deux côtés :
- « Task **appartient à** un Goal » → chaque tâche sait de quel objectif elle vient (lien qui
  remonte).
- « Task **possède plusieurs** Block » → chaque tâche connaît tous ses créneaux (lien qui
  descend).

Ici ce sont des relations **un-à-plusieurs** (*one-to-many*) : **un** Goal → **plusieurs**
Tasks ; **une** Task → **plusieurs** Blocks. En SwiftData : `@Relationship`. La suppression d'un
Goal supprime en cascade ses Tasks et leurs Blocks (pas d'orphelins).

## Entités

### 1. `Goal` — Objectif
| Champ | Type | Source | Description |
|---|---|---|---|
| `id` | UUID | système | Identifiant unique |
| `rawInput` | String | **utilisateur** | La phrase brute telle que dite/écrite (utile pour re-déduire) |
| `title` | String | **LLM** | Titre court généré à partir de `rawInput` |
| `deadline` | Date? | LLM/utilisateur | Échéance — **optionnelle** (ex. « apprendre la guitare » n'en a pas) |
| `createdAt` | Date | système | Date de création |
| `status` | enum | système | actif / terminé / abandonné |

**Relation :** un Goal **possède plusieurs** `PlanTask`.

### 2. `PlanTask` — Tâche déduite (par le LLM)
| Champ | Type | Source | Description |
|---|---|---|---|
| `id` | UUID | système | Identifiant unique |
| `title` | String | LLM | Ex. « réviser le backend » |
| `type` | → `TaskType` | LLM | Catégorie (relation, voir ci-dessous). Vocabulaire **dynamique** |
| `estimatedDuration` | Duration | LLM | Durée totale estimée (ex. 5h) |
| `rhythm` | `Rhythm` (struct) | LLM | Rythme déduit, **structuré** (voir ci-dessous) |
| `priority` | enum `Priority` | LLM | **haute / moyenne / basse** |
| `reasoning` | String | LLM | Explication : **pourquoi** cette tâche (le « pourquoi » du produit) |
| `status` | enum | système | à faire / en cours / faite / abandonnée |

**Relations :** une Task **appartient à** un `Goal`, **possède plusieurs** `Block`, et
**référence un** `TaskType`.

#### `rhythm` : structure exploitable par l'algo (pas du texte)
Le LLM ne sort **pas** une chaîne « 1h tous les 2 jours » (l'algo ne pourrait pas la calculer),
mais une **structure** que l'algo place directement :

```
Rhythm {
  sessionDuration: Duration   // ex. 1h  — durée d'une session
  frequency: Frequency        // ex. .everyNDays(2), .weekly, .daily, .once
}
```
> On peut dériver une version texte (« 1h tous les 2 jours ») pour l'affichage à partir de la
> structure — la structure reste la source de vérité.

#### `TaskType` : vocabulaire dynamique (taxonomie évolutive)
Petite entité dédiée qui stocke la **liste des types connus**. Logique de déduction du LLM :
1. il **lit** les `TaskType` existants ;
2. si l'un correspond → il le **réutilise** (évite les doublons « leetcode » / « LeetCode » / « algo ») ;
3. sinon → il **crée** un nouveau `TaskType`.

Champs : `id`, `name` (ex. « leetcode », « révision », « achat », « admin », « sport »).
C'est ce qui rend possible le système de **préférences V2** (« pas de leetcode le matin »
suppose que « leetcode » soit une catégorie stable et identifiable), **tout en restant
flexible**.

### 3. `Block` — Créneau planifié (par l'algo)
| Champ | Type | Source | Description |
|---|---|---|---|
| `id` | UUID | système | Identifiant unique |
| `start` | Date | **algo** | Début exact (horaire posé sans conflit) |
| `end` | Date | **algo** | Fin exacte |
| `status` | enum | utilisateur/système | planifié / fait / déplacé / sauté |

**Relation :** un Block **appartient à** une `PlanTask`.
C'est ce que l'utilisateur **voit et déplace** dans le planning.

> Note : une **tâche ponctuelle** (« appeler le dentiste », « acheter les vêtements de ski »)
> = une Task avec un Rhythm `.once` qui ne génère **qu'un seul** Block. Le modèle gère ponctuel
> et récurrent uniformément.

### 4. `TaskType` — Catégorie de tâche (vocabulaire dynamique)
| Champ | Type | Description |
|---|---|---|
| `id` | UUID | Identifiant unique |
| `name` | String | Nom de la catégorie (ex. « leetcode », « achat »…) |

**Relation :** un TaskType est **référencé par plusieurs** `PlanTask`. Liste alimentée
dynamiquement par le LLM (réutilise ou crée). Base des préférences **V2**.

### 5. `Settings` — Réglages (contraintes du moteur de placement)
| Champ | Type | Défaut proposé |
|---|---|---|
| `workStart` | Time | 09:00 |
| `workEnd` | Time | 19:00 |
| `minBlockDuration` | Duration | 25 min |
| `maxBlockDuration` | Duration | 2 h |
| `breakDuration` | Duration | 10 min |
| `workDays` | [Weekday] | Lun → Ven |
| `maxFocusHoursPerDay` | Duration | 6 h |

Toutes ces valeurs sont **configurables** par l'utilisateur (réglages).

## Ce qui n'est PAS une entité

- **Le calendrier (EventKit)** : source externe **en lecture seule**. L'algo lit les événements
  pour connaître les **trous** (créneaux libres) ; on ne **copie pas** ces événements dans
  SwiftData. Le calendrier reste la propriété d'iOS.

## Décisions actées

- **2026-06-08** — Structure à **3 niveaux** : `Goal → PlanTask → Block` (+ `TaskType`, `Settings`).
- **2026-06-08** — `Goal.title` est **généré par le LLM** depuis `rawInput`.
- **2026-06-08** — `estimatedDuration` / `rhythm` / `priority` / `reasoning` vivent sur la
  **Task**, pas sur le Goal (un Goal n'a ni durée ni rythme unique).
- **2026-06-08** — Un Goal peut exister **sans deadline** (`deadline` optionnelle).
- **2026-06-08** — Le calendrier (EventKit) reste **externe en lecture seule**, pas persisté.
- **2026-06-08** — `rhythm` = **structure** (`sessionDuration` + `frequency`), pas du texte —
  l'algo doit pouvoir la calculer. Version texte dérivée pour l'affichage.
- **2026-06-08** — `type` de Task = **vocabulaire dynamique** via entité `TaskType` : le LLM
  réutilise un type existant ou en crée un nouveau. Concilie préférences V2 et flexibilité.
- **2026-06-08** — `priority` = échelle **haute / moyenne / basse**.

## Questions ouvertes

*(aucune sur le modèle de données pour l'instant — tout est tranché)*
