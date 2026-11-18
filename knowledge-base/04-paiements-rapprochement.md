# Paiements et rapprochement bancaire

## Enregistrer un paiement client
Sur la facture confirmée, bouton « Enregistrer un paiement ». Choisissez le journal (banque ou caisse), la date et le montant. La facture passe à l'état « Payé » ou « En paiement » selon que le rapprochement bancaire est fait ou non.

## Facture restée « En paiement »
L'état « En paiement » signifie que le paiement est enregistré mais pas encore rapproché avec une ligne de relevé bancaire. Faites le rapprochement depuis le tableau de bord de Comptabilité : carte du journal de banque > « Rapprocher ». La facture passera alors à « Payé ».

## Rapprochement bancaire
Importez ou synchronisez vos relevés (Comptabilité > tableau de bord > journal de banque). Pour chaque ligne du relevé, Odoo propose la facture correspondante (même montant, même référence). Validez la proposition ou recherchez la bonne facture manuellement. Les modèles de rapprochement (Comptabilité > Configuration > Modèles de rapprochement) automatisent les frais bancaires récurrents.

## Paiement partiel ou en trop
Un paiement inférieur au montant laisse la facture « Partiellement payée ». Un paiement supérieur crée un crédit sur le compte du client, utilisable sur une prochaine facture (bouton « Ajouter » dans le bas de la facture suivante) ou remboursable.

## TVA et taxes
Les taxes se configurent dans Comptabilité > Configuration > Taxes. Une taxe mal paramétrée sur un produit se corrige dans l'onglet « Comptabilité » ou « Informations générales » de la fiche produit. Les factures déjà confirmées gardent l'ancienne taxe : il faut un avoir puis une nouvelle facture.
