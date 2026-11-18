# Hébergement Odoo.sh

## Branches : production, staging et développement
Odoo.sh sépare trois types de branches. La branche de production contient les vraies données. Les branches staging reçoivent une copie récente des données de production (anonymisée pour les e-mails sortants) pour tester. Les branches de développement démarrent avec des données de démonstration.

## Sauvegardes
Odoo.sh fait des sauvegardes automatiques quotidiennes de la production, conservées sur plusieurs semaines, et répliquées dans plusieurs centres de données. Une sauvegarde manuelle se lance depuis la branche de production > onglet « Backups » > « Backup ». Avant une opération risquée (import massif, mise à jour), faites une sauvegarde manuelle.

## Restaurer une sauvegarde
Onglet « Backups » de la branche de production > choisir la sauvegarde > « Restore ». La restauration remplace les données actuelles : toutes les saisies faites depuis la sauvegarde sont perdues. Seul un administrateur du projet peut la lancer. En cas de doute, contactez le support avant de restaurer.

## Build en échec (rouge)
Un build rouge signifie qu'une erreur est survenue à l'installation ou à la mise à jour des modules, ou que des tests échouent. Ouvrez l'onglet « Logs » du build (fichiers install.log ou update.log) pour lire le traceback. La production reste sur l'ancien code tant que le build de production n'est pas réussi.

## Base staging qui disparaît
Les branches staging et de développement inactives peuvent être supprimées ou leurs bases réinitialisées par Odoo.sh. Une nouvelle base staging est créée au prochain commit à partir de la production. Ne stockez pas de données importantes uniquement en staging.

## Nom de domaine personnalisé
Settings > Custom domains sur la branche de production : ajoutez le domaine puis créez chez votre registraire un enregistrement CNAME vers l'adresse odoo.com du projet. Le certificat HTTPS est généré automatiquement une fois le DNS propagé.
