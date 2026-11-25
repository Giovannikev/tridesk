#!/usr/bin/env bash
# Démarre une base PostgreSQL + pgvector jetable, initialisée exactement comme dans
# docker-compose.yml (postgres/init/), puis lance tests/sql/test_schema.sql.
#   ./tests/sql/run.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

IMAGE=$(sed -n 's/^ *image: *\(pgvector\/pgvector:.*\)$/\1/p' docker-compose.yml | head -1)
NAME="p04-sql-test-$$"
PW=$(openssl rand -hex 12 2>/dev/null || echo "test-$$")

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Image : $IMAGE"
docker run -d --name "$NAME" \
  -e POSTGRES_DB=support -e POSTGRES_USER=support -e POSTGRES_PASSWORD="$PW" -e GRAFANA_DB_PASSWORD="$PW" \
  -v "$PWD/postgres/init:/docker-entrypoint-initdb.d:ro" \
  -v "$PWD/postgres/seed_demo.sql:/seed/seed_demo.sql:ro" \
  -v "$PWD/tests/sql:/tests:ro" \
  "$IMAGE" >/dev/null

# Attendre la fin des scripts d'initialisation (le serveur redémarre ensuite)
for _ in $(seq 1 60); do
  if docker logs "$NAME" 2>&1 | grep -q 'PostgreSQL init process complete' \
     && docker exec "$NAME" pg_isready -U support -d support >/dev/null 2>&1; then
    break
  fi
  if ! docker ps -q -f "name=$NAME" | grep -q .; then docker logs "$NAME"; exit 1; fi
  sleep 1
done

docker exec "$NAME" psql -U support -d support -v ON_ERROR_STOP=1 -f /tests/test_schema.sql
