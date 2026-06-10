# DayPlanner

App iPhone de **planification intelligente de journée**. Elle ne se contente pas de lister
des tâches : elle construit réellement la journée à la place de l'utilisateur, en croisant
ce qui est *déjà prévu* (calendrier) et ce qu'il *doit faire* (tâches ajoutées à la voix ou
dans l'app), puis en générant un planning réaliste et adaptable.

> Question à laquelle l'app répond : **« Qu'est-ce que je dois faire aujourd'hui, à quel
> moment, et pourquoi ? »**

## État du projet

🟡 **Phase de cadrage** — réflexion et spécifications. Aucune ligne de code écrite.
On documente les décisions dans `docs/` avant de démarrer le développement.

**Plateforme de dev V1 : macOS d'abord** (macOS 26 Tahoe, MacBook M5) — évite la limite de
7 jours du provisioning iOS gratuit pour un usage perso quotidien. Portage iOS ensuite.

## Stack cible (Apple)

| Brique | Techno | Rôle |
|---|---|---|
| UI | SwiftUI | Interface de planning quotidien |
| Calendrier | EventKit | Lecture des événements existants |
| Voix | Siri / App Intents | Ajout de tâches & préférences à la voix |
| Compréhension | Apple Intelligence / Foundation Models | Extraction tâche/deadline/durée, sous-tâches, explications |

## Index des documents

| Doc | Contenu | Statut |
|---|---|---|
| [`docs/00-description-originale.md`](docs/00-description-originale.md) | Description initiale (figée, référence) | ✅ Figé |
| [`docs/01-vision-perimetre.md`](docs/01-vision-perimetre.md) | Vision, cible, problème, périmètre MVP | 🟡 En cours |
| [`docs/02-decisions-techniques.md`](docs/02-decisions-techniques.md) | Choix techniques + questions ouvertes | 🟡 En cours |
| [`docs/04-modele-donnees.md`](docs/04-modele-donnees.md) | Entités SwiftData (Goal → Task → Block) + Settings | ✅ Tranché |
| [`docs/05-plan-mvp.md`](docs/05-plan-mvp.md) | Plan de dev MVP : 7 étapes, sous-tâches + DoD | 🟡 En cours |
| [`docs/03-journal.md`](docs/03-journal.md) | Journal de décisions daté | 🟡 Vivant |

## Convention

- Les docs sont vivants : on les modifie au fil de la réflexion.
- Toute décision structurante est datée dans `docs/03-journal.md`.
- `docs/00` ne change pas (c'est la référence d'origine) ; tout le reste évolue.
