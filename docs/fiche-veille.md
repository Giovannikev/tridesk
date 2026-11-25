# Fiche de veille — Tri automatique des tickets de support avec n8n, RAG et LLM

*Projet P04 · ESTI L3 · novembre 2026 · brouillon à relire et compléter par l'équipe*

## 1. État de l'art

Le support client est l'un des premiers usages en entreprise de l'IA générative. Trois tendances se combinent :

- **Automatisation low-code des processus.** Des outils comme n8n, Make ou Zapier relient des services (e-mail, messagerie, bases de données, API) sous forme de workflows visuels. Depuis 2024, ils intègrent des appels aux LLM et des « agents ». Le développeur assemble des briques plutôt que d'écrire toute l'application.
- **RAG (*Retrieval-Augmented Generation*).** Le LLM ne répond plus « de mémoire » : on cherche d'abord dans une base de connaissances les passages proches de la question, par similarité de vecteurs (*embeddings*), puis on les donne au modèle comme contexte. Cette technique réduit les hallucinations et permet de **citer les sources** (Lewis et al., 2020). Elle demande une **base vectorielle**.
- **LLM open source exécutés en local.** Des modèles comme Llama, Mistral ou Qwen, servis par Ollama ou llama.cpp, tournent sans GPU sur un ordinateur portable s'ils sont petits (1 à 8 milliards de paramètres). Les données des clients ne quittent pas l'infrastructure, ce qui simplifie la conformité au RGPD.

Le marché se dirige vers des **assistants qui trient et proposent une réponse, avec un humain dans la boucle** pour les cas sensibles, plutôt que vers des chatbots 100 % autonomes. C'est aussi l'esprit de l'AI Act européen pour les systèmes qui interagissent avec le public : la transparence et la supervision humaine y sont centrales.

## 2. Comparaison des outils

### Moteur d'automatisation

| Critère | **n8n** (retenu) | Make | Zapier |
|---|---|---|---|
| Hébergement | auto-hébergeable (Docker) ou cloud | cloud uniquement | cloud uniquement |
| Licence | *Sustainable Use License* (« fair-code ») : code source ouvert, usage commercial encadré | propriétaire | propriétaire |
| Coût pour le projet | gratuit en auto-hébergement | offre gratuite limitée en opérations | offre gratuite très limitée |
| Code personnalisé | nœuds JavaScript/Python, requêtes HTTP libres | limité | limité (étapes Code) |
| Versionnage | workflows exportés en JSON et versionnés dans Git | export possible, peu pratique | non |
| Données | restent sur notre serveur | transitent par le cloud de l'éditeur | transitent par le cloud de l'éditeur |

### Base vectorielle (recherche RAG)

| Critère | **pgvector** (retenu) | Qdrant | ChromaDB |
|---|---|---|---|
| Nature | extension de PostgreSQL | base vectorielle dédiée (Rust) | base vectorielle embarquée (Python) |
| Licence | PostgreSQL (libre) | Apache 2.0 | Apache 2.0 |
| Index | HNSW, IVFFlat | HNSW, quantification, filtres riches | HNSW |
| Point fort | une seule base pour les tickets, les vecteurs et Grafana ; requêtes SQL et transactions | performances à grande échelle, filtrage | prise en main très rapide en Python |
| Limite | moins optimisé au-delà de plusieurs millions de vecteurs | un service de plus à opérer | pensé pour le prototypage, peu adapté à n8n |

### Fournisseur de LLM

| Critère | **Ollama local** (retenu) | API OpenAI | API Mistral AI |
|---|---|---|---|
| Coût | gratuit (matériel existant) | paiement à l'usage | paiement à l'usage (offre gratuite limitée) |
| Confidentialité | aucune donnée ne sort | données envoyées à un tiers (États-Unis) | données envoyées à un tiers (UE) |
| Qualité / vitesse | correcte pour classer, plus faible pour rédiger ; lent sur CPU (1 à 2 min par ticket) | très bonne, rapide | très bonne, rapide |
| Sortie structurée | schéma JSON imposé (`format`) | *structured outputs* | mode JSON |

## 3. Justification de nos choix

- **n8n** : c'est le seul des trois outils qu'on peut héberger nous-mêmes et versionner dans Git. Le sujet impose un dépôt Git reproductible avec Docker Compose.
- **pgvector** : les tickets, les vecteurs et les vues du tableau de bord sont dans **une seule base**. La recherche RAG reste une requête SQL lisible (`match_kb()`), et Grafana lit directement PostgreSQL.
- **Ollama** avec `qwen2.5:1.5b` pour le chat et `bge-m3` pour les embeddings multilingues : pas de clé payante, et pas de fuite de données. Le modèle tient dans 4 à 5 Go de RAM. Le passage à une API se fait en changeant l'URL des nœuds HTTP.

## 4. Avantages et limites de la solution

**Avantages**
- Stack 100 % open source et locale, démarrée par une seule commande Docker Compose.
- Chaque réponse cite ses sources, et toute réponse incertaine part chez un humain. Cinq règles d'escalade sont testées automatiquement.
- Logique visible et modifiable dans n8n, sans « boîte noire ».

**Limites**
- Lenteur sur CPU : Ollama traite une requête à la fois.
- Un petit modèle rédige parfois une étape approximative.
- La confiance est estimée par le LLM lui-même : il faudrait l'évaluer sur un jeu de tickets annotés.
- La base de connaissances ne contient que 10 fiches. WhatsApp n'est pas intégré, car il exige un compte Business.

## 5. Sources

1. P. Lewis et al., « Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks », NeurIPS 2020 — https://arxiv.org/abs/2005.11401
2. Documentation n8n — https://docs.n8n.io · licence : https://docs.n8n.io/sustainable-use-license/
3. Make — https://www.make.com · Zapier — https://zapier.com
4. pgvector — https://github.com/pgvector/pgvector
5. Qdrant — https://qdrant.tech/documentation/
6. Chroma — https://docs.trychroma.com
7. Ollama — https://github.com/ollama/ollama · Qwen2.5 — https://qwenlm.github.io/blog/qwen2.5/
8. BGE-M3 (embeddings multilingues) — https://huggingface.co/BAAI/bge-m3
9. Règlement européen sur l'IA (AI Act) — https://eur-lex.europa.eu/eli/reg/2024/1689/oj

> À faire par l'équipe : vérifier les offres et les tarifs actuels de Make, Zapier, OpenAI et Mistral à la date de remise, ajouter une capture de l'architecture, puis exporter en PDF de 2 pages.
