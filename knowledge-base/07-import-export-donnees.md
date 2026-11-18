# Import et export de données

## Importer un fichier CSV ou Excel
Dans la vue liste concernée (contacts, produits…), cliquez sur l'engrenage > « Importer des enregistrements ». Téléchargez le modèle d'import proposé par Odoo, remplissez-le puis chargez-le. Utilisez « Tester » avant « Importer » : Odoo affiche les erreurs ligne par ligne sans rien enregistrer.

## Erreurs d'import fréquentes
- « Aucune correspondance trouvée pour… » : la valeur d'un champ relationnel (pays, catégorie, client) n'existe pas exactement sous ce nom. Vérifiez l'orthographe ou utilisez l'identifiant externe.
- Dates refusées : choisissez le bon format de date dans les options d'import (par exemple %d/%m/%Y).
- Caractères accentués illisibles : enregistrez le fichier en UTF-8 ou choisissez le bon encodage dans les options.
- Nombres décimaux : vérifiez le séparateur décimal (virgule ou point) dans les options.

## Mettre à jour des enregistrements existants
Pour mettre à jour au lieu de créer des doublons, exportez d'abord les enregistrements avec la colonne « ID » (identifiant externe), modifiez le fichier, puis réimportez-le : Odoo reconnaît les lignes grâce à cet identifiant.

## Exporter des données
Cochez les enregistrements dans la vue liste > Action > « Exporter ». Choisissez les champs, le format (XLSX ou CSV) et cochez « Je veux mettre à jour des données (export compatible import) » si le fichier doit être réimporté. Les modèles d'export peuvent être enregistrés.

## Gros volumes
Au-delà de quelques dizaines de milliers de lignes, découpez le fichier : l'import se fait en une transaction et peut dépasser le délai du serveur. Sur Odoo.sh, l'import en plusieurs lots est recommandé.
