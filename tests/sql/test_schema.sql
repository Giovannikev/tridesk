-- Tests du schéma PostgreSQL (postgres/init/) : contraintes, trigger d'audit,
-- recherche vectorielle match_kb(), vue des délais et rôle Grafana en lecture seule.
-- Lancés par tests/sql/run.sh sur une base neuve. Toute assertion fausse arrête le script.
\set ON_ERROR_STOP on
\set QUIET on
SET client_min_messages = warning;

\echo '1. Création d''un ticket : statut « recu » et journal'
DO $$
DECLARE tid bigint; n int;
BEGIN
  INSERT INTO tickets (channel, external_id, body) VALUES ('webhook', 'test-1', 'Mot de passe oublié')
  RETURNING id INTO tid;
  ASSERT (SELECT status FROM tickets WHERE id = tid) = 'recu', 'statut par défaut';
  SELECT count(*) INTO n FROM ticket_events WHERE ticket_id = tid AND event = 'recu';
  ASSERT n = 1, 'événement « recu » attendu';
END $$;

\echo '2. Changement de statut : une ligne de journal, updated_at mis à jour'
DO $$
DECLARE tid bigint := (SELECT id FROM tickets WHERE external_id = 'test-1'); n int; ev jsonb;
BEGIN
  UPDATE tickets SET updated_at = now() - interval '1 hour' WHERE id = tid;   -- même statut
  SELECT count(*) INTO n FROM ticket_events WHERE ticket_id = tid;
  ASSERT n = 1, 'pas d''événement sans changement de statut';
  ASSERT (SELECT updated_at FROM tickets WHERE id = tid) >= now() - interval '1 minute', 'updated_at forcé par le trigger';

  UPDATE tickets SET status = 'escalade', priority = 'critique', escalated = true,
                     escalation_reasons = '{priorite_haute}' WHERE id = tid;
  SELECT details INTO ev FROM ticket_events WHERE ticket_id = tid AND event = 'escalade';
  ASSERT ev->>'from' = 'recu' AND ev->>'priority' = 'critique', 'détails de l''événement';
  ASSERT ev->'escalation_reasons' = '["priorite_haute"]'::jsonb, 'raisons d''escalade journalisées';
END $$;

\echo '3. Contraintes : valeurs interdites refusées'
DO $$
DECLARE bad text[] := ARRAY[
  $q$INSERT INTO tickets (channel, body) VALUES ('fax', 'x')$q$,
  $q$INSERT INTO tickets (channel, body, category) VALUES ('email', 'x', 'cuisine')$q$,
  $q$INSERT INTO tickets (channel, body, priority) VALUES ('email', 'x', 'urgente')$q$,
  $q$INSERT INTO tickets (channel, body, confidence) VALUES ('email', 'x', 1.5)$q$,
  $q$INSERT INTO tickets (channel, body, status) VALUES ('email', 'x', 'perdu')$q$,
  $q$INSERT INTO tickets (channel) VALUES ('email')$q$,
  $q$INSERT INTO tickets (channel, external_id, body) VALUES ('webhook', 'test-1', 'doublon')$q$
]; q text;
BEGIN
  FOREACH q IN ARRAY bad LOOP
    BEGIN
      EXECUTE q;
      RAISE EXCEPTION 'aurait dû être refusé : %', q;
    EXCEPTION WHEN check_violation OR not_null_violation OR unique_violation THEN NULL;
    END;
  END LOOP;
  -- même external_id sur un autre canal : autorisé
  INSERT INTO tickets (channel, external_id, body) VALUES ('email', 'test-1', 'autre canal');
END $$;

\echo '4. match_kb() : extraits triés par similarité cosinus'
DO $$
DECLARE r record; titles text[];
BEGIN
  INSERT INTO kb_chunks (doc_path, doc_title, section, chunk_index, content, embedding, model) VALUES
    ('a.md', 'A', 's', 0, 'proche',   '[1,0,0]', 'test'),
    ('b.md', 'B', 's', 0, 'moyen',    '[1,1,0]', 'test'),
    ('c.md', 'C', 's', 0, 'opposé',   '[-1,0,0]', 'test');
  SELECT array_agg(doc_title) INTO titles FROM match_kb('[1,0,0]', 2);
  ASSERT titles = ARRAY['A', 'B'], format('ordre inattendu : %s', titles);
  SELECT * INTO r FROM match_kb('[1,0,0]') LIMIT 1;
  ASSERT r.similarity = 1.000, 'vecteur identique = similarité 1';
  SELECT * INTO r FROM match_kb('[1,0,0]') WHERE doc_title = 'B';
  ASSERT r.similarity = 0.707, format('cos 45° attendu, obtenu %s', r.similarity);
  ASSERT (SELECT count(*) FROM match_kb('[1,0,0]')) = 3, 'k = 4 par défaut, 3 extraits disponibles';
END $$;

\echo '5. v_ticket_durations : délais en secondes'
DO $$
DECLARE tid bigint; v record;
BEGIN
  INSERT INTO tickets (channel, body, received_at, classified_at, answered_at, resolved_at)
  VALUES ('telegram', 'x', '2026-11-20 10:00+00', '2026-11-20 10:00:20+00', '2026-11-20 10:01:30+00', '2026-11-20 10:01:30+00')
  RETURNING id INTO tid;
  SELECT * INTO v FROM v_ticket_durations WHERE id = tid;
  ASSERT v.classification_s = 20 AND v.first_response_s = 90 AND v.resolution_s = 90, 'délais';
  ASSERT v.escalation_s IS NULL, 'pas d''escalade';
END $$;

\echo '6. Rôle grafana_ro : lecture seule'
SET ROLE grafana_ro;
DO $$
BEGIN
  PERFORM count(*) FROM v_ticket_durations;
  PERFORM count(*) FROM ticket_events;
  BEGIN
    INSERT INTO tickets (channel, body) VALUES ('email', 'intrus');
    RAISE EXCEPTION 'grafana_ro ne doit pas pouvoir écrire';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM count(*) FROM channel_state;
    RAISE EXCEPTION 'grafana_ro ne doit pas lire channel_state';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;

\echo '7. Données de démo : chargement puis suppression'
\i /seed/seed_demo.sql
DO $$
BEGIN
  ASSERT (SELECT count(*) FROM tickets WHERE is_demo) > 0, 'seed_demo.sql vide';
  DELETE FROM tickets WHERE is_demo;
  ASSERT (SELECT count(*) FROM ticket_events e LEFT JOIN tickets t ON t.id = e.ticket_id WHERE t.id IS NULL) = 0,
         'journal nettoyé en cascade';
END $$;

\echo 'OK : tous les tests SQL passent.'
