#!/bin/sh
# Rôle en lecture seule pour Grafana (mot de passe lu dans .env)
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v pwd="$GRAFANA_DB_PASSWORD" -v db="$POSTGRES_DB" <<'SQL'
CREATE ROLE grafana_ro LOGIN PASSWORD :'pwd';
GRANT CONNECT ON DATABASE :"db" TO grafana_ro;
GRANT USAGE ON SCHEMA public TO grafana_ro;
GRANT SELECT ON tickets, ticket_events, v_ticket_durations, kb_chunks TO grafana_ro;
SQL
