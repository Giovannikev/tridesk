# Charte graphique — TriDesk

**TriDesk** trie les tickets de support et y répond. L'identité visuelle se veut **premium et sobre** : beaucoup d'espace, une couleur sombre dominante et une seule touche menthe.

## Logo

| Fichier | Usage |
|---|---|
| `logo.svg` / `logo.png` | logo complet, sur fond clair |
| `logo-dark.svg` / `logo-dark.png` | logo complet, sur fond sombre |
| `logo-mark.svg` / `logo-mark-512.png` | symbole seul : avatar GitHub, favicon, icône de slide |
| `banner.svg` / `banner.png` | bannière du dépôt (1280 × 320) et image d'aperçu sur les réseaux sociaux |

**Le symbole** représente trois tickets triés par priorité. Le premier, en menthe, est celui qui est traité, et le point indique qu'il est résolu. Le dernier, estompé, est en attente.

**Règles**
- Laisser autour du logo une marge au moins égale à la hauteur d'une barre du symbole.
- Taille minimale : 24 px pour le symbole seul, 96 px de large pour le logo complet.
- Ne pas déformer le logo, ne pas changer ses couleurs et ne pas ajouter d'ombre.
- Le mot s'écrit toujours **TriDesk** (T et D en majuscules, en un seul mot). « Tri » est en couleur de texte, « Desk » en pétrole sur fond clair, en menthe sur fond sombre.

## Couleurs — palette retenue « Bleu pétrole et menthe »

| Nom | Hex | Rôle |
|---|---|---|
| Pétrole nuit | `#0D2226` | fond sombre principal, texte sur fond clair |
| Pétrole profond | `#16343A` | surfaces et cartes sur fond sombre |
| Pétrole | `#1F6F68` | accent **sur fond clair** (titres d'étiquette, chiffres, liens) |
| Menthe | `#5CC8B4` | accent **sur fond sombre** uniquement (trop clair pour du texte sur fond clair) |
| Gris pétrole | `#7E9396` | texte secondaire, légendes |
| Brume | `#EEF3F3` | fond clair, texte sur fond sombre |
| Blanc carte | `#FBFDFD` | cartes et blocs sur fond clair, bordure `#D6E1E1` |

**Couleurs d'état**, réservées aux données (tableau de bord, slides de résultats). Elles se distinguent aussi par le texte, jamais par la couleur seule :
- critique : `#B5483F` ;
- escalade : `#D08A3E` ;
- résolu : `#1F6F68`.

**Proportions conseillées** : 70 % Pétrole nuit ou Brume, 25 % Pétrole profond ou Gris pétrole, **5 % Menthe au maximum**. L'accent ne marche que s'il reste rare : un mot, un trait ou un chiffre clé par écran. Pas de crème ni de beige.

### Palettes écartées
| Palette | Fond | Accent | Pourquoi pas retenue |
|---|---|---|---|
| Encre et laiton | `#0E1726` | `#C9A45C` | or et crème : rendu jugé trop « généré par IA » |
| Monochrome graphite | `#111113` | aucun | très sobre, mais sans repère de marque |
| Graphite et bleu cobalt | `#0B0D12` | `#3B5BFD` | proche de beaucoup d'outils SaaS |
| Noir et orange signal | `#121212` | `#FF5A1F` | trop affirmé pour un outil de support |

## Typographie

| Usage | Police | Graisse |
|---|---|---|
| Titres, logo | **Manrope** | 700, 600 |
| Texte courant | **Inter** | 400, 500 |
| Code, commandes | **JetBrains Mono** | 400 |

Ces trois polices sont libres et disponibles sur Google Fonts. Si elles manquent sur la machine, on utilise Segoe UI, Helvetica ou Arial.

Règles :
- Titres en casse de phrase (« Architecture de la solution »), jamais tout en majuscules.
- Petites étiquettes en majuscules espacées, en Gris pétrole (comme « N8N · RAG · LLM LOCAL » sur la bannière).

## Mise en page (slides, article, vidéo)
- **Slides** : fond Pétrole nuit pour la couverture et les transitions, fond Brume pour le contenu, cartes en Blanc carte. Un seul message par slide.
- **Vidéo** : écran titre en bannière, puis le symbole en filigrane dans un coin pendant la démo.
- **Captures d'écran** : coins arrondis de 12 px et fine bordure Pétrole profond. Pas d'ombre portée.
- **Ton** : phrases courtes, à la voix active, en vouvoyant le lecteur. Pas de superlatifs (« révolutionnaire », « ultime »).
