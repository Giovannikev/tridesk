-- Données FICTIVES pour remplir le tableau de bord Grafana (30 derniers jours).
-- Toutes les lignes ont is_demo = true. Le tableau de bord peut les masquer
-- (variable « Données de démo ») et on les supprime avec :
--   DELETE FROM tickets WHERE is_demo;
-- Lancement :
--   docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /seed/seed_demo.sql'

INSERT INTO tickets (channel, external_id, customer_name, customer_contact, subject, body,
                     status, category, priority, confidence, wants_human, summary,
                     suggested_answer, answerable, answered_by, escalated, escalation_reasons,
                     resolved_by, llm_model, is_demo,
                     received_at, classified_at, answered_at, escalated_at, resolved_at)
SELECT channel, 'demo-' || n, 'Client démo ' || (n % 40), 'demo' || (n % 40) || '@exemple.test',
       'Demande de démonstration ' || n, 'Ticket fictif généré par seed_demo.sql',
       CASE WHEN escalated AND NOT resolved THEN 'escalade' ELSE 'resolu' END,
       category, priority, confidence, wants_human, 'Ticket fictif',
       'Réponse fictive', NOT escalated,
       CASE WHEN escalated AND NOT resolved THEN NULL WHEN escalated THEN 'humain' ELSE 'bot' END,
       escalated,
       CASE WHEN NOT escalated THEN '{}'::text[]
            WHEN wants_human THEN ARRAY['demande_humain']
            WHEN priority IN ('haute', 'critique') THEN ARRAY['priorite_haute']
            ELSE ARRAY['confiance_faible'] END,
       CASE WHEN escalated AND NOT resolved THEN NULL WHEN escalated THEN 'humain' ELSE 'bot' END,
       'demo', true,
       received_at,
       received_at + make_interval(secs => classif_s),
       CASE WHEN escalated AND NOT resolved THEN NULL
            WHEN escalated THEN received_at + make_interval(mins => human_min)
            ELSE received_at + make_interval(secs => classif_s + rag_s) END,
       CASE WHEN escalated THEN received_at + make_interval(secs => classif_s + rag_s) END,
       CASE WHEN escalated AND NOT resolved THEN NULL
            WHEN escalated THEN received_at + make_interval(mins => human_min)
            ELSE received_at + make_interval(secs => classif_s + rag_s) END
FROM (
    SELECT n,
           (ARRAY['webhook','email','email','telegram'])[1 + (random() * 3)::int] AS channel,
           (ARRAY['acces_connexion','acces_connexion','facturation_comptabilite','facturation_comptabilite',
                  'ventes_crm','achats_stock','import_export','technique_bug','technique_bug',
                  'hebergement_odoosh','autre'])[1 + (random() * 10)::int] AS category,
           (ARRAY['basse','normale','normale','normale','haute','critique'])[1 + (random() * 5)::int] AS priority,
           round((0.35 + random() * 0.64)::numeric, 3) AS confidence,
           random() < 0.08 AS wants_human,
           now() - make_interval(days => (random() * 29)::int, hours => (random() * 23)::int,
                                 mins => (random() * 59)::int) AS received_at,
           5 + random() * 20  AS classif_s,
           15 + random() * 40 AS rag_s,
           (20 + random() * 600)::int AS human_min,
           random() < 0.85 AS resolved
    FROM generate_series(1, 300) AS n
) s,
LATERAL (SELECT (s.wants_human OR s.priority IN ('haute', 'critique') OR s.confidence < 0.6) AS escalated) e;
