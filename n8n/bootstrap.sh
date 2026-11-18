#!/bin/sh
# Premier démarrage de n8n : crée les credentials LOCAUX (Postgres, Mailpit, GreenMail,
# clé d'API), importe et publie les workflows, puis lance l'ingestion de la base de
# connaissances si elle est vide. Les démarrages suivants lancent seulement n8n.
# Pour réimporter les workflows du dépôt (écrase tes modifications dans n8n) :
#   docker compose stop n8n
#   docker compose run --rm -e P04_FORCE_IMPORT=1 -e P04_IMPORT_ONLY=1 n8n
#   docker compose up -d n8n
set -e

MARKER=/home/node/.n8n/.p04-bootstrapped
WF_DIR=/bootstrap/workflows

if [ ! -f "$MARKER" ] || [ "${P04_FORCE_IMPORT:-0}" = "1" ]; then
  echo "[p04] Création des credentials locaux…"
  node -e '
    const e = process.env;
    const creds = [
      { id: "p04CredPostgres1", name: "P04 Postgres", type: "postgres",
        data: { host: "postgres", port: 5432, database: e.POSTGRES_DB, user: e.POSTGRES_USER,
                password: e.POSTGRES_PASSWORD, ssl: "disable", sshTunnel: false } },
      { id: "p04CredSmtpMail1", name: "P04 SMTP Mailpit", type: "smtp",
        data: { host: "mailpit", port: 1025, secure: false, disableStartTls: true, user: "", password: "" } },
      { id: "p04CredImapGreen", name: "P04 IMAP GreenMail", type: "imap",
        data: { host: "greenmail", port: 3143, secure: false, allowUnauthorizedCerts: true,
                user: "support@support.local", password: e.GREENMAIL_PASSWORD } },
      { id: "p04CredApiKey001", name: "P04 API Key", type: "httpHeaderAuth",
        data: { name: "X-API-Key", value: e.TICKETS_API_KEY } },
    ];
    require("fs").writeFileSync("/tmp/p04-credentials.json", JSON.stringify(creds));
  '
  n8n import:credentials --input=/tmp/p04-credentials.json
  rm -f /tmp/p04-credentials.json

  echo "[p04] Import des workflows…"
  n8n import:workflow --separate --input="$WF_DIR"

  for id in $(node -e '
      const fs = require("fs");
      for (const f of fs.readdirSync(process.argv[1]).filter(f => f.endsWith(".json")))
        console.log(JSON.parse(fs.readFileSync(process.argv[1] + "/" + f)).id);
    ' "$WF_DIR"); do
    n8n publish:workflow --id="$id"
  done
  touch "$MARKER"
  echo "[p04] Bootstrap terminé."
fi

[ "${P04_IMPORT_ONLY:-0}" = "1" ] && exit 0

# Ingestion de la base de connaissances en arrière-plan (ignorée si déjà indexée)
(
  until wget -qO- http://127.0.0.1:5678/healthz >/dev/null 2>&1; do sleep 3; done
  sleep 10
  echo "[p04] Ingestion de la base de connaissances (si vide)…"
  wget -qO- --header='Content-Type: application/json' --header="X-API-Key: ${TICKETS_API_KEY}" \
       --post-data='{"only_if_empty": true}' http://127.0.0.1:5678/webhook/kb/reindex \
    && echo "" && echo "[p04] Base de connaissances prête." \
    || echo "[p04] Ingestion non lancée : voir le workflow « P04 · 01 Ingestion »."
) &

exec n8n start
