# Cadrage technique — Étape 4 : Foundation Models → objectif + tâches

> Statut : implémenté et testé côté prototype.
> Date : 2026-06-10, mis à jour le 2026-06-11.

## Objectif de l'étape 4

Valider le pari central du produit : transformer une intention utilisateur formulée naturellement en
un objectif structuré et une liste de tâches concrètes, sans encore générer le planning final.

Exemple d'entrée :

```text
Je dois préparer un entretien full-stack dans un mois.
```

Sortie attendue côté app :

- un `Goal` avec un titre propre ;
- une deadline optionnelle si elle est détectable ;
- 1 à 5 `PlanTask` concrètes ;
- pour chaque tâche : titre, type optionnel, durée estimée, durée de session, priorité, raisonnement.

Cette étape ne crée pas encore de `Block` planifié. Les blocs arriveront à l'étape 5 avec l'algo de
placement.

---

## Vérifications réelles déjà faites

### Présence du framework dans Xcode 26.5

Le SDK local contient bien :

```text
/Applications/Xcode.app/.../MacOSX.sdk/System/Library/Frameworks/FoundationModels.framework
```

Et les interfaces Swift confirment :

- `@Generable`
- `@Guide`
- `SystemLanguageModel`
- `LanguageModelSession`
- `respond(to:generating:)`
- `SystemLanguageModel.Availability`

### Disponibilité réelle du modèle sur le Mac d'Antoine

Spike exécuté sur le Mac :

```text
availability=available
isAvailable=true
supportsCurrentLocale=true
contextSize=4096
```

Langues supportées : le français `fr-FR` est présent.

### Génération structurée réelle

Mini-spike compilé/lancé hors projet avec :

```swift
@Generable
struct ExtractedPlan {
    let goalTitle: String
    let tasks: [ExtractedTask]
}
```

Résultat réel obtenu :

```text
availability=available
goal=Préparer un entretien full-stack; tasks=Réviser le curriculum vitae:150m|Se familiariser avec les technologies de base:120m|Simuler des entretiens:180m|Réviser les questions fréquentes:90m|Pratiquer la communication:100m
```

Conclusion : l'étape 4 est faisable techniquement sur l'environnement actuel.

---

## Contraintes techniques importantes

### Disponibilité OS/framework

`FoundationModels` est disponible à partir de :

```text
iOS 26.0
macOS 26.0
visionOS 26.0
```

Non disponible :

```text
tvOS
watchOS
```

Pour le MVP actuel, on cible macOS/iPhone récents. Le code doit être protégé par :

```swift
if #available(macOS 26.0, iOS 26.0, *) { ... }
```

ou isolé dans des types annotés `@available`.

### Disponibilité runtime du modèle

Même si l'app compile, le modèle peut être indisponible au runtime :

```swift
SystemLanguageModel.default.availability
```

Raisons possibles :

- `deviceNotEligible`
- `appleIntelligenceNotEnabled`
- `modelNotReady`

Le MVP doit afficher un message clair plutôt que planter.

### Fenêtre de contexte

Sur le Mac testé :

```text
contextSize=4096
```

Donc il faut garder les prompts courts : une intention utilisateur, quelques règles de sortie, pas de
gros historique.

### Erreurs à gérer

`LanguageModelSession.GenerationError` peut produire notamment :

- `assetsUnavailable`
- `guardrailViolation`
- `unsupportedLanguageOrLocale`
- `decodingFailure`
- `rateLimited`
- `concurrentRequests`
- `refusal`

Pour le MVP, on affiche un message simple à l'utilisateur et on le laisse revenir à la création
manuelle.

---

## Décision d'architecture

### Ne pas mélanger FoundationModels avec SwiftData

On crée une couche pure :

```text
NaturalLanguagePlanning/
```

Avec des types simples, testables, non SwiftData :

```swift
struct ExtractedGoalDraft
struct ExtractedTaskDraft
```

Puis un mapper transforme ces drafts en modèles existants :

```text
ExtractedGoalDraft -> ManualGoalDraft -> Goal + PlanTask
```

Pourquoi :

- on réutilise la validation déjà testée de `ManualGoalDraft` ;
- le LLM devient juste une autre source d'entrée ;
- si FoundationModels est indisponible, l'app garde le formulaire manuel ;
- les tests peuvent couvrir le mapping sans appeler le modèle.

### Service proposé

```swift
@available(macOS 26.0, iOS 26.0, *)
protocol GoalExtractionProviding {
    func availability() -> GoalExtractionAvailability
    func extractGoal(from rawInput: String) async throws -> ExtractedGoalDraft
}
```

Implémentation FoundationModels :

```swift
FoundationModelsGoalExtractor
```

Responsabilités :

- vérifier `SystemLanguageModel.default.availability` ;
- créer une `LanguageModelSession` avec instructions courtes ;
- appeler `respond(to:generating:)` ;
- retourner un draft structuré ;
- ne jamais écrire directement en base.

### UI proposée

Ajouter une action :

```text
Créer depuis une phrase
```

Flux :

1. l'utilisateur saisit/copie une phrase naturelle ;
2. bouton **Analyser** ;
3. l'app affiche une prévisualisation éditable ;
4. l'utilisateur clique **Créer** ;
5. on persiste comme dans l'étape 3.

Important : ne pas créer directement sans prévisualisation. Le LLM propose, l'utilisateur valide.

---

## Schéma de sortie LLM proposé

