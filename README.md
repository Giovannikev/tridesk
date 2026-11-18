# P04 – Assistant de support et tri automatique de tickets (n8n, RAG, LLM)

Projet L3 « Automatisation + IA ». L'assistant reçoit les demandes de support d'un intégrateur **Odoo** par trois canaux (API webhook, e-mail, Telegram). Pour chaque demande, il :
1. classe la demande par **catégorie** et **priorité**, avec un **indice de confiance** ;
2. rédige une **réponse tirée de la base de connaissances** et cite ses sources (RAG) ;
3. répond lui-même au client, ou **fait remonter le cas à un humain** s'il est complexe.

Un **tableau de bord Grafana** suit les délais de traitement.

Tout tourne en local avec Docker : il ne faut aucune clé payante, car le LLM est **Ollama**.

## Architecture

```
 Webhook (API)  ─┐
 E-mail (IMAP)  ─┼─► n8n : enregistre le ticket (PostgreSQL, statut « recu »)
 Telegram       ─┘        │
                          ▼
            10 Traitement d'un ticket (orchestrateur)
              ├─ 20 Classification ── Ollama qwen2.5:3b, sortie JSON structurée
              ├─ 21 Réponse RAG ───── embedding bge-m3 → pgvector (match_kb) → réponse + sources
              └─ 22 Escalade ou réponse automatique
                     ├─ escalade : e-mail à l'agent (Mailpit) + Telegram + accusé au client
                     └─ sinon    : réponse avec sources au client (23 Envoi d'une réponse)

 PostgreSQL + pgvector : tickets, horodatages, journal, base vectorielle  ──►  Grafana
```

| Service | Rôle | URL locale |
|---|---|---|
| n8n 2.44.7 | workflows, webhooks | http://localhost:5679 |
| PostgreSQL 17 + pgvector | tickets, `kb_chunks`, vues | `localhost:5433` |
| Ollama | `qwen2.5:3b` (chat), `bge-m3` (embeddings) | interne |
| Grafana 13 | tableau de bord provisionné | http://localhost:3000 |
| Swagger UI | documentation de l'API | http://localhost:8081 |
| Mailpit | capte **tous** les e-mails sortants | http://localhost:8025 |
| GreenMail | boîte de test `support@support.local` (SMTP 3025, IMAP 3143) | – |

### Pourquoi ces choix
- **pgvector plutôt que Qdrant** : une seule base PostgreSQL stocke les tickets et les vecteurs, et sert de source à Grafana. La recherche reste du SQL : voir la fonction `match_kb()`.
- **Ollama dans la stack** : pas de clé d'API, et aucune donnée client ne sort de la machine. Le modèle `bge-m3` est multilingue, donc adapté au français. `qwen2.5:3b` tient sur un CPU.
- **Sortie JSON structurée** : la requête envoie un schéma JSON dans le champ `format` d'Ollama. Le modèle ne peut répondre qu'avec les valeurs autorisées (les catégories et les priorités).
- **Appels HTTP plutôt que les nœuds « AI » de n8n** : chaque requête au LLM est visible et modifiable dans n8n, ce qui aide à comprendre et à expliquer le fonctionnement.

## Installation

Il faut Docker avec Compose, environ 10 Go de disque et 8 Go de RAM libres. Le premier démarrage télécharge environ 6 Go : les images Docker, puis les modèles Ollama.

```bash
cp .env.example .env
```

Remplace chaque `change-me` du `.env` par une valeur aléatoire, par exemple avec :

```bash
openssl rand -hex 24
```

```bash
docker compose up -d
```

```bash
docker compose logs -f ollama-init n8n
```

Le démarrage se déroule ainsi :
1. `ollama-init` télécharge les deux modèles. n8n attend la fin de ce téléchargement.
2. Au **premier** démarrage, n8n exécute `n8n/bootstrap.sh`. Ce script crée les credentials locaux, importe et publie les 9 workflows, puis indexe la base de connaissances. Attends la ligne `[p04] Base de connaissances prête.`
3. Ouvre http://localhost:5679 et crée ton compte propriétaire n8n.

