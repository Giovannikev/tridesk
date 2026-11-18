#!/usr/bin/env bash
# Démo de bout en bout : envoie 3 tickets à l'API puis suit leur traitement.
#   ./scripts/demo.sh
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a
API="http://localhost:${N8N_PORT:-5679}/webhook"
H=(-H "X-API-Key: ${TICKETS_API_KEY}" -H "Content-Type: application/json")

send() {
  curl -sS -X POST "$API/tickets" "${H[@]}" -d "$1" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ticket_id"])'
}

echo "1) Ticket simple (réponse automatique attendue)"
T1=$(send '{"subject":"Mot de passe oublié","message":"Bonjour, j'\''ai oublié mon mot de passe Odoo. Comment le réinitialiser ?","customer":{"name":"Marie Dupont","email":"marie.dupont@exemple.test"}}')
echo "2) Incident critique (escalade attendue : priorité)"
T2=$(send '{"subject":"Production bloquée","message":"Depuis ce matin plus personne ne peut se connecter à Odoo en production, toute la société est bloquée !","customer":{"name":"Paul Martin","email":"paul.martin@exemple.test"}}')
echo "3) Demande d'un humain (escalade attendue : demande explicite)"
T3=$(send '{"message":"Bonjour, je voudrais parler à un conseiller au sujet de nos factures d'\''avoir.","customer":{"name":"Sophie Bernard"}}')
echo "Tickets créés : $T1 $T2 $T3 — traitement par le LLM (sur CPU : plusieurs minutes par ticket)…"

SHOW='
import json, sys
t = json.load(sys.stdin)
print("Catégorie : %s | priorité : %s | confiance : %s" % (t["category"], t["priority"], t["confidence"]))
print("Escalade  :", ", ".join(t["escalation_reasons"]) or "non")
print("Réponse   :", (t["final_answer"] or t["suggested_answer"] or "-")[:800])
for s in t["sources"]:
    print("  [%s] %s › %s (similarité %s)" % (s["n"], s["title"], s["section"], s["similarity"]))
'

for id in $T1 $T2 $T3; do
  for _ in $(seq 1 360); do
    status=$(curl -sS "$API/tickets?id=$id" "${H[@]}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status", "?"))')
    [[ "$status" == "resolu" || "$status" == "escalade" ]] && break
    sleep 5
  done
  echo; echo "===== Ticket $id ($status)"
  curl -sS "$API/tickets?id=$id" "${H[@]}" | python3 -c "$SHOW"
done
echo
echo "E-mails envoyés (escalades, réponses) : http://localhost:${MAILPIT_PORT:-8025}"
echo "Tableau de bord                       : http://localhost:${GRAFANA_PORT:-3000}"
