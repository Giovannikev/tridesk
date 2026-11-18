#!/usr/bin/env bash
# Envoie un e-mail de test à support@support.local (GreenMail, SMTP 3025) :
# le workflow « P04 · 03 Canal e-mail » le relève et crée un ticket.
#   ./scripts/envoyer_email_test.sh ["Sujet"] ["Message"]
set -euo pipefail
DEFAULT_SUBJECT="Erreur à l'import de mes contacts"
DEFAULT_BODY="Bonjour, quand j'importe mon fichier CSV de contacts, Odoo affiche « Aucune correspondance trouvée » pour la colonne Pays. Que faire ?"
SUBJECT="${1:-$DEFAULT_SUBJECT}"
BODY="${2:-$DEFAULT_BODY}"
FROM="client.test@exemple.test"
curl -sS --url smtp://localhost:3025 --mail-from "$FROM" --mail-rcpt support@support.local --upload-file - <<MAIL
From: Client Test <$FROM>
To: support@support.local
Subject: =?UTF-8?B?$(printf '%s' "$SUBJECT" | base64 -w0)?=
Message-ID: <$(date +%s%N)@exemple.test>
Date: $(LC_ALL=C date -R)
Content-Type: text/plain; charset=utf-8

$BODY
MAIL
echo "E-mail envoyé. La réponse arrivera dans Mailpit : http://localhost:8025"
