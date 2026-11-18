# Achats, stock et inventaire

## Valider une réception fournisseur
Inventaire > Opérations > Réceptions (ou depuis le bon de commande, bouton « Réception »). Vérifiez les quantités reçues puis « Valider ». En cas de livraison partielle, Odoo propose de créer un reliquat pour le reste.

## Le stock affiché est faux
Vérifiez d'abord qu'aucune réception ou livraison n'est restée en attente (état « Prêt »). Ensuite, faites un ajustement : Inventaire > Opérations > Inventaire physique, saisissez la quantité comptée puis « Appliquer ». Chaque ajustement est tracé dans l'historique des mouvements.

## Produit introuvable dans une livraison ou indisponible
Un produit doit être de type « Produit stockable » (ou « Bien » avec suivi de l'inventaire selon la version) pour être géré en stock. Un produit « Consommable » ou « Service » n'a pas de quantité en stock. Le type se change dans la fiche produit tant qu'aucun mouvement n'a été validé.

## Règles de réapprovisionnement
Inventaire > Configuration > Règles de réapprovisionnement : définissez un minimum et un maximum par produit. Odoo crée automatiquement des demandes de prix fournisseur quand le stock prévu passe sous le minimum (planificateur quotidien, ou « Exécuter le planificateur » manuellement).

## Bons de commande fournisseurs
Achats > Commandes > Demandes de prix > Nouveau. Après confirmation, la demande devient un bon de commande. La facture fournisseur se crée depuis le bon de commande (« Créer une facture ») une fois les produits reçus si la politique de contrôle est « Quantités reçues ».
