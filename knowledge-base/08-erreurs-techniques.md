# Erreurs techniques et lenteurs

## Message « Erreur serveur » ou « Odoo Server Error »
Cliquez sur « Voir les détails » (ou « Copier l'erreur dans le presse-papiers ») et transmettez le texte complet au support avec : l'heure, l'action réalisée, le menu et l'enregistrement concernés. Sans ce traceback, le diagnostic est très difficile.

## Avant de signaler un bug
1. Rechargez la page avec Ctrl+Maj+R pour vider le cache du navigateur.
2. Réessayez dans une fenêtre de navigation privée ou un autre navigateur.
3. Notez si l'erreur concerne tous les utilisateurs ou un seul (souvent un problème de droits).
4. Indiquez si le problème est apparu après une mise à jour ou l'installation d'un module.

## Odoo est lent
Une lenteur ponctuelle sur une seule vue vient souvent d'un filtre ou d'un regroupement trop large : réduisez la période. Une lenteur générale pour tous les utilisateurs peut venir du serveur ou d'une tâche planifiée lourde ; signalez-la au support avec l'heure exacte. Si Odoo est complètement inaccessible pour toute l'entreprise, c'est un incident critique.

## Mode développeur
Le mode développeur s'active dans Paramètres > « Activer le mode développeur » (ou en ajoutant ?debug=1 à l'URL). Il affiche les noms techniques des champs, utiles pour le support. Ne modifiez pas de vues ou de champs en mode développeur sans accord : ces modifications peuvent être écrasées par une mise à jour.

## Mise à jour d'un module
Après l'installation d'une nouvelle version d'un module spécifique, la mise à jour se fait par Applications > rechercher le module > « Mettre à jour » (mode développeur). En production, ne lancez une mise à jour qu'après validation sur une base de test (staging).