### Credentials
**Créés automatiquement à partir du `.env`.** Ils ne servent qu'aux services locaux, et aucun secret n'est écrit dans le dépôt.

| Credential n8n | Type | Utilisé pour |
|---|---|---|
| P04 Postgres | Postgres | tickets et base vectorielle |
| P04 SMTP Mailpit | SMTP | réponses aux clients et escalades (captées par Mailpit) |
| P04 IMAP GreenMail | IMAP | canal e-mail entrant |
| P04 API Key | Header Auth `X-API-Key` | protection des webhooks |

**À créer toi-même** si tu passes sur de vrais comptes :
- **Telegram** : crée un bot avec @BotFather et mets le jeton dans `TELEGRAM_BOT_TOKEN`. Ajoute ton chat ID dans `TELEGRAM_AGENT_CHAT_ID` si tu veux aussi recevoir les escalades sur Telegram. Lance ensuite `docker compose up -d n8n`. Le bot interroge Telegram régulièrement (polling) : pas besoin de tunnel ni d'URL publique.
- **Vraie boîte e-mail** : dans n8n, modifie *P04 IMAP GreenMail* (par exemple `imap.gmail.com`, port 993, SSL, avec un mot de passe d'application) et *P04 SMTP Mailpit*, en mettant les adresses dans `SUPPORT_FROM_EMAIL` et `AGENT_EMAIL`.

## Démo pas à pas

1. **Lancer la démo automatique** :

   ```bash
   ./scripts/demo.sh
   ```

   Le script envoie trois tickets et attend que chacun soit traité :
   - *« Mot de passe oublié »* : la réponse automatique cite la fiche « Connexion et mot de passe ». Statut `resolu`.
   - *« Production bloquée »* : priorité **critique**, donc escalade (`priorite_haute`).
   - *« Je voudrais parler à un conseiller »* : escalade (`demande_humain`).

2. **Voir l'escalade** : ouvre Mailpit (http://localhost:8025). L'e-mail `[Escalade][critique] Ticket n°…` contient le message du client, la classification, un brouillon de réponse avec ses sources et la commande pour clore le ticket.

3. **Répondre en tant qu'humain**, ce qui clôt le ticket et envoie la réponse au client par son canal d'origine :

   ```bash
   source .env; curl -X POST localhost:5679/webhook/tickets/2/resolve -H "X-API-Key: $TICKETS_API_KEY" -H "Content-Type: application/json" -d '{"answer":"Le serveur a redémarré, l accès est rétabli.","agent":"Kevin"}'
   ```

4. **Canal e-mail** :

   ```bash
   ./scripts/envoyer_email_test.sh
   ```

   Moins d'une minute plus tard, un ticket `email` est créé et la réponse arrive dans Mailpit.

5. **Canal Telegram**, si un jeton est configuré : écris au bot. L'accusé de réception arrive tout de suite, puis la réponse.

6. **Explorer l'API** : Swagger UI (http://localhost:8081), bouton *Authorize*, puis colle ta `TICKETS_API_KEY`.

7. **Tableau de bord** : Grafana (http://localhost:3000, identifiants `GRAFANA_ADMIN_*`), page « P04 · Support et tri des tickets ». Pour voir 30 jours d'historique fictif, charge les données de démo puis choisis « Données de démo = oui » dans le tableau de bord :

   ```bash
   docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /seed/seed_demo.sql'
   ```

   Pour les supprimer ensuite :

   ```bash
   docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DELETE FROM tickets WHERE is_demo"'
   ```

## Règles métier

**Classification** : le LLM attribue une catégorie et une priorité.
- Catégories : `acces_connexion`, `facturation_comptabilite`, `ventes_crm`, `achats_stock`, `import_export`, `technique_bug`, `hebergement_odoosh`, `autre`.
- Priorités : `critique`, `haute`, `normale`, `basse`. Elles suivent le SLA décrit dans `knowledge-base/10-support-sla-contact.md`.

**Escalade** : le ticket part chez un humain dès qu'une de ces règles est vraie.

| Raison | Condition |
|---|---|
| `demande_humain` | le LLM l'a détecté, ou le texte contient « parler à un conseiller », « rappelez-moi »… |
| `priorite_haute` | priorité `haute` ou `critique` |
| `confiance_faible` | confiance < `CONFIDENCE_MIN` (0,6) |
| `hors_base` | aucun extrait de la base n'atteint une similarité ≥ `SIMILARITY_MIN` (0,5), ou le LLM indique qu'il ne sait pas répondre |
| `erreur_technique` | Ollama ou la recherche vectorielle a échoué : le ticket n'est jamais perdu |

**Horodatages** (table `tickets`) : `received_at`, `classified_at`, `answered_at`, `escalated_at` et `resolved_at`. Chaque changement de statut est aussi enregistré dans `ticket_events` par un trigger. La vue `v_ticket_durations` calcule les délais en secondes pour Grafana.

## Contenu du dépôt

| Chemin | Contenu |
|---|---|
| `docker-compose.yml`, `.env.example` | la stack |
| `postgres/init/` | schéma SQL et rôle Grafana en lecture seule |
| `postgres/seed_demo.sql` | historique fictif (facultatif) |
| `n8n/workflows/` | les 9 workflows importables (01 ingestion, 02 à 04 canaux, 10 orchestrateur, 20 classification, 21 RAG, 22 escalade, 23 envoi) |
| `n8n/bootstrap.sh` | création des credentials locaux, import et publication des workflows |
| `knowledge-base/` | 10 fiches FAQ Odoo en Markdown |
| `openapi/openapi.yaml` | spécification OpenAPI 3 de l'API |
| `grafana/` | source de données et tableau de bord provisionnés |
| `scripts/` | démo, envoi d'un e-mail de test |

## Opérations courantes

**Modifier la base de connaissances** : édite ou ajoute une fiche `.md` (une section par `## Titre`), puis relance l'indexation :

```bash
source .env; curl -X POST localhost:5679/webhook/kb/reindex -H "X-API-Key: $TICKETS_API_KEY"
```

**Changer de modèle** : modifie `CHAT_MODEL` ou `EMBED_MODEL` dans `.env`, puis relance la stack. Après un changement de modèle d'embeddings, relance aussi l'indexation : la dimension des vecteurs change.

```bash
docker compose up -d
```

**Réimporter les workflows du dépôt** : la commande ci-dessous écrase les modifications faites dans n8n.

```bash
docker compose stop n8n && docker compose run --rm -e P04_FORCE_IMPORT=1 n8n
```

Arrête-la avec Ctrl+C une fois l'import terminé, puis redémarre n8n :

```bash
docker compose up -d n8n
```

**Tout remettre à zéro** : cette commande supprime aussi les modèles téléchargés.

```bash
docker compose down -v
```

## Limites et pistes
- Sur un CPU, un ticket prend environ 20 à 90 s. Un GPU ou une API (OpenAI, Mistral…) réduit beaucoup ce délai : il suffit de changer l'URL et le modèle dans les nœuds HTTP « Ollama · … ».
- La confiance est estimée par le LLM lui-même. Pour aller plus loin, on peut la croiser avec la similarité des sources, ou évaluer la classification sur un jeu de tickets annotés.
- Le RAG de démonstration utilise 10 fiches. Pour une vraie base, ajoute un index HNSW sur `kb_chunks.embedding`.
- WhatsApp n'est pas inclus, car il demande un compte WhatsApp Business. On l'ajouterait comme un quatrième canal, qui appellerait le même workflow `10 Traitement d'un ticket`.
