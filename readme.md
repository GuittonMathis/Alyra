# Readme.md

## Vue d'ensemble
Le fichier `test.js` est une suite de tests pour une application de vote basée sur un contrat intelligent de Solidity. Cette application de vote prend en charge l'inscription des votants, l'enregistrement des propositions, le vote, et le décompte des votes. Les tests sont écrits en **JavaScript** en utilisant les bibliothèques _chai_ pour les assertions, _openzeppelin-test-helpers_ pour certaines fonctionnalités de test de contrat intelligent, et le framework de test _mocha_.

## Fonctionnalités testées
### 1. Inscription des votants
Les tests vérifient si l'application :

- Enregistre correctement un votant
- Empêche l'enregistrement deux fois du même votant
- Rejette l'inscription des votants lorsque la phase d'inscription n'est pas encore ouverte
- Rejette l'inscription d'un votant par un utilisateur qui n'est pas propriétaire du contrat

### 2. Enregistrement des propositions
Les tests vérifient si l'application :

- Commence correctement la phase d'enregistrement des propositions
- Permet à un votant enregistré d'ajouter une proposition
- Rejette l'ajout d'une proposition par un non-votant
- Rejette l'ajout d'une proposition vide

### 3. Session de vote
Les tests vérifient si l'application :

- Commence correctement la session de vote
- Permet à un votant enregistré de voter
- Met fin correctement à la session de vote
- Rejette un vote avant le début de la session de vote
- Rejette un vote pour une proposition non existante

### 4. Décompte des votes
Les tests vérifient si l'application :

- Compte correctement les votes
- Rejette le décompte des votes avant la fin de la session de vote

## Autres tests
D'autres cas de tests pour les contraintes supplémentaires sont également inclus. Ces tests s'assurent que :

- Un votant enregistré ne peut pas voter après la fin de la session de vote
- Un votant enregistré ne peut pas voter plusieurs fois
- Un votant enregistré ne peut pas modifier une proposition après la fin de la période d'enregistrement des propositions

## Exécution des tests
Pour exécuter ces tests, vous aurez besoin de _Truffle_. Vous pouvez utiliser la commande suivante pour exécuter les tests : `truffle test`
