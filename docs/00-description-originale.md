# Description originale du projet

> ⚠️ **Document figé.** C'est la description initiale fournie par Antoine, conservée comme
> référence. Ne pas modifier. Les évolutions vont dans les autres documents.

---

Mon projet est une app iPhone de planification intelligente de journée. Elle s'adresse aux
personnes qui doivent gérer plusieurs tâches, rendez-vous, projets et deadlines : étudiants,
freelances, salariés, entrepreneurs ou toute personne qui a besoin de transformer ses
objectifs en planning concret.

Le problème que l'app veut résoudre est simple : aujourd'hui, un calendrier montre ce qui est
déjà prévu, et une todo-list montre ce qu'il faut faire, mais aucun des deux ne construit
réellement la journée à la place de l'utilisateur. On sait souvent ce qu'on doit faire, mais
on perd du temps à décider quand le faire, dans quel ordre, combien de temps y consacrer, et
comment adapter le planning quand nos préférences changent.

L'application combine deux types d'informations :
1. ce que l'utilisateur a déjà de prévu, récupéré depuis son calendrier ;
2. ce que l'utilisateur doit faire, ajouté naturellement via Siri ou via l'app.

Par exemple, l'utilisateur peut dire :
"Dis Siri, ajoute une tâche : je dois faire un site pour un naturopathe en moins de trois semaines."
ou :
"Dis Siri, je dois préparer un entretien full-stack dans un mois."
ou encore :
"Dis Siri, je dois faire une application de gestion de stock avant juillet."

L'app utilise Apple Intelligence / Foundation Models pour comprendre la demande, extraire la
tâche principale, la deadline, le type de projet, la durée estimée et éventuellement proposer
des sous-tâches. Ensuite, elle regarde le calendrier de l'utilisateur, identifie les créneaux
libres, classe les tâches par priorité, puis génère un planning réaliste de la journée.

L'originalité du projet est que l'app ne se contente pas de faire une simple todo-list. Elle
transforme des intentions parfois vagues en blocs de temps concrets. Par exemple, si
l'utilisateur ajoute "préparer un entretien full-stack dans un mois", l'app peut proposer une
progression sur plusieurs jours : LeetCode, révision backend, révision frontend, system
design, puis mock interview.

L'utilisateur garde toujours le contrôle. Il peut modifier les priorités, déplacer une tâche
ou donner une préférence à la voix. Par exemple, il peut dire :
"Dis Siri, je n'aime pas faire LeetCode le matin, je préfère le faire le soir."
L'app peut alors réorganiser le planning et retenir cette préférence pour les prochaines fois.
Si une tâche du même type apparaît plus tard, elle proposera plutôt un créneau en fin de
journée. L'objectif est que l'app devienne progressivement plus adaptée à la manière de
travailler de l'utilisateur.

Le MVP se concentre sur un périmètre clair et faisable : lecture du calendrier avec EventKit,
ajout de tâches via Siri/App Intents, compréhension des tâches avec Apple Intelligence/Foundation
Models, génération du planning en SwiftUI, et possibilité pour l'utilisateur de corriger le
planning. Les mails, Slack ou autres sources externes pourraient être ajoutés plus tard, mais
ne sont pas nécessaires pour la première version.

Le projet utilise fortement les technologies Apple :
- SwiftUI pour construire une interface claire de planning quotidien ;
- EventKit pour récupérer les événements du calendrier ;
- Siri / App Intents pour ajouter des tâches et modifier ses préférences à la voix ;
- Apple Intelligence / Foundation Models pour comprendre les objectifs formulés naturellement,
  extraire les deadlines, proposer des sous-tâches et expliquer les choix de planning.

En résumé, l'app répond à une question très concrète : "Qu'est-ce que je dois faire aujourd'hui,
à quel moment, et pourquoi ?" Elle aide l'utilisateur à passer d'une liste de choses à faire à
une journée réellement organisée.
