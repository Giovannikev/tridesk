# Charte graphique — TriDesk

**TriDesk** trie les tickets de support et y répond. L'identité visuelle se veut **premium et sobre** : beaucoup d'espace, une couleur sombre dominante et une seule touche dorée.

## Logo

| Fichier | Usage |
|---|---|
| `logo.svg` / `logo.png` | logo complet, sur fond clair |
| `logo-dark.svg` / `logo-dark.png` | logo complet, sur fond sombre |
| `logo-mark.svg` / `logo-mark-512.png` | symbole seul : avatar GitHub, favicon, icône de slide |
| `banner.svg` / `banner.png` | bannière du dépôt (1280 × 320) et image d'aperçu sur les réseaux sociaux |

**Le symbole** représente trois tickets triés par priorité. Le premier, en laiton, est celui qui est traité, et le point indique qu'il est résolu. Le dernier, estompé, est en attente.

**Règles**
- Laisser autour du logo une marge au moins égale à la hauteur d'une barre du symbole.
- Taille minimale : 24 px pour le symbole seul, 96 px de large pour le logo complet.
- Ne pas déformer le logo, ne pas changer ses couleurs et ne pas ajouter d'ombre.
- Le mot s'écrit toujours **TriDesk** (T et D en majuscules, en un seul mot). « Tri » est en couleur de texte, « Desk » en laiton.

## Couleurs — palette retenue « Encre & laiton »

| Nom | Hex | Rôle |
|---|---|---|
| Encre | `#0E1726` | fond sombre principal, texte sur fond clair |
| Ardoise | `#1E2A3B` | surfaces et cartes sur fond sombre |
| Brume | `#8A96A8` | texte secondaire, légendes |
| Brume claire | `#F3F5F8` | fond clair (gris-blanc froid), texte sur fond sombre |
| Laiton | `#C9A45C` | accent **sur fond sombre** uniquement |
| Blanc carte | `#FDFDFE` | cartes et blocs sur fond clair, bordure `#DDE2E9` |
| Laiton foncé | `#A8823C` | accent sur fond clair (meilleur contraste) |

**Couleurs d'état**, réservées aux données (tableau de bord, slides de résultats) :
- critique : `#B5483F` ;
- escalade : `#D08A3E` ;
- résolu : `#3E8E7E`.

**Proportions conseillées** : 70 % Encre ou Brume claire, 25 % Ardoise ou Brume, **5 % Laiton au maximum**. L'accent doré ne marche que s'il reste rare : un mot, un trait ou un chiffre clé par écran.

### Alternatives proposées
Si l'équipe préfère une autre ambiance, il suffit de changer l'accent. Le reste de la palette ne bouge pas.

| Palette | Fond | Accent | Ambiance |
|---|---|---|---|
| **Encre & laiton** (retenue) | `#0E1726` | `#C9A45C` | institutionnel, haut de gamme |
| Graphite & émeraude | `#16181D` | `#2F8F6F` | technique, « produit SaaS » |
| Nuit & bordeaux | `#121420` | `#8C2F39` | plus chaleureux, éditorial |

## Typographie

| Usage | Police | Graisse |
|---|---|---|
| Titres, logo | **Manrope** | 700, 600 |
| Texte courant | **Inter** | 400, 500 |
| Code, commandes | **JetBrains Mono** | 400 |

Ces trois polices sont libres et disponibles sur Google Fonts. Si elles manquent sur la machine, on utilise Segoe UI, Helvetica ou Arial.

Règles :
- Titres en casse de phrase (« Architecture de la solution »), jamais tout en majuscules.
- Petites étiquettes en majuscules espacées, en Brume (comme « N8N · RAG · LLM LOCAL » sur la bannière).

## Mise en page (slides, article, vidéo)
- **Slides** : fond Encre pour la couverture et les transitions, fond Brume claire pour le contenu (jamais de crème ni de beige : trop « généré par IA »). Un seul message par slide.
- **Vidéo** : écran titre en bannière, puis le symbole en filigrane dans un coin pendant la démo.
- **Captures d'écran** : coins arrondis de 12 px et fine bordure Ardoise. Pas d'ombre portée.
- **Ton** : phrases courtes, à la voix active, en vouvoyant le lecteur. Pas de superlatifs (« révolutionnaire », « ultime »).