Types `@Generable` séparés des modèles SwiftData :

```swift
@Generable
struct ExtractedGoalDraft {
    @Guide(description: "Titre court et clair de l'objectif")
    let goalTitle: String

    @Guide(description: "Deadline ISO yyyy-MM-dd si détectable, sinon chaîne vide")
    let deadlineDate: String

    @Guide(description: "Tâches concrètes", .count(1...5))
    let tasks: [ExtractedTaskDraft]
}

@Generable
struct ExtractedTaskDraft {
    @Guide(description: "Titre court de la tâche")
    let title: String

    @Guide(description: "Type court en minuscules : frontend, backend, design, admin, revision, autre")
    let typeName: String

    @Guide(description: "Durée totale estimée en minutes", .range(15...2400))
    let totalMinutes: Int

    @Guide(description: "Durée recommandée d'une session en minutes", .range(15...180))
    let sessionMinutes: Int

    @Guide(description: "Priorité : low, medium ou high")
    let priority: String

    @Guide(description: "Explication courte du choix")
    let rationale: String
}
```

Décision volontaire : `deadlineDate` en `String`, pas `Date`, parce que le LLM génère mieux du texte
contraint qu'un type `Date` Swift. Le parsing/validation reste côté app.

---

## Règles produit pour le prompt

Instructions système courtes :

- répondre en français ;
- rester concret ;
- ne pas inventer une deadline si elle n'est pas présente ;
- si l'objectif est vague, créer des tâches génériques mais utiles ;
- préférer 1 à 5 tâches ;
- durées réalistes mais prudentes ;
- priorité haute seulement si deadline proche ou objectif important explicite.

Exemple :

```text
Tu transformes une intention utilisateur en objectif et tâches de planning.
Ne crée pas de calendrier. Ne crée pas de blocs horaires.
Si une deadline est ambiguë, laisse deadlineDate vide.
Réponds avec des titres courts, en français.
```

---

## Stratégie de tests

### Tests unitaires sans appeler FoundationModels

À écrire en premier :

- mapping `ExtractedGoalDraft -> ManualGoalDraft` ;
- conversion minutes → heures/session ;
- priorité string `high|medium|low` → `Priority` ;
- deadline ISO valide → `Date` ;
- deadline vide ou invalide → `nil` ;
- type vide → pas de `TaskType` ;
- type existant → réutilisation au moment de la persistance UI/service.

### Test de compilation FoundationModels

Un test ou build suffit à garantir que les types `@Generable` compilent.

### Test manuel obligatoire

Sur Mac :

1. ouvrir **Créer depuis une phrase** ;
2. saisir `Je dois préparer un entretien full-stack dans un mois.` ;
3. cliquer **Analyser** ;
4. vérifier que des tâches sont proposées ;
5. modifier si besoin ;
6. créer ;
7. vérifier que l'objectif et les tâches apparaissent.

---

## Risques et décisions

### Risque confirmé : dates relatives sans date de référence

Smoke test réel : sans date de référence explicite, FoundationModels a produit des deadlines en
2024 pour des demandes relatives comme `dans un mois` / `en moins de trois semaines`.

Correction implémentée : `FoundationModelsGoalExtractor` injecte maintenant :

```text
Date de référence: yyyy-MM-dd
Demande utilisateur: ...
```

Avec `Date de référence: 2026-06-11`, le smoke test retourne des deadlines futures :

- `Je dois préparer un entretien full-stack dans un mois.` → `2026-07-11`
- `Je dois faire un site pour un naturopathe en moins de trois semaines.` → `2026-06-28`

### Risque : tâches proposées imparfaites

Accepté pour le prototype. Mitigation : prévisualisation éditable avant création.

### Risque : modèle indisponible sur certains appareils

Accepté. Mitigation : fallback formulaire manuel, message clair, pas de crash.

### Risque : dates relatives difficiles

Exemple : `dans trois semaines`, `avant juillet`.

Décision MVP : demander au modèle une chaîne ISO si possible, puis valider côté app. Si parsing
échoue, deadline `nil` et l'utilisateur peut corriger plus tard.

### Risque : doublons de `TaskType`

Décision : normaliser `typeName` (`trim`, lowercase) et réutiliser un type existant si le nom existe.
C'est déjà aligné avec l'étape 3.

### Risque : dépendance forte à FoundationModels dans les tests

Décision : pas d'appel LLM dans les tests unitaires. Le LLM est testé manuellement/spike ; la logique
app est testée par mapping pur.

---

## Décision de périmètre pour l'étape 4

Inclus :

- service FoundationModels minimal ;
- types `@Generable` ;
- écran **Créer depuis une phrase** ;
- prévisualisation éditable simple ;
- création de `Goal + PlanTask` après validation utilisateur ;
- gestion d'indisponibilité du modèle ;
- tests unitaires du mapping.

Exclus :

- génération automatique de blocs horaires ;
- App Intents / Siri ;
- apprentissage des préférences utilisateur ;
- streaming token par token ;
- tool calling ;
- persistance du transcript LLM.

---

## Prochaine action recommandée

Écrire le plan d'implémentation détaillé de l'étape 4, puis coder en TDD :

1. tests de mapping ;
2. types drafts purs ;
3. types `@Generable` FoundationModels ;
4. service `FoundationModelsGoalExtractor` ;
5. écran UI ;
6. validation build/test ;
7. validation manuelle par Antoine.
