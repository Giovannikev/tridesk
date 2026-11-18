# Droits d'accès et utilisateurs

## Erreur « Accès refusé » ou « Vous n'êtes pas autorisé »
Ce message signifie que votre utilisateur n'a pas le droit de lire ou de modifier ce type d'enregistrement. Un administrateur doit ouvrir votre fiche (Paramètres > Utilisateurs et sociétés > Utilisateurs) et vous donner le bon niveau d'accès dans l'onglet « Droits d'accès » (par exemple Ventes : « Utilisateur : tous les documents » ou Comptabilité : « Facturation »). Déconnectez-vous puis reconnectez-vous pour appliquer le changement.

Indiquez au support le texte complet du message : il précise le modèle concerné (par exemple account.move) et l'opération refusée (lecture, écriture, création, suppression).

## Ajouter un utilisateur
Paramètres > Utilisateurs et sociétés > Utilisateurs > Nouveau. Renseignez le nom et l'adresse e-mail (qui sert d'identifiant), choisissez les droits par application puis enregistrez : l'invitation part automatiquement. Chaque utilisateur interne compte dans l'abonnement Odoo.

## Désactiver un utilisateur qui quitte l'entreprise
Ne supprimez pas l'utilisateur : ouvrez sa fiche puis Action > « Archiver ». Il ne peut plus se connecter, mais son historique (devis, factures, messages) est conservé. L'archivage libère aussi la licence.

## Multi-société
Si vous travaillez sur plusieurs sociétés, le sélecteur en haut à droite permet de cocher les sociétés actives. Un enregistrement d'une société non cochée n'apparaît pas et peut provoquer une erreur de règle d'accès. L'administrateur définit les sociétés autorisées dans l'onglet « Droits d'accès » de l'utilisateur.
