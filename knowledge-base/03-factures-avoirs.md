# Factures clients et avoirs

## Créer une facture client
Comptabilité (ou Facturation) > Clients > Factures > Nouveau. Choisissez le client, ajoutez les lignes de produits, vérifiez les taxes puis cliquez sur « Confirmer ». La facture reçoit alors son numéro définitif. Une facture peut aussi être créée depuis une commande client : bouton « Créer une facture » sur la commande.

## Corriger une facture déjà confirmée
Une facture confirmée ne se modifie pas directement. Si elle n'a pas été envoyée ni payée, cliquez sur « Remettre en brouillon », corrigez puis confirmez à nouveau. Si elle a déjà été envoyée au client, créez un avoir.

## Créer un avoir (note de crédit)
Ouvrez la facture confirmée puis cliquez sur « Avoir ». Choisissez un remboursement partiel (avoir en brouillon à ajuster) ou une annulation complète. Le montant de l'avoir est ensuite lettré avec la facture d'origine ou remboursé au client.

## Numérotation des factures
Odoo numérote les factures par journal et par année (par exemple INV/2026/00042). La numérotation est séquentielle et ne doit pas comporter de trous : on ne supprime pas une facture confirmée, on l'annule par un avoir. Pour changer le préfixe, modifiez le code court du journal (Comptabilité > Configuration > Journaux) avant la première facture de l'année.

## Envoyer une facture par e-mail
Sur la facture, bouton « Envoyer et imprimer ». Odoo joint le PDF et utilise le modèle d'e-mail de facture. Si l'e-mail n'arrive pas chez le client, vérifiez l'adresse e-mail du contact et le serveur de messagerie sortant.
